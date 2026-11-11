import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const E = createRequire(import.meta.url)('../../main/resources/static/js/extra-voluntario.js');

test('opciones: solo los pasos que caben en el margen, ordenados', () => {
  assert.deepEqual(E.opciones([2000, 500, 1000], 5000), [500, 1000, 2000]);
  assert.deepEqual(E.opciones([500, 1000, 2000], 1500), [500, 1000]);
  assert.deepEqual(E.opciones([500, 1000, 2000], 0), []);
  assert.deepEqual(E.opciones(undefined, 5000), []);
});

test('totalEfectivo suma tarifa, extra enviado y selección', () => {
  assert.equal(E.totalEfectivo(7900, 0, 1000), 8900);
  assert.equal(E.totalEfectivo(7900, 500, 1000), 9400);
  assert.equal(E.totalEfectivo(7900, -5, null), 7900);
});

test('resumen: con y sin extra', () => {
  assert.match(E.resumen(7900, 0), /^Pagas \$7\.900 en efectivo$/);
  assert.match(E.resumen(7900, 1000), /^\+\$1\.000 extra enviado · Pagas \$8\.900 en efectivo$/);
});
