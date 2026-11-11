// Pruebas de la lógica pura de Solicitudes del conductor. Se ejecutan con:
//   node --test src/test/js/solicitudes-conductor.test.mjs
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { describe, it } from 'node:test';

const require = createRequire(import.meta.url);
const S = require('../../main/resources/static/js/solicitudes-conductor.js');

const sol = (id, lat, lng, extra = {}) => ({
  id,
  ubicacionOrigen: { latitud: lat, longitud: lng },
  tarifa: 5200,
  ...extra,
});

describe('distancias de recogida', () => {
  it('estima por calles (×1,3) y redondea minutos a 25 km/h', () => {
    const tu = { lat: 10.4, lng: -75.5 };
    const r = S.estimarRecogida(tu, sol('a', 10.41, -75.5)); // ~1,11 km en línea recta
    assert.ok(Math.abs(r.km - 1.112 * 1.3) < 0.02, `km=${r.km}`);
    assert.equal(r.minutos, Math.round((r.km / 25) * 60));
  });

  it('sin ubicación del conductor no inventa distancias', () => {
    assert.equal(S.estimarRecogida(null, sol('a', 10.41, -75.5)), null);
  });

  it('nunca muestra 0 minutos', () => {
    assert.equal(S.estimarRecogida({ lat: 10.4, lng: -75.5 }, sol('a', 10.4, -75.5)).minutos, 1);
  });
});

describe('formatos', () => {
  it('pesos colombianos e iniciales', () => {
    assert.match(S.formatoCOP(5200), /^\$5[.,\s]?200$/);
    assert.equal(S.iniciales('Laura Gómez Díaz'), 'LD');
    assert.equal(S.iniciales('carlos'), 'C');
    assert.equal(S.iniciales('   '), '?');
    assert.equal(S.formatoKm(3.44), '3,4 km');
  });

  it('interpreta la hora del servidor como hora de Colombia', () => {
    const d = S.parsearFechaColombia('2026-10-22T10:42:00');
    assert.equal(d.toISOString(), '2026-10-22T15:42:00.000Z');
    assert.equal(S.parsearFechaColombia('2026-10-22T15:42:00Z').toISOString(), '2026-10-22T15:42:00.000Z');
    assert.equal(S.parsearFechaColombia(null), null);
    assert.equal(S.parsearFechaColombia('no es fecha'), null);
  });

  it('"Hace N min"', () => {
    const ahora = new Date('2026-10-22T15:50:00Z');
    assert.equal(S.haceTexto(new Date('2026-10-22T15:49:40Z'), ahora), 'Hace un momento');
    assert.equal(S.haceTexto(new Date('2026-10-22T15:47:00Z'), ahora), 'Hace 3 min');
    assert.equal(S.haceTexto(new Date('2026-10-22T13:40:00Z'), ahora), 'Hace 2 h');
  });
});

describe('orden de la lista', () => {
  const tu = { lat: 10.4, lng: -75.5 };
  const lejos = sol('lejos', 10.45, -75.5, { solicitadoEn: '2026-10-22T10:50:00' });
  const cerca = sol('cerca', 10.401, -75.5, { solicitadoEn: '2026-10-22T10:40:00' });

  it('más cercanas primero cuando hay ubicación', () => {
    assert.deepEqual(S.ordenar([lejos, cerca], 'cercanas', tu).map((s) => s.id), ['cerca', 'lejos']);
  });

  it('más recientes primero', () => {
    assert.deepEqual(S.ordenar([cerca, lejos], 'recientes', tu).map((s) => s.id), ['lejos', 'cerca']);
  });

  it('prioridad: respeta el orden del servidor y no muta la lista', () => {
    const lista = [lejos, cerca];
    assert.deepEqual(S.ordenar(lista, 'prioridad', tu).map((s) => s.id), ['lejos', 'cerca']);
    assert.deepEqual(lista.map((s) => s.id), ['lejos', 'cerca']);
  });
});

