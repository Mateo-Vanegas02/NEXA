import 'package:latlong2/latlong.dart';

/// Zona donde NEXA presta el servicio: el área urbana de Cartagena alcanzable
/// en moto (de Bayunca y Manzanillo del Mar a Pasacaballos, con Mamonal; deja
/// por fuera Turbaco, Tierra Bomba y Barú).
///
/// Es una copia del polígono del servidor (`nexa.zona.poligono` en
/// `modelo-nexa.properties`, rama `main`): si cambia allá, cambia aquí. El
/// servidor sigue siendo el que decide al cotizar; la app lo usa para no
/// ofrecer lugares de afuera y avisar antes.
abstract final class ZonaServicio {
  static const poligono = <LatLng>[
    LatLng(10.545, -75.505),
    LatLng(10.560, -75.440),
    LatLng(10.545, -75.395),
    LatLng(10.420, -75.415),
    LatLng(10.360, -75.440),
    LatLng(10.300, -75.470),
    LatLng(10.265, -75.500),
    LatLng(10.270, -75.535),
    LatLng(10.330, -75.535),
    LatLng(10.385, -75.575),
    LatLng(10.430, -75.565),
    LatLng(10.480, -75.520),
  ];

  /// Rectángulo que envuelve el polígono (para pedir al buscador solo esa
  /// área).
  static const sur = 10.265;
  static const norte = 10.560;
  static const oeste = -75.575;
  static const este = -75.395;

  /// `true` si [p] está dentro de la zona (rayo horizontal: cuenta los
  /// cruces con los bordes).
  static bool contiene(LatLng p) {
    if (p.latitude < sur ||
        p.latitude > norte ||
        p.longitude < oeste ||
        p.longitude > este) {
      return false;
    }
    var dentro = false;
    for (var i = 0, j = poligono.length - 1; i < poligono.length; j = i++) {
      final a = poligono[i];
      final b = poligono[j];
      final cruza =
          (a.latitude > p.latitude) != (b.latitude > p.latitude) &&
          p.longitude <
              (b.longitude - a.longitude) *
                      (p.latitude - a.latitude) /
                      (b.latitude - a.latitude) +
                  a.longitude;
      if (cruza) dentro = !dentro;
    }
    return dentro;
  }
}
