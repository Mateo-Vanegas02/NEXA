/* =============================================
 * MAPA — Leaflet.js (Pasajero) - VERSION 2.0.0
 * ============================================= */
console.log('%c --- NEXA Dashboard_P V2.0.0 CARGADO --- ', 'background: #00c4ff; color: #000; font-weight: bold;');

// Tile layer URLs
const TILE_LIGHT = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
const TILE_DARK = TILE_LIGHT; // mapa siempre claro (sin API key)
const TILE_ATTR_LIGHT = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';
const TILE_ATTR_DARK = TILE_ATTR_LIGHT;
const TILE_ATTR = TILE_ATTR_LIGHT;

/* ---- UI helpers ---- */

/* showSection — gestiona la navegación y la inicialización del mapa */
function showSection(id) {
  console.log(`[NAV] Cambiando a sección: ${id}`);
  
  // Quitar clase activa de todas las secciones y ponerla en la actual
  document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
  const section = document.getElementById(id);
  if (section) section.classList.add('active');

  // Quitar clase activa de todos los items del sidebar y ponerla en el actual
  document.querySelectorAll('.sidebar ul li').forEach(li => li.classList.remove('active'));
  const menuItem = document.querySelector(`.sidebar ul li[onclick*="'${id}'"]`);
  if (menuItem) menuItem.classList.add('active');

  // Ocultar automáticamente el sidebar en pantallas móviles al cambiar de sección
  const sidebar = document.getElementById('sidebar');
  if (sidebar && sidebar.classList.contains('active')) {
    sidebar.classList.remove('active');
  }

  if (id === 'historial') { cargarHistorialPasajero(); cargarCargosPasajero(); }

  if (id === 'viaje') {
    console.log('[NAV] Detectada sección VIAJE, preparando mapa...');
    // Esperar a que display:block se aplique antes de que Leaflet mida el contenedor
    requestAnimationFrame(() => {
      if (!map) {
        console.log('[NAV] Mapa no existe, llamando a initMap()...');
        initMap();
      } else {
        console.log('[NAV] Mapa ya existe, invalidando tamaño...');
        setTimeout(() => map.invalidateSize(), 50);
      }
    });
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
      { attribution: isDark ? TILE_ATTR_DARK : TILE_ATTR_LIGHT, maxZoom: 19, crossOrigin: true }
    ).addTo(map);
    currentTileLayer.on('tileerror', (e) => {
      console.warn('Tile error:', e.tile.src);
    });
  }
}

function checkDarkMode() {
  const isDark = localStorage.getItem('darkMode') === 'true';
  if (isDark) {
    document.body.classList.add('dark-mode');
    document.getElementById('darkModeText').textContent = 'Modo claro';
  }
}

/* ---- Variables globales del mapa ---- */
let map, currentTileLayer;
let marcadorLeaflet = null;
let originLeaflet = null;
let destinationLeaflet = null;
let routePolyline = null;
let estimatedPrice = 0;
let calculatedDistanceKm = 0;
let originLatLng = null;
let destinationLatLng = null;
/* Ubicación en vivo del pasajero: el origen siempre es su GPS (ubicacion-pasajero.js) */
let posicionPasajero = null;      // {lat, lng, precision, tiempo}
let precisionCirculo = null;
let vigilanciaGps = null;
// Seguimiento hasta la recogida: mientras el conductor va en camino, el servidor recibe dónde está el pasajero
let seguimientoActivo = false;
let ultimoReporteSeguimiento = null;   // {lat, lng, en}
let latidoSeguimiento = null;
let ultimaGeocodificada = null;
let direccionActual = null;
/* Punto de recogida: arranca en el GPS del pasajero y él puede moverlo con el pin (siempre cerca y sobre calle) */
let recogidaManual = false;
let marcadorRecogida = null;
let radioRecogida = null;
let origenCotizado = null;
let recotizando = false;

/* ---- Utilidad: convierte segundos OSRM a texto legible ---- */
function segundosATexto(segundos) {
  const totalMin = Math.round(segundos / 60);
  if (totalMin < 60) return `${totalMin} min`;
  const horas = Math.floor(totalMin / 60);
  const mins = totalMin % 60;
  return mins > 0 ? `${horas} h ${mins} min` : `${horas} h`;
}

/* ---- Geocodificación inversa con Nominatim ---- */
function reverseGeocode(lat, lng, callback) {
  fetch(`https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json`, {
    headers: { 'Accept-Language': 'es', 'User-Agent': 'NEXA-App/1.0' }
  })
    .then(r => r.json())
    .then(data => callback(data.display_name || `${lat.toFixed(5)}, ${lng.toFixed(5)}`))
    .catch(() => callback(`${lat.toFixed(5)}, ${lng.toFixed(5)}`));
}

/* ---- Autocomplete con Photon (Komoot) ---- */
let photonDebounceOrigen = null;
let photonDebounceDestino = null;

function setupPhotonAutocomplete(inputId, onSelect) {
  console.log(`Buscando input '${inputId}' para autocomplete...`);
  const input = document.getElementById(inputId);
  if (!input) {
    console.error(`ERROR: No se encontró el input con id '${inputId}'`);
    return;
  }
  console.log(`Autocomplete vinculado correctamente a #${inputId}`);

  const debounceRef = inputId === 'origen' ? 'photonDebounceOrigen' : 'photonDebounceDestino';

  // El input-group ya tiene position:relative en el CSS
  // Ponemos el dropdown directamente dentro del input-group (parentNode del input)
  const inputGroup = input.parentNode;

  const dropdown = document.createElement('ul');
  dropdown.id = `photon-dropdown-${inputId}`;
  // Estilos del dropdown (oscuro premium)
  dropdown.style.cssText = [
    'position:absolute', 'top:100%', 'left:0', 'right:0', 'z-index:10000',
    'background:#1e293b', 'border:1px solid #00c4ff', 'border-radius:8px',
    'list-style:none', 'margin:4px 0 0', 'padding:5px 0', 'max-height:250px',
    'overflow-y:auto', 'box-shadow:0 10px 15px -3px rgba(0,0,0,0.5)', 'display:none',
    'color: white !important'
  ].join(';');

  // Para evitar problemas de overflow en el padre, nos aseguramos que el inputGroup sea relative
  inputGroup.style.position = 'relative';
  inputGroup.appendChild(dropdown);

  const LAT_MIN = 10.25, LAT_MAX = 10.55, LON_MIN = -75.75, LON_MAX = -75.35;

  input.addEventListener('input', () => {
    const q = input.value.trim();
    console.log(`Input detectado en #${inputId}: "${q}"`);

    if (inputId === 'origen') clearTimeout(photonDebounceOrigen);
    else clearTimeout(photonDebounceDestino);

    if (q.length < 3) {
      console.log(`Consulta muy corta (<3): "${q}"`);
      dropdown.style.display = 'none';
      return;
    }

    const timer = setTimeout(() => {
      const url = `https://photon.komoot.io/api/?q=${encodeURIComponent(q)}&lat=10.4055&lon=-75.5037&limit=10`;

      console.log(`[PHOTON] Solicitando: ${url}`);

      fetch(url)
        .then(r => {
          if (!r.ok) throw new Error(`HTTP status ${r.status}`);
          return r.json();
        })
        .then(data => {
          dropdown.innerHTML = '';
          const features = data.features || [];
          console.log(`[PHOTON] Resultados para #${inputId}: ${features.length}`);

          if (features.length === 0) {
            console.warn(`[PHOTON] Sin resultados para "${q}"`);
            dropdown.style.display = 'none';
            return;
          }

          features.forEach(f => {
            const props = f.properties;
            const parts = [props.name, props.street, props.city].filter(Boolean);
            const label = parts.join(', ');
            const [lon, lat] = f.geometry.coordinates;

            const li = document.createElement('li');
            li.textContent = label;
            li.style.cssText = 'padding: 10px 15px; cursor: pointer; font-size: 0.9rem; border-bottom: 1px solid rgba(255,255,255,0.1); color: white !important;';

            li.addEventListener('mouseenter', () => li.style.background = 'rgba(0, 196, 255, 0.2)');
            li.addEventListener('mouseleave', () => li.style.background = '');
            li.addEventListener('mousedown', (e) => {
              e.preventDefault();
              console.log(`Seleccionado en #${inputId}: ${label} @ ${lat},${lon}`);
              input.value = label;
              dropdown.style.display = 'none';
              onSelect({ lat, lng: lon, label });
            });
            dropdown.appendChild(li);
          });
          dropdown.style.display = 'block';
        })
        .catch(err => {
          console.error(`Error crítico en Photon para #${inputId}:`, err);
          dropdown.style.display = 'none';
        });
    }, 450);

    if (inputId === 'origen') photonDebounceOrigen = timer;
    else photonDebounceDestino = timer;
  });

  input.addEventListener('blur', () => {
    setTimeout(() => { dropdown.style.display = 'none'; }, 200);
  });
}

