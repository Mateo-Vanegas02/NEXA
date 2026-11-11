/*
 * Restringe en el navegador lo que se puede escribir en un campo, para que el servidor reciba
 * datos ya limpios. Se activa con atributos en el input (el servidor valida igual):
 *   data-solo="digitos"  → 0-9              (celular, licencia, SOAT, tarjeta…)
 *   data-solo="letras"   → letras y espacios (nombres, color)
 *   data-solo="placa"    → letras y números, en mayúsculas
 * Filtra al escribir, al pegar y al autocompletar (evento "input"), sin mover el cursor de más.
 */
(function (raiz, fabrica) {
    var api = fabrica();
    if (typeof module === 'object' && module.exports) module.exports = api;
    else raiz.CamposRestringidos = api;
    if (typeof document !== 'undefined') {
        var iniciar = function () { api.activar(document); };
        if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', iniciar);
        else iniciar();
    }
})(typeof self !== 'undefined' ? self : this, function () {
    'use strict';

    var FILTROS = {
        digitos: function (t) { return t.replace(/\D/g, ''); },
        letras: function (t) { return t.replace(/[^A-Za-záéíóúÁÉÍÓÚñÑüÜ\s]/g, '').replace(/\s{2,}/g, ' '); },
        placa: function (t) { return t.replace(/[^A-Za-z0-9]/g, '').toUpperCase(); }
    };

    /** Texto filtrado según el tipo; tipo desconocido lo deja igual. */
    function filtrar(tipo, texto) {
        var f = FILTROS[tipo];
        return f ? f(String(texto == null ? '' : texto)) : String(texto == null ? '' : texto);
    }

    function aplicar(input) {
        var limpio = filtrar(input.getAttribute('data-solo'), input.value);
        if (limpio === input.value) return;
        var cursor = input.selectionStart, antes = input.value.length;
        input.value = limpio;
        if (cursor != null && input.setSelectionRange) {
            var pos = Math.max(0, cursor - (antes - limpio.length));
            try { input.setSelectionRange(pos, pos); } catch (e) { /* tipos sin selección */ }
        }
    }

    function activar(raizDom) {
        raizDom.addEventListener('input', function (e) {
            var el = e.target;
            if (el && el.matches && el.matches('input[data-solo]')) aplicar(el);
        });
        raizDom.querySelectorAll('input[data-solo]').forEach(aplicar);
    }

    return { filtrar: filtrar, activar: activar };
});
