// Verifica diagnostico-tarjeta-repetida.js sobre los datos sintéticos (CI).
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const texto = readFileSync(process.argv[2], 'utf8');
const r = JSON.parse(texto.slice(texto.indexOf('{')));
for (const prohibido of ['700001', '700002', 'AAA11A', 'BBB22B', 'example.invalid']) {
  assert.ok(!texto.includes(prohibido), `la salida no debe contener "${prohibido}"`);
}
assert.equal(r.gruposConTarjetaRepetida, 1);
const g = r.grupos[0];
assert.equal(g.conductores, 2);
assert.equal(g.compartenPlaca, false);
assert.equal(g.compartenLicencia, true);
assert.deepEqual(g.miembros.map((m) => m.fotoTarjeta).sort(), ['coincide', 'difiere']);
assert.ok(g.miembros.every((m) => m.id === undefined), 'sin MOSTRAR_IDS no hay ids');
assert.equal(r.placasRepetidasEnVehiculos, 1, 'la misma placa con minúsculas y espacio');
console.log('diagnóstico de tarjeta verificado');
