import '../../../../core/config/env.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/segundo_plano/modo_segundo_plano.dart';
import '../../../../core/utils/mi_posicion.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../niveles/presentation/controllers/niveles_controller.dart';
import '../../domain/servicio.dart';
import '../../domain/viajes_repository.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fase visible del viaje del conductor (la deduce el estado y `fechaLlegada`).
enum FaseConductor { aRecoger, enElPunto, enViaje }

class ConductorState {
  const ConductorState({
    this.aprobacion = EstadoAprobacion.pendiente,
    this.enLinea = false,
    this.solicitudes = const [],
    this.activo,
    this.posicion,
    this.pasajero,
    this.terminado,
    this.desgloseTerminado,
    this.pasajeroCancelo = false,
  });

  final EstadoAprobacion aprobacion;
  final bool enLinea;
  final List<Servicio> solicitudes;
  final Servicio? activo;

  /// Posición propia con la fase, distancia y ETA que calcula el servidor.
  final PosicionViaje? posicion;

  /// Dónde está el pasajero mientras el conductor va a recogerlo.
  final PosicionPasajero? pasajero;

  /// Viaje recién finalizado, hasta que el conductor cierra el resumen.
  final Servicio? terminado;
  final DesgloseConductor? desgloseTerminado;

  /// El pasajero canceló el viaje que tenía activo el conductor.
  final bool pasajeroCancelo;

  FaseConductor? get fase {
    final a = activo;
    if (a == null) return null;
    if (a.estado == EstadoServicio.enCurso) return FaseConductor.enViaje;
    return a.fechaLlegada == null
        ? FaseConductor.aRecoger
        : FaseConductor.enElPunto;
  }

  ConductorState copyWith({
    EstadoAprobacion? aprobacion,
    bool? enLinea,
    List<Servicio>? solicitudes,
    Servicio? activo,
    bool limpiarActivo = false,
    PosicionViaje? posicion,
    bool limpiarPosicion = false,
    PosicionPasajero? pasajero,
    bool limpiarPasajero = false,
    Servicio? terminado,
    DesgloseConductor? desgloseTerminado,
    bool limpiarTerminado = false,
    bool? pasajeroCancelo,
  }) => ConductorState(
    aprobacion: aprobacion ?? this.aprobacion,
    enLinea: enLinea ?? this.enLinea,
    solicitudes: solicitudes ?? this.solicitudes,
    activo: limpiarActivo ? null : (activo ?? this.activo),
    posicion: limpiarPosicion ? null : (posicion ?? this.posicion),
    pasajero: limpiarPasajero ? null : (pasajero ?? this.pasajero),
    terminado: limpiarTerminado ? null : (terminado ?? this.terminado),
    desgloseTerminado: limpiarTerminado
        ? null
        : (desgloseTerminado ?? this.desgloseTerminado),
    pasajeroCancelo: pasajeroCancelo ?? this.pasajeroCancelo,
  );
}

/// Panel del conductor: aprobación, conexión, solicitudes y viaje activo.
///
/// Mientras está en línea o tiene un viaje, cada 5 s:
/// - reporta su posición (`POST /conductor/ubicacion`): sin esto el servidor solo
///   le muestra las solicitudes de la última ola de despacho;
/// - en línea y libre, pide las solicitudes cercanas;
/// - con un viaje, refresca el viaje (detecta si el pasajero lo canceló), toma
///   la fase/ETA que calcula el servidor y, yendo a recoger, la posición del pasajero.
class ConductorController extends AsyncNotifier<ConductorState> {
  Timer? _timer;
  bool _sondeando = false;
  int _ciclo = 0;
  final Set<String> _rechazadas = {};

  @override
  Future<ConductorState> build() async {
    ref.onDispose(() => _timer?.cancel());
    ref.watch(sesionProvider.select((s) => s.sesion?.email));
    final aprobacion = await ref
        .read(authRepositoryProvider)
        .estadoAprobacion();
    if (aprobacion != EstadoAprobacion.aprobado) {
      return ConductorState(aprobacion: aprobacion);
    }
    final activo = await _repo.viajeActivo();
    if (activo != null) _iniciarPolling();
    return ConductorState(aprobacion: aprobacion, activo: activo);
  }

