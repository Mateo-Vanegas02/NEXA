import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/l10n/gen/app_localizations.dart';
import 'package:nexa_mobile/core/utils/validators.dart';

void main() {
  late AppLocalizations l;

  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('es'));
  });

  test('correo: requerido, formato y largo', () {
    expect(validarEmail(l, ''), l.campoRequerido);
    expect(validarEmail(l, 'sin-arroba'), l.emailInvalido);
    expect(validarEmail(l, 'a@b'), l.emailInvalido);
    expect(validarEmail(l, 'a b@c.co'), l.emailInvalido);
    expect(validarEmail(l, '${'x' * 100}@c.co'), l.emailInvalido);
    expect(validarEmail(l, ' frank@nexa.co '), isNull);
  });

  test('nombre: solo letras y mínimo 3', () {
    expect(validarNombre(l, 'Al'), l.nombreInvalido);
    expect(validarNombre(l, 'Frank 123'), l.nombreInvalido);
    expect(validarNombre(l, 'Ñandú Pérez'), isNull);
  });

  test('teléfono colombiano: 10 dígitos que empiezan por 3', () {
    expect(validarTelefono(l, '2001234567'), l.telefonoInvalido);
    expect(validarTelefono(l, '300123456'), l.telefonoInvalido);
    expect(validarTelefono(l, '3001234567'), isNull);
  });

  test('contraseña nueva: 8+, mayúscula, minúscula y número', () {
    expect(validarPasswordNueva(l, 'Ab1'), l.passwordCorta);
    expect(validarPasswordNueva(l, 'abcdefg1'), l.passwordDebil);
    expect(validarPasswordNueva(l, 'ABCDEFG1'), l.passwordDebil);
    expect(validarPasswordNueva(l, 'Abcdefgh'), l.passwordDebil);
    expect(validarPasswordNueva(l, 'Abcdefg1'), isNull);
  });

  test('confirmación de contraseña', () {
    expect(validarConfirmacion(l, 'x', 'y'), l.passwordNoCoincide);
    expect(validarConfirmacion(l, 'y', 'y'), isNull);
  });
}
