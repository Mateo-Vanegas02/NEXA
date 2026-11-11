import test from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const V = createRequire(import.meta.url)('../../main/resources/static/js/verificacion-conductor.js');

test('estadoConductor traduce y tolera desconocidos', () => {
  assert.equal(V.estadoConductor('en_revision').texto, 'En revisión');
  assert.equal(V.estadoConductor('PENDIENTE').clase, 'vc-pill--ambar');
  assert.equal(V.estadoConductor('X').clase, 'vc-pill--gris');
});
test('estadoDocumento: sin foto, sin revisar y lecturas', () => {
  assert.equal(V.estadoDocumento(false, null).texto, 'Sin foto');
  assert.equal(V.estadoDocumento(true, null).texto, 'Sin revisar');
  assert.equal(V.estadoDocumento(true, { resultado: 'COINCIDE' }).clase, 'vc-pill--verde');
  assert.equal(V.estadoDocumento(true, { resultado: 'DIFERENTE' }).clase, 'vc-pill--rojo');
  assert.equal(V.estadoDocumento(true, { resultado: 'NO_LEGIBLE' }).texto, 'No legible');
});
test('formatoFecha y diasHasta', () => {
  assert.equal(V.formatoFecha('2026-11-10'), '10 nov 2026');
  assert.equal(V.formatoFecha([2026, 1, 5]), '5 ene 2026');
  assert.equal(V.formatoFecha(null), '—');
  assert.equal(V.diasHasta('2026-11-10', new Date(2026, 10, 7)), 3);
  assert.equal(V.diasHasta('2026-11-01', new Date(2026, 10, 7)), -6);
  assert.equal(V.diasHasta(null, new Date()), null);
});
test('avancePlazo acotado', () => {
  assert.equal(V.avancePlazo(null), 0);
  assert.equal(V.avancePlazo(-5), 1);
  assert.equal(V.avancePlazo(999), 0);
});
test('documentosPorTipo elige el más reciente y respeta el vehículo', () => {
  const docs = [
    { id: 'a', tipo: 'SOAT', vehiculoId: 'v1', subidoEn: '2026-01-01T00:00:00' },
    { id: 'b', tipo: 'SOAT', vehiculoId: 'v1', subidoEn: '2026-02-01T00:00:00' },
    { id: 'c', tipo: 'SOAT', vehiculoId: 'v2', subidoEn: '2026-03-01T00:00:00' },
    { id: 'd', tipo: 'LICENCIA', subidoEn: '2026-01-01T00:00:00' },
  ];
  const r = V.documentosPorTipo(docs, { id: 'v1' }, false);
  assert.equal(r.SOAT.id, 'b');
  assert.equal(r.LICENCIA.id, 'd');
});
test('esConductorAntiguo', () => {
  assert.equal(V.esConductorAntiguo([], []), true);
  assert.equal(V.esConductorAntiguo([{}], []), false);
});
