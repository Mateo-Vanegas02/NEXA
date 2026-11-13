import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Dónde queda algo (la moto) respecto de hacia dónde apunta el teléfono.
enum LadoRelativo { deFrente, derecha, izquierda, detras }

/// Reglas puras de los marcadores del mapa (diseño «Quién es quién», M01–M05).
///
/// Solo deciden lo que se dibuja; la posición, la distancia y el ETA siguen
/// llegando del servidor.
abstract final class ReglasMarcadores {
  /// Medio ancho del cono «de frente» (±30°) y del cono «detrás» (180° ± 30°).
  static const conoFrente = 30.0;
  static const conoDetras = 30.0;

  /// Por debajo de este avance el rumbo de la moto no se recalcula: con el
  /// GPS quieto daría direcciones al azar.
  static const avanceMinimoMetros = 5.0;

  /// Con una posición más vieja que esto la moto se pinta «sin señal».
  static const sinSenalTras = Duration(seconds: 20);

  static const _distancia = Distance();

  static double normalizar(double grados) => ((grados % 360) + 360) % 360;

  /// Rumbo inicial de [desde] a [hasta] (grados desde el norte, horario).
  static double rumboEntre(LatLng desde, LatLng hasta) {
    final f1 = desde.latitudeInRad;
    final f2 = hasta.latitudeInRad;
    final dl = (hasta.longitude - desde.longitude) * math.pi / 180;
    final y = math.sin(dl) * math.cos(f2);
    final x =
        math.cos(f1) * math.sin(f2) -
        math.sin(f1) * math.cos(f2) * math.cos(dl);
    return normalizar(math.atan2(y, x) * 180 / math.pi);
  }

  /// Hacia dónde avanza la moto; null si casi no se movió (se conserva el
  /// rumbo anterior).
  static double? rumboDeAvance(LatLng? anterior, LatLng actual) {
    if (anterior == null) return null;
    if (_distancia.as(LengthUnit.Meter, anterior, actual) <
        avanceMinimoMetros) {
      return null;
    }
    return rumboEntre(anterior, actual);
  }

  /// Lado en el que queda un objetivo a [haciaObjetivo] grados para quien
  /// mira hacia [rumboTelefono].
  static LadoRelativo ladoRelativo({
    required double rumboTelefono,
    required double haciaObjetivo,
  }) {
    final d = normalizar(haciaObjetivo - rumboTelefono);
    if (d <= conoFrente || d >= 360 - conoFrente) return LadoRelativo.deFrente;
    if (d >= 180 - conoDetras && d <= 180 + conoDetras) {
      return LadoRelativo.detras;
    }
    return d < 180 ? LadoRelativo.derecha : LadoRelativo.izquierda;
  }

  /// La moto está sin señal si su última posición tiene más de [sinSenalTras].
  static bool sinSenal(int haceSegundos) =>
      haceSegundos > sinSenalTras.inSeconds;
}
