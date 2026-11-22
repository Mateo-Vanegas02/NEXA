import '../../../../core/config/env.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/tiempo_real/tiempo_real_provider.dart';
import '../../../../core/utils/mi_posicion.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../niveles/presentation/controllers/niveles_controller.dart';
import '../../domain/oferta_activa.dart';
import '../../domain/perfil_pasajero.dart';
import '../../domain/servicio.dart';
import '../../domain/viajes_repository.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Dónde va el conductor del viaje activo (ETA y distancia las calcula el servidor).
class PosicionConductorNotifier extends Notifier<PosicionViaje?> {
  @override
  PosicionViaje? build() => null;

  // ignore: use_setters_to_change_properties
  void poner(PosicionViaje? p) => state = p;
}

final posicionConductorProvider =
    NotifierProvider<PosicionConductorNotifier, PosicionViaje?>(
      PosicionConductorNotifier.new,
    );

/// Ola del despacho mientras la solicitud espera conductor (P04/E03).
class OfertaActivaNotifier extends Notifier<OfertaActiva?> {
  @override
  OfertaActiva? build() => null;

  // ignore: use_setters_to_change_properties
  void poner(OfertaActiva? o) => state = o;
}

final ofertaActivaProvider =
    NotifierProvider<OfertaActivaNotifier, OfertaActiva?>(
      OfertaActivaNotifier.new,
    );

/// Dónde está el pasajero mientras espera la moto (la última que se reportó
/// al servidor): el mapa lo pinta como personita con su haz.
class MiUbicacionViajeNotifier extends Notifier<LatLng?> {
  @override
  LatLng? build() => null;

  // ignore: use_setters_to_change_properties
  void poner(LatLng? p) => state = p;
}

final miUbicacionViajeProvider =
    NotifierProvider<MiUbicacionViajeNotifier, LatLng?>(
      MiUbicacionViajeNotifier.new,
    );

/// Cuenta cada vez que el conductor cambia la ruta del viaje en curso (tomó
/// otra calle y eligió una ruta nueva): la pantalla del viaje lo avisa.
class RutaCambiadaNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void avisar() => state++;
}

final rutaCambiadaProvider = NotifierProvider<RutaCambiadaNotifier, int>(
  RutaCambiadaNotifier.new,
);

/// La ruta de antes del último cambio (polyline), para dibujarla tenue un
/// rato y que se entienda por dónde va ahora.
class RutaAnteriorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void poner(String? geometria) => state = geometria;
}

final rutaAnteriorProvider = NotifierProvider<RutaAnteriorNotifier, String?>(
  RutaAnteriorNotifier.new,
);

/// Viaje en curso del pasajero (o recién finalizado, hasta que se califica).
///
/// Hace polling cada 5 s SOLO mientras el viaje está activo (el WebSocket del
/// backend autentica por sesión web, no por JWT). En cada ciclo:
/// - refresca el viaje (`GET /pasajero/servicios/{id}`);
/// - con conductor asignado, pide su posición (`/pasajero/posicion-conductor`);
/// - mientras el conductor va en camino (`ACEPTADO`), reporta dónde está el
///   pasajero para que el conductor lo vea.
class ViajePasajeroController extends AsyncNotifier<Servicio?> {
  Timer? _timer;
  Timer? _timerPosicion;
  bool _sondeando = false;
  bool _siguiendo = false;

  /// Suscripciones al canal en vivo (posición de la moto y cambios del viaje).
  final _enVivo = <void Function()>[];
  DateTime? _ultimoPush;

  @override
  Future<Servicio?> build() async {
    ref.onDispose(_detener);
    // Sin sesión (recién cerrada) no se consulta nada: respondería 401.
    if (sinSesionActiva(ref)) {
      return null;
    }
    final activo = await _buscarAbierto();
    if (activo != null) _iniciarPolling();
    return activo;
  }

  PasajeroRepository get _repo => ref.read(pasajeroRepositoryProvider);

  /// Solicitud que espera conductor o viaje en marcha. El servidor lo dice
  /// directo (el historial no trae las solicitudes que aún esperan).
  Future<Servicio?> _buscarAbierto() async {
    final repo = ref.read(pasajeroRepositoryProvider);
    final id = await repo.viajeAbiertoId();
    return id == null ? null : repo.detalle(id);
  }

