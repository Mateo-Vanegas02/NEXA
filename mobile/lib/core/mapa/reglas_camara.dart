/// Reglas puras de la cámara del mapa en navegación.
abstract final class ReglasCamara {
  /// Zoom sin un dato de velocidad válido.
  static const zoomRespaldo = 17.0;

  /// Acercamiento según la velocidad del GPS (km/h): cerca a paso lento
  /// (17,5 hasta 15 km/h), 16,5 a 30 km/h y 15,5 desde 50 km/h, interpolado
  /// entre esos puntos.
  static double zoomPorVelocidad(double? kmh) {
    if (kmh == null || !kmh.isFinite || kmh < 0) return zoomRespaldo;
    if (kmh <= 15) return 17.5;
    if (kmh <= 30) return 17.5 - (kmh - 15) / 15;
    return 16.5 - ((kmh - 30) / 20).clamp(0.0, 1.0);
  }
}
