import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexa_mobile/core/mapa/zona_servicio.dart';

/// Los mismos puntos que `ZonaServicioTest` del servidor: las dos zonas
/// deben responder igual.
void main() {
  const dentro = {
    'Centro histórico': LatLng(10.4236, -75.5487),
    'Bocagrande': LatLng(10.3997, -75.5580),
    'Castillogrande': LatLng(10.3920, -75.5530),
    'Manga': LatLng(10.4100, -75.5400),
    'Aeropuerto': LatLng(10.4424, -75.5130),
    'La Boquilla': LatLng(10.4740, -75.4950),
    'Manzanillo del Mar': LatLng(10.5200, -75.4700),
    'Bayunca': LatLng(10.5370, -75.4100),
    'Ternera': LatLng(10.3870, -75.4600),
    'El Pozón': LatLng(10.4150, -75.4650),
    'Olaya Herrera': LatLng(10.4170, -75.4980),
    'Mamonal': LatLng(10.3300, -75.5000),
    'Pasacaballos': LatLng(10.2850, -75.5180),
  };
  const fuera = {
    'Turbaco': LatLng(10.3325, -75.4142),
    'Tierra Bomba': LatLng(10.3600, -75.5800),
    'Playa Blanca (Barú)': LatLng(10.2300, -75.6000),
    'Barranquilla': LatLng(10.9639, -74.7964),
    'Bogotá': LatLng(4.7110, -74.0721),
    'Origen 0 0': LatLng(0, 0),
  };

  for (final e in dentro.entries) {
    test('${e.key} está dentro', () {
      expect(ZonaServicio.contiene(e.value), isTrue);
    });
  }
  for (final e in fuera.entries) {
    test('${e.key} está fuera', () {
      expect(ZonaServicio.contiene(e.value), isFalse);
    });
  }

  test('el rectángulo envuelve todo el polígono', () {
    for (final p in ZonaServicio.poligono) {
      expect(p.latitude, inInclusiveRange(ZonaServicio.sur, ZonaServicio.norte));
      expect(p.longitude, inInclusiveRange(ZonaServicio.oeste, ZonaServicio.este));
    }
  });
}
