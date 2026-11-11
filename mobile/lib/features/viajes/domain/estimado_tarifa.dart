/// Velocidad media urbana usada solo para mostrar un tiempo aproximado cuando el
/// servidor todavía no entregó el suyo (km/h). El precio nunca se calcula aquí:
/// lo cotiza el servidor.
const double kVelocidadUrbanaKmh = 21;

/// Minutos aproximados de viaje para [km] (mínimo 1).
int minutosEstimados(double km) =>
    (km / kVelocidadUrbanaKmh * 60).round().clamp(1, 999);
