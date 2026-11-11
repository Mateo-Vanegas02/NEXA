/*
 * "Mi vehículo" del conductor: lista sus vehículos (GET /api/conductor/vehiculos) y deja elegir
 * cuál queda activo (PUT /api/conductor/vehiculos/{id}/activar, sesión + CSRF). Solo uno puede
 * estar activo y no se cambia con un viaje en curso (el servidor lo valida).
 */
(function (raiz, fabrica) {
    var api = fabrica();
    if (typeof module === 'object' && module.exports) module.exports = api;
    else raiz.VehiculosConductor = api;
    if (typeof document !== 'undefined' && document.getElementById('miVehiculo')) {
        var iniciar = function () { api.iniciar(document); };
        if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', iniciar);
        else iniciar();
    }
})(typeof self !== 'undefined' ? self : this, function () {
    'use strict';

    /** Estado que se pinta: EN_SERVICIO (activo con viaje), ACTIVO o INACTIVO. */
    function estadoDe(v) {
        if (v.verificado === false) return 'EN_REVISION';
        if (v.activo && v.enServicio) return 'EN_SERVICIO';
        return v.activo ? 'ACTIVO' : 'INACTIVO';
    }

    var ROTULO = { EN_SERVICIO: 'En servicio', ACTIVO: 'Activo', INACTIVO: 'Inactivo', EN_REVISION: 'En revisión' };
    var MAX_FOTO = 5 * 1024 * 1024;

    /** Primer problema del formulario de vehículo nuevo, o '' si está bien. `fotos` = [{nombre, tamano}]. */
    function validarFormulario(valores, fotos) {
        if (!/^[A-Za-z]{3}[A-Za-z0-9]{3}$/.test((valores.placa || '').trim())) return 'La placa debe ser como ABC123 o ABC12D';
        if ((valores.marca || '').trim().length < 2 || (valores.modelo || '').trim().length < 2) return 'Escribe la marca y el modelo';
        if ((valores.color || '').trim().length < 2) return 'Escribe el color';
        var numeros = ['tarjetaPropiedad', 'soat', 'tecnomecanica'];
        for (var i = 0; i < numeros.length; i++) {
            if (!/^\d{5,12}$/.test((valores[numeros[i]] || '').trim())) return 'Los números de los documentos son de 5 a 12 dígitos';
        }
        if (!fotos || fotos.length < 3) return 'Falta alguna foto de los documentos';
        for (var k = 0; k < fotos.length; k++) {
            if (!fotos[k].tamano) return 'Falta la foto ' + fotos[k].nombre;
            if (fotos[k].tamano > MAX_FOTO) return 'Cada foto debe pesar máximo 5 MB';
        }
        return '';
    }

    /** "Bajaj Boxer 150 · Negro" (omite lo que falte). */
    function descripcion(v) {
        var modelo = [v.marca, v.modelo].filter(Boolean).join(' ');
        return [modelo, v.color].filter(Boolean).join(' · ');
    }

    function el(tag, clase, texto) {
        var e = document.createElement(tag);
        if (clase) e.className = clase;
        if (texto != null) e.textContent = texto;
        return e;
    }

    function csrf() {
        var campo = document.querySelector('input[name="_csrf"]');
        return campo ? campo.value : '';
    }

    function iniciar(doc) {
        var lista = doc.getElementById('mvLista');
        var estado = doc.getElementById('mvEstado');
        if (!lista) return;

        function mensaje(texto, error) {
            estado.textContent = texto || '';
            estado.classList.toggle('mv-error', !!error);
        }

        function pintar(vehiculos) {
            lista.replaceChildren();
            if (!vehiculos.length) {
                lista.appendChild(el('li', 'mv-vacio', 'Aún no tienes vehículos registrados.'));
                return;
            }
            vehiculos.forEach(function (v) {
                var e = estadoDe(v);
                var li = el('li', 'mv-item' + (v.activo ? ' mv-item--activo' : ''));
                var info = el('div', 'mv-info');
                var fila = el('div', 'mv-fila');
                fila.appendChild(el('span', 'mv-placa', v.placa));
                fila.appendChild(el('span', 'mv-desc', descripcion(v)));
                info.appendChild(fila);
                li.appendChild(info);
                if (v.activo || e === 'EN_REVISION') {
                    li.appendChild(el('span', 'mv-chip mv-chip--' + e.toLowerCase(), ROTULO[e]));
                } else {
                    var b = el('button', 'mv-usar', 'Usar este vehículo');
                    b.type = 'button';
                    b.addEventListener('click', function () { activar(v, b); });
                    li.appendChild(b);
                }
                lista.appendChild(li);
            });
        }

        function cargar() {
            return fetch('/api/conductor/vehiculos', { credentials: 'same-origin', headers: { Accept: 'application/json' } })
                .then(function (r) { if (!r.ok) throw new Error('No se pudieron cargar tus vehículos'); return r.json(); })
                .then(pintar)
                .catch(function (e) { mensaje(e.message, true); });
        }

        function activar(v, boton) {
            boton.disabled = true;
            mensaje('');
            fetch('/api/conductor/vehiculos/' + encodeURIComponent(v.id) + '/activar', {
                method: 'PUT', credentials: 'same-origin',
                headers: { Accept: 'application/json', 'X-CSRF-TOKEN': csrf() }
            })
                .then(function (r) {
                    return r.json().catch(function () { return {}; }).then(function (d) {
                        if (!r.ok) throw new Error(d.error || 'No se pudo cambiar de vehículo');
                    });
                })
                .then(function () { mensaje('Ahora das servicio con ' + v.placa + '.'); return cargar(); })
                .catch(function (e) { mensaje(e.message, true); boton.disabled = false; });
        }

        var boton = doc.getElementById('mvAgregar');
        var form = doc.getElementById('mvForm');
        if (boton && form) {
            boton.addEventListener('click', function () {
                form.hidden = !form.hidden;
                boton.setAttribute('aria-expanded', String(!form.hidden));
            });
            form.addEventListener('submit', function (ev) {
                ev.preventDefault();
                var datos = new FormData(form);
                var valores = {};
                ['placa', 'marca', 'modelo', 'color', 'tarjetaPropiedad', 'soat', 'tecnomecanica'].forEach(function (k) { valores[k] = datos.get(k) || ''; });
                var fotos = ['fotoTarjetaPropiedad', 'fotoSoat', 'fotoTecnomecanica'].map(function (k) {
                    var f = datos.get(k);
                    return { nombre: k, tamano: f && f.size ? f.size : 0 };
                });
                var problema = validarFormulario(valores, fotos);
                if (problema) { mensaje(problema, true); return; }
                var enviar = doc.getElementById('mvEnviar');
                enviar.disabled = true;
                mensaje('Enviando…');
                fetch('/api/conductor/vehiculos', {
                    method: 'POST', credentials: 'same-origin', body: datos,
                    headers: { Accept: 'application/json', 'X-CSRF-TOKEN': csrf() }
                })
                    .then(function (r) {
                        return r.json().catch(function () { return {}; }).then(function (d) {
                            if (!r.ok) throw new Error(d.error || 'No se pudo agregar el vehículo');
                        });
                    })
                    .then(function () {
                        form.reset(); form.hidden = true; boton.setAttribute('aria-expanded', 'false');
                        mensaje('Vehículo enviado. Podrás usarlo cuando NEXA lo apruebe.');
                        return cargar();
                    })
                    .catch(function (e) { mensaje(e.message, true); })
                    .then(function () { enviar.disabled = false; });
            });
        }

        cargar();
    }

    return { validarFormulario: validarFormulario, estadoDe: estadoDe, descripcion: descripcion, iniciar: iniciar };
});
