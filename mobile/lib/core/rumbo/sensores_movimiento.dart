import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import 'reglas_rumbo.dart';

/// Sensores de movimiento del teléfono. Un sensor que no existe termina su
/// flujo con un error (así lo reporta Android): quien escucha lo trata como
/// «sin ese sensor».
abstract class SensoresMovimiento {
  Stream<Vector3> acelerometro();
  Stream<Vector3> magnetometro();
  Stream<Vector3> giroscopio();
}

/// Sensores reales (`sensors_plus`), a ~15 lecturas por segundo: basta para
/// girar el mapa y gasta poca batería.
class SensoresPlus implements SensoresMovimiento {
  const SensoresPlus();

  static const _ritmo = SensorInterval.uiInterval;

  @override
  Stream<Vector3> acelerometro() =>
      accelerometerEventStream(samplingPeriod: _ritmo)
          .map((e) => (x: e.x, y: e.y, z: e.z));

  @override
  Stream<Vector3> magnetometro() =>
      magnetometerEventStream(samplingPeriod: _ritmo)
          .map((e) => (x: e.x, y: e.y, z: e.z));

  @override
  Stream<Vector3> giroscopio() =>
      gyroscopeEventStream(samplingPeriod: _ritmo)
          .map((e) => (x: e.x, y: e.y, z: e.z));
}

/// Pruebas y plataformas sin sensores: ningún flujo emite.
class SensoresInactivos implements SensoresMovimiento {
  const SensoresInactivos();

  @override
  Stream<Vector3> acelerometro() => const Stream.empty();

  @override
  Stream<Vector3> magnetometro() => const Stream.empty();

  @override
  Stream<Vector3> giroscopio() => const Stream.empty();
}

/// Para pruebas: se le inyectan lecturas a mano y cuenta las suscripciones
/// (para comprobar que se apagan los sensores al salir).
class SensoresEnMemoria implements SensoresMovimiento {
  final acel = StreamController<Vector3>.broadcast();
  final mag = StreamController<Vector3>.broadcast();
  final giro = StreamController<Vector3>.broadcast();

  bool get escuchando =>
      acel.hasListener || mag.hasListener || giro.hasListener;

  @override
  Stream<Vector3> acelerometro() => acel.stream;

  @override
  Stream<Vector3> magnetometro() => mag.stream;

  @override
  Stream<Vector3> giroscopio() => giro.stream;
}
