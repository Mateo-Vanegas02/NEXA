import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/config/env.dart';

/// Valores por defecto de la configuración (sin `--dart-define`).
void main() {
  test(
    'por defecto la app usa el backend real, no los datos de demostración',
    () {
      expect(Env.useMocks, isFalse);
    },
  );

  test('en debug apunta al backend local y en release a producción', () {
    // Las pruebas corren en modo debug.
    expect(Env.apiBaseUrl, Env.urlLocal);
    expect(Env.urlLocal, startsWith('http://10.0.2.2'));
  });

  test('producción es HTTPS y sin barra final (la app añade /api)', () {
    expect(Env.urlProduccion, startsWith('https://'));
    expect(Env.urlProduccion, isNot(endsWith('/')));
  });
}
