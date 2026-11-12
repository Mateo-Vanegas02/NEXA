import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'reglas_rumbo.dart';

/// Cómo se orienta el mapa.
enum ModoOrientacion {
  /// Norte arriba (por defecto; no usa sensores).
  norte,

  /// Gira con el teléfono (botón de brújula).
  brujula,

  /// Modo navegación del conductor: gira con su avance y lo sigue.
  navegacion,
}

/// Aviso para quien mira el mapa.
enum AvisoOrientacion { ninguno, calibrar, sinBrujula }

class EstadoOrientacion {
  const EstadoOrientacion({
    this.modo = ModoOrientacion.norte,
    this.rumbo,
    this.fuente = FuenteRumbo.ninguna,
    this.aviso = AvisoOrientacion.ninguno,
  });

  final ModoOrientacion modo;

  /// Grados desde el norte (horario); null = norte arriba.
  final double? rumbo;
  final FuenteRumbo fuente;
  final AvisoOrientacion aviso;

  bool get orientado => modo != ModoOrientacion.norte;

  /// Cuánto se ve girado el mapa en pantalla (aguja y flecha).
  double get rotacionMapa =>
      rumbo == null ? 0 : ReglasRumbo.rotacionMapa(rumbo!);

  EstadoOrientacion copyWith({
    ModoOrientacion? modo,
    double? rumbo,
    bool sinRumbo = false,
    FuenteRumbo? fuente,
    AvisoOrientacion? aviso,
  }) => EstadoOrientacion(
    modo: modo ?? this.modo,
    rumbo: sinRumbo ? null : (rumbo ?? this.rumbo),
    fuente: fuente ?? this.fuente,
    aviso: aviso ?? this.aviso,
  );
}

/// Orientación del mapa a la vista. Solo escucha los sensores mientras el
/// mapa está orientado y la app a la vista; con la app en segundo plano o al
/// salir de la pantalla los apaga (ahorro de batería).
class OrientacionMapaController extends Notifier<EstadoOrientacion> {
  final _subs = <StreamSubscription<Object>>[];
  Timer? _latido;
  FusionRumbo _fusion = FusionRumbo();
  Vector3? _gravedad;
  Vector3? _magnetico;
  Vector3? _giroscopio;
  bool _sinMagnetometro = false;
  DateTime? _publicadoEn;

  /// Con «reducir movimiento» se gira menos seguido (lo pone la pantalla).
  bool sinAnimacion = false;

  /// La brújula mide hacia dónde apunta la parte de arriba del teléfono: en
  /// horizontal no coincide con la pantalla, así que solo vale el GPS.
  bool vertical = true;

  @override
  EstadoOrientacion build() {
    ref.onDispose(_apagar);
    ref.listen(primerPlanoProvider, (_, aLaVista) {
      if (!state.orientado) return;
      aLaVista ? _encender() : _apagar();
    });
    return const EstadoOrientacion();
  }

  void cambiarModo(ModoOrientacion modo) {
    if (modo == state.modo) return;
    if (modo == ModoOrientacion.norte) {
      _apagar();
      state = const EstadoOrientacion();
      return;
    }
    state = state.copyWith(modo: modo);
    if (ref.read(primerPlanoProvider)) _encender();
  }

  /// Botón de brújula: alterna entre norte arriba y girar con el teléfono.
  void alternarBrujula() => cambiarModo(
    state.modo == ModoOrientacion.norte
        ? ModoOrientacion.brujula
        : ModoOrientacion.norte,
  );

  void _encender() {
    if (_subs.isNotEmpty) return;
    _fusion = FusionRumbo();
    _gravedad = _magnetico = _giroscopio = null;
    _sinMagnetometro = false;
    final s = ref.read(sensoresProvider);
    _subs
      ..add(
        s.acelerometro().listen((v) => _gravedad = v, onError: (Object _) {}),
      )
      ..add(
        s.magnetometro().listen(
          (v) {
            _magnetico = v;
            _calcular();
          },
          onError: (Object _) {
            _sinMagnetometro = true;
            _calcular();
          },
        ),
      )
      ..add(
        s.giroscopio().listen((v) => _giroscopio = v, onError: (Object _) {}),
      );
    // Sin brújula (o con el teléfono quieto) el GPS igual puede dar rumbo.
    _latido = Timer.periodic(const Duration(seconds: 1), (_) => _calcular());
  }

  void _apagar() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
    _latido?.cancel();
    _latido = null;
  }

  void _calcular() {
    if (!state.orientado) return;
    final ahora = DateTime.now();
    _fusion.actualizar(
      gravedad: _gravedad,
      magnetico: _magnetico,
      giroscopio: _giroscopio,
      ahora: ahora,
      sinMagnetometro: _sinMagnetometro,
    );
    final gps = ref.read(rastreadorProvider).movimiento;
    final fuente = ReglasRumbo.elegirFuente(
      gps: gps,
      brujula: vertical ? _fusion.estado : EstadoBrujula.sinDatos,
      ahora: ahora,
    );
    final rumbo = switch (fuente) {
      FuenteRumbo.gps => ReglasRumbo.normalizar(gps!.rumbo),
      FuenteRumbo.sensores => _fusion.rumbo,
      FuenteRumbo.ninguna => null,
    };
    final aviso = switch (_fusion.estado) {
      EstadoBrujula.interferencia when fuente != FuenteRumbo.gps =>
        AvisoOrientacion.calibrar,
      EstadoBrujula.sinSensor when fuente != FuenteRumbo.gps =>
        AvisoOrientacion.sinBrujula,
      _ => AvisoOrientacion.ninguno,
    };
    final cambia = ReglasRumbo.debeActualizar(
      anterior: state.rumbo,
      nuevo: rumbo,
      anteriorEn: _publicadoEn,
      ahora: ahora,
      sinAnimacion: sinAnimacion,
    );
    if (!cambia && fuente == state.fuente && aviso == state.aviso) return;
    _publicadoEn = ahora;
    state = state.copyWith(
      rumbo: cambia ? rumbo : state.rumbo,
      sinRumbo: cambia && rumbo == null,
      fuente: fuente,
      aviso: aviso,
    );
  }
}

/// Se apaga solo (y con él los sensores) cuando ningún mapa lo mira.
final orientacionMapaProvider =
    NotifierProvider.autoDispose<OrientacionMapaController, EstadoOrientacion>(
      OrientacionMapaController.new,
    );
