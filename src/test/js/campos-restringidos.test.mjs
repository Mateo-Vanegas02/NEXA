import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const { filtrar } = createRequire(import.meta.url)('../../main/resources/static/js/campos-restringidos.js');

test('dígitos: quita letras y símbolos', () => {
  assert.equal(filtrar('digitos', '300 abc-123.4567'), '3001234567');
  assert.equal(filtrar('digitos', ''), '');
  assert.equal(filtrar('digitos', null), '');
});
test('letras: permite tildes y ñ, quita números y colapsa espacios', () => {
  assert.equal(filtrar('letras', 'José  Ñandú 99!'), 'José Ñandú ');
});
test('placa: alfanumérica en mayúsculas', () => {
  assert.equal(filtrar('placa', 'abc-12 3'), 'ABC123');
});
test('tipo desconocido no cambia el texto', () => {
  assert.equal(filtrar('x', 'a1'), 'a1');
});