describe('mensajes en tiempo real', () => {
  const base = () => ({ lista: [sol('a', 10.4, -75.5), sol('b', 10.41, -75.5)], tomados: new Map(), seleccionadoId: 'a' });

  it('una solicitud nueva pide recargar', () => {
    assert.equal(S.aplicarMensaje(base(), { id: 'c', estado: 'SOLICITADO' }).accion, 'recargar');
  });

  it('un extra voluntario sobre una solicitud de la lista pide volver a ofrecerla', () => {
    const r = S.aplicarMensaje(base(), { id: 'a', estado: 'OFERTA_SUBIDA', extraVoluntario: 1000 });
    assert.equal(r.accion, 'oferta-subida');
  });

  it('un extra sobre una solicitud que no está en la lista se ignora', () => {
    assert.equal(S.aplicarMensaje(base(), { id: 'zzz', estado: 'OFERTA_SUBIDA', extraVoluntario: 500 }).accion, null);
  });

  it('la seleccionada tomada por otro queda visible como "tomada"', () => {
    const r = S.aplicarMensaje(base(), { id: 'a', estado: 'RETIRADO', motivo: 'TOMADO' });
    assert.equal(r.accion, 'tomado');
    assert.deepEqual(r.estado.lista.map((s) => s.id), ['b']);
    assert.ok(r.estado.tomados.has('a'));
    assert.equal(r.estado.seleccionadoId, 'a');
  });

  it('una no seleccionada tomada por otro simplemente desaparece', () => {
    const r = S.aplicarMensaje(base(), { id: 'b', estado: 'RETIRADO', motivo: 'TOMADO' });
    assert.equal(r.accion, null);
    assert.deepEqual(r.estado.lista.map((s) => s.id), ['a']);
    assert.equal(r.estado.tomados.size, 0);
  });

  it('si el pasajero cancela la seleccionada, se deselecciona y se avisa', () => {
    const r = S.aplicarMensaje(base(), { id: 'a', estado: 'RETIRADO', motivo: 'CANCELADO' });
    assert.equal(r.accion, 'cancelado');
    assert.equal(r.estado.seleccionadoId, null);
    assert.equal(r.estado.tomados.size, 0);
  });

  it('ignora retiros de solicitudes que no conoce', () => {
    const e = base();
    const r = S.aplicarMensaje(e, { id: 'zz', estado: 'RETIRADO', motivo: 'TOMADO' });
    assert.equal(r.estado, e);
    assert.equal(r.accion, null);
  });
});

describe('lo ya visto baja al final', () => {
  const tu = { lat: 10.4, lng: -75.5 };
  const a = sol('a', 10.45, -75.5, { solicitadoEn: '2026-10-22T10:50:00' });
  const b = sol('b', 10.401, -75.5, { solicitadoEn: '2026-10-22T10:40:00' });
  const c = sol('c', 10.41, -75.5, { solicitadoEn: '2026-10-22T10:45:00' });

  it('las vistas van al final y el resto conserva el orden elegido', () => {
    const vistas = new Set(['b']);
    assert.deepEqual(S.ordenarConVistas([a, b, c], 'cercanas', tu, vistas).map((s) => s.id), ['c', 'a', 'b']);
    assert.deepEqual(S.ordenarConVistas([a, b, c], 'prioridad', tu, vistas).map((s) => s.id), ['a', 'c', 'b']);
  });

  it('entre varias vistas se respeta el orden relativo', () => {
    assert.deepEqual(S.ordenarConVistas([a, b, c], 'recientes', tu, new Set(['a', 'c'])).map((s) => s.id), ['b', 'a', 'c']);
  });

  it('sin vistas queda igual que ordenar()', () => {
    assert.deepEqual(S.ordenarConVistas([a, b, c], 'cercanas', tu, new Set()), S.ordenar([a, b, c], 'cercanas', tu));
  });

  it('una solicitud vista sigue en la lista (no se oculta)', () => {
    assert.equal(S.ordenarConVistas([a, b, c], 'prioridad', tu, new Set(['a', 'b', 'c'])).length, 3);
  });
});

describe('tarjetas emergentes', () => {
  const a = sol('a', 10.4, -75.5);
  const b = sol('b', 10.4, -75.5);
  const c = sol('c', 10.4, -75.5);

  it('solo se ofrecen las no vistas y las que no se mostraron ya', () => {
    assert.deepEqual(S.ofertasNuevas([a, b, c], new Set(['a']), new Set(['b'])).map((s) => s.id), ['c']);
  });

  it('una solicitud marcada "Ahora no" nunca vuelve a emerger', () => {
    assert.deepEqual(S.ofertasNuevas([a], new Set(['a']), new Set()), []);
  });

  it('una oferta retirada sola (sin marcarse vista) no se repite en esta carga', () => {
    assert.deepEqual(S.ofertasNuevas([a], new Set(), new Set(['a'])), []);
  });
});

