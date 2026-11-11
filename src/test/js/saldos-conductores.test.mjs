import test from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const S = createRequire(import.meta.url)('../../main/resources/static/js/saldos-conductores.js');

test('estadoSaldo distingue quién le debe a quién', () => {
  assert.deepEqual(S.estadoSaldo(6200), { texto: '$6.200', clase: 'estado-pill--ambar', titulo: 'Le debe a NEXA' });
  assert.deepEqual(S.estadoSaldo(-1500), { texto: '$1.500', clase: 'estado-pill--verde', titulo: 'NEXA le debe' });
  assert.equal(S.estadoSaldo(0).titulo, 'Al día');
  assert.equal(S.estadoSaldo(null).titulo, 'Al día');
});
