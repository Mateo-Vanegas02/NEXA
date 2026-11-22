import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/mapa/reglas_camara.dart';

void main() {
  test('zoom limitado e interpolado según velocidad', () {
    for (final (velocidad, zoom) in [
      (0.0, 17.5),
      (15.0, 17.5),
      (22.5, 17.0),
      (30.0, 16.5),
      (40.0, 16.0),
      (50.0, 15.5),
      (150.0, 15.5),
    ]) {
      expect(ReglasCamara.zoomPorVelocidad(velocidad), zoom);
    }
  });
  test('GPS inválido usa el zoom de respaldo', () {
    for (final velocidad in [null, -1.0, double.nan, double.infinity]) {
      expect(ReglasCamara.zoomPorVelocidad(velocidad), 17);
    }
  });
}
