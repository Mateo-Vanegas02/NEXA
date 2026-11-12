import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/permisos/permisos_dispositivo.dart';
import '../../../../core/providers.dart';
import '../../../../core/segundo_plano/modo_segundo_plano.dart';
import '../../../../core/segundo_plano/rastreador_ubicacion.dart';
import '../../../auth/domain/auth.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../domain/servicio.dart';
import 'aviso_viaje.dart';
import 'viaje_conductor_controller.dart';
import 'viaje_pasajero_controller.dart';

/// Prende y apaga el GPS en segundo plano según el estado que entrega el
/// servidor, nunca por su cuenta:
/// - conductor en línea → modo «en línea» (cada 15 s);
/// - conductor con viaje aceptado o en curso → modo «en viaje» (cada 3 s);
/// - pasajero con el conductor en camino → hasta que inicia el viaje;
/// - todo lo demás → apagado (sin notificación fija ni consumo de batería).
///
/// El reporte al servidor lo siguen haciendo los controladores del viaje con
/// su sondeo; el rastreador mantiene viva la app con la pantalla apagada y les
/// da una posición reciente. Se vigila desde la raíz de la app (`NexaApp`).
class CoordinadorSegundoPlano extends Notifier<ModoSegundoPlano> {
  Future<void> _cola = Future.value();

  /// Último texto publicado en la notificación fija (no se repite).
  AvisoViaje? _avisoPublicado;
  bool _hayAviso = false;

  @override
  ModoSegundoPlano build() {
    final rol = ref.watch(sesionProvider.select((s) => s.sesion?.rol));
    final rastreador = ref.read(rastreadorProvider);
    // Al cerrar sesión o cambiar de cuenta, se apaga.
    ref.onDispose(() => unawaited(rastreador.detener()));
    if (rol == Rol.conductor) {
      ref.listen(conductorProvider, (_, _) => _evaluar());
    } else if (rol == Rol.pasajero) {
      ref.listen(viajePasajeroProvider, (_, _) => _evaluar());
      // El ETA del conductor llega aparte: también actualiza la notificación.
      ref.listen(posicionConductorProvider, (_, _) => _evaluar());
    }
    // Un cambio que no se pudo aplicar en segundo plano se aplica al volver.
    ref.listen(primerPlanoProvider, (_, _) => _evaluar());
    return ModoSegundoPlano.apagado;
  }

  ModoSegundoPlano _deseado() {
    final rol = ref.read(sesionProvider).sesion?.rol;
    if (rol == Rol.conductor) {
      final s = ref.read(conductorProvider).value;
      if (s == null) return ModoSegundoPlano.apagado;
      return ReglasSegundoPlano.conductor(
        enLinea: s.enLinea,
        conViaje: s.activo != null,
      );
    }
    if (rol == Rol.pasajero) {
      final v = ref.read(viajePasajeroProvider).value;
      return ReglasSegundoPlano.pasajero(
        conductorEnCamino: v?.estado == EstadoServicio.aceptado,
      );
    }
    return ModoSegundoPlano.apagado;
  }

  /// Los cambios se aplican en orden, uno a la vez.
  void _evaluar() {
    _cola = _cola.then((_) => _aplicar()).catchError((Object _) {});
  }

  Future<void> _aplicar() async {
    await _cambiarModo();
    await _actualizarAviso();
  }

  /// Texto del viaje en la notificación fija, con lo que dice el servidor.
  Future<void> _actualizarAviso() async {
    final notificaciones = ref.read(notificacionesProvider);
    final aviso = switch (state) {
      ModoSegundoPlano.enViaje => TextosAvisoViaje.conductor(
        _textos,
        ref.read(conductorProvider).value ?? const ConductorState(),
      ),
      ModoSegundoPlano.pasajeroEnCamino => TextosAvisoViaje.pasajero(
        _textos,
        ref.read(viajePasajeroProvider).value,
        ref.read(posicionConductorProvider),
      ),
      _ => null,
    };
    // Sin viaje (en línea) queda el texto propio del servicio («En línea»).
    if (aviso == null || aviso == _avisoPublicado) return;
    _avisoPublicado = aviso;
    _hayAviso = true;
    await notificaciones.mostrarViaje(
      titulo: aviso.titulo,
      texto: aviso.texto,
      canal: _textos.segPlanoCanal,
      abrir: _textos.avisoAbrir,
    );
  }

  static AppLocalizations get _textos =>
      lookupAppLocalizations(const Locale('es'));

  Future<void> _cambiarModo() async {
    final nuevo = _deseado();
    if (nuevo == state) return;
    // Un modo nuevo reinicia el servicio con su texto propio.
    _avisoPublicado = null;
    final primerPlano = ref.read(primerPlanoProvider);
    if (!ReglasSegundoPlano.puedeCambiar(
      actual: state,
      nuevo: nuevo,
      primerPlano: primerPlano,
    )) {
      return;
    }
    final rastreador = ref.read(rastreadorProvider);
    if (nuevo == ModoSegundoPlano.apagado) {
      await rastreador.detener();
      if (_hayAviso) {
        _hayAviso = false;
        await ref.read(notificacionesProvider).cerrarViaje();
      }
      state = nuevo;
      return;
    }
    // Sin permiso de ubicación no hay servicio (las pantallas lo piden).
    try {
      if (!(await ref.read(permisosProvider).ubicacion()).concedida) return;
    } on Object {
      return;
    }
    await rastreador.iniciar(nuevo, _aviso(nuevo));
    state = nuevo;
  }

  static AvisoRastreo _aviso(ModoSegundoPlano modo) {
    final l = lookupAppLocalizations(const Locale('es'));
    return switch (modo) {
      ModoSegundoPlano.enViaje => AvisoRastreo(
        titulo: l.segPlanoViajeTitulo,
        texto: l.segPlanoViajeTexto,
        canal: l.segPlanoCanal,
      ),
      ModoSegundoPlano.pasajeroEnCamino => AvisoRastreo(
        titulo: l.segPlanoPasajeroTitulo,
        texto: l.segPlanoPasajeroTexto,
        canal: l.segPlanoCanal,
      ),
      _ => AvisoRastreo(
        titulo: l.segPlanoEnLineaTitulo,
        texto: l.segPlanoEnLineaTexto,
        canal: l.segPlanoCanal,
      ),
    };
  }
}

final coordinadorSegundoPlanoProvider =
    NotifierProvider<CoordinadorSegundoPlano, ModoSegundoPlano>(
      CoordinadorSegundoPlano.new,
    );
