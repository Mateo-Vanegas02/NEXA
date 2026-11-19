// Verifica correcciones-datos-fase3-2.js sobre los datos sintéticos (CI).
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const leer = (f) => { const t = readFileSync(f, 'utf8'); return { t, r: JSON.parse(t.slice(t.indexOf('{'))) }; };
const [plan, aplicar, despues, revertir] = process.argv.slice(2).map(leer);
for (const { t } of [plan, aplicar, despues, revertir]) {
  assert.ok(!t.includes('sintetico') && !t.includes('example.invalid'), 'sin datos sembrados en la salida');
}
const accion = (r, c) => r.archivo.find((x) => x.coleccion === c).accion;

assert.equal(plan.r.viajesAtascados.encontrados, 1, 'solo el viaje de hace 50 h, no el de hace 10 min');
assert.equal(plan.r.tokensAntiguos.cuentasConCampoAntiguo, 1);
assert.equal(plan.r.tokensAntiguos.vencimientosSinToken, 1);
assert.equal(accion(plan.r, 'Servicio'), 'se archivaría');

assert.equal(aplicar.r.viajesAtascados.cancelados, 1);
assert.equal(aplicar.r.tokensAntiguos.cuentasLimpiadas, 1);
assert.equal(aplicar.r.tokensAntiguos.vencimientosBorrados, 1);
for (const c of ['Servicio', 'Vehiculo', 'creditos_nexa', 'beneficios_uso', 'ModeloInfo']) {
  assert.equal(accion(aplicar.r, c), 'archivada', c);
  assert.equal(accion(despues.r, c), 'ya archivada', c);
  assert.equal(accion(revertir.r, c), 'restaurada', c);
}
assert.equal(despues.r.viajesAtascados.encontrados, 0, 'repetir no encuentra nada (idempotente)');
assert.equal(despues.r.tokensAntiguos.cuentasConCampoAntiguo, 0);
console.log('script de correcciones verificado');
