import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexa_mobile/core/mapa/maniobra.dart';

void main() {
  // Ruta en L: ~220 m al norte y luego al este (giro a la derecha).
  const a = LatLng(10.400, -75.500);
  const b = LatLng(10.402, -75.500);
  const c = LatLng(10.402, -75.497);

  test('giro a la derecha con la distancia hasta el cruce', () {
    final m = ReglasManiobra.siguiente([a, b, c], const LatLng(10.401, -75.500))!;
    expect(m.giro, Giro.derecha);
    expect(m.metros, closeTo(111, 3));
  });

  test('a la izquierda cuando el trazado dobla al oeste', () {
    final m = ReglasManiobra.siguiente([
      a,
      b,
      const LatLng(10.402, -75.503),
    ], a)!;
    expect(m.giro, Giro.izquierda);
  });

  test('pasado el último cruce queda la llegada', () {
    final m = ReglasManiobra.siguiente([a, b, c], const LatLng(10.402, -75.499))!;
    expect(m.giro, Giro.llegada);
    expect(m.metros, closeTo(219, 5));
  });

  test('fuera de la ruta no hay maniobra', () {
    expect(ReglasManiobra.siguiente([a, b, c], const LatLng(10.41, -75.52)), isNull);
    expect(ReglasManiobra.siguiente([a], a), isNull);
  });

  test('cambios suaves, vuelta y texto', () {
    expect(ReglasManiobra.cambioRumbo(350, 10), 20);
    expect(ReglasManiobra.cambioRumbo(10, 350), -20);
    expect(ReglasManiobra.texto(123), '120 m');
    expect(ReglasManiobra.texto(1450), '1,4 km');
  });
}
