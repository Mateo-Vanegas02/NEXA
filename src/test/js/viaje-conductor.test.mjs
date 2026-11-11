import test from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const V = createRequire(import.meta.url)('../../main/resources/static/js/viaje-conductor.js');

test('fase según llegada', () => {
  assert.equal(V.fase({}), 'ACEPTADO');
  assert.equal(V.fase({ fechaLlegada: '2026-10-22T10:00:00' }), 'ESPERANDO');
});
test('formatoEspera', () => {
  assert.equal(V.formatoEspera(0), '00:00');
  assert.equal(V.formatoEspera(75), '01:15');
  assert.equal(V.formatoEspera(3725), '1:02:05');
  assert.equal(V.formatoEspera(-5), '00:00');
});
test('segundosEspera nunca negativo', () => {
  const t = Date.parse('2026-10-22T10:00:00Z');
  assert.equal(V.segundosEspera('2026-10-22T10:00:00Z', t + 90000), 90);
  assert.equal(V.segundosEspera('2026-10-22T10:00:00Z', t - 5000), 0);
  assert.equal(V.segundosEspera('basura', t), 0);
});
test('avisoLlegada usa el radio del servidor', () => {
  assert.match(V.avisoLlegada(150), /~150 m/);
});
test('filasCobro solo muestra lo que suma a lo que gana: ni tarifa bruta ni comisión', () => {
  assert.deepEqual(V.filasCobro({ recargoEspera: 0, extraVoluntario: 0, gananciaConductor: 7000 }), []);
  const g = V.filasCobro({ recargoEspera: 500, extraVoluntario: 1000, gananciaConductor: 8000,
    comisionPct: 12, comisionMonto: 960, tarifaBruta: 8000 });
  assert.deepEqual(g.map(x => x.etiqueta), ['Espera', 'Extra voluntario']);
  const texto = JSON.stringify(g);
  assert.ok(!/omisi/.test(texto) && !/960/.test(texto), 'nunca se pinta la comisión');
});
test('el conductor no tiene forma de pintar la comisión del mes', () => {
  assert.equal(V.comisionDelMes, undefined);
});
test('textoXp', () => {
  assert.equal(V.textoXp(12, 2), '+12 XP · Nivel 2');
  assert.equal(V.textoXp(5), '+5 XP');
});
test('textoFaltante', () => {
  assert.equal(V.textoFaltante(119.2, 2), 'Te faltan 120 XP para el nivel 3');
  assert.equal(V.textoFaltante(null, 5), 'Estás en el nivel máximo');
  assert.equal(V.textoFaltante(null, 2), '');
  assert.equal(V.textoFaltante(10, null), '');
});
test('totalACobrar usa lo que manda el servidor', () => {
  assert.equal(V.totalACobrar({ cobrarAlPasajero: 9500 }), '$9.500');
  assert.equal(V.totalACobrar(null), '$0');
});

test('textoSeguimiento: qué ve el conductor del pasajero', () => {
  const V = createRequire(import.meta.url)('../../main/resources/static/js/viaje-conductor.js');
  assert.equal(V.textoSeguimiento(null).nivel, 'sin-senal');
  assert.equal(V.textoSeguimiento({ haceSegundos: 3, distanciaRecogidaMetros: 12 }).nivel, 'en-punto');
  assert.equal(V.textoSeguimiento({ haceSegundos: 3, distanciaRecogidaMetros: 118 }).texto,
    'El pasajero está a 120 m del punto de recogida');
  assert.equal(V.textoSeguimiento({ haceSegundos: 2, distanciaRecogidaMetros: 1450 }).texto,
    'El pasajero está a 1,5 km del punto de recogida');
  const viejo = V.textoSeguimiento({ haceSegundos: 25, distanciaRecogidaMetros: 200 });
  assert.equal(viejo.nivel, 'viejo');
  assert.match(viejo.texto, /hace 25 s/);
});
