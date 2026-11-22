import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/utils/formatters.dart';
import 'package:nexa_mobile/features/viajes/domain/perfil_pasajero.dart';

import '../helpers.dart';

void main() {
  setUpAll(iniciarFormatos);

  group('PerfilPasajero', () {
    test('iniciales y lectura del backend', () {
      final p = PerfilPasajero.fromBackend({'nombreCompleto': 'frank salcedo'});
      expect(p.iniciales, 'FS');
      expect(p.calificacion, isNull);
      expect(const PerfilPasajero(nombre: '').iniciales, '?');
    });
  });

  group('Fmt', () {
    test('COP y fecha relativa en español', () {
      expect(Fmt.cop(8500), contains('8.500'));
      final ahora = DateTime(2026, 10, 9, 20);
      expect(
        Fmt.fechaRelativa(DateTime(2026, 10, 8, 18, 40), ahora),
        startsWith('Ayer'),
      );
      expect(
        Fmt.fechaRelativa(DateTime(2026, 10, 9, 8), ahora),
        startsWith('Hoy'),
      );
    });
  });
}
