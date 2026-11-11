/* =============================================
 * MAPA — Leaflet.js + OpenStreetMap (Conductor)
 * ============================================= */

// Tile layer URLs
const TILE_LIGHT = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
const TILE_DARK = TILE_LIGHT; // mapa siempre claro (sin API key)
const TILE_ATTR_LIGHT = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';
const TILE_ATTR_DARK = TILE_ATTR_LIGHT;
const TILE_ATTR = TILE_ATTR_LIGHT;

// Variables globales
let map, currentTileLayer;
let solicitudes = null; // controlador de SolicitudesConductor (lista + pines)
let stompClient = null;
let currentServicioId = null;

/* ---- UI helpers ---- */
function showSection(id) {
    document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
    document.getElementById(id).classList.add('active');

    // Quitar clase activa de todos los items del sidebar y ponerla en el actual
    document.querySelectorAll('.sidebar ul li').forEach(li => li.classList.remove('active'));
    const menuItem = document.querySelector(`.sidebar ul li[onclick*="'${id}'"]`);
    if (menuItem) menuItem.classList.add('active');

    // Ocultar automáticamente el sidebar en pantallas móviles al cambiar de sección
    const sidebar = document.getElementById('sidebar');
    if (sidebar && sidebar.classList.contains('active')) {
        sidebar.classList.remove('active');
    }
}

function toggleDarkMode() {
    const isDark = document.body.classList.toggle('dark-mode');
    localStorage.setItem('darkMode', isDark);
    document.getElementById('darkModeText').textContent = isDark ? 'Modo claro' : 'Modo oscuro';
    if (currentTileLayer && map) {
        map.removeLayer(currentTileLayer);
        currentTileLayer = L.tileLayer(
            isDark ? TILE_DARK : TILE_LIGHT,
            { attribution: isDark ? TILE_ATTR_DARK : TILE_ATTR_LIGHT, maxZoom: 19 }
        ).addTo(map);
    }
}

function checkDarkMode() {
    const isDark = localStorage.getItem('darkMode') === 'true';
    if (isDark) {
        document.body.classList.add('dark-mode');
        document.getElementById('darkModeText').textContent = 'Modo claro';
    }
}

/* ---- initMap: Leaflet ---- */
function initMap() {
    const mapEl = document.getElementById('map');
    if (!mapEl) { console.error('Elemento #map no encontrado'); return; }
    if (map) {
        // Ya inicializado: solo forzar recálculo de tamaño
        setTimeout(() => map.invalidateSize(), 50);
        return;
    }

    const centro = [10.4055, -75.5037];
    const isDarkMode = document.body.classList.contains('dark-mode');

    const mapContainer = document.querySelector('.map-container');
    const loadingOverlay = document.createElement('div');
    loadingOverlay.className = 'map-loading';
    loadingOverlay.innerHTML = '<div class="spinner"></div>';
    mapContainer.appendChild(loadingOverlay);

    try {
        // Zoom abajo a la derecha: arriba a la izquierda va el contador de solicitudes
        map = L.map('map', { center: centro, zoom: 13, zoomControl: false });
        L.control.zoom({ position: 'bottomright' }).addTo(map);

        currentTileLayer = L.tileLayer(
            isDarkMode ? TILE_DARK : TILE_LIGHT,
            {
                attribution: isDarkMode ? TILE_ATTR_DARK : TILE_ATTR_LIGHT,
                maxZoom: 19,
                crossOrigin: true
            }
        ).addTo(map);

        currentTileLayer.on('tileerror', (e) => {
            console.warn('Tile error conductor:', e.tile.src);
        });
        currentTileLayer.on('tileload', () => {
            if (loadingOverlay && loadingOverlay.parentNode) {
                loadingOverlay.classList.add('hidden');
                setTimeout(() => { try { loadingOverlay.remove(); } catch (e2) { } }, 500);
            }
        });

        // Forzar recálculo de tamaño (puede haber estado oculto)
        setTimeout(() => {
            map.invalidateSize();
            cargarServiciosDisponibles();
        }, 500);
    } catch (error) {
        console.error('Error al inicializar el mapa:', error);
        showError('Error al cargar el mapa.');
        loadingOverlay.remove();
    }
}

/* ---- Solicitudes disponibles: lista "Cerca de ti" + pines de precio (solicitudes-conductor.js) ---- */
function estaEnViaje() {
    return !!(document.getElementById('viaje-activo')?.classList.contains('active')
        || document.getElementById('servicioModal'));
}

/** Al terminar o cancelarse un viaje: de vuelta a la lista de solicitudes, con el mapa bien dimensionado. */
function volverASolicitudes() {
    showSection('solicitudes');
    requestAnimationFrame(() => { if (map) map.invalidateSize(); });
}

