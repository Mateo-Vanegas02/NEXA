/*
 * Extra voluntario del pasajero (modelo v2.2, sección 12A): lógica pura del panel "Subir oferta".
 * Los pasos y el tope los entrega el servidor (modelo-nexa.properties); aquí solo se decide qué
 * mostrar. El servidor valida de todos modos.
 */
(function (raiz, fabrica) {
  var api = fabrica();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else raiz.ExtraVoluntario = api;
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  function formatoCOP(n) {
    return '$' + Math.round(Number(n) || 0).toLocaleString('es-CO');
  }

  /** Pasos que todavía caben sin pasar el tope (margen = lo que falta para el tope), de menor a mayor. */
  function opciones(pasos, margen) {
    return (pasos || []).map(Number).filter(function (p) { return p > 0 && p <= margen; })
      .sort(function (a, b) { return a - b; });
  }

  /** Total en efectivo que pagará el pasajero con el extra ya enviado más la selección. */
  function totalEfectivo(tarifa, extraEnviado, seleccion) {
    return Math.max(0, Number(tarifa) || 0) + Math.max(0, Number(extraEnviado) || 0) + Math.max(0, Number(seleccion) || 0);
  }

  /** Texto del resumen en la ventana de búsqueda. */
  function resumen(tarifa, extraEnviado) {
    var extra = Math.max(0, Number(extraEnviado) || 0);
    if (!extra) return 'Pagas ' + formatoCOP(tarifa) + ' en efectivo';
    return '+' + formatoCOP(extra) + ' extra enviado · Pagas ' + formatoCOP(totalEfectivo(tarifa, extra, 0)) + ' en efectivo';
  }

  return { formatoCOP: formatoCOP, opciones: opciones, totalEfectivo: totalEfectivo, resumen: resumen };
});
