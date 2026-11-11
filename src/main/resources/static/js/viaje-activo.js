/*
 * Viaje en curso del conductor: mapa con su posición real (GPS), la ruta, el pin del pasajero y el panel por fase
 * (a recoger → en el punto → en viaje). Reporta su posición al servidor, que calcula distancia y ETA y se la reenvía
 * al pasajero; aquí no se simula nada. Las acciones (llegué, iniciar, finalizar, cancelar) las pasa Dashboard_C.js.
 */
(function (raiz) {
  'use strict';
  var F = raiz.ViajeFases;
  var TILES = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  var ajustes = null;
  var e = vacio();

  function vacio() {
    return { servicio: null, vivo: null, pos: null, ultimoReporte: null, panel: null, capa: null, mapa: null,
      watchId: null, ticker: null, sondeoPasajero: null, textoPasajero: null, errorGps: null, confirmando: null,
      rutaDe: null, yaEncuadro: false };
  }

  function iniciar(opciones) { ajustes = opciones; }

  function activo() { return !!e.servicio; }

  function datosSeccion(nombre) {
    var s = raiz.document.getElementById('solicitudes');
    return s ? Number(s.dataset[nombre]) || 0 : 0;
  }

  function crearMapaYPanel() {
    var cont = raiz.document.getElementById('viajeActivoContenedor');
    var lienzo = raiz.document.getElementById('mapa-viaje');
    ajustes.mostrarSeccion();
    if (!e.mapa) {
      e.mapa = raiz.L.map(lienzo, { zoomControl: false }).setView([10.388, -75.484], 14);
      raiz.L.tileLayer(TILES, { maxZoom: 19,
        attribution: '&copy; OpenStreetMap contributors' }).addTo(e.mapa);
      raiz.L.control.zoom({ position: 'bottomright' }).addTo(e.mapa);
    }
    e.capa = raiz.ViajeMapa.crear(e.mapa);
    e.panel = raiz.ViajePanel.crear(cont, {
      rol: 'conductor',
      acciones: {
        maps: abrirMaps,
        llegue: function () { ajustes.acciones.llegue(e.servicio.id); },
        iniciar: function () { ajustes.acciones.iniciar(e.servicio.id); },
        finalizar: alFinalizar,
        cancelar: alCancelar,
      },
    });
    raiz.setTimeout(function () { e.mapa.invalidateSize(); encuadrar(); }, 80);
  }

  /** Finalizar antes del destino (el pasajero se bajó): pide un segundo toque porque se cobra según lo recorrido. */
  function alFinalizar(ev) {
    var b = ev.currentTarget;
    if (e.finalizaAntes && !e.confirmandoFin) {
      b.textContent = 'Aún no llegas: toca otra vez para finalizar aquí';
      e.confirmandoFin = raiz.setTimeout(function () { e.confirmandoFin = null; b.textContent = 'Finalizar viaje'; }, 5000);
      return;
    }
    if (e.confirmandoFin) { raiz.clearTimeout(e.confirmandoFin); e.confirmandoFin = null; }
    b.textContent = 'Finalizar viaje';
    ajustes.acciones.finalizar(e.servicio.id);
  }

  /** Última posición propia del GPS si es reciente (para "Llegué" sin esperar otra lectura del navegador). */
  function posicion() {
    return e.pos && Date.now() - e.pos.en < 10000 ? { latitud: e.pos.lat, longitud: e.pos.lng } : null;
  }

  function alCancelar(ev) {
    var b = ev.currentTarget;
    if (e.confirmando) {
      raiz.clearTimeout(e.confirmando);
      e.confirmando = null;
      b.textContent = 'Cancelando…';
      b.disabled = true;
      ajustes.acciones.cancelar(e.servicio.id);
      return;
    }
    b.textContent = '¿Seguro? Toca otra vez para cancelar';
    e.confirmando = raiz.setTimeout(function () { e.confirmando = null; b.textContent = 'Cancelar viaje'; }, 4000);
  }

  function objetivo(s) {
    return s.estado === 'EN_CURSO' ? s.ubicacionDestino : s.ubicacionOrigen;
  }

  function abrirMaps() {
    var o = e.servicio && objetivo(e.servicio);
    if (o) raiz.open(F.enlaceMaps(o.latitud, o.longitud), '_blank', 'noopener');
  }

  function dibujarMapa() {
    var s = e.servicio;
    if (s.ubicacionOrigen) e.capa.fijarRecogida(s.ubicacionOrigen.latitud, s.ubicacionOrigen.longitud);
    if (s.ubicacionDestino) e.capa.fijarDestino(s.ubicacionDestino.latitud, s.ubicacionDestino.longitud);
    if (e.rutaDe !== s.id) {
      e.rutaDe = s.id;
      var ruta = F.decodificarPolyline(s.rutaGeometria);
      if (!ruta.length && s.ubicacionOrigen && s.ubicacionDestino) {
        ruta = [[s.ubicacionOrigen.latitud, s.ubicacionOrigen.longitud], [s.ubicacionDestino.latitud, s.ubicacionDestino.longitud]];
      }
      // La ruta trazada es recogida → destino; yendo a recoger se muestra solo el tramo hasta el pasajero con la línea de la moto
      e.capa.fijarRuta(ruta);
    }
    if (e.pos) e.capa.moverMoto(e.pos.lat, e.pos.lng, e.pos.rumbo);
  }

  function encuadrar() {
    if (!e.servicio || !e.capa) return;
    var puntos = [];
    if (e.pos) puntos.push([e.pos.lat, e.pos.lng]);
    var o = objetivo(e.servicio);
    if (o) puntos.push([o.latitud, o.longitud]);
    e.capa.encuadrar(puntos);
    e.yaEncuadro = !!e.pos;
  }

  function contexto() {
    var s = e.servicio, ctx = { radioRecogidaM: datosSeccion('radioLlegada'), radioDestinoM: datosSeccion('radioDestino'),
      seguimiento: e.textoPasajero, espera: null };
    if (e.pos) {
      if (s.ubicacionOrigen) ctx.distanciaRecogidaM = F.distanciaMetros(e.pos, { lat: s.ubicacionOrigen.latitud, lng: s.ubicacionOrigen.longitud });
      if (s.ubicacionDestino) ctx.distanciaDestinoM = F.distanciaMetros(e.pos, { lat: s.ubicacionDestino.latitud, lng: s.ubicacionDestino.longitud });
    }
    return ctx;
  }

  function pintar() {
    if (!e.panel || !e.servicio) return;
    var vista = F.vistaConductor(e.servicio, e.vivo, Date.now(), contexto());
    e.finalizaAntes = !!vista.finalizaAntes;
    if (e.errorGps) vista.subtitulo = e.errorGps;
    e.panel.render(vista);
  }

  /* ---- GPS propio ---- */
  function alPosicion(p) {
    var anterior = e.pos;
    var actual = { lat: p.coords.latitude, lng: p.coords.longitude, en: Date.now(), rumbo: undefined };
    if (typeof p.coords.heading === 'number' && isFinite(p.coords.heading)) actual.rumbo = p.coords.heading;
    else if (anterior && F.distanciaMetros(anterior, actual) > 5) actual.rumbo = F.rumbo(anterior, actual);
    else if (anterior) actual.rumbo = anterior.rumbo;
    e.pos = actual;
    e.errorGps = null;
    if (e.capa) e.capa.moverMoto(actual.lat, actual.lng, actual.rumbo);
    if (!e.yaEncuadro) encuadrar();
    if (F.debeReportarViaje(e.ultimoReporte, { lat: actual.lat, lng: actual.lng }, actual.en)) reportar(actual);
    pintar();
  }

  /** Quieto, el GPS casi no avisa: cada segundo se revisa si toca el latido para que el servidor no vea vencida la posición. */
  function latido() {
    var ahora = Date.now();
    if (e.pos && ahora - e.pos.en < 30000 && F.debeReportarViaje(e.ultimoReporte, e.pos, ahora)) {
      reportar({ lat: e.pos.lat, lng: e.pos.lng, en: ahora });
    }
    pintar();
  }

  function alErrorGps(err) {
    e.errorGps = err && err.code === 1
      ? 'Activa el permiso de ubicación para que tu pasajero te vea.'
      : 'No logramos ubicarte; revisa tu GPS.';
    pintar();
  }

  function reportar(actual) {
    e.ultimoReporte = { lat: actual.lat, lng: actual.lng, en: actual.en };
    raiz.fetch('/conductor/ubicacion', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json', 'X-CSRF-TOKEN': ajustes.csrf() },
      body: JSON.stringify({ latitud: actual.lat, longitud: actual.lng, disponible: false }),
    }).then(function (r) { return r.status === 200 ? r.json() : null; })
      .then(function (v) {
        if (v && e.servicio && v.servicioId === e.servicio.id) {
          e.vivo = { fase: v.fase, latitud: v.latitud, longitud: v.longitud, distanciaRestanteKm: v.distanciaRestanteKm,
            etaMinutos: v.etaMinutos, recibidoEn: Date.now() };
          pintar();
        }
      })
      .catch(function () { e.ultimoReporte = null; /* se reintenta con el próximo punto */ });
  }

  /* ---- Dónde está el pasajero (solo mientras voy a recogerlo) ---- */
  function consultarPasajero() {
    var s = e.servicio;
    if (!s || F.fase(s) !== 'A_RECOGER') { e.textoPasajero = null; if (e.capa) e.capa.quitarPasajero(); return; }
    raiz.fetch('/conductor/pasajero-ubicacion/' + s.id, { headers: { Accept: 'application/json' } })
      .then(function (r) { return r.status === 200 ? r.json() : null; })
      .then(function (pos) {
        var t = raiz.ViajeConductor.textoSeguimiento(pos);
        e.textoPasajero = t.texto;
        if (!e.capa) return;
        if (pos) e.capa.fijarPasajero(pos.latitud, pos.longitud, ((s.pasajero && s.pasajero.nombre) || 'Pasajero').split(' ')[0]);
        else e.capa.quitarPasajero();
        pintar();
      })
      .catch(function () { e.textoPasajero = null; });
  }

  function arrancarServicios() {
    if (raiz.navigator.geolocation && e.watchId == null) {
      e.watchId = raiz.navigator.geolocation.watchPosition(alPosicion, alErrorGps,
        { enableHighAccuracy: true, maximumAge: 2000, timeout: 15000 });
    } else if (!raiz.navigator.geolocation) {
      alErrorGps({ code: 2 });
    }
    if (!e.ticker) e.ticker = raiz.setInterval(latido, 1000);
    if (!e.sondeoPasajero) { consultarPasajero(); e.sondeoPasajero = raiz.setInterval(consultarPasajero, 4000); }
  }

  /** Cada cambio del servicio (aceptado → llegué → en curso). */
  function mostrar(servicio) {
    var nuevo = !e.servicio || e.servicio.id !== servicio.id;
    if (nuevo && e.servicio) terminar();
    var cambioFase = !e.servicio || F.fase(e.servicio) !== F.fase(servicio);
    e.servicio = servicio;
    if (!e.panel) crearMapaYPanel();
    if (cambioFase) { e.vivo = null; e.yaEncuadro = false; e.textoPasajero = null; }
    dibujarMapa();
    arrancarServicios();
    if (cambioFase && e.pos) encuadrar();
    pintar();
  }

  /** Tras recargar la página o reiniciar el servidor: recupera el viaje que sigue vigente. */
  function retomar() {
    return raiz.fetch('/conductor/viaje-activo', { headers: { Accept: 'application/json' } })
      .then(function (r) { return r.status === 200 ? r.json() : null; })
      .then(function (s) { if (s && (s.estado === 'ACEPTADO' || s.estado === 'EN_CURSO')) { mostrar(s); return true; } return false; })
      .catch(function () { return false; });
  }

  function terminar() {
    if (e.watchId != null) raiz.navigator.geolocation.clearWatch(e.watchId);
    if (e.ticker) raiz.clearInterval(e.ticker);
    if (e.sondeoPasajero) raiz.clearInterval(e.sondeoPasajero);
    if (e.confirmando) raiz.clearTimeout(e.confirmando);
    if (e.panel) e.panel.destruir();
    if (e.capa) e.capa.limpiar();
    e = Object.assign(vacio(), { mapa: e.mapa });
  }

  raiz.ViajeActivo = { iniciar: iniciar, mostrar: mostrar, retomar: retomar, terminar: terminar, activo: activo, posicion: posicion };
})(window);