/* ---- initMap: Leaflet ---- */
function initMap() {
  console.log('[MAP] Ejecutando initMap()...');
  if (map) {
    // Ya inicializado — solo forzar recálculo de tamaño por si el contenedor estaba oculto
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

  map = L.map('map', {
    center: centro,
    zoom: 14,
    zoomControl: true
  });

  currentTileLayer = L.tileLayer(
    isDarkMode ? TILE_DARK : TILE_LIGHT,
    {
      attribution: isDarkMode ? TILE_ATTR_DARK : TILE_ATTR_LIGHT,
      maxZoom: 19,
      crossOrigin: true
    }
  ).addTo(map);

  // Log errores de tiles para diagnosticar
  currentTileLayer.on('tileerror', (e) => {
    console.warn('Tile error:', e.tile.src);
  });
  currentTileLayer.on('tileload', () => {
    // Al primer tile cargado, quitar spinner
    if (loadingOverlay && loadingOverlay.parentNode) {
      loadingOverlay.classList.add('hidden');
      setTimeout(() => { try { loadingOverlay.remove(); } catch (e2) { } }, 500);
    }
  });

  // Forzar recálculo de tamaño (el contenedor puede haber estado oculto)
  setTimeout(() => map.invalidateSize(), 100);

  // Punto del pasajero: su ubicación en vivo (no se arrastra ni se busca)
  const iconoPasajero = L.divIcon({
    className: 'pasajero-gps',
    html: '<span class="pasajero-gps-punto"></span>',
    iconSize: [22, 22],
    iconAnchor: [11, 11]
  });
  marcadorLeaflet = L.marker(centro, { icon: iconoPasajero, keyboard: false, interactive: false, opacity: 0 }).addTo(map);

  // Pin de recogida: el pasajero lo arrastra o toca el mapa para decir dónde quiere que lo recojan
  marcadorRecogida = L.marker(centro, {
    draggable: true,
    opacity: 0,
    icon: L.divIcon({ className: 'pin-recogida', html: '<span class="pin-recogida-aguja"></span>', iconSize: [30, 40], iconAnchor: [15, 38] }),
  }).addTo(map).bindTooltip('Te recogemos aquí');
  marcadorRecogida.on('dragend', () => fijarRecogida(marcadorRecogida.getLatLng(), true));
  map.on('click', (e) => { if (posicionPasajero) fijarRecogida(e.latlng, true); });
  document.getElementById('recogidaReset')?.addEventListener('click', () => {
    if (posicionPasajero) fijarRecogida({ lat: posicionPasajero.lat, lng: posicionPasajero.lng }, false);
  });

  iniciarUbicacionEnVivo();

  setupPhotonAutocomplete('destino', ({ lat, lng }) => {
    destinationLatLng = { lat, lng };
  });
}

/* ---- animateMarker: placeholder (Leaflet no tiene API de animación nativa) ---- */
function animateMarker(marker) {
  // No-op: marcador ya se mueve visualmente al cambiar latLng
}

/* ---- Limpiar ruta ---- */
function limpiarRuta() {
  if (routePolyline) { map.removeLayer(routePolyline); routePolyline = null; }
  if (originLeaflet) { map.removeLayer(originLeaflet); originLeaflet = null; }
  if (destinationLeaflet) { map.removeLayer(destinationLeaflet); destinationLeaflet = null; }

  document.getElementById('destino').value = '';
  pintarPanelVacio('vacio');
  pintarPasos([]);
  document.getElementById('requestRideBtn').disabled = true;
  calculatedDistanceKm = 0;
  estimatedPrice = 0;
  destinationLatLng = null;
  origenCotizado = null;
}

/* ---- Ubicación en vivo: el origen del viaje es la posición GPS del pasajero ---- */
function pintarEstadoUbicacion(texto, tipo) {
  const e = document.getElementById('ubicacionEstado');
  if (!e) return;
  e.textContent = texto || '';
  e.hidden = !texto;
  e.className = 'ubicacion-estado' + (tipo ? ' ubicacion-estado--' + tipo : '');
}

function iniciarUbicacionEnVivo() {
  const U = window.UbicacionPasajero;
  const campo = document.getElementById('origen');
  if (!navigator.geolocation) {
    pintarEstadoUbicacion(U.mensajeError(null, false), 'error');
    return;
  }
  if (vigilanciaGps != null) navigator.geolocation.clearWatch(vigilanciaGps);
  if (!posicionPasajero && campo) campo.value = '';
  pintarEstadoUbicacion('Buscando tu ubicación…', 'info');
  vigilanciaGps = navigator.geolocation.watchPosition(alRecibirPosicion, alFallarPosicion, U.OPCIONES_GPS);
}

function alRecibirPosicion({ coords, timestamp }) {
  const U = window.UbicacionPasajero;
  const primera = !posicionPasajero;
  const posicion = { lat: coords.latitude, lng: coords.longitude };
  posicionPasajero = { ...posicion, precision: coords.accuracy, tiempo: timestamp || Date.now() };

  marcadorLeaflet.setLatLng([posicion.lat, posicion.lng]).setOpacity(1);
  const chip = document.getElementById('gpsChip');
  if (chip) chip.hidden = false;
  if (precisionCirculo) precisionCirculo.setLatLng(posicion).setRadius(coords.accuracy);
  else precisionCirculo = L.circle(posicion, { radius: coords.accuracy, color: '#00c4ff', weight: 1, fillOpacity: 0.12, interactive: false }).addTo(map);
  // Hasta dónde puede alejar el pin de recogida
  if (radioRecogida) radioRecogida.setLatLng(posicion);
  else radioRecogida = L.circle(posicion, { radius: U.RADIO_RECOGIDA_M, color: '#00c4ff', weight: 1, dashArray: '4 6', fill: false, interactive: false }).addTo(map);
  if (primera) map.setView([posicion.lat, posicion.lng], 16);

  pintarEstadoUbicacion(U.precisionBaja(coords.accuracy)
    ? `Tu ubicación es aproximada (±${Math.round(coords.accuracy)} m). Si puedes, sal a un lugar abierto o activa el GPS de alta precisión.`
    : '', U.precisionBaja(coords.accuracy) ? 'aviso' : null);

  reportarSeguimiento();
  // Con un viaje pedido el punto de recogida queda fijo (el servidor guardó el original): solo se mueve el punto azul
  if (currentServicioId) return;
  if (!recogidaManual) {
    fijarRecogida(posicion, false);
  } else if (!U.recogidaValida(posicionPasajero, originLatLng)) {
    // Caminó y su punto de recogida quedó fuera del radio: se trae al borde
    fijarRecogida(U.limitarAlRadio(posicionPasajero, originLatLng), true);
  } else {
    pintarRecogida();
  }
}

/* ---- Seguimiento: el conductor ve dónde estoy mientras llega ---- */

function reportarSeguimiento() {
  const U = window.UbicacionPasajero;
  if (!seguimientoActivo || !currentServicioId || !posicionPasajero) return;
  if (!U.vigente(posicionPasajero, Date.now())) return;
  const ahora = Date.now();
  if (!U.debeReportarSeguimiento(ultimoReporteSeguimiento, posicionPasajero, ahora)) return;
  const enviado = { lat: posicionPasajero.lat, lng: posicionPasajero.lng, en: ahora };
  ultimoReporteSeguimiento = enviado;
  fetch(`/pasajero/ubicacion/${currentServicioId}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': document.querySelector('input[name="_csrf"]').value },
    body: JSON.stringify({ latitud: enviado.lat, longitud: enviado.lng }),
  }).then(r => {
    // 409: el viaje ya empezó o se canceló; 403/404: ya no es nuestro
    if (r.status === 409 || r.status === 403 || r.status === 404) detenerSeguimiento();
    else if (!r.ok) ultimoReporteSeguimiento = null;
  }).catch(() => { ultimoReporteSeguimiento = null; /* se reintenta en el próximo latido */ });
}

function iniciarSeguimiento() {
  if (seguimientoActivo) return;
  seguimientoActivo = true;
  ultimoReporteSeguimiento = null;
  reportarSeguimiento();
  // Quieto, el GPS casi no avisa: el latido reenvía la última posición para que el conductor no la vea vencida
  latidoSeguimiento = setInterval(reportarSeguimiento, 5000);
}

function detenerSeguimiento() {
  seguimientoActivo = false;
  ultimoReporteSeguimiento = null;
  if (latidoSeguimiento) { clearInterval(latidoSeguimiento); latidoSeguimiento = null; }
}

/** Tras recargar con el conductor ya en camino, vuelve a mostrar su ficha y a reportar la posición. */
function retomarViajeEnCamino() {
  return fetch('/pasajero/viaje-en-camino')
    .then(r => r.ok ? r.json() : { activo: false })
    .then(d => {
      if (!d.activo) return false;
      // El servidor entrega la vista completa del viaje para pintar el panel sin esperar otro mensaje
      handleServicioUpdate(d.servicio || { id: d.id, estado: d.estado, conductor: d.conductor });
      return true;
    })
    .catch(() => false);
}

/* ---- Punto de recogida: cerca del pasajero y pegado a una calle ---- */

/** Pega el punto a la calle más cercana con OSRM; si el ajuste es grande, respeta lo que marcó el pasajero. */
function pegarACalle(punto) {
  const U = window.UbicacionPasajero;
  return fetch(`https://router.project-osrm.org/nearest/v1/driving/${punto.lng},${punto.lat}?number=1`)
    .then(r => r.ok ? r.json() : null)
    .then(d => {
      const w = d && d.waypoints && d.waypoints[0];
      if (!w || !Array.isArray(w.location)) return punto;
      const enCalle = { lat: w.location[1], lng: w.location[0] };
      return U.aceptarAjusteACalle(punto, enCalle) ? enCalle : punto;
    })
    .catch(() => punto);
}

/** Fija el punto de recogida: lo acerca si quedó lejos, lo pega a la calle, lo nombra y recotiza si hace falta. */
function fijarRecogida(punto, manual) {
  const U = window.UbicacionPasajero;
  if (!punto) return;
  recogidaManual = manual;
  const dentro = posicionPasajero ? U.limitarAlRadio(posicionPasajero, { lat: punto.lat, lng: punto.lng }) : punto;
  originLatLng = { lat: dentro.lat, lng: dentro.lng };
  pintarRecogida();
  pegarACalle(originLatLng).then(final => {
    originLatLng = posicionPasajero ? U.limitarAlRadio(posicionPasajero, final) : final;
    pintarRecogida();
    if (U.debeGeocodificar(ultimaGeocodificada, originLatLng)) {
      ultimaGeocodificada = { ...originLatLng };
      reverseGeocode(originLatLng.lat, originLatLng.lng, (direccion) => {
        direccionActual = direccion;
        pintarRecogida();
      });
    }
    // Si el punto se movió lo suficiente, el precio se recalcula desde ahí (no mientras ya busca conductor)
    if (!currentServicioId && !recotizando && destinationLatLng && U.debeRecotizar(origenCotizado, originLatLng)) {
      recotizando = true;
      actualizarBotonSolicitar(false);
      calcularRuta();
    }
  });
}

/** Dibuja el pin, el campo de texto y el botón de volver a mi ubicación. */
function pintarRecogida() {
  const U = window.UbicacionPasajero;
  if (!originLatLng || !marcadorRecogida) return;
  marcadorRecogida.setLatLng(originLatLng).setOpacity(1);
  const metros = posicionPasajero ? U.distanciaMetros(posicionPasajero, originLatLng) : 0;
  const campo = document.getElementById('origen');
  if (campo) campo.value = U.textoRecogida(direccionActual, metros);
  const reset = document.getElementById('recogidaReset');
  if (reset) reset.hidden = !recogidaManual;
  const chip = document.getElementById('gpsChipTexto');
  if (chip) chip.textContent = recogidaManual ? 'Elegido' : 'En vivo';
}

function alFallarPosicion(err) {
  const U = window.UbicacionPasajero;
  if (err && err.code === 1) {
    posicionPasajero = null;
    originLatLng = null;
    actualizarBotonSolicitar(false);
    const chip = document.getElementById('gpsChip');
    if (chip) chip.hidden = true;
  }
  // Timeout con una posición ya conocida: se sigue usando mientras esté vigente
  if (err && err.code === 3 && posicionPasajero && U.vigente(posicionPasajero, Date.now())) return;
  pintarEstadoUbicacion(U.mensajeError(err && err.code), 'error');
}

/* ---- Centrar mapa en la ubicación en vivo ---- */
function centrarMapa() {
  if (posicionPasajero) { map.setView([posicionPasajero.lat, posicionPasajero.lng], 16); return; }
  iniciarUbicacionEnVivo();
}

/* ---- Capa de tráfico: eliminada (no existe alternativa gratuita) ---- */
function alternarTrafico() {
  showError('La capa de tráfico en tiempo real no está disponible en esta versión.');
}

/* ---- Panel de detalles: se arma con nodos (nunca con innerHTML de datos externos) ---- */
function crear(tag, clase, texto) {
  const e = document.createElement(tag);
  if (clase) e.className = clase;
  if (texto != null) e.textContent = texto;
  return e;
}

function icono(clases) {
  const i = document.createElement('i');
  i.className = clases;
  i.setAttribute('aria-hidden', 'true');
  return i;
}

function formatoCOP(n) {
  return '$' + Math.round(n).toLocaleString('es-CO');
}

function filaDetalle(clasesIcono, etiqueta, valor, claseValor) {
  const f = crear('div', 'rr-fila');
  f.append(icono(clasesIcono), crear('span', 'rr-fila-et', etiqueta), crear('span', 'rr-fila-val' + (claseValor ? ' ' + claseValor : ''), valor));
  return f;
}

/* Sin cotización: 'vacio' (inicial) o 'zona' (el servidor rechazó el viaje; mensaje del servidor) */
function pintarPanelVacio(tipo, mensaje) {
  const cont = document.getElementById('detalle-precio');
  const e = crear('div', 'empty-state' + (tipo === 'zona' ? ' rr-error' : ''));
  e.append(icono(tipo === 'zona' ? 'fas fa-ban' : 'fas fa-route'));
  if (tipo === 'zona') e.append(crear('strong', null, 'No se pudo cotizar el viaje'));
  e.append(crear('p', null, tipo === 'zona' ? (mensaje || 'No pudimos calcular este viaje.') : 'Ingresa origen y destino para calcular tu viaje'));
  cont.replaceChildren(e);
}

function pintarCotizacion(q, duracionTexto) {
  const cont = document.getElementById('detalle-precio');
  const nodos = [
    filaDetalle('fas fa-road', 'Distancia', `${q.distanciaKm.toFixed(2).replace('.', ',')} km`),
    filaDetalle('fas fa-clock', 'Duración', duracionTexto),
    crear('hr', 'rr-sep'),
    filaDetalle('fas fa-money-bill-wave', 'Tarifa del viaje', formatoCOP(q.tarifa))
  ];
  if (q.descuento > 0) {
    const pct = q.tarifa > 0 ? Math.round((q.descuento / q.tarifa) * 100) : 0;
    nodos.push(filaDetalle('fas fa-tag', `Descuento por tu nivel (−${pct} %)`, `− ${formatoCOP(q.descuento)}`, 'rr-ahorro'));
  }
  const deuda = Number(q.deudaPendiente) || 0;
  if (deuda > 0) {
    nodos.push(filaDetalle('fas fa-receipt', 'Deuda de una cancelación', `+ ${formatoCOP(deuda)}`, 'rr-deuda-fila'));
  }
  const total = crear('div', 'rr-total');
  total.append(crear('span', null, deuda > 0 ? 'Total en efectivo' : 'Total a pagar'),
    crear('strong', null, `${formatoCOP(deuda > 0 ? q.totalAPagar : q.precio)} COP`));
  nodos.push(total, crear('p', 'rr-nota', deuda > 0
    ? 'Le entregas este total en efectivo al conductor: la tarifa del viaje más tu deuda pendiente.'
    : 'Lo calcula NEXA según la zona y la distancia de tu viaje. El cobro final nunca supera este valor.'));
  cont.replaceChildren(...nodos);
  deudaEnCotizacion = deuda;
}

/* Instrucciones: se ven las 3 primeras; el resto, bajo "Ver N pasos más" */
function pintarPasos(pasos) {
  const det = document.getElementById('rrPasos');
  const lista = document.getElementById('rrPasosLista');
  const mas = document.getElementById('rrMasPasos');
  det.hidden = pasos.length === 0;
  lista.replaceChildren();
  mas.hidden = true;
  if (!pasos.length) return;
  const VISIBLES = 3;
  pasos.forEach((p, i) => {
    const li = crear('li', i >= VISIBLES ? 'rr-oculto' : '');
    li.append(crear('span', 'step-number', String(i + 1)), crear('span', 'instruction-text', p.texto), crear('span', 'step-distance', p.distancia));
    lista.append(li);
  });
  if (pasos.length > VISIBLES) {
    mas.hidden = false;
    mas.textContent = `Ver ${pasos.length - VISIBLES} pasos más`;
    mas.onclick = () => {
      const abierto = lista.classList.toggle('rr-todos');
      mas.textContent = abierto ? 'Ver menos' : `Ver ${pasos.length - VISIBLES} pasos más`;
    };
  }
}

function marcarErrorEntradas() {
  document.querySelectorAll('.location-input').forEach(i => i.setAttribute('aria-invalid', 'true'));
}
function quitarErrorEntradas() {
  document.querySelectorAll('.location-input').forEach(i => i.removeAttribute('aria-invalid'));
}

/* "Solicitar viaje" solo se habilita con cotización vigente y sin deuda */
function actualizarBotonSolicitar(hayCotizacion) {
  document.getElementById('requestRideBtn').disabled = !hayCotizacion;
  document.getElementById('rrBloqueo').hidden = !deudaPendiente;
}

/* ---- Cotización: el precio y la distancia cobrada los calcula el servidor ---- */
function cotizarViaje() {
  return fetch('/pasajero/cotizar', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-TOKEN': document.querySelector('input[name="_csrf"]').value
    },
    body: JSON.stringify({
      ubicacionOrigen: { latitud: originLatLng.lat, longitud: originLatLng.lng },
      ubicacionDestino: { latitud: destinationLatLng.lat, longitud: destinationLatLng.lng }
    })
  }).then(r => {
    if (r.ok) return r.json();
    return r.json().catch(() => ({})).then(err => {
      const e = new Error(err.error || err.message || 'No se pudo cotizar el viaje');
      e.delServidor = true;
      throw e;
    });
  });
}

