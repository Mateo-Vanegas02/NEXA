/*
 * Estados del viaje del conductor (modal): lógica pura. El DOM lo arma Dashboard_C.js.
 * Fases: ACEPTADO (yendo a recoger) → ESPERANDO (llegada registrada) → FINALIZADO (desglose).
 */
(function (raiz, fabrica) {
  var api = fabrica();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else raiz.ViajeConductor = api;
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  function formatoCOP(n) {
    return '$' + Math.round(Number(n) || 0).toLocaleString('es-CO');
  }

  /** 'ESPERANDO' si el conductor ya registró su llegada; si no, 'ACEPTADO'. */
  function fase(servicio) {
    return servicio && servicio.fechaLlegada ? 'ESPERANDO' : 'ACEPTADO';
  }

  /** Segundos de espera desde la llegada hasta "ahora" (ms). Nunca negativo. */
  function segundosEspera(fechaLlegada, ahoraMs) {
    var t = Date.parse(fechaLlegada);
    if (isNaN(t)) return 0;
    return Math.max(0, Math.floor((ahoraMs - t) / 1000));
  }

  /** mm:ss (o h:mm:ss si pasa de una hora). */
  function formatoEspera(seg) {
    var s = Math.max(0, Math.floor(Number(seg) || 0));
    var h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), r = s % 60;
    var mm = (m < 10 ? '0' : '') + m, rr = (r < 10 ? '0' : '') + r;
    return h ? h + ':' + mm + ':' + rr : mm + ':' + rr;
  }

  /** Texto del aviso bajo el botón Llegué. */
  function avisoLlegada(radioMetros) {
    var r = Math.round(Number(radioMetros) || 0);
    return '«Llegué» se habilita cuando estés a menos de ~' + r + ' m del punto de recogida';
  }

  /**
   * Filas extra del resumen final (DesgloseConductorDto): solo lo que suma a lo que gana. No hay fila de tarifa
   * bruta ni de comisión: el conductor ve lo que cobra y lo que recibe.
   */
  function filasCobro(d) {
    d = d || {};
    var filas = [];
    if (Number(d.recargoEspera) > 0) filas.push({ etiqueta: 'Espera', valor: '+' + formatoCOP(d.recargoEspera) });
    if (Number(d.extraVoluntario) > 0) filas.push({ etiqueta: 'Extra voluntario', valor: '+' + formatoCOP(d.extraVoluntario) });
    return filas;
  }

  /** Efectivo que el conductor debe recibir del pasajero (lo calcula el servidor). */
  function totalACobrar(d) {
    d = d || {};
    return formatoCOP(d.cobrarAlPasajero);
  }

  function textoXp(xp, nivel) {
    var x = Math.round(Number(xp) || 0);
    return '+' + x + ' XP' + (nivel != null ? ' · Nivel ' + nivel : '');
  }

  /** "Te faltan 120 XP para el nivel 3" (o "Nivel máximo") a partir de lo que devuelve finalizar; '' si no hay dato. */
  function textoFaltante(faltante, nivel) {
    if (nivel == null) return '';
    if (faltante == null) return Number(nivel) >= 5 ? 'Estás en el nivel máximo' : '';
    var f = Math.ceil(Number(faltante) || 0);
    return 'Te faltan ' + f + ' XP para el nivel ' + (Number(nivel) + 1);
  }

  /**
   * Qué le decimos al conductor sobre dónde está el pasajero. {@code pos} = {haceSegundos, distanciaRecogidaMetros}
   * de GET /conductor/pasajero-ubicacion, o null si el servidor no tiene una posición reciente.
   */
  function textoSeguimiento(pos) {
    if (!pos) return { nivel: 'sin-senal', texto: 'Aún no vemos al pasajero en el mapa. Puede que tenga la pantalla apagada.' };
    var m = Math.max(0, Math.round(Number(pos.distanciaRecogidaMetros) || 0));
    var hace = Math.max(0, Math.round(Number(pos.haceSegundos) || 0));
    var cuando = hace > 15 ? ' (hace ' + (hace >= 60 ? Math.round(hace / 60) + ' min' : hace + ' s') + ')' : '';
    if (m <= 30) return { nivel: 'en-punto', texto: 'El pasajero está en el punto de recogida' + cuando };
    var dist = m >= 1000 ? (Math.round(m / 100) / 10).toFixed(1).replace('.', ',') + ' km' : (Math.round(m / 10) * 10) + ' m';
    return { nivel: hace > 15 ? 'viejo' : 'cerca', texto: 'El pasajero está a ' + dist + ' del punto de recogida' + cuando };
  }

  return { textoSeguimiento: textoSeguimiento, formatoCOP: formatoCOP, fase: fase, segundosEspera: segundosEspera, formatoEspera: formatoEspera,
    avisoLlegada: avisoLlegada, filasCobro: filasCobro, textoXp: textoXp, textoFaltante: textoFaltante, totalACobrar: totalACobrar };
});
