import test from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const F = require('../../main/resources/static/js/viaje-fases.js');

const ahora = Date.parse('2026-10-25T12:10:00Z');
const base = { estado: 'ACEPTADO', origen: 'Calle 1', destino: 'Calle 2', tarifa: 5000, extraVoluntario: 1000, distanciaKM: 4,
  conductor: { nombre: 'Andrés Ríos', calificacion: 4.86, nivel: 3, vehiculo: 'Yamaha FZ 150 · Negra', placa: 'ABC12D' } };

test('formatos', () => {
  assert.equal(F.formatoDistancia(0.85), '850 m');
  assert.equal(F.formatoDistancia(1.44), '1,4 km');
  assert.equal(F.formatoReloj(125), '02:05');
  assert.equal(F.formatoReloj(3725), '1:02:05');
  assert.equal(F.iniciales('Andrés Ríos'), 'AR');
  assert.equal(F.iniciales(''), '?');
  assert.equal(F.formatoCOP(6822), '$' + (6822).toLocaleString('es-CO'));
});

test('polyline decodifica el ejemplo de Google', () => {
  const p = F.decodificarPolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
  assert.deepEqual(p, [[38.5, -120.2], [40.7, -120.95], [43.252, -126.453]]);
  assert.deepEqual(F.decodificarPolyline(''), []);
});

test('distancia y rumbo', () => {
  const d = F.distanciaMetros({ lat: 10, lng: -75 }, { lat: 10.001, lng: -75 });
  assert.ok(d > 110 && d < 112);
  assert.ok(Math.abs(F.rumbo({ lat: 10, lng: -75 }, { lat: 10.1, lng: -75 })) < 1e-6);
});

test('progreso acotado', () => {
  assert.equal(F.progresoViaje(4, 4), 0.05);
  assert.equal(F.progresoViaje(0, 4), 0.98);
  assert.equal(F.progresoViaje(2, 4), 0.5);
  assert.equal(F.progresoViaje(undefined, 0), 0.05);
});

test('recargo de espera sigue la regla del servidor', () => {
  const e = { graciaMinutos: 5, valorMinuto: 400, maxMinutos: 10 };
  assert.equal(F.recargoEspera(4 * 60, e), 0);
  assert.equal(F.recargoEspera(7 * 60, e), 800);
  assert.equal(F.recargoEspera(30 * 60, e), 2000);
  assert.equal(F.recargoEspera(60, null), 0);
});

test('pasajero: a recoger con y sin posición en vivo', () => {
  let v = F.vistaPasajero(base, null, ahora, null);
  assert.equal(v.fase, 'A_RECOGER');
  assert.equal(v.paso, 2);
  assert.equal(v.etiqueta, 'CONDUCTOR EN CAMINO');
  assert.equal(v.pago.total, 6000);
  assert.equal(v.vehiculo.placa, 'ABC12D');
  v = F.vistaPasajero(base, { fase: 'ACEPTADO', etaMinutos: 4, distanciaRestanteKm: 0.9 }, ahora, null);
  assert.equal(v.titulo, 'Llega en 4 min');
  assert.equal(v.subtitulo, 'Está a 900 m de tu punto de recogida');
});

test('pasajero: posición de otra fase se ignora', () => {
  const v = F.vistaPasajero(base, { fase: 'EN_CURSO', etaMinutos: 4, distanciaRestanteKm: 3 }, ahora, null);
  assert.equal(v.titulo, 'Tu conductor va hacia ti');
});

test('pasajero: en el punto con espera y en viaje', () => {
  const llego = { ...base, fechaLlegada: new Date(ahora - 7 * 60000).toISOString() };
  const e = { graciaMinutos: 5, valorMinuto: 400, maxMinutos: 10 };
  let v = F.vistaPasajero(llego, null, ahora, e);
  assert.equal(v.fase, 'EN_EL_PUNTO');
  assert.equal(v.paso, 3);
  assert.equal(v.espera.recargo, 800);
  assert.equal(v.espera.reloj, '07:00');
  v = F.vistaPasajero({ ...llego, estado: 'EN_CURSO' }, { fase: 'EN_CURSO', etaMinutos: 6, distanciaRestanteKm: 1 }, ahora, e);
  assert.equal(v.fase, 'EN_VIAJE');
  assert.equal(v.puedeCancelar, false);
  assert.equal(v.progreso, 0.75);
});

test('conductor: "llegué" solo dentro del radio; finalizar en cualquier tramo del viaje', () => {
  let v = F.vistaConductor({ ...base, pasajero: { nombre: 'Laura Gómez' } }, null, ahora, { distanciaRecogidaM: 40, radioRecogidaM: 50 });
  assert.equal(v.puedeLlegar, true);
  v = F.vistaConductor(base, null, ahora, { distanciaRecogidaM: 60, radioRecogidaM: 50 });
  assert.equal(v.puedeLlegar, false);
  const curso = { ...base, estado: 'EN_CURSO', fechaLlegada: new Date(ahora).toISOString() };
  v = F.vistaConductor(curso, null, ahora, { distanciaDestinoM: 100, radioDestinoM: 150 });
  assert.equal(v.puedeFinalizar, true);
  assert.equal(v.finalizaAntes, false);
  v = F.vistaConductor(curso, null, ahora, { distanciaDestinoM: 900, radioDestinoM: 150 });
  assert.equal(v.puedeFinalizar, true);
  assert.equal(v.finalizaAntes, true);
  v = F.vistaConductor(curso, null, ahora, {});
  assert.equal(v.puedeFinalizar, true);
  assert.equal(v.finalizaAntes, true);
});

test('pasajero: en viaje ve la advertencia de la mitad y que solo el conductor finaliza', () => {
  const curso = { ...base, estado: 'EN_CURSO', fechaLlegada: new Date(ahora).toISOString() };
  const v = F.vistaPasajero(curso, null, ahora, null);
  assert.match(v.nota, /mitad/);
  assert.match(v.nota, /conductor finaliza/);
  assert.equal(F.vistaPasajero(base, null, ahora, null).nota, undefined);
});

test('reporte de posición del viaje', () => {
  const a = { lat: 10, lng: -75, en: 0 };
  assert.equal(F.debeReportarViaje(null, a, 0), true);
  assert.equal(F.debeReportarViaje(a, a, 2000), false);
  assert.equal(F.debeReportarViaje(a, a, 4000), false);
  assert.equal(F.debeReportarViaje(a, { lat: 10.0002, lng: -75 }, 4000), true);
  assert.equal(F.debeReportarViaje(a, a, 8000), true);
});

test('enlace a mapas y señal perdida', () => {
  assert.match(F.enlaceMaps(10.4, -75.5), /destination=10\.4%2C-75\.5/);
  assert.equal(F.senalPerdida({ recibidoEn: 0 }, 25000, 20000), true);
  assert.equal(F.senalPerdida(null, 25000), false);
});