/* ---- Calcular ruta: cotiza en el servidor y dibuja el trayecto con OSRM ---- */
function calcularRuta() {
  const destinoText = document.getElementById('destino').value.trim();
  if (!posicionPasajero || !originLatLng) {
    recotizando = false;
    showError('Aún no tenemos tu ubicación. Activa el permiso de ubicación para pedir un viaje.'); return;
  }
  if (!destinoText || !destinationLatLng) {
    recotizando = false;
    showError('Elige tu destino desde las sugerencias del buscador.'); return;
  }

  // Spinner
  const mapContainer = document.querySelector('.map-container');
  let loadingOverlay = document.querySelector('.map-loading');
  if (!loadingOverlay) {
    loadingOverlay = document.createElement('div');
    loadingOverlay.className = 'map-loading';
    loadingOverlay.innerHTML = '<div class="spinner"></div>';
    mapContainer.appendChild(loadingOverlay);
  }

  document.getElementById('detalle-precio').innerHTML = `
    <div class="loading-state">
      <div class="spinner"></div>
      <p>Calculando la mejor ruta...</p>
    </div>`;

  const { lat: oLat, lng: oLng } = originLatLng;
  const origenDeEstaCotizacion = { lat: oLat, lng: oLng };
  const { lat: dLat, lng: dLng } = destinationLatLng;
  const osrmUrl = `https://router.project-osrm.org/route/v1/driving/${oLng},${oLat};${dLng},${dLat}?overview=full&geometries=geojson&steps=true`;

  cotizarViaje()
    .then(q => fetch(osrmUrl).then(r => r.json()).then(data => ({ q, data })))
    .then(({ q, data }) => {
      loadingOverlay.classList.add('hidden');
      setTimeout(() => loadingOverlay.remove(), 500);

      if (!data.routes || data.routes.length === 0) {
        recotizando = false;
        showError('No se encontró una ruta entre esas direcciones.'); return;
      }

      const route = data.routes[0];
      // Distancia y precio cobrados: los del servidor (OSRM solo dibuja el trayecto)
      const distanciaKm = q.distanciaKm;
      calculatedDistanceKm = distanciaKm;
      const duracionTexto = segundosATexto(route.duration);
      estimatedPrice = q.precio;

      // Limpiar capas previas
      if (routePolyline) { map.removeLayer(routePolyline); routePolyline = null; }
      if (originLeaflet) { map.removeLayer(originLeaflet); originLeaflet = null; }
      if (destinationLeaflet) { map.removeLayer(destinationLeaflet); destinationLeaflet = null; }

      // Polilínea de ruta
      const coords = route.geometry.coordinates.map(([lng, lat]) => [lat, lng]);
      routePolyline = L.polyline(coords, {
        color: '#1E3A8A', weight: 5, opacity: 0.8
      }).addTo(map);
      map.fitBounds(routePolyline.getBounds(), { padding: [45, 45] });

      // Ícono SVG origen (gris)
      const mkOrigenIcon = L.divIcon({
        className: '',
        html: `<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24"
                 style="fill:#a6adc4;filter:drop-shadow(0 1px 3px rgba(0,0,0,.5))">
                 <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>`,
        iconSize: [28, 28], iconAnchor: [14, 28]
      });
      // Ícono SVG destino (verde)
      const mkDestinoIcon = L.divIcon({
        className: '',
        html: `<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24"
                 style="fill:#4caf50;filter:drop-shadow(0 1px 3px rgba(0,0,0,.5))">
                 <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>`,
        iconSize: [28, 28], iconAnchor: [14, 28]
      });

      // El origen es el punto en vivo del pasajero (marcadorLeaflet): no se dibuja un pin aparte
      destinationLeaflet = L.marker([dLat, dLng], { icon: mkDestinoIcon }).addTo(map).bindTooltip('Destino');

      // Instrucciones de ruta (steps OSRM)
      const steps = route.legs[0]?.steps || [];
      function traducirInstruccion(modifier, type) {
        let modStr = '';
        if (modifier) {
          switch (modifier.toLowerCase()) {
            case 'left': modStr = 'a la izquierda'; break;
            case 'right': modStr = 'a la derecha'; break;
            case 'slight left': modStr = 'levemente a la izquierda'; break;
            case 'slight right': modStr = 'levemente a la derecha'; break;
            case 'sharp left': modStr = 'bruscamente a la izquierda'; break;
            case 'sharp right': modStr = 'bruscamente a la derecha'; break;
            case 'straight': modStr = 'recto'; break;
            case 'uturn': modStr = 'en U'; break;
            default: modStr = modifier;
          }
        }

        let typeStr = '';
        if (type) {
          switch (type.toLowerCase()) {
            case 'depart': typeStr = 'Salga'; break;
            case 'arrive': typeStr = 'Llegue al destino'; break;
            case 'continue': typeStr = 'Continúe'; break;
            case 'turn': typeStr = 'Gire'; break;
            case 'off ramp': typeStr = 'Tome la salida de la rampa'; break;
            case 'rotary': typeStr = 'Ingrese a la rotonda'; break;
            case 'exit rotary': typeStr = 'Salga de la rotonda'; break;
            case 'merge': typeStr = 'Incorpórese'; break;
            case 'fork': typeStr = 'Tome la bifurcación'; break;
            case 'new name': typeStr = 'Continúe por la nueva vía'; break;
            default: typeStr = type;
          }
        }

        if (typeStr === 'Llegue al destino') {
          return typeStr;
        }

        if (typeStr && modStr) {
          return `${typeStr} ${modStr}`;
        }
        return typeStr || 'Continúe';
      }

      const pasos = steps.map(step => ({
        texto: traducirInstruccion(step.maneuver?.modifier, step.maneuver?.type),
        distancia: step.distance >= 1000
          ? `${(step.distance / 1000).toFixed(1)} km`
          : `${Math.round(step.distance)} m`
      }));

      pintarCotizacion(q, duracionTexto);
      pintarPasos(pasos);
      quitarErrorEntradas();
      origenCotizado = origenDeEstaCotizacion;
      recotizando = false;
      actualizarBotonSolicitar(true);
    })
    .catch(err => {
      loadingOverlay.classList.add('hidden');
      setTimeout(() => loadingOverlay.remove(), 500);
      // No reintentar en bucle desde el mismo punto: se recotiza solo si vuelve a moverse
      origenCotizado = origenDeEstaCotizacion;
      recotizando = false;
      if (err && err.delServidor) {
        // Fuera de Cartagena, ruta demasiado larga, etc.: el servidor explica el motivo
        pintarPanelVacio('zona', err.message);
        pintarPasos([]);
        marcarErrorEntradas();
        actualizarBotonSolicitar(false);
        showError(err.message);
      } else {
        pintarPanelVacio('vacio');
        pintarPasos([]);
        actualizarBotonSolicitar(false);
        showError('No se pudo calcular la ruta. Verifica tu conexión.');
      }
      console.error('Error al cotizar o trazar la ruta:', err);
    });
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
 * MODAL BÚSQUEDA DE MOTO
 * ============================================= */
function showMotoModal(title, message = '', showDriverInfo = false, showProgress = false, progress = 0, origin = '', destination = '', driverData = {}) {
  const motoModal = document.getElementById('motoModal');
  const modalTitle = document.getElementById('modalTitle');
  const modalMessage = document.getElementById('modalMessage');
  const driverInfo = document.getElementById('driverInfo');
  const progressContainer = document.getElementById('progressContainer');
  const progressBar = document.getElementById('progressBar');
  const originText = document.getElementById('originText');
  const destinationText = document.getElementById('destinationText');
  const driverPhoto = document.getElementById('driverPhoto');
  const driverName = document.getElementById('driverName');
  const driverStatus = document.getElementById('driverStatus');

  if (!motoModal || !modalTitle || !modalMessage || !driverInfo || !progressContainer || !progressBar || !originText || !destinationText || !driverPhoto || !driverName || !driverStatus) {
    console.error('Faltan elementos en el DOM para mostrar el modal');
    showError('Error al mostrar el modal. Por favor, revisa la estructura HTML.');
    return;
  }

  modalTitle.textContent = title;
  if (message) {
    modalMessage.textContent = message;
    modalMessage.style.display = 'block';
  } else {
    modalMessage.style.display = 'none';
  }

  const searchActions = document.getElementById('searchActions');
  if (searchActions) searchActions.style.display = showDriverInfo || showProgress ? 'none' : 'flex';
  const buscando = !(showDriverInfo || showProgress);
  const resumenExtra = document.getElementById('extraResumen');
  if (resumenExtra && !buscando) resumenExtra.hidden = true;
  if (buscando) pintarOferta();

  if (showDriverInfo) {
    driverInfo.style.display = 'block';
    driverPhoto.src = driverData.driverPhoto || 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';
    driverName.textContent = driverData.driverName || 'Conductor no asignado';
    driverStatus.textContent = driverData.driverStatus || 'Preparándose para recogerte';

    let cancelBtn = driverInfo.querySelector('.action-buttons .cancel-btn');
    if (!cancelBtn) {
      const actionButtons = document.createElement('div');
      actionButtons.className = 'action-buttons';
      actionButtons.innerHTML = `
        <button id="cancelRideBtn" class="btn cancel-btn">
          <i class="fas fa-times"></i> Cancelar viaje
        </button>`;
      driverInfo.appendChild(actionButtons);
      cancelBtn = document.getElementById('cancelRideBtn');
      cancelBtn.addEventListener('click', cancelRide);
    }
  } else {
    driverInfo.style.display = 'none';
  }

  if (showProgress) {
    progressContainer.style.display = 'block';
    progressBar.style.width = `${progress}%`;
    originText.textContent = origin || 'Origen';
    destinationText.textContent = destination || 'Destino';
  } else {
    progressContainer.style.display = 'none';
  }

  motoModal.style.display = 'flex';
  setTimeout(() => motoModal.classList.add('active'), 10);
}

function hideMotoModal() {
  const motoModal = document.getElementById('motoModal');
  if (motoModal) {
    motoModal.classList.remove('active');
    setTimeout(() => {
      motoModal.style.display = 'none';
      const modalMessage = document.getElementById('modalMessage');
      const driverInfo = document.getElementById('driverInfo');
      const progressContainer = document.getElementById('progressContainer');
      if (modalMessage) modalMessage.style.display = 'block';
      if (driverInfo) driverInfo.style.display = 'none';
      if (progressContainer) progressContainer.style.display = 'none';
    }, 200);
  }
}

/* Cancelar tras la gracia genera un cargo (20 % de la tarifa) que queda como deuda */
function mostrarResultadoCancelacion(data) {
  if (data && data.cargoCancelacion > 0) {
    showError(`Viaje cancelado. Se generó un cargo de $${data.cargoCancelacion.toLocaleString('es-CO')} COP ` +
      'que debes pagar para volver a solicitar un viaje.');
  } else {
    showError('Viaje cancelado correctamente');
  }
}

/** Pregunta antes de sumar la deuda al viaje; solo entonces se envía con `aceptaDeuda`. */
function confirmarDeudaYSolicitar(solicitud) {
  const total = estimatedPrice + deudaEnCotizacion;
  pedirConfirmacion('Tienes una deuda pendiente',
    `Pagarás ${formatoCOP(total)} en efectivo al conductor: ${formatoCOP(estimatedPrice)} del viaje `
    + `y ${formatoCOP(deudaEnCotizacion)} de la cancelación anterior. ¿Pedimos el viaje?`,
    () => enviarSolicitud({ ...solicitud, aceptaDeuda: true }));
}

function enviarSolicitud(solicitud) {
  fetch('/pasajero/solicitar-viaje', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-TOKEN': document.querySelector('input[name="_csrf"]').value
    },
    body: JSON.stringify(solicitud)
  })
    .then(response => {
      if (response.status === 402 && !solicitud.aceptaDeuda) {
        // El servidor sabe de una deuda que la cotización no traía: se pregunta y se reintenta
        return response.json().catch(() => ({})).then(err => {
          pedirConfirmacion('Tienes una deuda pendiente',
            (err.error || 'Tu deuda se sumará a este viaje.') + ' ¿Pedimos el viaje?',
            () => enviarSolicitud({ ...solicitud, aceptaDeuda: true }));
          return null;
        });
      }
      if (!response.ok) return response.json().then(err => { throw err; });
      return response.json();
    })
    .then(data => {
      if (!data) return;
      currentServicioId = data.servicioId;
      showMotoModal('Buscando conductor...', 'Por favor espera mientras encontramos un conductor para ti');
      subscribeToPasajeroTopic();
      cargarOferta();
    })
    .catch(error => {
      console.error('Error al solicitar viaje:', error);
      showError(error.message || 'Error al solicitar el viaje');
    });
}

