import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const F = createRequire(import.meta.url)('../../main/resources/static/js/calificacion-factores.js');

const CATALOGO = [
  { codigo: 'ACEPTACION_LENTA', etiqueta: 'Tardaron en aceptar', positivo: false },
  { codigo: 'LLEGADA_TARDE', etiqueta: 'Tardó en llegar a recogerme', positivo: false },
  { codigo: 'ACEPTACION_RAPIDA', etiqueta: 'Aceptaron rápido', positivo: true },
  { codigo: 'AMABLE', etiqueta: 'Amable', positivo: true },
];
const codigos = (l) => l.map((f) => f.codigo);

test('visibles: nada sin nota, «qué falló» con nota baja y positivos desde 4', () => {
  assert.deepEqual(F.visibles(CATALOGO, 0, 4), []);
  assert.deepEqual(codigos(F.visibles(CATALOGO, 1, 4)), ['ACEPTACION_LENTA', 'LLEGADA_TARDE']);
  assert.deepEqual(codigos(F.visibles(CATALOGO, 3, 4)), ['ACEPTACION_LENTA', 'LLEGADA_TARDE']);
  assert.deepEqual(codigos(F.visibles(CATALOGO, 4, 4)), ['ACEPTACION_RAPIDA', 'AMABLE']);
  assert.deepEqual(codigos(F.visibles(CATALOGO, 5, 4)), ['ACEPTACION_RAPIDA', 'AMABLE']);
  assert.deepEqual(F.visibles(undefined, 5, 4), []);
});

test('alternar marca y desmarca sin repetir ni tocar la lista original', () => {
  const inicial = ['AMABLE'];
  assert.deepEqual(F.alternar(inicial, 'ACEPTACION_RAPIDA'), ['AMABLE', 'ACEPTACION_RAPIDA']);
  assert.deepEqual(F.alternar(inicial, 'AMABLE'), []);
  assert.deepEqual(inicial, ['AMABLE']);
  assert.deepEqual(F.alternar(undefined, 'AMABLE'), ['AMABLE']);
});

test('ajustar quita lo que ya no corresponde al cambiar la nota', () => {
  assert.deepEqual(F.ajustar(['ACEPTACION_LENTA', 'LLEGADA_TARDE'], CATALOGO, 5, 4), []);
  assert.deepEqual(F.ajustar(['ACEPTACION_LENTA'], CATALOGO, 2, 4), ['ACEPTACION_LENTA']);
  assert.deepEqual(F.ajustar(['AMABLE', 'ACEPTACION_LENTA'], CATALOGO, 4, 4), ['AMABLE']);
});

test('pregunta y texto de la nota', () => {
  assert.equal(F.pregunta(0, 4), '');
  assert.equal(F.pregunta(2, 4), '¿Qué falló?');
  assert.equal(F.pregunta(4, 4), '¿Qué estuvo bien?');
  assert.equal(F.textoNota(1), 'Muy malo');
  assert.equal(F.textoNota(5), 'Excelente');
  assert.equal(F.textoNota(0), '');
});
