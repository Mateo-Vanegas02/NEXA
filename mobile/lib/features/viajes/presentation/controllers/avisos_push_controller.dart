import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../avisos/notificaciones_screen.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/providers.dart';
import '../../../../core/push/aviso_push.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/domain/auth.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import 'viaje_conductor_controller.dart';
import 'viaje_pasajero_controller.dart';

/// Une los avisos push con la app abierta (se vigila desde `NexaApp`):
/// - registra el token del teléfono al tener sesión y cuando FCM lo rota (el
///   `DELETE` antes de cerrar sesión lo hace `SesionController.logout`);
/// - un aviso con la app a la vista no se muestra: refresca el viaje o las
///   solicitudes al instante, sin esperar el siguiente sondeo;
/// - tocar un aviso abre la pantalla que corresponde y «Aceptar» toma la
///   solicitud (el servidor decide: 409 si otro conductor la tomó).
///
/// El estado es un mensaje para la pantalla del conductor cuando «Aceptar»
/// no se pudo (null si no hay nada que avisar).
class AvisosPushController extends Notifier<String?> {
  /// `correo|token` ya registrado en el servidor (no se repite).
  String? _registrado;

  /// Toque que llegó antes de restaurar la sesión.
  AvisoPush? _pendiente;

  @override
  String? build() {
    final push = ref.watch(servicioPushProvider);
    if (!push.activo) return null;
    final subs = <StreamSubscription<Object>>[
      push.tokenRenovado.listen((t) => unawaited(_registrar(t))),
      push.recibidos.listen((a) => unawaited(_recibido(a))),
      push.tocados.listen((a) => unawaited(_tocado(a))),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        unawaited(s.cancel());
      }
    });
    ref.listen(
      sesionProvider.select((s) => (s.inicializado, s.sesion?.email)),
      (_, _) => unawaited(_alCambiarSesion()),
      fireImmediately: true,
    );
    unawaited(_leerTocadoAlAbrir());
    return null;
  }

  Rol? get _rol => ref.read(sesionProvider).sesion?.rol;

  bool get _conSesion {
    final s = ref.read(sesionProvider);
    return s.inicializado && s.sesion != null;
  }

  Future<void> _leerTocadoAlAbrir() async {
    try {
      final aviso = await ref.read(servicioPushProvider).tocadoAlAbrir();
      if (aviso != null) await _tocado(aviso);
    } on Object catch (e) {
      debugPrint('No se pudo leer el aviso que abrió la app: $e');
    }
  }

  Future<void> _alCambiarSesion() async {
    if (!_conSesion) {
      _registrado = null;
      return;
    }
    try {
      final token = await ref.read(servicioPushProvider).token();
      if (token != null) await _registrar(token);
    } on Object catch (e) {
      debugPrint('Sin token de avisos: $e');
    }
    final pendiente = _pendiente;
    _pendiente = null;
    if (pendiente != null) await _tocado(pendiente);
  }

  Future<void> _registrar(String token) async {
    final correo = ref.read(sesionProvider).sesion?.email;
    if (correo == null) return;
    final clave = '$correo|$token';
    if (clave == _registrado) return;
    try {
      await ref.read(dispositivosRepositoryProvider).registrar(token);
      _registrado = clave;
    } on Object catch (e) {
      // Se reintenta al próximo inicio de sesión o rotación del token.
      debugPrint('No se pudo registrar el teléfono para avisos: $e');
    }
  }

  Future<void> _recibido(AvisoPush aviso) async {
    if (!_conSesion ||
        !await ref
            .read(eventosVistosProvider)
            .reservar('recibido:${aviso.eventoId}')) {
      return;
    }
    // La búsqueda que se amplía no es un aviso para la bandeja.
    if (!aviso.esDeBusqueda) {
      try {
        await ref.read(bandejaAvisosProvider).registrar(aviso);
        ref.invalidate(bandejaProvider);
      } on Object catch (e) {
        debugPrint('Bandeja de avisos: $e');
      }
    }
    if (aviso.tipo == TipoAviso.solicitudRetirada) {
      await ref
          .read(servicioPushProvider)
          .quitarNotificacion(aviso.idNotificacion);
    }
    await _refrescar();
  }

  Future<void> _refrescar() async {
    switch (_rol) {
      case Rol.conductor:
        await ref.read(conductorProvider.notifier).sondear();
      case Rol.pasajero:
        await ref.read(viajePasajeroProvider.notifier).sondear();
      case Rol.admin || null:
        break;
    }
  }

  Future<void> _tocado(AvisoPush aviso) async {
    if (!_conSesion) {
      _pendiente = aviso;
      return;
    }
    if (!await ref
        .read(eventosVistosProvider)
        .reservar('tocado:${aviso.eventoId}')) {
      return;
    }
    final rol = _rol!;
    if (aviso.esSolicitud) {
      await ref
          .read(servicioPushProvider)
          .quitarNotificacion(aviso.idNotificacion);
    }
    var ruta = aviso.rutaAlTocar(rol);
    if (rol == Rol.pasajero && ruta == '/p/viaje') {
      // El aviso solo despierta la app: el servidor decide cuál viaje sigue abierto.
      final vigente = await ref.read(viajePasajeroProvider.future);
      ruta = aviso.rutaConViajeVigente(rol, vigente?.id);
    }
    ref.read(routerProvider).go(ruta);
    final id = aviso.servicioId;
    if (rol == Rol.conductor &&
        aviso.esSolicitud &&
        aviso.accion == AccionAviso.aceptar &&
        id != null) {
      await _aceptar(id);
      return;
    }
    await _refrescar();
  }

  Future<void> _aceptar(String id) async {
    try {
      await ref.read(conductorProvider.notifier).aceptarPorId(id);
    } on Object catch (e) {
      final error = AppException.from(e);
      final t = lookupAppLocalizations(const Locale('es'));
      state = switch (error.statusCode) {
        409 || 403 || 404 => t.pushSolicitudNoDisponible,
        _ => error.mensaje,
      };
    }
  }

  /// La pantalla ya mostró el mensaje.
  void consumirMensaje() => state = null;
}

final avisosPushProvider = NotifierProvider<AvisosPushController, String?>(
  AvisosPushController.new,
);