  void _iniciarPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(Env.pollingInterval, (_) => sondear());
    // Rediseño 2026: la moto se consulta más seguido que el viaje, para que el
    // mapa la mueva fluida.
    _timerPosicion?.cancel();
    _timerPosicion = Timer.periodic(Env.pollingPosicion, (_) => seguirMoto());
    _escucharEnVivo();
  }

  /// Con el canal en vivo, la moto llega apenas el conductor la envía y un
  /// cambio del viaje se consulta al instante; el sondeo queda de respaldo.
  void _escucharEnVivo() {
    if (_enVivo.isNotEmpty) return;
    final canal = ref.read(canalTiempoRealProvider);
    final uid = ref.read(sesionProvider).sesion?.userId;
    if (canal == null || uid == null) return;
    _enVivo
      ..add(
        canal.suscribir('/topic/pasajero/$uid/posicion', (json) {
          final actual = state.value;
          if (json is! Map<String, dynamic> ||
              actual == null ||
              json['servicioId'] != actual.id) {
            return;
          }
          try {
            ref
                .read(posicionConductorProvider.notifier)
                .poner(PosicionViaje.fromJson(json));
            _ultimoPush = DateTime.now();
          } on Object {
            // Mensaje incompleto: lo cubre el sondeo.
          }
        }),
      )
      ..add(
        canal.suscribir('/topic/pasajero/$uid', (_) => unawaited(sondear())),
      );
  }

  void _detener() {
    for (final cancelar in _enVivo) {
      cancelar();
    }
    _enVivo.clear();
    _timer?.cancel();
    _timer = null;
    _timerPosicion?.cancel();
    _timerPosicion = null;
  }

  /// Con el conductor asignado, solo la posición de la moto (cada 2 s).
  Future<void> seguirMoto() async {
    final actual = state.value;
    // Si el canal en vivo acaba de traerla, no hace falta preguntar.
    final push = _ultimoPush;
    if (push != null &&
        DateTime.now().difference(push) < const Duration(seconds: 3)) {
      return;
    }
    if (actual == null ||
        _sondeando ||
        _siguiendo ||
        (actual.estado != EstadoServicio.aceptado &&
            actual.estado != EstadoServicio.enCurso)) {
      return;
    }
    _siguiendo = true;
    try {
      final p = await _repo.posicionConductor(actual.id);
      if (p != null && state.value?.id == actual.id) {
        ref.read(posicionConductorProvider.notifier).poner(p);
      }
    } on Object {
      // Se conserva la anterior; el ciclo de 5 s vuelve a intentar.
    } finally {
      _siguiendo = false;
    }
  }

  Future<void> sondear() async {
    final actual = state.value;
    if (actual == null || !actual.estado.activo) {
      _detener();
      return;
    }
    // Evita ciclos encimados si la red va lenta.
    if (_sondeando) return;
    _sondeando = true;
    try {
      final nuevo = await _repo.detalle(actual.id);
      // El conductor tomó otra calle y eligió una ruta nueva.
      if (actual.estado == EstadoServicio.enCurso &&
          nuevo.estado == EstadoServicio.enCurso &&
          actual.rutaGeometria != null &&
          nuevo.rutaGeometria != null &&
          actual.rutaGeometria != nuevo.rutaGeometria) {
        ref.read(rutaAnteriorProvider.notifier).poner(actual.rutaGeometria);
        ref.read(rutaCambiadaProvider.notifier).avisar();
      }
      state = AsyncData(nuevo);
      if (!nuevo.estado.activo) {
        _detener();
        ref.read(posicionConductorProvider.notifier).poner(null);
        ref.read(rutaAnteriorProvider.notifier).poner(null);
        if (nuevo.estado == EstadoServicio.finalizado) {
          unawaited(
            ref
                .read(nivelProvider.notifier)
                .viajeCompletado(nuevo.xpGanadoPasajero),
          );
        }
        return;
      }
      await _seguimiento(nuevo);
    } on Object {
      // Fallo de red transitorio: se reintenta en el siguiente ciclo.
    } finally {
      _sondeando = false;
    }
  }

  Future<void> _seguimiento(Servicio s) async {
    if (s.estado == EstadoServicio.solicitado) {
      ref.read(posicionConductorProvider.notifier).poner(null);
      try {
        ref
            .read(ofertaActivaProvider.notifier)
            .poner(await _repo.ofertaActiva());
      } on Object {
        // Sin la ola por ahora: la pantalla muestra el texto general.
      }
      return;
    }
    ref.read(ofertaActivaProvider.notifier).poner(null);
    try {
      ref
          .read(posicionConductorProvider.notifier)
          .poner(await _repo.posicionConductor(s.id));
    } on Object {
      // Sin posición por ahora: se conserva la anterior.
    }
    if (s.estado != EstadoServicio.aceptado) {
      // Ya va en la moto: solo se ve la moto.
      ref.read(miUbicacionViajeProvider.notifier).poner(null);
      return;
    }
    final yo = await ref.read(miPosicionProvider)();
    if (yo == null) return;
    ref.read(miUbicacionViajeProvider.notifier).poner(yo);
    try {
      await _repo.reportarUbicacion(
        s.id,
        Coordenada(latitud: yo.latitude, longitud: yo.longitude),
      );
    } on Object {
      // Solo ayuda al conductor a ubicarte: no debe interrumpir el viaje.
    }
  }

  Future<void> solicitar(SolicitudViaje solicitud) async {
    // Un segundo toque mientras va la primera petición no pide otro viaje.
    if (_solicitando) return;
    _solicitando = true;
    try {
      final s = await _repo.solicitar(solicitud);
      state = AsyncData(s);
      _iniciarPolling();
    } on AppException catch (e) {
      // 409: ya hay una solicitud o un viaje abierto (p. ej. la respuesta de
      // la primera no llegó). Se retoma en vez de dejar al pasajero bloqueado.
      if (e.statusCode == 409 && await _retomar()) return;
      rethrow;
    } finally {
      _solicitando = false;
    }
  }

  bool _solicitando = false;

  /// Vuelve a buscar el viaje abierto en el servidor; true si lo encontró.
  Future<bool> _retomar() async {
    try {
      final activo = await _buscarAbierto();
      if (activo == null) return false;
      state = AsyncData(activo);
      _iniciarPolling();
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> cancelar() async {
    final actual = state.value;
    if (actual == null) return;
    await _repo.cancelar(actual.id);
    _detener();
    ref.read(posicionConductorProvider.notifier).poner(null);
    state = const AsyncData(null);
  }

  /// Suma un extra voluntario mientras se busca conductor (el servidor limita el total).
  Future<void> subirExtra(int incremento) async {
    final actual = state.value;
    if (actual == null) return;
    await _repo.subirExtra(actual.id, incremento);
    await sondear();
  }

  /// Cierra el viaje terminado (tras calificar u omitir).
  void cerrar() {
    ref.read(posicionConductorProvider.notifier).poner(null);
    state = const AsyncData(null);
  }

  Future<void> calificar(
    double calificacion,
    String comentarios, {
    List<String> factores = const [],
  }) async {
    final actual = state.value;
    if (actual == null) return;
    await _repo.calificar(
      actual.id,
      calificacion,
      comentarios,
      factores: factores,
    );
    cerrar();
    ref.invalidate(historialPasajeroProvider);
  }
}

final viajePasajeroProvider =
    AsyncNotifierProvider<ViajePasajeroController, Servicio?>(
      ViajePasajeroController.new,
    );

final historialPasajeroProvider = FutureProvider<List<Servicio>>((ref) {
  if (sinSesionActiva(ref)) {
    return const [];
  }
  return ref.watch(pasajeroRepositoryProvider).historial();
});

final perfilPasajeroProvider = FutureProvider<PerfilPasajero>((ref) {
  // Sin sesión queda cargando: no hay perfil que pedir (evita un 401).
  if (sinSesionActiva(ref)) {
    return Completer<PerfilPasajero>().future;
  }
  return ref.watch(pasajeroRepositoryProvider).perfil();
});

final desglosePasajeroProvider =
    FutureProvider.family<DesglosePasajero, String>(
      (ref, id) => ref.watch(pasajeroRepositoryProvider).desglose(id),
    );