/* Con deuda pendiente: aviso fijo arriba; el cobro va junto con el próximo viaje */
let deudaPendiente = false;
let deudaDatos = null;
/** Deuda que el servidor sumó a la última cotización. */
let deudaEnCotizacion = 0;
const CORREO_NEXA = 'nexabikeservice@gmail.com';

function abrirDeudaModal() {
  if (!deudaDatos) return;
  const d = deudaDatos;
  const cop = (n) => '$' + Number(n).toLocaleString('es-CO');
  const fecha = d.creadaEn ? new Date(d.creadaEn).toLocaleDateString('es-CO', { day: 'numeric', month: 'short', year: 'numeric' }) : '';
  document.getElementById('deudaMonto').textContent = cop(d.monto);
  document.getElementById('deudaViaje').textContent = '…' + String(d.servicioId).slice(-4) + (fecha ? ' · ' + fecha : '');
  document.getElementById('deudaMotivo').textContent = d.motivo || 'Cancelaste un viaje con cargo';
  document.getElementById('deudaEfectivo').textContent =
    'Se suma a tu próximo viaje: le entregas ' + cop(d.monto) + ' más la tarifa al conductor, en un solo pago. '
    + 'Antes de confirmar el viaje ves el total exacto.';
  const asunto = 'Pago de deuda por cancelación';
  const cuerpo = `Hola NEXA, quiero pagar mi deuda de ${cop(d.monto)} (viaje …${String(d.servicioId).slice(-4)}).`;
  document.getElementById('deudaContacto').href =
    `mailto:${CORREO_NEXA}?subject=${encodeURIComponent(asunto)}&body=${encodeURIComponent(cuerpo)}`;
  document.getElementById('deudaModal').style.display = 'flex';
}

