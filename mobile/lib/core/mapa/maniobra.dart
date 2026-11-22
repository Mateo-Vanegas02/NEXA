import 'package:latlong2/latlong.dart';

import 'reglas_marcadores.dart';

/// Qué hacer en el siguiente cruce (tarjeta de navegación del conductor, G01).
enum Giro {
  recto,
  derecha,
  izquierda,
  ligeraDerecha,
  ligeraIzquierda,
  vuelta,
  llegada,
}

class Maniobra {
  const Maniobra({required this.giro, required this.metros, this.punto});

  final Giro giro;

  /// Dónde es el giro (para buscar el nombre de la calle).
  final LatLng? punto;

  /// Distancia hasta el cruce (o hasta el final de la ruta en [Giro.llegada]).
  final double metros;
}

/// Siguiente giro sobre la ruta del servidor, calculado con su trazado: se
/// mira dónde cambia el rumbo. El nombre de la calle sale de los pasos del
/// servidor (`calleDeManiobra`). Nada de esto toca el cobro.
abstract final class ReglasManiobra {
  /// Un cambio de rumbo menor a esto es «seguir derecho».
  static const giroMinimo = 35.0;

  /// Hasta aquí es un giro suave («ligeramente»).
  static const giroSuave = 60.0;

  /// Desde aquí es dar la vuelta.
  static const giroVuelta = 150.0;

  /// Más lejos de la ruta que esto = fuera de la ruta (sin maniobra).
  static const fueraDeRutaMetros = 60.0;

  static const _d = Distance();

  static double _m(LatLng a, LatLng b) => _d.as(LengthUnit.Meter, a, b);

  /// Diferencia de rumbo con signo, entre −180 y 180 (positivo = derecha).
  static double cambioRumbo(double desde, double hacia) {
    final d = ReglasMarcadores.normalizar(hacia - desde);
    return d > 180 ? d - 360 : d;
  }

  static Giro _giro(double cambio) {
    final a = cambio.abs();
    if (a < giroMinimo) return Giro.recto;
    if (a >= giroVuelta) return Giro.vuelta;
    if (a <= giroSuave) {
      return cambio > 0 ? Giro.ligeraDerecha : Giro.ligeraIzquierda;
    }
    return cambio > 0 ? Giro.derecha : Giro.izquierda;
  }

  /// Punto más cercano de la ruta a [p]: (índice del tramo, punto, distancia).
  static (int, LatLng, double) _proyectar(List<LatLng> ruta, LatLng p) {
    var mejor = (0, ruta.first, double.infinity);
    for (var i = 0; i < ruta.length - 1; i++) {
      final a = ruta[i];
      final b = ruta[i + 1];
      // Proyección plana (tramos cortos de una ciudad).
      final ax = a.longitude, ay = a.latitude;
      final bx = b.longitude, by = b.latitude;
      final dx = bx - ax, dy = by - ay;
      final largo = dx * dx + dy * dy;
      var t = largo == 0
          ? 0.0
          : ((p.longitude - ax) * dx + (p.latitude - ay) * dy) / largo;
      t = t.clamp(0.0, 1.0);
      final q = LatLng(ay + t * dy, ax + t * dx);
      final m = _m(p, q);
      if (m < mejor.$3) mejor = (i, q, m);
    }
    return mejor;
  }

  /// La siguiente maniobra desde [posicion]; null si la ruta no sirve o el
  /// conductor va fuera de ella.
  static Maniobra? siguiente(List<LatLng> ruta, LatLng posicion) {
    if (ruta.length < 2) return null;
    final (i, punto, lejos) = _proyectar(ruta, posicion);
    if (lejos > fueraDeRutaMetros) return null;
    var metros = _m(punto, ruta[i + 1]);
    for (var k = i + 1; k < ruta.length - 1; k++) {
      final cambio = cambioRumbo(
        ReglasMarcadores.rumboEntre(ruta[k - 1], ruta[k]),
        ReglasMarcadores.rumboEntre(ruta[k], ruta[k + 1]),
      );
      final giro = _giro(cambio);
      if (giro != Giro.recto) {
        return Maniobra(giro: giro, metros: metros, punto: ruta[k]);
      }
      metros += _m(ruta[k], ruta[k + 1]);
    }
    return Maniobra(giro: Giro.llegada, metros: metros, punto: ruta.last);
  }

  /// Distancia redondeada para leerla de un vistazo: de 10 en 10 m bajo 1 km,
  /// luego en km con un decimal.
  static String texto(double metros) {
    if (metros >= 1000) {
      return '${(metros / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
    }
    return '${(metros / 10).round() * 10} m';
  }
}