describe('ganancia neta del conductor', () => {
  it('(1 − comisión) × tarifa bruta, no el precio con descuento del pasajero', () => {
    const s = { tarifa: 8800, desglose: { tarifaBruta: 9000 } };
    assert.equal(S.gananciaConductor(s, 0.19), 7290); // 0,81 × 9.000
  });

  it('sin desglose usa la tarifa; sin precio no inventa nada', () => {
    assert.equal(S.gananciaConductor({ tarifa: 10000 }, 0.2), 8000);
    assert.equal(S.gananciaConductor({}, 0.2), null);
  });

  it('comisión inválida: usa la del nivel 1 (20 %)', () => {
    assert.equal(S.gananciaConductor({ tarifa: 10000 }, NaN), 8000);
    assert.equal(S.gananciaConductor({ tarifa: 10000 }, 1.5), 8000);
  });

  it('el extra voluntario va completo al conductor', () => {
    assert.equal(S.gananciaConductor({ tarifa: 10800, desglose: { tarifaBruta: 10800 }, extraVoluntario: 1000 }, 0.18), 9856);
  });

  it('ganancia por km del viaje', () => {
    assert.equal(Math.round(S.gananciaPorKm(4160, 3.4)), 1224);
    assert.equal(S.gananciaPorKm(4160, 0), null);
    assert.equal(S.gananciaPorKm(null, 3), null);
  });
});

describe('etiquetas de la tarjeta', () => {
  const ahora = new Date('2026-10-22T15:50:00Z'); // 10:50 en Colombia
  const tu = { lat: 10.4, lng: -75.5 };
  const base = (extra = {}) => ({
    id: 'x', tarifa: 5200, desglose: { tarifaBruta: 5200 }, distanciaKM: 3.4,
    ubicacionOrigen: { latitud: 10.4, longitud: -75.5 }, solicitadoEn: '2026-10-22T10:49:00', ...extra,
  });
  const textos = (s, pos = tu) => S.etiquetas(s, { comision: 0.2, posicion: pos, ahora }).map((e) => e.texto);

  it('una solicitud reciente y cerca solo dice "Cerca de ti"', () => {
    assert.deepEqual(textos(base()), ['Buen pago', 'Cerca de ti']);
  });

  it('"Lleva N min esperando" desde los 5 minutos', () => {
    assert.ok(!textos(base({ solicitadoEn: '2026-10-22T10:46:00' })).some((t) => t.startsWith('Lleva')));
    assert.ok(textos(base({ solicitadoEn: '2026-10-22T10:44:00' })).includes('Lleva 6 min esperando'));
  });

  it('el extra voluntario va primero y en verde', () => {
    const e = S.etiquetas(base({ extraVoluntario: 1000 }), { comision: 0.2, posicion: tu, ahora });
    assert.equal(e[0].texto, '+$1.000 extra');
    assert.equal(e[0].tono, 'verde');
  });

  it('sin ubicación no hay "Cerca de ti", y "Buen pago" usa solo el viaje', () => {
    const t = textos(base(), null);
    assert.ok(!t.includes('Cerca de ti'));
    assert.ok(t.includes('Buen pago')); // 4.160 / 3,4 km = 1.224 por km
  });

  it('un viaje largo con recogida lejana no es "Buen pago"', () => {
    const lejos = base({ tarifa: 10800, desglose: { tarifaBruta: 10800 }, distanciaKM: 6.5, ubicacionOrigen: { latitud: 10.43, longitud: -75.5 } });
    assert.ok(!textos(lejos).includes('Buen pago')); // 8.640 / (6,5 + ~4,3 km) ≈ 800 por km
  });
});

describe('cuándo reportar la posición al servidor', () => {
  const t0 = 1_000_000;
  const aqui = { lat: 10.4236, lng: -75.5253 };
  const ultimo = { ...aqui, en: t0, disponible: true };

  it('la primera vez siempre, y nunca sin posición', () => {
    assert.equal(S.debeReportar(null, aqui, t0, true), true);
    assert.equal(S.debeReportar(null, null, t0, true), false);
  });

  it('quieto no repite antes del latido de 30 s', () => {
    assert.equal(S.debeReportar(ultimo, aqui, t0 + 10_000, true), false);
    assert.equal(S.debeReportar(ultimo, aqui, t0 + 30_000, true), true);
  });

  it('en movimiento reporta pasados 5 s, pero no antes', () => {
    const mas = { lat: 10.4236 + 0.0005, lng: -75.5253 }; // ~55 m
    assert.equal(S.debeReportar(ultimo, mas, t0 + 3_000, true), false);
    assert.equal(S.debeReportar(ultimo, mas, t0 + 6_000, true), true);
  });

  it('un movimiento menor a 30 m no cuenta', () => {
    const poco = { lat: 10.4236 + 0.0001, lng: -75.5253 }; // ~11 m
    assert.equal(S.debeReportar(ultimo, poco, t0 + 10_000, true), false);
  });

  it('cambiar de disponible a ocupado se avisa de inmediato', () => {
    assert.equal(S.debeReportar(ultimo, aqui, t0 + 1_000, false), true);
  });
});
