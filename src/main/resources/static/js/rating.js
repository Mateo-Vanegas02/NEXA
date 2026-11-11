/*
 * Pantalla de calificación al final del viaje (pasajero y conductor). Calificar es opcional: «Ahora no» vuelve al
 * panel sin guardar nada. Con estrellas se muestran los factores del modelo de satisfacción para marcar qué falló o
 * qué estuvo bien. Lógica pura en calificacion-factores.js.
 */
document.addEventListener('DOMContentLoaded', function () {
    'use strict';
    var F = window.CalificacionFactores;
    var contenedor = document.querySelector('.rating-container');
    var servicioId = contenedor.getAttribute('data-servicio-id');
    var rol = contenedor.getAttribute('data-rol');
    var notaSatisfecho = Number(contenedor.getAttribute('data-nota-satisfecho')) || 4;
    var estrellas = Array.prototype.slice.call(document.querySelectorAll('#stars .star'));
    var botonesFactor = Array.prototype.slice.call(document.querySelectorAll('#factores .factor'));
    var seccionFactores = document.getElementById('factores');
    var tituloFactores = document.getElementById('factoresTitulo');
    var notaTexto = document.getElementById('notaTexto');
    var enviar = document.getElementById('submitRating');
    var error = document.getElementById('ratingError');

    var catalogo = botonesFactor.map(function (b) {
        return { codigo: b.dataset.codigo, positivo: b.dataset.positivo === 'true' };
    });
    var nota = 0;
    var seleccion = [];

    if (!servicioId || !rol) {
        error.textContent = 'No encontramos el viaje. Vuelve a tu panel.';
        return;
    }

    function pintarEstrellas(valor) {
        estrellas.forEach(function (b, i) {
            var icono = b.querySelector('i');
            icono.classList.toggle('fas', i < valor);
            icono.classList.toggle('far', i >= valor);
        });
    }

    function pintar() {
        pintarEstrellas(nota);
        estrellas.forEach(function (b, i) { b.setAttribute('aria-checked', String(i + 1 === nota)); });
        notaTexto.textContent = F.textoNota(nota);
        var visibles = F.visibles(catalogo, nota, notaSatisfecho).map(function (f) { return f.codigo; });
        botonesFactor.forEach(function (b) {
            var codigo = b.dataset.codigo;
            b.hidden = visibles.indexOf(codigo) < 0;
            var marcado = seleccion.indexOf(codigo) >= 0;
            b.classList.toggle('activo', marcado);
            b.setAttribute('aria-pressed', String(marcado));
        });
        seccionFactores.hidden = visibles.length === 0;
        tituloFactores.textContent = F.pregunta(nota, notaSatisfecho);
        enviar.disabled = nota === 0;
    }

    estrellas.forEach(function (b) {
        var valor = Number(b.dataset.rating);
        b.addEventListener('click', function () {
            nota = valor;
            seleccion = F.ajustar(seleccion, catalogo, nota, notaSatisfecho);
            error.textContent = '';
            pintar();
        });
        b.addEventListener('mouseenter', function () { pintarEstrellas(valor); });
        b.addEventListener('mouseleave', function () { pintarEstrellas(nota); });
    });

    botonesFactor.forEach(function (b) {
        b.addEventListener('click', function () {
            seleccion = F.alternar(seleccion, b.dataset.codigo);
            pintar();
        });
    });

    enviar.addEventListener('click', function () {
        if (nota === 0) {
            error.textContent = 'Elige de 1 a 5 estrellas o pulsa «Ahora no».';
            return;
        }
        var csrf = document.querySelector('input[name="_csrf"]');
        // Formulario normal (no fetch): el servidor responde con una redirección al panel con la misma sesión.
        var form = document.createElement('form');
        form.method = 'POST';
        form.action = '/rating/calificar';
        var campos = [
            ['servicioId', servicioId],
            ['calificacion', String(nota)],
            ['comentarios', document.getElementById('comentarios').value],
            ['rol', rol],
            [csrf.name, csrf.value]
        ];
        seleccion.forEach(function (codigo) { campos.push(['factores', codigo]); });
        campos.forEach(function (par) {
            var input = document.createElement('input');
            input.type = 'hidden';
            input.name = par[0];
            input.value = par[1];
            form.appendChild(input);
        });
        enviar.disabled = true;
        enviar.textContent = 'Enviando…';
        document.body.appendChild(form);
        form.submit();
    });

    pintar();
});
