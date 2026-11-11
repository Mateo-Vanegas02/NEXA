import test from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const D = createRequire(import.meta.url)('../../main/resources/static/js/despacho-metricas.js');

const olas = (p1, p4, s1 = 10) => [{ porcentaje: p1, medianaSegundos: s1 }, { porcentaje: 0 }, { porcentaje: 0 }, { porcentaje: p4 }];

test('pocos datos: pide esperar', () => {
  assert.match(D.sugerencia({ aceptadas: 12, aceptadasSinMedicion: 2, olas: olas(50, 10) }), /pocos datos \(10/);
  assert.match(D.sugerencia(null), /pocos datos/);
});
test('muchas sin conductor', () => {
  assert.match(D.sugerencia({ aceptadas: 50, porcentajeSinConductor: 20, olas: olas(50, 10) }), /sin conductor/);
});
test('muchas en la última ola', () => {
  assert.match(D.sugerencia({ aceptadas: 50, porcentajeSinConductor: 5, olas: olas(20, 50) }), /última ola/);
});
test('casi todo en la primera', () => {
  assert.match(D.sugerencia({ aceptadas: 50, porcentajeSinConductor: 5, olas: olas(80, 5, 8) }), /primera ola/);
  assert.match(D.sugerencia({ aceptadas: 50, porcentajeSinConductor: 5, olas: olas(50, 20) }), /razonable/);
});
test('formatos', () => {
  assert.equal(D.km(1.5), '1,5 km');
  assert.equal(D.segundos(null), '—');
  assert.equal(D.pct(28.6), '28,6 %');
});