function iniciarSolicitudes() {
    if (solicitudes || !window.SolicitudesConductor) return solicitudes;
    solicitudes = window.SolicitudesConductor.iniciar({
        obtenerMapa: () => map,
        csrf: () => document.querySelector('input[name="_csrf"]').value,
        aviso: showError,
        // Comisión real de este conductor (la entrega el servidor al abrir el panel)
        comision: () => parseFloat(document.getElementById('solicitudes')?.dataset.comision),
        // Sin tarjetas emergentes si ya está en un viaje o apagó las notificaciones
        puedeOfrecer: () => {
            const notif = document.getElementById('chkNotificaciones');
            return !estaEnViaje() && (!notif || notif.checked);
        },
        // En un viaje no cuenta como conductor disponible para avisar nuevas solicitudes
        disponible: () => !estaEnViaje(),
        abrirLista: (id) => {
            showSection('solicitudes');
            requestAnimationFrame(() => {
                if (!map) initMap(); else map.invalidateSize();
                if (id && solicitudes) solicitudes.seleccionar(id);
            });
        }
    });
    return solicitudes;
}

function cargarServiciosDisponibles() {
    const s = iniciarSolicitudes();
    if (s) s.recargar();
}

function verTodasLasSolicitudes() {
    if (solicitudes) solicitudes.verTodas();
}

/* ---- Centrar mapa ---- */
function centrarMapa() {
    if (!map) return;
    const conocida = solicitudes && solicitudes.posicion();
    if (conocida) { map.setView([conocida.lat, conocida.lng], 15); return; }
    if (!navigator.geolocation) { showError('Tu navegador no soporta geolocalización.'); return; }
    navigator.geolocation.getCurrentPosition(
        ({ coords }) => map.setView([coords.latitude, coords.longitude], 15),
        () => { showError('No se pudo obtener tu ubicación.'); if (map) map.setView([10.4055, -75.5037], 13); }
    );
}

/* ---- Capa de tráfico: eliminada ---- */
function alternarTrafico() {
    showError('La capa de tráfico en tiempo real no está disponible en esta versión.');
}

/* ---- showError ---- */
function showError(message) {
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-message';
    errorDiv.innerHTML = `<i class="fas fa-exclamation-circle"></i> ${message}`;
    document.body.appendChild(errorDiv);
    setTimeout(() => {
        errorDiv.classList.add('fade-out');
        setTimeout(() => errorDiv.remove(), 500);
    }, 3000);
}

/* =============================================
 * HISTORIAL
 * ============================================= */
function cargarHistorial() {
    fetch('/conductor/historial')
        .then(response => response.json())
        .then(historial => {
            const tbody = document.getElementById('historialBody');
            tbody.innerHTML = '';
            historial.forEach(viaje => {
                const row = document.createElement('tr');
                row.innerHTML = `
          <td>${new Date(viaje.fechaHora).toLocaleDateString()}</td>
          <td>${new Date(viaje.fechaHora).toLocaleTimeString()}</td>
          <td>${viaje.origen}</td>
          <td>${viaje.destino}</td>
          <td>${viaje.pasajero.nombre}</td>
          <td>$${viaje.tarifa.toLocaleString('es-CO')}</td>
          <td><button onclick="mostrarDetallesViaje('${viaje.id}')"><i class="fas fa-eye"></i></button></td>`;
                tbody.appendChild(row);
            });
        })
        .catch(error => {
            console.error('Error al cargar historial:', error);
            showError('Error al cargar historial de viajes');
        });
}

