// Verifica rechazar-conductores-prueba.js sobre los datos sintéticos (CI).
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const leer = (f) => { const t = readFileSync(f, 'utf8'); return JSON.parse(t.slice(t.indexOf('{'))); };
const [plan, aplicar, repetir, revertir, tras] = process.argv.slice(2).map(leer);

assert.equal(plan.porRechazar, 2);
assert.equal(plan.gruposConTarjetaRepetida, 1);
assert.equal(aplicar.rechazados, 2);
assert.equal(aplicar.gruposConTarjetaRepetida, 0, 'tras rechazar ya no hay tarjeta repetida');
assert.equal(repetir.porRechazar, 0, 'repetir no vuelve a rechazar (idempotente)');
assert.equal(repetir.rechazados, undefined);
assert.equal(revertir.restaurados, 2);
assert.equal(tras.porRechazar, 2, 'revertir devuelve estado y tarjeta');
assert.equal(tras.gruposConTarjetaRepetida, 1);
assert.deepEqual(tras.estadosActuales, plan.estadosActuales);
console.log('rechazo de conductores de prueba verificado');