function avisarDeudaPendiente() {
  fetch('/pasajero/deuda')
    .then(r => r.ok ? r.json() : null)
    .then(d => {
      if (d && d.tieneDeuda) {
        deudaPendiente = true;
        document.getElementById('rrDeudaTitulo').textContent =
          `Tienes una deuda de $${d.monto.toLocaleString('es-CO')} COP y se suma a tu próximo viaje`;
        document.getElementById('rrDeuda').hidden = false;
        deudaDatos = d;
        actualizarBotonSolicitar(estimatedPrice > 0);
      }
    })
    .catch(() => { /* sin aviso: el servidor igual bloquea la solicitud */ });
}

/* =============================================
 * EXTRA VOLUNTARIO ("Subir oferta")
 * ============================================= */
let ofertaActual = null;   // {tarifa, extra, margen, pasos, tope} de la solicitud que espera conductor
let extraSeleccion = 0;

function guardarOferta(d) {
  ofertaActual = {
    tarifa: Number(d.tarifa) || 0,
    extra: Number(d.extraVoluntario) || 0,
    margen: Number(d.margenExtra) || 0,
    pasos: d.pasosExtra || [],
    tope: Number(d.topeExtra) || 0,
    despacho: d.despacho || null
  };
}

/* "Avisamos a N conductores": a cuántos llegó la solicitud en la ola actual y cuándo se amplía la búsqueda */
function textoDespacho(d) {
  if (!d) return '';
  const n = Number(d.conductoresAvisados) || 0;
  const base = n === 0
    ? 'Buscando conductores cerca de ti…'
    : (n === 1 ? 'Avisamos a 1 conductor' : `Avisamos a ${n} conductores`) + (d.radioKm ? ' cerca de ti' : '');
  const falta = d.segundosSiguienteOla;
  const conExtra = d.adelantadaPorExtra ? ' · tu extra amplió la búsqueda' : '';
  return falta == null ? base + conExtra
    : `${base}${conExtra} · ampliamos la búsqueda en ${Math.max(0, Math.round(falta))} s`;
}