function mostrarDetallesViaje(servicioId) {
    fetch(`/conductor/servicios/${servicioId}`)
        .then(response => response.json())
        .then(servicio => {
            document.getElementById('detallesViajeContent').innerHTML = `
        <div class="detail-row"><i class="fas fa-calendar"></i><span>Fecha:</span><span>${new Date(servicio.fechaHora).toLocaleDateString()}</span></div>
        <div class="detail-row"><i class="fas fa-clock"></i><span>Hora:</span><span>${new Date(servicio.fechaHora).toLocaleTimeString()}</span></div>
        <div class="detail-row"><i class="fas fa-map-marker-alt"></i><span>Origen:</span><span>${servicio.origen}</span></div>
        <div class="detail-row"><i class="fas fa-flag-checkered"></i><span>Destino:</span><span>${servicio.destino}</span></div>
        <div class="detail-row"><i class="fas fa-user"></i><span>Pasajero:</span><span>${servicio.pasajero.nombre}</span></div>
        <div class="detail-row"><i class="fas fa-money-bill-wave"></i><span>Precio:</span><span>$${servicio.tarifa.toLocaleString('es-CO')}</span></div>
        ${servicio.calificacionPasajero ? `<div class="detail-row"><i class="fas fa-star" style="color: #ffb703;"></i><span>Tu calificación al pasajero:</span><span>${Number(servicio.calificacionPasajero).toFixed(1)} ★</span></div>` : ''}`;
            // Tu comentario: se arma como texto para que nada del comentario se interprete como HTML
            if (servicio.comentariosPasajero) {
                const fila = el('div', 'detail-row');
                fila.appendChild(el('i', 'fas fa-comment-dots'));
                fila.appendChild(el('span', null, 'Tu comentario:'));
                fila.appendChild(el('span', null, '"' + servicio.comentariosPasajero + '"'));
                document.getElementById('detallesViajeContent').appendChild(fila);
            }
            document.getElementById('modalDetallesViaje').classList.add('active');
        })
        .catch(error => {
            console.error('Error al cargar detalles:', error);
            showError('Error al cargar detalles del viaje');
        });
}

function cerrarModalDetalles() {
    document.getElementById('modalDetallesViaje').classList.remove('active');
}

/* =============================================
 * INGRESOS
 * ============================================= */
function cargarIngresos() {
    fetch('/conductor/ingresos')
        .then(response => response.json())
        .then(ingresos => {
            const tbody = document.getElementById('ingresosBody');
            tbody.innerHTML = '';
            ingresos.forEach(ingreso => {
                const row = document.createElement('tr');
                row.innerHTML = `
          <td>${new Date(ingreso.fecha).toLocaleDateString()}</td>
          <td>$${ingreso.monto.toLocaleString('es-CO')}</td>
          <td>${ingreso.descripcion}</td>`;
                tbody.appendChild(row);
            });
        })
        .catch(error => {
            console.error('Error al cargar ingresos:', error);
            showError('Error al cargar historial de ingresos');
        });
}

/* =============================================
 * WEBSOCKET
 * ============================================= */
let servicioModal = null;

function connectWebSocket() {
    const socket = new SockJS('/ws');
    stompClient = Stomp.over(socket);

    fetch('/api/user-id')
        .then(response => response.json())
        .then(data => {
            if (data.userId) startWebSocket(data.userId);
            else { console.error('No se recibió userId'); showError('Por favor, inicia sesión nuevamente'); }
        })
        .catch(error => {
            console.error('Error al obtener userId:', error);
            setTimeout(connectWebSocket, 5000);
        });
}

function startWebSocket(userId) {
    stompClient.connect({}, function (frame) {
        console.log('Conductor conectado al WebSocket: ' + frame);

        const lista = iniciarSolicitudes();
        if (lista) lista.estadoConexion(true);

        stompClient.subscribe('/topic/servicios-disponibles', function (message) {
            const msg = JSON.parse(message.body);
            if (lista) lista.alMensaje(msg);
        });

        stompClient.subscribe(`/topic/conductor/${userId}`, function (message) {
            const servicio = JSON.parse(message.body);
            console.log('Conductor recibió actualización:', servicio);
            handleServicioUpdate(servicio);
        });

    }, function (error) {
        console.error('Error en WebSocket del conductor:', error);
        if (solicitudes) solicitudes.estadoConexion(false);
        showError('Error de conexión. Reintentando...');
        setTimeout(() => connectWebSocket(), 5000);
    });
}

function handleServicioUpdate(servicio) {
    console.log('Conductor procesando estado:', servicio.estado, servicio);
    currentServicioId = servicio.id;
    switch (servicio.estado) {
        case 'ACEPTADO':
        case 'EN_CURSO':
            // Panel del viaje sobre el mapa con la posición real (viaje-activo.js)
            hideServicioModal();
            ViajeActivo.mostrar(servicio);
            break;
        case 'FINALIZADO':
            // Si el modal de resumen ya está abierto lo maneja finalizarViaje; si no, ir a calificar.
            if (!document.getElementById('resumenViaje')) {
                ViajeActivo.terminar();
                hideServicioModal();
                window.location.href = `/rating?servicioId=${servicio.id}&rol=conductor`;
            }
            break;
        case 'CANCELADO':
            hideServicioModal();
            ViajeActivo.terminar();
            volverASolicitudes();
            showError('El pasajero ha cancelado el viaje');
            cargarServiciosDisponibles();
            break;
    }
}

/* ---------- Modal de estados del viaje (nodos DOM, sin innerHTML con datos del servidor) ---------- */
function el(tag, clase, texto) {
    const n = document.createElement(tag);
    if (clase) n.className = clase;
    if (texto != null) n.textContent = texto;
    return n;
}

