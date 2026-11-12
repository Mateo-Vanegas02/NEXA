import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/mapa/polyline.dart';

void main() {
  test('decodifica el ejemplo de la especificación', () {
    // https://developers.google.com/maps/documentation/utilities/polylinealgorithm
    final p = decodificarPolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
    expect(p, hasLength(3));
    expect(p[0].latitude, closeTo(38.5, 1e-6));
    expect(p[0].longitude, closeTo(-120.2, 1e-6));
    expect(p[1].latitude, closeTo(40.7, 1e-6));
    expect(p[1].longitude, closeTo(-120.95, 1e-6));
    expect(p[2].latitude, closeTo(43.252, 1e-6));
    expect(p[2].longitude, closeTo(-126.453, 1e-6));
  });

  test('vacío o nulo no tiene puntos', () {
    expect(decodificarPolyline(null), isEmpty);
    expect(decodificarPolyline(''), isEmpty);
  });

  test('un texto cortado devuelve lo que alcanzó a leer', () {
    final p = decodificarPolyline('_p~iF~ps|U_ulL');
    expect(p, hasLength(1));
  });
}