function cargarOferta() {
  return fetch('/pasajero/solicitud-activa')
    .then(r => r.ok ? r.json() : { activa: false })
    .then(d => { if (d.activa) { guardarOferta(d); pintarOferta(); } })
    .catch(() => { /* sin oferta: el botón queda oculto */ });
}

function pintarOferta() {
  const btn = document.getElementById('subirOfertaBtn');
  const resumen = document.getElementById('extraResumen');
  if (!btn || !resumen) return;
  const hay = !!ofertaActual && !!currentServicioId;
  btn.hidden = !hay || ofertaActual.margen <= 0;
  resumen.hidden = !hay || !(ofertaActual && ofertaActual.extra > 0);
  if (hay) resumen.textContent = ExtraVoluntario.resumen(ofertaActual.tarifa, ofertaActual.extra);
  const aviso = document.getElementById('despachoAviso');
  if (aviso) {
    aviso.textContent = hay ? textoDespacho(ofertaActual.despacho) : '';
    aviso.hidden = !aviso.textContent;
  }
}

// Mientras espera conductor, el aviso se refresca solo (la ola y el número de conductores cambian con el tiempo)
setInterval(() => {
  const modal = document.getElementById('motoModal');
  if (currentServicioId && ofertaActual && modal && modal.classList.contains('active')
      && document.visibilityState === 'visible') {
    cargarOferta();
  }
}, 8000);

function abrirExtraModal() {
  if (!ofertaActual) return;
  const o = ofertaActual;
  extraSeleccion = 0;
  document.getElementById('extraTope').textContent = ExtraVoluntario.formatoCOP(o.tope);
  document.getElementById('extraError').hidden = true;
  const contenedor = document.getElementById('extraOpciones');
  contenedor.replaceChildren();
  const disponibles = ExtraVoluntario.opciones(o.pasos, o.margen);
  (o.pasos || []).slice().sort((a, b) => a - b).forEach(p => {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'extra-opcion';
    b.setAttribute('role', 'radio');
    b.setAttribute('aria-checked', 'false');
    b.dataset.monto = p;
    b.textContent = '+' + ExtraVoluntario.formatoCOP(p);
    b.disabled = !disponibles.includes(p);
    contenedor.appendChild(b);
  });
  pintarDesgloseExtra();
  document.getElementById('extraModal').style.display = 'flex';
}

function pintarDesgloseExtra() {
  const o = ofertaActual;
  document.getElementById('extraTarifa').textContent = ExtraVoluntario.formatoCOP(o.tarifa);
  document.getElementById('extraFilaEnviado').hidden = !(o.extra > 0);
  document.getElementById('extraEnviado').textContent = '+' + ExtraVoluntario.formatoCOP(o.extra);
  document.getElementById('extraNuevo').textContent = extraSeleccion ? '+' + ExtraVoluntario.formatoCOP(extraSeleccion) : '—';
  document.getElementById('extraTotal').textContent =
    ExtraVoluntario.formatoCOP(ExtraVoluntario.totalEfectivo(o.tarifa, o.extra, extraSeleccion));
  document.getElementById('extraConfirmar').disabled = !extraSeleccion;
  document.querySelectorAll('#extraOpciones .extra-opcion').forEach(b =>
    b.setAttribute('aria-checked', String(Number(b.dataset.monto) === extraSeleccion)));
}

function cerrarExtraModal() {
  document.getElementById('extraModal').style.display = 'none';
}

