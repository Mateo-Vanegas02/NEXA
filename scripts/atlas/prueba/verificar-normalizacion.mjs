import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const [plan, aplicar, despues] = process.argv.slice(2).map((p) => {
  const texto = readFileSync(p, 'utf8');
  assert(!texto.includes('Limpio.Sintetico') && !texto.includes('Repetido.Sintetico'));
  return JSON.parse(texto);
});
assert.equal(plan.afectados, 2);
assert.equal(plan.colisiones, 1);
assert.equal(plan.actualizados, 0);
assert.equal(aplicar.actualizados, 1);
assert.equal(aplicar.copiasServicio, 1);
assert.equal(aplicar.copiasDispositivo, 1);
assert.equal(despues.afectados, 1);
assert.equal(despues.colisiones, 1);
console.log('Normalización sintética: colisión omitida y copias corregidas');