function boton(clase, icono, texto, alClick, deshabilitado) {
    const b = el('button', clase);
    b.type = 'button';
    b.appendChild(el('i', 'fas ' + icono));
    b.appendChild(document.createTextNode(' ' + texto));
    if (deshabilitado) b.disabled = true;
    b.addEventListener('click', alClick);
    return b;
}

function mostrarResumenViaje(servicioId, datos) {
    const V = window.ViajeConductor;
    const d = datos.desglose || {};
    const cuerpo = el('div');
    cuerpo.id = 'resumenViaje';
    const tabla = el('div', 'service-details');
    V.filasCobro(d).forEach(f => {
        const fila = el('div', 'detail-row');
        fila.appendChild(el('span', null, f.etiqueta));
        fila.appendChild(el('strong', null, f.valor));
        tabla.appendChild(fila);
    });
    if (tabla.childElementCount) cuerpo.appendChild(tabla);
    const cobro = el('div', 'cobro-box');
    cobro.appendChild(el('span', null, 'Cobra al pasajero en efectivo'));
    cobro.appendChild(el('strong', null, V.totalACobrar(d)));
    cuerpo.appendChild(cobro);
    const total = el('div', 'earn-box');
    total.appendChild(el('span', null, 'Tú recibes'));
    total.appendChild(el('strong', null, V.formatoCOP(d.gananciaConductor)));
    cuerpo.appendChild(total);
    if (datos.xpGanado != null) cuerpo.appendChild(el('p', 'xp-note', V.textoXp(datos.xpGanado, datos.nivel)));
    const faltan = V.textoFaltante(datos.xpFaltante, datos.nivel);
    if (faltan) cuerpo.appendChild(el('p', 'xp-note', faltan));
    const acciones = el('div', 'action-buttons');
    acciones.appendChild(boton('start-btn', 'fa-check', 'Cerrar', () => {
        window.location.href = `/rating?servicioId=${servicioId}&rol=conductor`;
    }));
    cuerpo.appendChild(acciones);
    showServicioModal({ id: servicioId }, 'Viaje finalizado', cuerpo);
}

function hideServicioModal() {
    const existingModal = document.getElementById('servicioModal');
    if (existingModal) existingModal.remove();
}

function showServicioModal(servicio, title, content) {
    console.log('Mostrando modal para:', title);
    hideServicioModal();

    servicioModal = document.createElement('div');
    servicioModal.id = 'servicioModal';
    servicioModal.className = 'modal';
    const contenido = el('div', 'modal-content');
    const cab = el('div', 'modal-header');
    cab.appendChild(el('h3', null, title));
    const cerrar = el('span', 'close-btn', '×');
    cerrar.addEventListener('click', hideServicioModal);
    cab.appendChild(cerrar);
    const cuerpoModal = el('div', 'modal-body');
    cuerpoModal.appendChild(content);
    contenido.appendChild(cab);
    contenido.appendChild(cuerpoModal);
    servicioModal.appendChild(contenido);
    document.body.appendChild(servicioModal);
    servicioModal.classList.add('active');
    Object.assign(servicioModal.style, {
        position: 'fixed', top: '0', left: '0', width: '100%', height: '100%',
        zIndex: '2000', backgroundColor: 'rgba(0,0,0,0.5)',
        display: 'flex', alignItems: 'center', justifyContent: 'center'
    });
}

