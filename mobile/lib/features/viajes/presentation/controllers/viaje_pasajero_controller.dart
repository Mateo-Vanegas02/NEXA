import '../../../../core/config/env.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/mi_posicion.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../niveles/presentation/controllers/niveles_controller.dart';
import '../../domain/perfil_pasajero.dart';
import '../../domain/servicio.dart';
import '../../domain/viajes_repository.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  bool _sondeando = false;

  @override
  Future<Servicio?> build() async {
    ref.onDispose(_detener);
    ref.watch(sesionProvider.select((s) => s.sesion?.email));
    final historial = await ref.read(pasajeroRepositoryProvider).historial();
    final activo = historial.where((s) => s.estado.activo).firstOrNull;
    if (activo != null) _iniciarPolling();
    return activo;
  }

  PasajeroRepository get _repo => ref.read(pasajeroRepositoryProvider);

  void _iniciarPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(Env.pollingInterval, (_) => sondear());
  }

  void _detener() {
    _timer?.cancel();
    _timer = null;
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
      state = AsyncData(nuevo);
      if (!nuevo.estado.activo) {
        _detener();
        ref.read(posicionConductorProvider.notifier).poner(null);
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
      return;
    }
    try {
      ref
          .read(posicionConductorProvider.notifier)
          .poner(await _repo.posicionConductor(s.id));
    } on Object {
      // Sin posición por ahora: se conserva la anterior.
    }
    if (s.estado != EstadoServicio.aceptado) return;
    final yo = await ref.read(miPosicionProvider)();
    if (yo == null) return;
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
    final s = await _repo.solicitar(solicitud);
    state = AsyncData(s);
    _iniciarPolling();
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

  Future<void> calificar(double calificacion, String comentarios) async {
    final actual = state.value;
    if (actual == null) return;
    await _repo.calificar(actual.id, calificacion, comentarios);
    cerrar();
    ref.invalidate(historialPasajeroProvider);
  }
}

final viajePasajeroProvider =
    AsyncNotifierProvider<ViajePasajeroController, Servicio?>(
      ViajePasajeroController.new,
    );

final historialPasajeroProvider = FutureProvider<List<Servicio>>((ref) {
  ref.watch(sesionProvider.select((s) => s.sesion?.email));
  return ref.watch(pasajeroRepositoryProvider).historial();
});

final perfilPasajeroProvider = FutureProvider<PerfilPasajero>((ref) {
  ref.watch(sesionProvider.select((s) => s.sesion?.email));
  return ref.watch(pasajeroRepositoryProvider).perfil();
});

final desglosePasajeroProvider =
    FutureProvider.family<DesglosePasajero, String>(
      (ref, id) => ref.watch(pasajeroRepositoryProvider).desglose(id),
    );
