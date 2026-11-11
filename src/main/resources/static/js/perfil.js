/*
 * Perfil de usuario (pasajero y conductor): datos editables y foto de perfil.
 * Lee GET /api/perfil, guarda con PUT /api/perfil y PUT|DELETE /api/perfil/foto (sesión + CSRF).
 * La foto se encuadra en un círculo y se reduce a 512 px (JPEG) en el navegador antes de subirla.
 * Todo texto que viene del servidor se inserta con textContent.
 */
(function () {
    'use strict';

    var LADO_SALIDA = 512;     // px de la foto que se sube
    var LADO_VISTA = 240;      // px del lienzo de previsualización
    var MAX_ORIGINAL = 25 * 1024 * 1024; // lo que se intenta reducir en el navegador
    var MAX_SERVIDOR = 5 * 1024 * 1024;
    var TIPOS = ['image/jpeg', 'image/png', 'image/webp'];

    // ── funciones puras (se prueban con node) ───────────────
    function iniciales(nombre) {
        var partes = String(nombre || '').trim().split(/\s+/).filter(Boolean);
        if (!partes.length) return '?';
        var a = partes[0].charAt(0);
        var b = partes.length > 1 ? partes[1].charAt(0) : '';
        return (a + b).toUpperCase();
    }

    function validarDatos(nombre, telefono) {
        var n = String(nombre || '').trim();
        if (!n) return 'El nombre es obligatorio.';
        if (n.length < 3 || n.length > 100) return 'El nombre debe tener entre 3 y 100 caracteres.';
        if (!/^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$/.test(n)) return 'El nombre solo puede contener letras y espacios.';
        if (!/^3\d{9}$/.test(String(telefono || '').trim())) return 'El teléfono debe tener 10 dígitos y empezar con 3 (ej: 3001234567).';
        return '';
    }

    /** Escala base para que la imagen cubra el cuadrado de lado `lado`, multiplicada por el zoom. */
    function escala(anchoImg, altoImg, lado, zoom) {
        return Math.max(lado / anchoImg, lado / altoImg) * zoom;
    }

    /** Limita el desplazamiento para que la imagen siempre cubra el cuadrado (sin bordes vacíos). */
    function limitarDesplazamiento(x, y, anchoImg, altoImg, lado, esc) {
        var w = anchoImg * esc, h = altoImg * esc;
        var minX = lado - w, minY = lado - h;
        return { x: Math.min(0, Math.max(minX, x)), y: Math.min(0, Math.max(minY, y)) };
    }

    function formatoTamano(bytes) {
        if (bytes >= 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1).replace('.', ',') + ' MB';
        return Math.max(1, Math.round(bytes / 1024)) + ' KB';
    }

    function fechaLarga(iso) {
        if (!iso) return '';
        var d = new Date(iso);
        if (isNaN(d.getTime())) return '';
        return 'Miembro desde ' + d.toLocaleDateString('es-CO', { month: 'long', year: 'numeric' });
    }

    var puras = { iniciales: iniciales, validarDatos: validarDatos, escala: escala,
        limitarDesplazamiento: limitarDesplazamiento, formatoTamano: formatoTamano };
    if (typeof module === 'object' && module.exports) { module.exports = puras; }
    if (typeof document === 'undefined') return;

    // ── interfaz ────────────────────────────────────────────
    var raiz = document.getElementById('perfilApp');
    if (!raiz) return;
    function $(id) { return document.getElementById(id); }

    var perfil = null;
    var carga = false;

    function csrf() {
        var campo = document.querySelector('input[name="_csrf"]');
        return campo && campo.value ? campo.value : '';
    }

    async function api(ruta, opciones) {
        var cab = Object.assign({ 'X-CSRF-TOKEN': csrf() }, (opciones && opciones.headers) || {});
        var ctl = new AbortController();
        var t = setTimeout(function () { ctl.abort(); }, 30000);
        try {
            var r = await fetch(ruta, Object.assign({ credentials: 'same-origin', signal: ctl.signal }, opciones, { headers: cab }));
            if (r.status === 401) { window.location.href = '/auth/login'; throw new Error('Tu sesión expiró.'); }
            if (!r.ok) {
                var msg = 'No se pudo completar la acción.';
                try { var j = await r.json(); msg = j.error || j.message || msg; } catch (e) { /* sin cuerpo */ }
                throw new Error(msg);
            }
            return r.status === 204 ? null : r.json();
        } catch (e) {
            if (e.name === 'AbortError') throw new Error('La conexión tardó demasiado. Inténtalo de nuevo.');
            throw e;
        } finally { clearTimeout(t); }
    }

    function decir(el, texto, tipo) {
        el.textContent = texto || '';
        el.classList.toggle('pf-error', tipo === 'error');
        el.classList.toggle('pf-exito', tipo === 'exito');
    }

    function pintarFoto() {
        var img = $('pfAvatarImg'), ini = $('pfIniciales');
        if (perfil.fotoUrl) {
            img.src = perfil.fotoUrl;
            img.hidden = false;
            ini.hidden = true;
        } else {
            img.removeAttribute('src');
            img.hidden = true;
            ini.hidden = false;
            ini.textContent = iniciales(perfil.nombre);
        }
        $('pfQuitar').hidden = !perfil.tieneFoto;
        // La barra lateral usa la misma foto (o su imagen por defecto si no hay).
        var lateral = document.getElementById('profilePicDisplay');
        if (lateral) {
            if (!lateral.dataset.porDefecto) lateral.dataset.porDefecto = lateral.getAttribute('src') || '';
            lateral.src = perfil.fotoUrl || lateral.dataset.porDefecto;
        }
    }

    function pintarDatos() {
        $('pfNombre').textContent = perfil.nombre || '';
        var rol = $('pfRol');
        var esConductor = perfil.rol === 'CONDUCTOR';
        rol.textContent = esConductor ? 'CONDUCTOR' + (perfil.estadoValidacion === 'APROBADO' ? ' · APROBADO' : '') : 'PASAJERO';
        rol.classList.toggle('pf-ok', esConductor && perfil.estadoValidacion === 'APROBADO');
        $('pfDesde').textContent = fechaLarga(perfil.miembroDesde);
        $('pfInputNombre').value = perfil.nombre || '';
        $('pfInputTelefono').value = perfil.telefono || '';
        $('pfInputEmail').value = perfil.email || '';
        $('pfCampoLicencia').hidden = perfil.licencia == null;
        if (perfil.licencia != null) $('pfInputLicencia').value = String(perfil.licencia);
        var lateral = document.getElementById('usernameDisplay');
        if (lateral && perfil.nombre) lateral.textContent = perfil.nombre;
        var titulo = document.querySelector('#perfil .section-header h2 span');
        if (titulo && perfil.nombre) titulo.textContent = perfil.nombre;
        actualizarBotonGuardar();
    }

    function sucio() {
        return perfil && ($('pfInputNombre').value.trim() !== (perfil.nombre || '') ||
            $('pfInputTelefono').value.trim() !== (perfil.telefono || ''));
    }
    function actualizarBotonGuardar() { $('pfGuardar').disabled = carga || !sucio(); }

    async function cargarPerfil() {
        try {
            perfil = await api('/api/perfil');
            pintarDatos();
            pintarFoto();
        } catch (e) {
            decir($('pfMensaje'), e.message, 'error');
        }
    }

    // ── datos ───────────────────────────────────────────────
    $('pfForm').addEventListener('input', function () {
        $('pfInputNombre').removeAttribute('aria-invalid');
        $('pfInputTelefono').removeAttribute('aria-invalid');
        decir($('pfMensaje'), '');
        actualizarBotonGuardar();
    });
    $('pfDescartar').addEventListener('click', function () { if (perfil) { pintarDatos(); decir($('pfMensaje'), ''); } });
    $('pfForm').addEventListener('submit', async function (e) {
        e.preventDefault();
        var nombre = $('pfInputNombre').value, tel = $('pfInputTelefono').value;
        var error = validarDatos(nombre, tel);
        if (error) {
            var campoMal = /tel/i.test(error) ? $('pfInputTelefono') : $('pfInputNombre');
            campoMal.setAttribute('aria-invalid', 'true');
            campoMal.focus();
            decir($('pfMensaje'), error, 'error');
            return;
        }
        carga = true; actualizarBotonGuardar();
        try {
            perfil = await api('/api/perfil', {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ nombre: nombre.trim(), telefono: tel.trim() })
            });
            pintarDatos(); pintarFoto();
            decir($('pfMensaje'), 'Cambios guardados.', 'exito');
        } catch (err) {
            decir($('pfMensaje'), err.message, 'error');
        } finally { carga = false; actualizarBotonGuardar(); }
    });

    // ── foto ────────────────────────────────────────────────
    var modal = $('pfModal'), lienzo = $('pfLienzo'), ctx = lienzo.getContext('2d');
    var imagen = null, nombreOriginal = 'foto', bytesOriginal = 0;
    var zoom = 1, desp = { x: 0, y: 0 }, arrastre = null, ultimoFoco = null;

    function abrirModal() {
        ultimoFoco = document.activeElement;
        reiniciarEditor();
        modal.hidden = false;
        $('pfZona').focus();
    }
    function cerrarModal() {
        modal.hidden = true;
        if (imagen && imagen.close) imagen.close();
        imagen = null;
        if (ultimoFoco && ultimoFoco.focus) ultimoFoco.focus();
    }
    function reiniciarEditor() {
        if (imagen && imagen.close) imagen.close();
        imagen = null; zoom = 1; desp = { x: 0, y: 0 };
        $('pfZona').hidden = false; $('pfEditor').hidden = true;
        $('pfOtra').hidden = true; $('pfSubir').disabled = true;
        $('pfZoom').value = '1';
        decir($('pfModalMensaje'), '');
        $('pfArchivo').value = '';
    }

    function dibujar(destino, lado, factor) {
        var c = destino.getContext('2d');
        c.fillStyle = '#ffffff'; c.fillRect(0, 0, lado, lado);
        var esc = escala(imagen.width, imagen.height, LADO_VISTA, zoom) * factor;
        c.drawImage(imagen, desp.x * factor, desp.y * factor, imagen.width * esc, imagen.height * esc);
    }
    function repintar() {
        if (!imagen) return;
        var esc = escala(imagen.width, imagen.height, LADO_VISTA, zoom);
        desp = limitarDesplazamiento(desp.x, desp.y, imagen.width, imagen.height, LADO_VISTA, esc);
        dibujar(lienzo, LADO_VISTA, 1);
    }

    async function elegirArchivo(archivo) {
        decir($('pfModalMensaje'), '');
        if (!archivo) return;
        if (TIPOS.indexOf(archivo.type) === -1) { decir($('pfModalMensaje'), 'La foto debe ser JPG, PNG o WebP.', 'error'); return; }
        if (archivo.size > MAX_ORIGINAL) { decir($('pfModalMensaje'), 'La foto pesa demasiado (máx. 25 MB).', 'error'); return; }
        try {
            var bmp = await createImageBitmap(archivo, { imageOrientation: 'from-image' });
            if (imagen && imagen.close) imagen.close();
            imagen = bmp; nombreOriginal = archivo.name; bytesOriginal = archivo.size;
            zoom = 1; $('pfZoom').value = '1';
            var esc = escala(bmp.width, bmp.height, LADO_VISTA, 1);
            desp = { x: (LADO_VISTA - bmp.width * esc) / 2, y: (LADO_VISTA - bmp.height * esc) / 2 };
            $('pfZona').hidden = true; $('pfEditor').hidden = false; $('pfOtra').hidden = false;
            $('pfSubir').disabled = false;
            $('pfInfoTamano').textContent = 'Original: ' + formatoTamano(bytesOriginal) + ' · se reducirá a ' + LADO_SALIDA + ' px al guardar.';
            repintar();
        } catch (e) {
            decir($('pfModalMensaje'), 'No se pudo leer la foto. Prueba con otra.', 'error');
        }
    }

    function aBlob(canvas, calidad) {
        return new Promise(function (ok) { canvas.toBlob(ok, 'image/jpeg', calidad); });
    }

    async function subirFoto() {
        if (!imagen) return;
        $('pfSubir').disabled = true;
        decir($('pfModalMensaje'), 'Guardando…');
        try {
            var salida = document.createElement('canvas');
            salida.width = LADO_SALIDA; salida.height = LADO_SALIDA;
            dibujar(salida, LADO_SALIDA, LADO_SALIDA / LADO_VISTA);
            var calidad = 0.88, blob = await aBlob(salida, calidad);
            while (blob && blob.size > 300 * 1024 && calidad > 0.5) { calidad -= 0.1; blob = await aBlob(salida, calidad); }
            if (!blob) throw new Error('No se pudo preparar la foto.');
            if (blob.size > MAX_SERVIDOR) throw new Error('La foto debe pesar máximo 5 MB.');
            var datos = new FormData();
            datos.append('foto', new File([blob], 'perfil.jpg', { type: 'image/jpeg' }));
            perfil = await api('/api/perfil/foto', { method: 'PUT', body: datos });
            pintarDatos(); pintarFoto();
            cerrarModal();
            decir($('pfEstadoFoto'), 'Foto actualizada.', 'exito');
        } catch (e) {
            decir($('pfModalMensaje'), e.message, 'error');
            $('pfSubir').disabled = false;
        }
    }

    async function quitarFoto() {
        $('pfQuitar').disabled = true;
        try {
            perfil = await api('/api/perfil/foto', { method: 'DELETE' });
            pintarFoto();
            decir($('pfEstadoFoto'), 'Foto eliminada.', 'exito');
        } catch (e) {
            decir($('pfEstadoFoto'), e.message, 'error');
        } finally { $('pfQuitar').disabled = false; }
    }

    $('pfCamara').addEventListener('click', abrirModal);
    $('pfCambiar').addEventListener('click', abrirModal);
    $('pfQuitar').addEventListener('click', quitarFoto);
    $('pfCancelar').addEventListener('click', cerrarModal);
    $('pfOtra').addEventListener('click', function () { reiniciarEditor(); $('pfArchivo').click(); });
    $('pfSubir').addEventListener('click', subirFoto);
    $('pfZona').addEventListener('click', function () { $('pfArchivo').click(); });
    $('pfZona').addEventListener('keydown', function (e) { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); $('pfArchivo').click(); } });
    $('pfArchivo').addEventListener('change', function () { elegirArchivo(this.files && this.files[0]); });
    ['dragenter', 'dragover'].forEach(function (ev) {
        $('pfZona').addEventListener(ev, function (e) { e.preventDefault(); $('pfZona').classList.add('pf-arrastrando'); });
    });
    ['dragleave', 'drop'].forEach(function (ev) {
        $('pfZona').addEventListener(ev, function (e) { e.preventDefault(); $('pfZona').classList.remove('pf-arrastrando'); });
    });
    $('pfZona').addEventListener('drop', function (e) { elegirArchivo(e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0]); });
    modal.addEventListener('click', function (e) { if (e.target === modal) cerrarModal(); });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && !modal.hidden) cerrarModal(); });

    $('pfZoom').addEventListener('input', function () {
        if (!imagen) return;
        // Mantiene fijo el centro del encuadre al cambiar el zoom.
        var antes = escala(imagen.width, imagen.height, LADO_VISTA, zoom);
        var cx = (LADO_VISTA / 2 - desp.x) / antes, cy = (LADO_VISTA / 2 - desp.y) / antes;
        zoom = parseFloat(this.value) || 1;
        var despues = escala(imagen.width, imagen.height, LADO_VISTA, zoom);
        desp = { x: LADO_VISTA / 2 - cx * despues, y: LADO_VISTA / 2 - cy * despues };
        repintar();
    });
    lienzo.addEventListener('pointerdown', function (e) {
        if (!imagen) return;
        lienzo.setPointerCapture(e.pointerId);
        arrastre = { x: e.clientX, y: e.clientY, dx: desp.x, dy: desp.y };
    });
    lienzo.addEventListener('pointermove', function (e) {
        if (!arrastre) return;
        desp = { x: arrastre.dx + (e.clientX - arrastre.x), y: arrastre.dy + (e.clientY - arrastre.y) };
        repintar();
    });
    ['pointerup', 'pointercancel'].forEach(function (ev) { lienzo.addEventListener(ev, function () { arrastre = null; }); });

    cargarPerfil();
})();
