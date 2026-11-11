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

  test('por defecto apunta a la web de AWS (debug y release)', () {
    expect(Env.apiBaseUrl, Env.urlAws);
    expect(Env.urlLocal, startsWith('http://10.0.2.2'));
  });

  test('AWS es HTTPS y sin barra final (la app añade /api)', () {
    expect(Env.urlAws, startsWith('https://'));
    expect(Env.urlAws, isNot(endsWith('/')));
  });

  test('el panel de satisfacción apunta a la Lambda de AWS', () {
    expect(Env.satisfaccionUrl, Env.satisfaccionUrlAws);
    expect(Env.satisfaccionUrlAws, startsWith('https://'));
    expect(Env.satisfaccionUrlAws, isNot(endsWith('/')));
  });
}