/* "Llegué": el servidor verifica que estés a menos de ~50 m del punto de recogida */
function confirmarLlegada(servicioId) {
    const enviar = (latitud, longitud) => fetch(`/conductor/llegue/${servicioId}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': document.querySelector('input[name="_csrf"]').value
        },
        body: JSON.stringify({ latitud, longitud })
    })
        .then(response => response.json().then(data => {
            if (!response.ok) throw new Error(data.error || data.message || 'No se pudo registrar la llegada');
            showError(data.mensaje);
        }))
        .catch(error => showError(error.message));

    // Se usa la posición que el panel ya sigue (reciente): pedir otra al navegador tarda y suele ser menos precisa
    const propia = window.ViajeActivo && ViajeActivo.posicion();
    if (propia) { enviar(propia.latitud, propia.longitud); return; }
    if (!navigator.geolocation) {
        showError('Tu navegador no soporta geolocalización.');
        return;
    }
    navigator.geolocation.getCurrentPosition(({ coords }) => enviar(coords.latitude, coords.longitude),
        () => showError('No se pudo obtener tu ubicación.'),
        { enableHighAccuracy: true, maximumAge: 3000, timeout: 8000 });
}

function iniciarViaje(servicioId) {
    fetch(`/conductor/iniciar-servicio/${servicioId}`, {
        method: 'POST',
        headers: { 'X-CSRF-TOKEN': document.querySelector('input[name="_csrf"]').value }
    })
        .then(response => { if (!response.ok) throw new Error('Error al iniciar'); })
        .catch(error => showError(error.message || 'Error al iniciar el viaje'));
}

function finalizarViaje(servicioId) {
    fetch(`/conductor/finalizar-servicio/${servicioId}`, {
        method: 'POST',
        headers: { 'X-CSRF-TOKEN': document.querySelector('input[name="_csrf"]').value }
    })
        .then(response => {
            if (!response.ok) {
                // El servidor explica el motivo (p. ej. "Aún estás a 800 m del destino")
                return response.text().then(texto => { throw new Error(texto || 'Error al finalizar'); });
            }
            return response.json();
        })
        .then(datos => { ViajeActivo.terminar(); mostrarResumenViaje(servicioId, datos); })
        .catch(error => {
            console.error('Error al finalizar viaje:', error);
            showError(error.message || 'Error al finalizar el viaje');
        });
}

function cancelarServicio(servicioId) {
    fetch(`/conductor/cancelar-servicio/${servicioId}`, {
        method: 'POST',
        headers: { 'X-CSRF-TOKEN': document.querySelector('input[name="_csrf"]').value }
    })
        .then(response => {
            if (!response.ok) throw new Error('Error al cancelar');
            hideServicioModal();
            ViajeActivo.terminar();
            volverASolicitudes();
            showError('Servicio cancelado correctamente');
        })
        .catch(error => showError(error.message || 'Error al cancelar el servicio'));
}

// Conectar WebSocket al cargar
document.addEventListener('DOMContentLoaded', () => {
    connectWebSocket();
    ViajeActivo.iniciar({
        csrf: () => document.querySelector('input[name="_csrf"]').value,
        mostrarSeccion: () => showSection('viaje-activo'),
        acciones: {
            llegue: confirmarLlegada,
            iniciar: iniciarViaje,
            finalizar: finalizarViaje,
            cancelar: cancelarServicio,
        },
    });
    ViajeActivo.retomar();
});

/* =============================================
 * HISTORIAL LOCAL (paginación + filtros)
 * ============================================= */
let historialData = [];
let currentPage = 1;
const itemsPerPage = 5;

function cargarHistorialLocal() {
    fetch('/conductor/historial')
        .then(response => response.json())
        .then(historial => { historialData = historial; renderizarHistorial(); })
        .catch(error => { console.error('Error al cargar historial:', error); showError('Error al cargar historial de viajes'); });
}

function renderizarHistorial(filteredData = historialData) {
    const tbody = document.getElementById('historialBody');
    tbody.replaceChildren();
    const start = (currentPage - 1) * itemsPerPage;
    const end = start + itemsPerPage;
    const paginatedData = filteredData.slice(start, end);

    paginatedData.forEach(viaje => {
        const row = document.createElement('tr');
        const f = new Date(viaje.fechaHora);
        [f.toLocaleDateString(), f.toLocaleTimeString(), viaje.origen, viaje.destino,
         viaje.pasajero.nombre, window.ViajeConductor.formatoCOP(viaje.tarifa)]
            .forEach(t => row.appendChild(el('td', null, t)));
        const accion = el('td');
        const ver = el('button');
        ver.type = 'button';
        ver.setAttribute('aria-label', 'Ver detalles del viaje');
        ver.appendChild(el('i', 'fas fa-eye'));
        ver.addEventListener('click', () => mostrarDetallesViaje(viaje.id));
        accion.appendChild(ver);
        row.appendChild(accion);
        tbody.appendChild(row);
    });

    document.getElementById('pageInfo').textContent = `Página ${currentPage}`;
    document.getElementById('prevPage').disabled = currentPage === 1;
    document.getElementById('nextPage').disabled = end >= filteredData.length;
}

function filtrarHistorial() {
    const fecha = document.getElementById('filtroFecha').value;
    const pasajero = document.getElementById('filtroPasajero').value.toLowerCase();
    const filteredData = historialData.filter(viaje => {
        const matchFecha = fecha ? new Date(viaje.fechaHora).toLocaleDateString() === new Date(fecha).toLocaleDateString() : true;
        const matchPasajero = pasajero ? viaje.pasajero.nombre.toLowerCase().includes(pasajero) : true;
        return matchFecha && matchPasajero;
    });
    currentPage = 1;
    renderizarHistorial(filteredData);
}

function resetFiltrosHistorial() {
    document.getElementById('filtroFecha').value = '';
    document.getElementById('filtroPasajero').value = '';
    currentPage = 1;
    renderizarHistorial();
}

function cambiarPagina(delta) {
    currentPage += delta;
    if (currentPage < 1) currentPage = 1;
    if (currentPage > Math.ceil(historialData.length / itemsPerPage)) currentPage = Math.ceil(historialData.length / itemsPerPage);
    renderizarHistorial();
}

/* =============================================
 * INGRESOS LOCAL (filtros)
 * ============================================= */
let ingresosData = [];

function cargarIngresosLocal() {
    fetch('/conductor/ingresos')
        .then(response => response.json())
        .then(ingresos => {
            ingresosData = [...ingresos].sort((a, b) => String(b.fecha).localeCompare(String(a.fecha)));
            actualizarMontoBilletera(ingresos);
            filtrarIngresos();
        })
        .catch(error => { console.error('Error al cargar ingresos:', error); showError('Error al cargar historial de ingresos'); });
}

function actualizarMontoBilletera(ingresos) {
    if (!ingresos) return;
    const total = ingresos.reduce((sum, i) => sum + (Number(i.monto) || 0), 0);
    const display = document.getElementById('walletAmountDisplay');
    if (display) {
        display.textContent = `${window.ViajeConductor.formatoCOP(total)} COP`;
    }
}

/** 'YYYY-MM-DD' → dd/mm/aaaa sin el desfase de zona horaria de new Date('YYYY-MM-DD'). */
function fechaLocal(iso) {
    const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(iso || ''));
    return m ? `${m[3]}/${m[2]}/${m[1]}` : '—';
}

function filtrarIngresos() {
    const periodo = document.getElementById('filtroPeriodo').value;
    const fechaFiltro = document.getElementById('filtroFechaIngresos').value;
    const today = new Date();
    let filteredIngresos = [...ingresosData];

    if (fechaFiltro) {
        filteredIngresos = filteredIngresos.filter(i => i.fecha === fechaFiltro);
    } else {
        if (periodo === 'año') filteredIngresos = filteredIngresos.filter(i => new Date(i.fecha).getFullYear() === today.getFullYear());
        else if (periodo === 'mes') filteredIngresos = filteredIngresos.filter(i => { const d = new Date(i.fecha); return d.getFullYear() === today.getFullYear() && d.getMonth() === today.getMonth(); });
        else if (periodo === 'semana') {
            const weekAgo = new Date(today); weekAgo.setDate(today.getDate() - 7);
            filteredIngresos = filteredIngresos.filter(i => new Date(i.fecha) >= weekAgo);
        } else if (periodo === 'día') filteredIngresos = filteredIngresos.filter(i => new Date(i.fecha).toDateString() === today.toDateString());
    }

    const tbody = document.getElementById('ingresosBody');
    tbody.replaceChildren();
    filteredIngresos.forEach(ingreso => {
        const row = document.createElement('tr');
        [fechaLocal(ingreso.fecha),
         window.ViajeConductor.formatoCOP(ingreso.monto),
         ingreso.descripcion].forEach(t => row.appendChild(el('td', null, t)));
        tbody.appendChild(row);
    });
}

function resetFiltrosIngresos() {
    document.getElementById('filtroFechaIngresos').value = '';
    filtrarIngresos();
}

/* =============================================
 * DOMContentLoaded
 * ============================================= */
document.addEventListener('DOMContentLoaded', function () {
    if (new URLSearchParams(window.location.search).has('cierreBloqueado')) {
        setTimeout(() => showError(MENSAJE_VIAJE_EN_MARCHA), 800);
        history.replaceState(null, '', window.location.pathname);
    }
    checkDarkMode();
    initNotificationSettings();
    cargarIngresosLocal();

    // Inicializar mapa si la sección activa es solicitudes
    const activeSection = document.querySelector('.section.active');
    if (activeSection && activeSection.id === 'solicitudes') {
        requestAnimationFrame(() => initMap());
    }

    document.querySelectorAll('.sidebar ul li[data-section]').forEach(item => {
        item.addEventListener('click', () => {
            const sectionId = item.getAttribute('data-section');
            showSection(sectionId);
            if (sectionId === 'solicitudes') {
                requestAnimationFrame(() => {
                    if (!map) initMap();
                    else {
                        map.invalidateSize();
                        cargarServiciosDisponibles();
                    }
                });
            } else if (sectionId === 'historial') {
                cargarHistorialLocal();
            } else if (sectionId === 'billetera') {
                cargarIngresosLocal();
            }
        });
    });

    const toggleBtn = document.querySelector('.toggle-btn');
    if (toggleBtn) {
        toggleBtn.addEventListener('click', () => {
            const sidebar = document.querySelector('.sidebar');
            const main = document.querySelector('.main');
            const icon = toggleBtn.querySelector('i');
            sidebar.classList.toggle('collapsed');
            main.classList.toggle('collapsed');
            icon.classList.toggle('fa-angle-double-left');
            icon.classList.toggle('fa-angle-double-right');
        });
    }

    const centerMapBtn = document.querySelector('.map-controls .map-btn[title="Centrar mapa"]');
    if (centerMapBtn) centerMapBtn.addEventListener('click', centrarMapa);

    // Botón tráfico: solo muestra aviso
    const trafficBtn = document.querySelector('.map-controls .map-btn[title="Mostrar tráfico"]');
    if (trafficBtn) trafficBtn.addEventListener('click', alternarTrafico);

    const modalClose = document.querySelector('.modal-close');
    if (modalClose) modalClose.addEventListener('click', cerrarModalDetalles);
});

/* =============================================
 * MODAL CONFIRMACIÓN GENÉRICO
 * ============================================= */
const confirmModal = document.getElementById('confirm-modal');
const confirmBtnYes = document.getElementById('confirm-modal-btn-yes');
const confirmTitle = document.getElementById('confirm-modal-title');
const confirmMessage = document.getElementById('confirm-modal-message');

const MENSAJE_VIAJE_EN_MARCHA = 'Tienes un servicio en marcha. Cancela el viaje (o termínalo) antes de cerrar sesión.';

function openConfirmModal(title, message, actionId) {
    if (actionId === 'logout' && window.ViajeActivo && ViajeActivo.activo()) {
        showError(MENSAJE_VIAJE_EN_MARCHA);
        return;
    }
    if (!confirmModal || !confirmBtnYes || !confirmTitle || !confirmMessage) { console.error('Elementos del modal de confirmación no encontrados'); return; }
    confirmTitle.textContent = title;
    confirmMessage.textContent = message;
    confirmBtnYes.dataset.actionId = actionId;
    confirmModal.style.display = 'flex';
    document.body.style.overflow = 'hidden';
}

function closeConfirmModal() {
    if (!confirmModal) return;
    confirmModal.style.display = 'none';
    document.body.style.overflow = 'auto';
}

function executeConfirmAction() {
    const actionId = confirmBtnYes.dataset.actionId;
    switch (actionId) {
        case 'logout':
            const logoutForm = document.getElementById('logout-form');
            if (logoutForm) logoutForm.submit();
            else console.error("El formulario 'logout-form' no se encontró.");
            break;
        default:
            console.warn('Acción de confirmación desconocida:', actionId);
    }
    closeConfirmModal();
}

if (confirmBtnYes) confirmBtnYes.addEventListener('click', executeConfirmAction);
if (confirmModal) confirmModal.addEventListener('click', (e) => { if (e.target === confirmModal) closeConfirmModal(); });

/* =============================================
 * NOTIFICACIONES
 * ============================================= */
function initNotificationSettings() {
    const chkNotif = document.getElementById('chkNotificaciones');
    if (!chkNotif) return;
    const savedState = localStorage.getItem('receiveNotifications');
    chkNotif.checked = savedState === null ? true : (savedState === 'true');
    chkNotif.addEventListener('change', function () {
        localStorage.setItem('receiveNotifications', this.checked);
        if (this.checked) showNewRequestToast('Sistema', 'Notificaciones activadas correctamente');
    });
}

function showNewRequestToast(pasajeroNombre, mensajeExtra = 'está buscando conductor') {
    const existingToast = document.querySelector('.toast-notification');
    if (existingToast) existingToast.remove();

    const toast = document.createElement('div');
    toast.className = 'toast-notification';
    toast.innerHTML = `
    <div class="toast-icon"><i class="fas fa-street-view"></i></div>
    <div class="toast-content">
      <h4>Nueva Solicitud</h4>
      <p><strong>${pasajeroNombre}</strong> ${mensajeExtra}</p>
    </div>`;
    document.body.appendChild(toast);
    playNotificationSound();
    setTimeout(() => toast.classList.add('show'), 10);
    setTimeout(() => { toast.classList.remove('show'); setTimeout(() => toast.remove(), 400); }, 5000);
}

function playNotificationSound() {
    // const audio = new Audio('/sounds/notification.mp3');
    // audio.play().catch(e => console.log('Interacción requerida para audio'));
}

function optimizarJornadaConductor() {
    let meta = parseFloat(document.getElementById('optMeta').value) || 0;
    let horas = parseFloat(document.getElementById('optHoras').value) || 8;
    let gasolina = parseFloat(document.getElementById('optGasolina').value) || 30000;
    let riesgo = parseFloat(document.getElementById('optRiesgo').value) || 0.5;

    // Validar metaIngreso para restringir errores en la jornada
    if (meta > 0 && meta < 40000) {
        showError('La meta de ingresos mínima debe ser de $40.000 COP (debido a la cuota obligatoria de 10 viajes cortos). Ingresa $0 para el modo de Máximo Rendimiento.');
        return;
    }
    if (meta > 169000) {
        showError('La meta de ingresos máxima posible dentro de tu jornada y presupuesto es de $169.000 COP.');
        return;
    }

    // Enforce maximum business limits on client-side
    if (horas > 8) {
        horas = 8;
        document.getElementById('optHoras').value = 8;
    }
    if (gasolina > 30000) {
        gasolina = 30000;
        document.getElementById('optGasolina').value = 30000;
    }

    const emptyContainer = document.getElementById('optimizerResultEmpty');
    const loadingContainer = document.getElementById('optimizerResultLoading');
    const contentContainer = document.getElementById('optimizerResultContent');

    // Cambiar estados de visualización
    emptyContainer.style.display = 'none';
    contentContainer.style.display = 'none';
    loadingContainer.style.display = 'block';

    const url = `/api/conductor/optimizar?metaIngreso=${meta}&horasJornada=${horas}&presupuestoGasolina=${gasolina}&riskAversion=${riesgo}`;

    fetch(url)
        .then(response => {
            if (!response.ok) throw new Error('Error al procesar la optimización');
            return response.json();
        })
        .then(data => {
            loadingContainer.style.display = 'none';
            contentContainer.style.display = 'block';

            // Cargar datos en la UI
            document.getElementById('optResX1').textContent = data.x1;
            document.getElementById('optResX2').textContent = data.x2;
            document.getElementById('optResX3').textContent = data.x3;

            document.getElementById('optResEz').textContent = `$${data.beneficioEsperado.toLocaleString('es-CO')} COP`;
            document.getElementById('optResSigma').textContent = `$${data.riesgoDiario.toLocaleString('es-CO')} COP`;
            document.getElementById('optResZadj').textContent = `$${data.utilidadAjustada.toLocaleString('es-CO')} COP`;
            document.getElementById('optResGas').textContent = `$${data.costoGasolina.toLocaleString('es-CO')} COP`;

            // Calcular horas y minutos
            const totalMinutos = data.tiempoTotal;
            const h = Math.floor(totalMinutos / 60);
            const m = Math.round(totalMinutos % 60);
            document.getElementById('optResTiempo').textContent = `${totalMinutos} min (${h}h ${m}m)`;

            // Configurar Banner de Estado
            const banner = document.getElementById('optimizerMsgBanner');
            const icon = document.getElementById('optimizerMsgIcon');
            const text = document.getElementById('optimizerMsgText');

            text.textContent = data.mensaje;

            if (data.factible) {
                banner.style.backgroundColor = 'rgba(76, 175, 80, 0.1)';
                banner.style.color = '#00e676';
                banner.style.border = '1px solid rgba(76, 175, 80, 0.2)';
                banner.style.borderLeft = '4px solid #4CAF50';
                icon.className = 'fas fa-check-circle';
            } else {
                banner.style.backgroundColor = 'rgba(255, 152, 0, 0.1)';
                banner.style.color = '#ff9100';
                banner.style.border = '1px solid rgba(255, 152, 0, 0.2)';
                banner.style.borderLeft = '4px solid #FF9800';
                icon.className = 'fas fa-exclamation-triangle';
            }
        })
        .catch(error => {
            console.error('Error al optimizar:', error);
            loadingContainer.style.display = 'none';
            emptyContainer.style.display = 'block';
            showError('No se pudo establecer comunicación con el solver de optimización.');
        });
}

/* Exponer al scope global */
window.openConfirmModal = openConfirmModal;
window.closeConfirmModal = closeConfirmModal;
window.initMap = initMap;
window.showSection = showSection;
window.verTodasLasSolicitudes = verTodasLasSolicitudes;
window.centrarMapa = centrarMapa;
window.optimizarJornadaConductor = optimizarJornadaConductor;

// Cerrar sidebar al hacer clic fuera en pantallas móviles
document.addEventListener('click', (e) => {
    const sidebar = document.getElementById('sidebar');
    const toggleBtn = document.querySelector('.menu-toggle-btn');
    if (sidebar && sidebar.classList.contains('active')) {
        if (!sidebar.contains(e.target) && (!toggleBtn || !toggleBtn.contains(e.target))) {
            sidebar.classList.remove('active');
        }
    }
});