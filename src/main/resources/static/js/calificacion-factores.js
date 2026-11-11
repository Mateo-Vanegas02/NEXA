/*
 * Calificación al final del viaje: qué factores se muestran según la nota y cómo cambia la selección.
 * El catálogo (códigos, textos y si son positivos) y la nota desde la que el viaje cuenta como satisfecho los
 * entrega el servidor (FactoresCalificacion); aquí solo se decide qué mostrar. El servidor valida de todos modos.
 */
(function (raiz, fabrica) {
  var api = fabrica();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else raiz.CalificacionFactores = api;
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  /** Sin nota no hay factores; con nota baja, los de «qué falló»; con nota de satisfecho, los positivos. */
  function visibles(catalogo, nota, notaSatisfecho) {
    if (!nota) return [];
    var satisfecho = nota >= notaSatisfecho;
    return (catalogo || []).filter(function (f) { return !!f.positivo === satisfecho; });
  }

  /** Marca o desmarca un factor (devuelve una lista nueva, sin repetidos). */
  function alternar(seleccion, codigo) {
    var actual = (seleccion || []).slice();
    var i = actual.indexOf(codigo);
    if (i >= 0) actual.splice(i, 1);
    else actual.push(codigo);
    return actual;
  }

  /** Al cambiar la nota se quitan los factores que ya no corresponden (p. ej. de 2 a 5 estrellas). */
  function ajustar(seleccion, catalogo, nota, notaSatisfecho) {
    var validos = visibles(catalogo, nota, notaSatisfecho).map(function (f) { return f.codigo; });
    return (seleccion || []).filter(function (c) { return validos.indexOf(c) >= 0; });
  }

  /** Pregunta encima de los factores. */
  function pregunta(nota, notaSatisfecho) {
    if (!nota) return '';
    return nota >= notaSatisfecho ? '¿Qué estuvo bien?' : '¿Qué falló?';
  }

  /** Texto bajo las estrellas. */
  function textoNota(nota) {
    return ['', 'Muy malo', 'Malo', 'Regular', 'Bueno', 'Excelente'][nota] || '';
  }

  return { visibles: visibles, alternar: alternar, ajustar: ajustar, pregunta: pregunta, textoNota: textoNota };
});