function confirmarExtra() {
  if (!extraSeleccion || !currentServicioId) return;
  const boton = document.getElementById('extraConfirmar');
  const error = document.getElementById('extraError');
  boton.disabled = true;
  error.hidden = true;
  fetch(`/pasajero/subir-oferta/${currentServicioId}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-TOKEN': document.querySelector('input[name="_csrf"]').value
    },
    body: JSON.stringify({ incremento: extraSeleccion })
  })
    .then(r => r.json().catch(() => ({})).then(d => {
      if (!r.ok) throw new Error(d.error || 'No se pudo subir la oferta');
      ofertaActual.extra = Number(d.extraVoluntario) || ofertaActual.extra;
      ofertaActual.margen = Number(d.margenRestante);
      cerrarExtraModal();
      pintarOferta();
    }))
    .catch(e => {
      error.textContent = e.message;
      error.hidden = false;
      boton.disabled = false;
    });
}

/* Tras recargar, retoma la solicitud que sigue esperando conductor para poder cancelarla */
function retomarSolicitudPendiente() {
  return fetch('/pasajero/solicitud-activa')
    .then(r => r.ok ? r.json() : { activa: false })
    .then(d => {
      if (!d.activa) return false;
      currentServicioId = d.servicioId;
      guardarOferta(d);
      showMotoModal('Buscando conductor...', 'Por favor espera mientras encontramos un conductor para ti');
      return true;
    })
    .catch(() => false);
}

const MENSAJE_VIAJE_EN_MARCHA = 'Tienes un servicio en marcha. Cancela el viaje (o termínalo) antes de cerrar sesión.';

/* Con una solicitud esperando conductor no se puede cerrar sesión: primero hay que cancelarla */
function pedirCerrarSesion(titulo, mensaje) {
  retomarSolicitudPendiente().then(pendiente => {
    if (pendiente) {
      showError('Tienes una solicitud esperando conductor. Cancélala antes de cerrar sesión.');
    } else if (window.ViajePasajero && ViajePasajero.activo()) {
      showError(MENSAJE_VIAJE_EN_MARCHA);
    } else {
      mostrarConfirmacion(titulo, mensaje, 'logout');
    }
  });
}

function cancelRide() {
  if (!currentServicioId) { hideMotoModal(); return; }

  fetch(`/pasajero/cancelar-viaje/${currentServicioId}`, {
    method: 'POST',
    headers: { 'X-CSRF-TOKEN': document.querySelector('input[name="_csrf"]').value }
  })
    .then(response => response.json().catch(() => ({})).then(data => {
      if (!response.ok) throw new Error(data.error || 'Error al cancelar el viaje');
      detenerSeguimiento();
      hideMotoModal();
      ViajePasajero.ocultar();
      ofertaActual = null;
      currentServicioId = null;
      mostrarResultadoCancelacion(data);
    }))
    .catch(error => {
      console.error('Error al cancelar viaje:', error);
      showError(error.message || 'Error al cancelar el viaje');
    });
}

/* =============================================
 * WEBSOCKET
 * ============================================= */
let stompClient = null;
let currentServicioId = null;

function connectWebSocket() {
  const socket = new SockJS('/ws');
  stompClient = Stomp.over(socket);

  fetch('/api/user-id')
    .then(response => response.json())
    .then(data => {
      if (data.userId) {
        startWebSocket(data.userId);
      } else {
        console.error('No se recibió userId');
        showError('Por favor, inicia sesión nuevamente');
      }
    })
    .catch(error => {
      console.error('Error al obtener userId:', error);
      setTimeout(connectWebSocket, 5000);
    });
}

function startWebSocket(userId) {
  stompClient.connect({}, function (frame) {
    console.log('Pasajero conectado al WebSocket: ' + frame);
    stompClient.subscribe(`/topic/pasajero/${userId}`, function (message) {
      const servicio = JSON.parse(message.body);
      console.log('Pasajero recibió actualización:', servicio);
      handleServicioUpdate(servicio);
    });
    // Posición real del conductor (≈ 1/s) mientras va a recogerte o te lleva
    stompClient.subscribe(`/topic/pasajero/${userId}/posicion`, function (message) {
      try { ViajePasajero.posicion(JSON.parse(message.body)); } catch (e) { console.warn('Posición ilegible', e); }
    });
  }, function (error) {
    console.error('Error en WebSocket del pasajero:', error);
    showError('Error de conexión. Reintentando...');
    setTimeout(() => connectWebSocket(), 5000);
  });
}

/** Panel del viaje sobre el mapa (conductor en camino, espera y viaje en curso). */
function mostrarPanelViaje(servicio) {
  ViajePasajero.iniciar({ mapa: map, cancelar: cancelRide });
  ViajePasajero.actualizar(servicio);
}

function handleServicioUpdate(servicio) {
  console.log('Pasajero procesando estado:', servicio.estado, servicio);
  currentServicioId = servicio.id;

  const driverPhoto = servicio.conductor?.fotoUrl || 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';
  const driverName = servicio.conductor?.nombre || 'Conductor asignado';

  switch (servicio.estado) {
    case 'ACEPTADO':
      hideMotoModal();
      mostrarPanelViaje(servicio);
      iniciarSeguimiento();
      break;
    case 'EN_CURSO':
      detenerSeguimiento();
      hideMotoModal();
      mostrarPanelViaje(servicio);
      break;
    case 'FINALIZADO':
      console.log('Servicio FINALIZADO, redirigiendo a calificación');
      detenerSeguimiento();
      hideMotoModal();
      ViajePasajero.ocultar();
      try {
        window.location.href = `/rating?servicioId=${servicio.id}&rol=pasajero`;
      } catch (error) {
        console.error('Error al redirigir:', error);
        showError('Error al redirigir a la página de calificación');
      }
      break;
    case 'CANCELADO':
      detenerSeguimiento();
      currentServicioId = null;
      hideMotoModal();
      ViajePasajero.ocultar();
      showError('El conductor ha cancelado el viaje');
      break;
    default:
      console.warn('Estado no manejado:', servicio.estado);
  }
}

/* Funciones adicionales */
function showServicioModal(servicio, title, content) {
  hideServicioModal();
  const servicioModal = document.createElement('div');
  servicioModal.id = 'servicioModal';
  servicioModal.className = 'modal';
  servicioModal.innerHTML = `
    <div class="modal-content">
      <div class="modal-header">
        <h3>${title}</h3>
        <span class="close-btn" onclick="hideServicioModal()">×</span>
      </div>
      <div class="modal-body">${content}</div>
    </div>`;
  document.body.appendChild(servicioModal);
  setTimeout(() => servicioModal.classList.add('active'), 10);
}

function hideServicioModal() {
  const servicioModal = document.getElementById('servicioModal');
  if (servicioModal) {
    servicioModal.classList.remove('active');
    setTimeout(() => servicioModal.remove(), 200);
  }
}

function cancelarViaje(servicioId) {
  fetch(`/pasajero/cancelar-viaje/${servicioId}`, {
    method: 'POST',
    headers: { 'X-CSRF-TOKEN': document.querySelector('input[name="_csrf"]').value }
  })
    .then(response => response.json().catch(() => ({})).then(data => {
      if (!response.ok) throw new Error(data.error || 'Error al cancelar');
      detenerSeguimiento();
      currentServicioId = null;
      hideMotoModal();
      ViajePasajero.ocultar();
      mostrarResultadoCancelacion(data);
    }))
    .catch(error => showError(error.message || 'Error al cancelar el viaje'));
}

function subscribeToPasajeroTopic() {
  const userId = localStorage.getItem('userId');
  if (userId && stompClient) {
    stompClient.subscribe('/topic/pasajero/' + userId, function (message) {
      const servicio = JSON.parse(message.body);
      handleServicioUpdate(servicio);
    });
  }
}

/* =============================================
 * HISTORIAL
 * ============================================= */
let historialDataPasajero = [];
let currentPagePasajero = 1;
const itemsPerPagePasajero = 5;

function cargarHistorialPasajero() {
  fetch('/pasajero/historial')
    .then(response => response.json())
    .then(historial => {
      historialDataPasajero = historial;
      renderizarHistorialPasajero();
    })
    .catch(error => {
      console.error('Error al cargar historial:', error);
      showError('Error al cargar historial de viajes');
    });
}

/* Cargos por cancelación: pagados, condonados y el pendiente */
const ESTADO_CARGO = {
  PENDIENTE: 'Pendiente de pago',
  PAGADO: 'Pagado',
  CONDONADO: 'Condonado',
  REGISTRADO: 'Registrado'
};

function cargarCargosPasajero() {
  fetch('/pasajero/historial-cargos')
    .then(r => r.ok ? r.json() : [])
    .then(cargos => {
      const seccion = document.getElementById('cargosSeccion');
      const tbody = document.getElementById('cargosBody');
      if (!seccion || !tbody) return;
      tbody.replaceChildren();
      seccion.hidden = !cargos.length;
      cargos.forEach(c => {
        const tr = document.createElement('tr');
        const celdas = [
          c.canceladoEn ? new Date(c.canceladoEn).toLocaleDateString('es-CO') : '—',
          '$' + Number(c.monto).toLocaleString('es-CO'),
          ESTADO_CARGO[c.estado] || c.estado,
          c.estado === 'CONDONADO' && c.detalle ? 'Motivo: ' + c.detalle
            : c.estado === 'PAGADO' ? 'Pagado el ' + new Date(c.resueltoEn).toLocaleDateString('es-CO')
            : ''
        ];
        celdas.forEach(texto => {
          const td = document.createElement('td');
          td.textContent = texto;
          tr.appendChild(td);
        });
        tbody.appendChild(tr);
      });
    })
    .catch(() => { /* sin historial de cargos: la sección queda oculta */ });
}

function renderizarHistorialPasajero(filteredData = historialDataPasajero) {
  const tbody = document.getElementById('historialBody');
  tbody.innerHTML = '';

  const start = (currentPagePasajero - 1) * itemsPerPagePasajero;
  const end = start + itemsPerPagePasajero;
  const paginatedData = filteredData.slice(start, end);

  paginatedData.forEach(viaje => {
    const row = document.createElement('tr');
    row.innerHTML = `
      <td>${new Date(viaje.fechaHora).toLocaleDateString()}</td>
      <td>${new Date(viaje.fechaHora).toLocaleTimeString()}</td>
      <td>${viaje.origen}</td>
      <td>${viaje.destino}</td>
      <td>$${viaje.tarifa.toLocaleString('es-CO')}</td>
      <td>
        <button onclick="mostrarDetallesViajePasajero('${viaje.id}')">
          <i class="fas fa-eye"></i>
        </button>
      </td>`;
    tbody.appendChild(row);
  });

  document.getElementById('pageInfo').textContent = `Página ${currentPagePasajero}`;
  document.getElementById('prevPage').disabled = currentPagePasajero === 1;
  document.getElementById('nextPage').disabled = end >= filteredData.length;
}

function filtrarHistorialPasajero() {
  const fecha = document.getElementById('filtroFecha').value;
  const filteredData = historialDataPasajero.filter(viaje => {
    return fecha
      ? new Date(viaje.fechaHora).toLocaleDateString() === new Date(fecha).toLocaleDateString()
      : true;
  });
  currentPagePasajero = 1;
  renderizarHistorialPasajero(filteredData);
}

function resetFiltrosHistorialPasajero() {
  document.getElementById('filtroFecha').value = '';
  document.getElementById('filtroConductor').value = '';
  currentPagePasajero = 1;
  renderizarHistorialPasajero();
}

function cambiarPaginaPasajero(delta) {
  currentPagePasajero += delta;
  if (currentPagePasajero < 1) currentPagePasajero = 1;
  const maxPage = Math.ceil(historialDataPasajero.length / itemsPerPagePasajero);
  if (currentPagePasajero > maxPage) currentPagePasajero = maxPage;
  renderizarHistorialPasajero();
}

function mostrarDetallesViajePasajero(servicioId) {
  fetch(`/pasajero/servicios/${servicioId}`)
    .then(response => response.json())
    .then(servicio => {
      document.getElementById('detallesViajeContent').innerHTML = `
        <div class="detail-row"><i class="fas fa-calendar"></i><span>Fecha:</span><span>${new Date(servicio.fechaHora).toLocaleDateString()}</span></div>
        <div class="detail-row"><i class="fas fa-clock"></i><span>Hora:</span><span>${new Date(servicio.fechaHora).toLocaleTimeString()}</span></div>
        <div class="detail-row"><i class="fas fa-map-marker-alt"></i><span>Origen:</span><span>${servicio.origen}</span></div>
        <div class="detail-row"><i class="fas fa-flag-checkered"></i><span>Destino:</span><span>${servicio.destino}</span></div>
        <div class="detail-row"><i class="fas fa-money-bill-wave"></i><span>Precio:</span><span>$${servicio.tarifa.toLocaleString('es-CO')}</span></div>
        ${servicio.calificacionConductor ? `<div class="detail-row"><i class="fas fa-star" style="color: #ffb703;"></i><span>Tu calificación al conductor:</span><span>${Number(servicio.calificacionConductor).toFixed(1)} ★</span></div>` : ''}`;
      if (servicio.comentariosConductor) {
        const fila = document.createElement('div');
        fila.className = 'detail-row';
        const icono = document.createElement('i');
        icono.className = 'fas fa-comment';
        const rotulo = document.createElement('span');
        rotulo.textContent = 'Tu comentario:';
        const texto = document.createElement('span');
        texto.textContent = '"' + servicio.comentariosConductor + '"';
        fila.append(icono, rotulo, texto);
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
 * DOMContentLoaded
 * ============================================= */
/* showSection ya está definida globalmente arriba */


document.addEventListener('DOMContentLoaded', () => {
  checkDarkMode();
  connectWebSocket();

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
  // NO llamar initMap() aquí: el contenedor #viaje está oculto (display:none)
  // initMap se llama en showSection('viaje') via requestAnimationFrame

  document.querySelector('.toggle-btn').addEventListener('click', () => {
    const sidebar = document.querySelector('.sidebar');
    const main = document.querySelector('.main');
    const icon = document.querySelector('.toggle-btn i');
    sidebar.classList.toggle('collapsed');
    main.classList.toggle('collapsed');
    icon.classList.toggle('fa-angle-double-left');
    icon.classList.toggle('fa-angle-double-right');
  });

  avisarDeudaPendiente();
  retomarViajeEnCamino();
  retomarSolicitudPendiente().then(() => {
    const motivo = new URLSearchParams(window.location.search).get('cierreBloqueado');
    if (motivo) {
      showError(motivo === 'viaje' ? MENSAJE_VIAJE_EN_MARCHA
        : 'Tienes una solicitud esperando conductor. Cancélala antes de cerrar sesión.');
      history.replaceState(null, '', window.location.pathname);
    }
  });
  const cancelSearchBtn = document.getElementById('cancelSearchBtn');
  if (cancelSearchBtn) cancelSearchBtn.addEventListener('click', cancelRide);
  document.getElementById('rrDeudaPagar')?.addEventListener('click', abrirDeudaModal);
  document.getElementById('deudaCerrar')?.addEventListener('click', () => { document.getElementById('deudaModal').style.display = 'none'; });
  document.getElementById('subirOfertaBtn')?.addEventListener('click', abrirExtraModal);
  document.getElementById('extraCerrar')?.addEventListener('click', cerrarExtraModal);
  document.getElementById('extraCancelar')?.addEventListener('click', cerrarExtraModal);
  document.getElementById('extraConfirmar')?.addEventListener('click', confirmarExtra);
  document.getElementById('extraOpciones')?.addEventListener('click', (e) => {
    const b = e.target.closest('.extra-opcion');
    if (!b || b.disabled) return;
    extraSeleccion = Number(b.dataset.monto);
    pintarDesgloseExtra();
  });
  const requestBtn = document.getElementById('requestRideBtn');
  const closeModalBtn = document.getElementById('closeModalBtn');
  const motoModal = document.getElementById('motoModal');

  requestBtn.addEventListener('click', () => {
    const U = window.UbicacionPasajero;
    const destino = document.getElementById('destino').value;
    const metodoPago = document.querySelector('.option-card.selected span').textContent;

    if (!U.vigente(posicionPasajero, Date.now())) {
      showError('No tenemos tu ubicación actual. Activa la ubicación y espera a que aparezca tu punto en el mapa.'); return;
    }
    if (!destinationLatLng || !origenCotizado) {
      showError('Primero calcula una ruta.'); return;
    }
    if (U.debeRecotizar(origenCotizado, originLatLng)) {
      showError('Te moviste desde que cotizamos. Recalculamos el precio desde donde estás.');
      calcularRuta(); return;
    }
    if (!U.recogidaValida(posicionPasajero, originLatLng)) {
      showError('Tu punto de recogida quedó lejos de donde estás. Acércalo o toca "Volver a mi ubicación".'); return;
    }
    const origen = direccionActual
      || `Punto de recogida (${originLatLng.lat.toFixed(5)}, ${originLatLng.lng.toFixed(5)})`;

    const solicitud = {
      origen,
      destino,
      ubicacionOrigen: { latitud: originLatLng.lat, longitud: originLatLng.lng },
      ubicacionDestino: { latitud: destinationLatLng.lat, longitud: destinationLatLng.lng },
      ubicacionPasajero: { latitud: posicionPasajero.lat, longitud: posicionPasajero.lng },
      fechaHora: new Date().toISOString(),
      metodoPago
    };
    // Con deuda pendiente, el pasajero confirma primero el total que pagará en efectivo
    if (deudaEnCotizacion > 0) confirmarDeudaYSolicitar(solicitud);
    else enviarSolicitud(solicitud);
  });

  if (closeModalBtn) closeModalBtn.addEventListener('click', () => hideMotoModal());

  if (motoModal) {
    window.addEventListener('click', (event) => {
      if (event.target === motoModal) hideMotoModal();
    });
  }

  document.querySelectorAll('.option-card:not(.disabled)').forEach(card => {
    card.addEventListener('click', function () {
      document.querySelectorAll('.option-card').forEach(c => c.classList.remove('selected'));
      this.classList.add('selected');
    });
  });
});

/* =============================================
 * MODAL CONFIRMACIÓN GENÉRICO
 * ============================================= */
const confirmModal = document.getElementById('confirm-modal');
const confirmBtnYes = document.getElementById('confirm-modal-btn-yes');
const confirmTitle = document.getElementById('confirm-modal-title');
const confirmMessage = document.getElementById('confirm-modal-message');

function openConfirmModal(title, message, actionId) {
  if (actionId === 'logout') { pedirCerrarSesion(title, message); return; }
  mostrarConfirmacion(title, message, actionId);
}

/** Confirmación con una acción propia (no las de `data-action-id`). */
function pedirConfirmacion(titulo, mensaje, alAceptar) {
  if (!confirmModal || !confirmBtnYes) { if (window.confirm(mensaje)) alAceptar(); return; }
  accionConfirmada = alAceptar;
  mostrarConfirmacion(titulo, mensaje, 'accion-directa');
}

let accionConfirmada = null;

function mostrarConfirmacion(title, message, actionId) {
  if (!confirmModal || !confirmBtnYes || !confirmTitle || !confirmMessage) {
    console.error('Elementos del modal de confirmación no encontrados'); return;
  }
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
    case 'accion-directa': {
      const accion = accionConfirmada;
      accionConfirmada = null;
      closeConfirmModal();
      if (accion) accion();
      return;
    }
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

if (confirmModal) {
  confirmModal.addEventListener('click', (e) => {
    if (e.target === confirmModal) closeConfirmModal();
  });
}

/* Exponer al scope global para los onclick del HTML */
window.openConfirmModal = openConfirmModal;
window.closeConfirmModal = closeConfirmModal;
window.initMap = initMap;
window.showSection = showSection;
window.calcularRuta = calcularRuta;
window.limpiarRuta = limpiarRuta;
window.centrarMapa = centrarMapa;
window.alternarTrafico = alternarTrafico;
window.toggleDarkMode = toggleDarkMode;
window.showSolicitudDetails = function () { }; // placeholder