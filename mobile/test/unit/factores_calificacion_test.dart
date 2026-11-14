import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/features/viajes/domain/factores_calificacion.dart';

void main() {
  test('desde 4 estrellas solo factores positivos; abajo, solo negativos', () {
    expect(FactoresCalificacion.paraNota(5).every((f) => f.positivo), isTrue);
    expect(
      FactoresCalificacion.paraNota(4).map((f) => f.codigo),
      contains('CONDUCCION_SEGURA'),
    );
    expect(
      FactoresCalificacion.paraNota(3.9).every((f) => !f.positivo),
      isTrue,
    );
  });

  test('al bajar la nota se descartan los positivos ya marcados', () {
    expect(FactoresCalificacion.validos(2, {'AMABLE', 'LLEGADA_TARDE'}), [
      'LLEGADA_TARDE',
    ]);
  });

  test('conserva el orden del catálogo y no repite', () {
    expect(
      FactoresCalificacion.validos(5, [
        'AMABLE',
        'ACEPTACION_RAPIDA',
        'AMABLE',
      ]),
      ['ACEPTACION_RAPIDA', 'AMABLE'],
    );
  });

  test('ignora códigos desconocidos', () {
    expect(FactoresCalificacion.validos(5, ['NO_EXISTE']), isEmpty);
  });
}
