import test from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const S = createRequire(import.meta.url)('../../main/resources/static/js/saldo-conductor.js');

test('saldo positivo: el conductor le debe a NEXA', () => {
  const r = S.resumen({ saldoConNexa: 6200 });
  assert.equal(r.titulo, 'Le debes a NEXA');
  assert.equal(r.monto, '$6.200');
  assert.equal(r.clase, 'saldo--debe');
});
test('saldo negativo: NEXA le debe al conductor', () => {
  const r = S.resumen({ saldoConNexa: -1000 });
  assert.equal(r.titulo, 'NEXA te debe');
  assert.equal(r.monto, '$1.000');
});
test('saldo cero', () => {
  assert.equal(S.resumen({ saldoConNexa: 0 }).titulo, 'Estás al día');
  assert.equal(S.resumen(null).titulo, 'Estás al día');
});
