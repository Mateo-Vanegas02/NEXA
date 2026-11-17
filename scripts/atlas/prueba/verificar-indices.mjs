// Verifica indices-propuestos.js sobre los datos sintéticos (CI).
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const leer = (f) => { const t = readFileSync(f, 'utf8'); return JSON.parse(t.slice(t.indexOf('{'))); };
const [plan, crear, revertir] = process.argv.slice(2).map(leer);
const fila = (r, id) => r.resultados.find((x) => x.id === id);

assert.equal(plan.modo, 'plan');
assert.ok(plan.resultados.every((x) => x.accion !== 'creado'), 'el modo plan no crea nada');
assert.equal(fila(plan, 'I5').duplicadosQueLoImpiden, 1, 'la licencia repetida bloquea el índice único');
assert.match(fila(crear, 'I5').accion, /NO se crea/);
for (const id of ['I1', 'I2', 'I3', 'I4', 'I6', 'I7', 'I8', 'I9']) {
  assert.equal(fila(crear, id).accion, 'creado', id + ' se crea en la copia');
}
for (const id of ['I1', 'I2', 'I3', 'I4', 'I6', 'I7', 'I8', 'I9']) {
  assert.equal(fila(revertir, id).accion, 'borrado', id + ' se revierte');
}
assert.equal(fila(revertir, 'I5').accion, 'no existía');
console.log('script de índices verificado');
