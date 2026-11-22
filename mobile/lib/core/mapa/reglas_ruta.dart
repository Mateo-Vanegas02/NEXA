import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Punto de la ruta más cercano a una posición.
class Proyeccion {
  const Proyeccion({
    required this.tramo,
    required this.punto,
    required this.metros,
  });

  /// Índice del tramo (entre `ruta[tramo]` y `ruta[tramo + 1]`).
  final int tramo;

  /// El punto proyectado sobre la ruta.
  final LatLng punto;

  /// Distancia de la posición a la ruta, en metros.
  final double metros;
}

/// Reglas puras del trazado en el mapa (rediseño 2026): cuánto se alejó la
/// moto de la ruta y qué parte ya recorrió. No decide nada del negocio: la
/// ruta, la distancia y el ETA siguen saliendo del servidor.
abstract final class ReglasRuta {
  /// A más de esto de la ruta, la lectura cuenta como «fuera de ruta».
  static const umbralDesvioMetros = 35.0;

  /// Lecturas seguidas fuera de la ruta para dar el desvío por hecho (una
  /// sola puede ser ruido del GPS).
  static const lecturasDesvio = 2;

  /// Tras un aviso de desvío no se vuelve a avisar antes de esto.
  static const esperaEntreAvisos = Duration(seconds: 30);

  static const _mLat = 110540.0;
  static const _mLng = 111320.0;

  /// El punto de [ruta] más cercano a [p]; null si la ruta tiene menos de dos
  /// puntos. Usa una proyección plana local: sobra para unos pocos km.
  static Proyeccion? proyectar(List<LatLng> ruta, LatLng p) {
    if (ruta.length < 2) return null;
    final cosLat = math.cos(p.latitudeInRad);
    double x(LatLng q) => (q.longitude - p.longitude) * _mLng * cosLat;
    double y(LatLng q) => (q.latitude - p.latitude) * _mLat;
    Proyeccion? mejor;
    for (var i = 0; i < ruta.length - 1; i++) {
      final ax = x(ruta[i]);
      final ay = y(ruta[i]);
      final bx = x(ruta[i + 1]);
      final by = y(ruta[i + 1]);
      final dx = bx - ax;
      final dy = by - ay;
      final largo2 = dx * dx + dy * dy;
      // t = cuánto del tramo hay que avanzar para quedar frente a p (0..1).
      final t = largo2 == 0
          ? 0.0
          : ((-ax * dx - ay * dy) / largo2).clamp(0.0, 1.0);
      final px = ax + dx * t;
      final py = ay + dy * t;
      final d = math.sqrt(px * px + py * py);
      if (mejor == null || d < mejor.metros) {
        mejor = Proyeccion(
          tramo: i,
          punto: LatLng(
            p.latitude + py / _mLat,
            p.longitude + px / (_mLng * cosLat),
          ),
          metros: d,
        );
      }
    }
    return mejor;
  }

  /// Distancia en metros de [p] a la ruta (infinito sin ruta).
  static double distanciaA(List<LatLng> ruta, LatLng p) =>
      proyectar(ruta, p)?.metros ?? double.infinity;

  /// Divide la ruta donde queda la moto: lo recorrido (se apaga en el mapa)
  /// y lo que falta (brilla). Sin ruta, ambas vacías.
  static ({List<LatLng> recorrido, List<LatLng> falta}) dividir(
    List<LatLng> ruta,
    LatLng p,
  ) {
    final pr = proyectar(ruta, p);
    if (pr == null) return (recorrido: const [], falta: ruta);
    return (
      recorrido: [...ruta.sublist(0, pr.tramo + 1), pr.punto],
      falta: [pr.punto, ...ruta.sublist(pr.tramo + 1)],
    );
  }

  /// Interpola entre dos posiciones (t de 0 a 1) para que la moto se deslice
  /// entre un dato del GPS y el siguiente en vez de saltar.
  static LatLng interpolar(LatLng a, LatLng b, double t) {
    final k = t.clamp(0.0, 1.0);
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * k,
      a.longitude + (b.longitude - a.longitude) * k,
    );
  }

  /// Interpola un rumbo por el camino más corto (de 350° a 10° pasa por 0°).
  static double interpolarRumbo(double a, double b, double t) {
    final d = ((b - a + 540) % 360) - 180;
    return ((a + d * t.clamp(0.0, 1.0)) % 360 + 360) % 360;
  }
}

/// Decide cuándo la moto se salió de la ruta: [ReglasRuta.lecturasDesvio]
/// lecturas seguidas a más de [ReglasRuta.umbralDesvioMetros], y como mucho un
/// aviso cada [ReglasRuta.esperaEntreAvisos].
class DetectorDesvio {
  int _fuera = 0;
  DateTime? _ultimoAviso;

  /// Registra una lectura; true si es el momento de pedir rutas nuevas.
  bool registrar(List<LatLng> ruta, LatLng p, DateTime ahora) {
    if (ruta.length < 2) {
      _fuera = 0;
      return false;
    }
    if (ReglasRuta.distanciaA(ruta, p) <= ReglasRuta.umbralDesvioMetros) {
      _fuera = 0;
      return false;
    }
    _fuera++;
    if (_fuera < ReglasRuta.lecturasDesvio) return false;
    final ultimo = _ultimoAviso;
    if (ultimo != null &&
        ahora.difference(ultimo) < ReglasRuta.esperaEntreAvisos) {
      return false;
    }
    _ultimoAviso = ahora;
    _fuera = 0;
    return true;
  }

  /// Ruta nueva: se empieza a contar de cero.
  void reiniciar() => _fuera = 0;
}
