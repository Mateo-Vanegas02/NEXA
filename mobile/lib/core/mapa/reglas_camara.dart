/// Acercamiento de navegación según la velocidad del GPS, en km/h.
abstract final class ReglasCamara {
  static double zoomPorVelocidad(double? kmh) {
    if (kmh == null || !kmh.isFinite || kmh < 0) return 17;
    if (kmh <= 15) return 17.5;
    if (kmh <= 30) return 17.5 - (kmh - 15) / 15;
    return 16.5 - ((kmh - 30) / 20).clamp(0.0, 1.0);
  }
}
