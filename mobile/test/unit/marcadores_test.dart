import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexa_mobile/core/mapa/reglas_marcadores.dart';

void main() {
  const centro = LatLng(10.4, -75.5);

  group('rumboEntre', () {
    test('norte, este, sur y oeste', () {
      expect(
        ReglasMarcadores.rumboEntre(centro, const LatLng(10.41, -75.5)),
        closeTo(0, 0.5),
      );
      expect(
        ReglasMarcadores.rumboEntre(centro, const LatLng(10.4, -75.49)),
        closeTo(90, 0.5),
      );
      expect(
        ReglasMarcadores.rumboEntre(centro, const LatLng(10.39, -75.5)),
        closeTo(180, 0.5),
      );
      expect(
        ReglasMarcadores.rumboEntre(centro, const LatLng(10.4, -75.51)),
        closeTo(270, 0.5),
      );
    });
  });

  group('rumboDeAvance', () {
    test('sin posición anterior no hay rumbo', () {
      expect(ReglasMarcadores.rumboDeAvance(null, centro), isNull);
    });

    test('un avance menor a 5 m no cambia el rumbo', () {
      expect(
        ReglasMarcadores.rumboDeAvance(centro, const LatLng(10.40002, -75.5)),
        isNull,
      );
    });

    test('con avance real da hacia dónde va', () {
      expect(
        ReglasMarcadores.rumboDeAvance(centro, const LatLng(10.4, -75.4995)),
        closeTo(90, 1),
      );
    });
  });

  group('ladoRelativo', () {
    LadoRelativo lado(double tel, double hacia) =>
        ReglasMarcadores.ladoRelativo(rumboTelefono: tel, haciaObjetivo: hacia);

    test('de frente con ±30°, también cruzando el norte', () {
      expect(lado(0, 25), LadoRelativo.deFrente);
      expect(lado(350, 10), LadoRelativo.deFrente);
      expect(lado(10, 340), LadoRelativo.deFrente);
    });

    test('derecha e izquierda', () {
      expect(lado(0, 90), LadoRelativo.derecha);
      expect(lado(0, 270), LadoRelativo.izquierda);
      expect(lado(300, 20), LadoRelativo.derecha);
    });

    test('detrás con 180° ± 30°', () {
      expect(lado(0, 180), LadoRelativo.detras);
      expect(lado(90, 250), LadoRelativo.detras);
      expect(lado(0, 145), LadoRelativo.derecha);
    });
  });

  test('sin señal tras 20 s', () {
    expect(ReglasMarcadores.sinSenal(10), isFalse);
    expect(ReglasMarcadores.sinSenal(25), isTrue);
  });
}
