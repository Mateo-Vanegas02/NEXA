import test from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const U = createRequire(import.meta.url)('../../main/resources/static/js/ubicacion-pasajero.js');

const A = { lat: 10.4236, lng: -75.5253 };
const mover = (m) => ({ lat: A.lat + m / 111195, lng: A.lng });

test('distanciaMetros', () => {
  assert.ok(Math.abs(U.distanciaMetros(A, mover(100)) - 100) < 1);
  assert.equal(U.distanciaMetros(null, A), Infinity);
});
test('geocodifica la primera vez y al moverse 50 m o más', () => {
  assert.equal(U.debeGeocodificar(null, A), true);
  assert.equal(U.debeGeocodificar(A, mover(30)), false);
  assert.equal(U.debeGeocodificar(A, mover(60)), true);
});
test('recotiza solo si hay cotización y se alejó más de 150 m', () => {
  assert.equal(U.debeRecotizar(null, mover(500)), false);
  assert.equal(U.debeRecotizar(A, mover(100)), false);
  assert.equal(U.debeRecotizar(A, mover(200)), true);
});
test('precisión y vigencia', () => {
  assert.equal(U.precisionBaja(20), false);
  assert.equal(U.precisionBaja(400), true);
  assert.equal(U.precisionBaja(null), true);
  assert.equal(U.vigente({ tiempo: 1000 }, 1000 + 60000), true);
  assert.equal(U.vigente({ tiempo: 1000 }, 1000 + 180000), false);
  assert.equal(U.vigente(null, 0), false);
});
test('textos', () => {
  assert.equal(U.textoOrigen(null, 10), 'Tu ubicación actual');
  assert.equal(U.textoOrigen('Calle 30', 10), 'Tu ubicación: Calle 30');
  assert.equal(U.textoOrigen('Calle 30', 320.4), 'Tu ubicación: Calle 30 (±320 m)');
  assert.match(U.mensajeError(1), /permiso de ubicación/);
  assert.match(U.mensajeError(2), /GPS/);
  assert.match(U.mensajeError(null, false), /navegador/);
});

test('el punto de recogida solo vale cerca del pasajero', () => {
  assert.equal(U.recogidaValida(A, mover(250)), true);
  assert.equal(U.recogidaValida(A, mover(350)), false);
  assert.equal(U.recogidaValida(null, A), false);
});
test('limitarAlRadio acerca el pin al borde sin cambiar la dirección', () => {
  assert.deepEqual(U.limitarAlRadio(A, mover(100)), mover(100));
  const limitado = U.limitarAlRadio(A, mover(900));
  assert.ok(U.distanciaMetros(A, limitado) < U.RADIO_RECOGIDA_M && U.distanciaMetros(A, limitado) > U.RADIO_RECOGIDA_M - 10);
  assert.equal(U.recogidaValida(A, limitado), true);
  assert.ok(Math.abs(limitado.lng - A.lng) < 1e-9, 'mantiene la dirección');
});
test('pegar a la calle solo si el ajuste es pequeño', () => {
  assert.equal(U.aceptarAjusteACalle(A, mover(30)), true);
  assert.equal(U.aceptarAjusteACalle(A, mover(200)), false);
  assert.equal(U.aceptarAjusteACalle(A, null), false);
});
test('textoRecogida', () => {
  assert.equal(U.textoRecogida('Calle 30', 5), 'Calle 30');
  assert.equal(U.textoRecogida('Calle 30', 120.6), 'Calle 30 · a 121 m de ti');
  assert.equal(U.textoRecogida(null, 0), 'Punto de recogida');
});

test('seguimiento: primer envío, mínimo 3 s, movimiento de 10 m y latido de 10 s', () => {
  const t0 = 1_000_000;
  const previo = { ...A, en: t0 };
  assert.equal(U.debeReportarSeguimiento(null, A, t0), true);
  assert.equal(U.debeReportarSeguimiento(previo, null, t0), false);
  assert.equal(U.debeReportarSeguimiento(previo, mover(50), t0 + 2000), false, 'nunca antes de 3 s');
  assert.equal(U.debeReportarSeguimiento(previo, mover(5), t0 + 5000), false, 'quieto y sin latido');
  assert.equal(U.debeReportarSeguimiento(previo, mover(15), t0 + 5000), true, 'se movió 15 m');
  assert.equal(U.debeReportarSeguimiento(previo, A, t0 + 10000), true, 'latido: el servidor oculta lo de más de 30 s');
});