  ConductorRepository get _repo => ref.read(conductorRepositoryProvider);

  ConductorState get _s => state.requireValue;

  void _iniciarPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(Env.pollingInterval, (_) => sondear());
  }

  Coordenada _coord(({double lat, double lng}) p) =>
      Coordenada(latitud: p.lat, longitud: p.lng);

  Future<({double lat, double lng})?> _gps() async {
    final p = await ref.read(miPosicionProvider)();
    return p == null ? null : (lat: p.latitude, lng: p.longitude);
  }

  Future<void> sondear() async {
    final actual = state.value;
    if (actual == null) return;
    if (!actual.enLinea && actual.activo == null) {
      _timer?.cancel();
      return;
    }
    if (_sondeando) return;
    // Pantalla apagada y sin viaje: cada 15 s en vez de cada 5 s.
    if (ReglasSegundoPlano.saltarCiclo(
      primerPlano: ref.read(primerPlanoProvider),
      conViaje: actual.activo != null,
      ciclo: _ciclo++,
    )) {
      return;
    }
    _sondeando = true;
    try {
      final gps = await _gps();
      if (actual.activo != null) {
        await _sondearViaje(actual.activo!, gps);
      } else {
        PosicionViaje? aVer;
        if (gps != null) {
          aVer = await _repo.reportarUbicacion(_coord(gps), disponible: true);
        }
        // Si acaba de aceptar un viaje desde otro lado, el servidor ya lo sigue.
        if (aVer != null) {
          final activo = await _repo.viajeActivo();
          if (activo != null) {
            state = AsyncData(_s.copyWith(activo: activo));
            return;
          }
        }
        final solicitudes = (await _repo.disponibles(
          lat: gps?.lat,
          lng: gps?.lng,
        )).where((s) => !_rechazadas.contains(s.id)).toList();
        state = AsyncData(_s.copyWith(solicitudes: solicitudes));
      }
    } on Object {
      // Se reintenta en el siguiente ciclo.
    } finally {
      _sondeando = false;
    }
  }

  Future<void> _sondearViaje(
    Servicio activo,
    ({double lat, double lng})? gps,
  ) async {
    PosicionViaje? posicion;
    if (gps != null) {
      posicion = await _repo.reportarUbicacion(_coord(gps), disponible: false);
    }
    final vigente = await _repo.viajeActivo();
    if (vigente == null) {
      // 204: el viaje ya no está activo (lo canceló el pasajero).
      _timer?.cancel();
      state = AsyncData(
        _s.copyWith(
          limpiarActivo: true,
          limpiarPosicion: true,
          limpiarPasajero: true,
          pasajeroCancelo: true,
        ),
      );
      return;
    }
    PosicionPasajero? pasajero;
    if (vigente.estado == EstadoServicio.aceptado) {
      pasajero = await _repo.ubicacionPasajero(vigente.id);
    }
    state = AsyncData(
      _s.copyWith(
        activo: vigente,
        posicion: posicion,
        limpiarPosicion: posicion == null,
        pasajero: pasajero,
        limpiarPasajero: pasajero == null,
      ),
    );
  }

  Future<void> alternarLinea() async {
    final enLinea = !_s.enLinea;
    state = AsyncData(_s.copyWith(enLinea: enLinea, pasajeroCancelo: false));
    if (enLinea) {
      _iniciarPolling();
      await sondear();
    } else {
      state = AsyncData(_s.copyWith(solicitudes: const []));
      if (_s.activo == null) _timer?.cancel();
      // Avisa al servidor para que deje de despacharle solicitudes.
      final gps = await _gps();
      if (gps != null) {
        try {
          await _repo.reportarUbicacion(_coord(gps), disponible: false);
        } on Object {
          // Sin conexión: el servidor lo da por desconectado a los 45 s.
        }
      }
    }
  }

  /// Acepta una solicitud. Si otro conductor la tomó (409) o ya no está en su
  /// ola (403), se quita de la lista y el error llega a la pantalla.
  Future<void> aceptar(Servicio s) => aceptarPorId(s.id);

  /// Igual que [aceptar], con solo el id (botón «Aceptar» de la notificación).
  /// Espera a que el panel termine de cargar si la app acaba de abrirse.
  Future<void> aceptarPorId(String id) async {
    await future;
    try {
      final nuevo = await _repo.aceptar(id);
      state = AsyncData(
        _s.copyWith(
          activo: nuevo,
          solicitudes: const [],
          pasajeroCancelo: false,
        ),
      );
      _iniciarPolling();
    } on Object catch (e) {
      final codigo = AppException.from(e).statusCode;
      if (codigo == 409 || codigo == 403 || codigo == 404) {
        state = AsyncData(
          _s.copyWith(
            solicitudes: [..._s.solicitudes.where((x) => x.id != id)],
          ),
        );
      }
      rethrow;
    }
  }

  /// El backend no tiene "rechazar": se oculta localmente (PENDIENTES_BACKEND.md).
  void rechazar(Servicio s) {
    _rechazadas.add(s.id);
    state = AsyncData(
      _s.copyWith(solicitudes: [..._s.solicitudes.where((e) => e.id != s.id)]),
    );
  }

  /// Avanza el viaje: "Llegué" → iniciar → finalizar. El servidor valida cada
  /// paso (llegada a ≤ 50 m de la recogida; sin "llegué" no deja iniciar).
  Future<void> avanzar() async {
    final activo = _s.activo;
    final fase = _s.fase;
    if (activo == null || fase == null) return;
    switch (fase) {
      case FaseConductor.aRecoger:
        final gps = await _gps();
        if (gps == null) {
          throw const AppException(
            ErrorKind.validacion,
            'No pudimos obtener tu ubicación. Activa el GPS e inténtalo de nuevo.',
          );
        }
        final nuevo = await _repo.llegue(activo.id, _coord(gps));
        state = AsyncData(_s.copyWith(activo: nuevo));
      case FaseConductor.enElPunto:
        state = AsyncData(_s.copyWith(activo: await _repo.iniciar(activo.id)));
      case FaseConductor.enViaje:
        final fin = await _repo.finalizar(activo.id);
        DesgloseConductor? desglose;
        try {
          desglose = await _repo.desglose(fin.id);
        } on Object {
          // El resumen se muestra igual con el total del viaje.
        }
        state = AsyncData(
          _s.copyWith(
            limpiarActivo: true,
            limpiarPosicion: true,
            limpiarPasajero: true,
            terminado: fin,
            desgloseTerminado: desglose,
          ),
        );
        if (!_s.enLinea) _timer?.cancel();
        ref.invalidate(ingresosProvider);
        ref.invalidate(saldoProvider);
        await ref
            .read(nivelProvider.notifier)
            .viajeCompletado(fin.xpGanadoConductor);
    }
  }

  Future<void> cancelarActivo() async {
    final activo = _s.activo;
    if (activo == null) return;
    await _repo.cancelar(activo.id);
    state = AsyncData(
      _s.copyWith(
        limpiarActivo: true,
        limpiarPosicion: true,
        limpiarPasajero: true,
      ),
    );
    if (!_s.enLinea) _timer?.cancel();
  }

  void cerrarResumen() =>
      state = AsyncData(_s.copyWith(limpiarTerminado: true));

  void descartarAvisoCancelacion() =>
      state = AsyncData(_s.copyWith(pasajeroCancelo: false));
}

final conductorProvider =
    AsyncNotifierProvider<ConductorController, ConductorState>(
      ConductorController.new,
    );

final ingresosProvider = FutureProvider<List<Ingreso>>(
  (ref) => ref.watch(conductorRepositoryProvider).ingresos(),
);

/// Saldo con NEXA de los últimos 30 días (vista del conductor: sin comisión).
final saldoProvider = FutureProvider<SaldoConductor>(
  (ref) => ref.watch(conductorRepositoryProvider).saldo(),
);
