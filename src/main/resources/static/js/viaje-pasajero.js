/*
 * Viaje en curso del pasajero: panel flotante sobre el mapa + moto del conductor en vivo.
 * Dashboard_P_v2.js le pasa cada actualización del servicio (STOMP /topic/pasajero/{id}) y la posición en vivo
 * (/topic/pasajero/{id}/posicion); toda la lógica de textos y fases está en ViajeFases.
 */
(function (raiz) {
  'use strict';
  var F = raiz.ViajeFases;
  var estado = { servicio: null, vivo: null, espera: null, panel: null, mapa: null, capa: null, ticker: null, confirmando: null, hidratando: false, rutaDe: null };
  var ajustes = null;

  function iniciar(opciones) {
    ajustes = opciones;
  }

  function contenedor() {
    return raiz.document.querySelector('.map-container');
  }

  function crearPanel() {
    var cont = contenedor();
    if (!cont) return;
    cont.classList.add('vp-contenedor');
    raiz.document.querySelector('.ride-request-container').classList.add('ride-request-container--viaje');
    estado.capa = raiz.ViajeMapa.crear(ajustes.mapa);
    estado.panel = raiz.ViajePanel.crear(cont, {
      rol: 'pasajero',
      notaCancelar: 'Si cancelas cuando tu conductor ya llegó, puede aplicarse un cargo.',
      acciones: { cancelar: alCancelar },
    });
    estado.ticker = raiz.setInterval(pintar, 1000);
    setTimeout(function () { ajustes.mapa.invalidateSize(); }, 50);
  }

  function alCancelar(e) {
    var boton = e.currentTarget;
    if (estado.confirmando) {
      raiz.clearTimeout(estado.confirmando);
      estado.confirmando = null;
      boton.textContent = 'Cancelando…';
      boton.disabled = true;
      ajustes.cancelar();
      return;
    }
    boton.textContent = '¿Seguro? Toca otra vez para cancelar';
    estado.confirmando = raiz.setTimeout(function () {
      estado.confirmando = null;
      boton.textContent = 'Cancelar viaje';
    }, 4000);
  }

  /** La configuración de espera la define el servidor; se pide una sola vez al empezar el viaje. */
  function cargarEspera() {
    if (estado.espera || estado.hidratando) return;
    estado.hidratando = true;
    raiz.fetch('/pasajero/viaje-en-camino').then(function (r) { return r.ok ? r.json() : null; })
      .then(function (d) { if (d && d.espera) { estado.espera = d.espera; pintar(); } })
      .catch(function () { /* sin la regla de espera solo se oculta el aviso del recargo */ })
      .finally(function () { estado.hidratando = false; });
  }

  function dibujarMapa() {
    var s = estado.servicio, capa = estado.capa;
    if (!s || !capa) return;
    if (s.ubicacionOrigen) capa.fijarRecogida(s.ubicacionOrigen.latitud, s.ubicacionOrigen.longitud);
    if (s.ubicacionDestino) capa.fijarDestino(s.ubicacionDestino.latitud, s.ubicacionDestino.longitud);
    if (estado.rutaDe !== s.id) {
      estado.rutaDe = s.id;
      var ruta = F.decodificarPolyline(s.rutaGeometria);
      if (!ruta.length && s.ubicacionOrigen && s.ubicacionDestino) {
        ruta = [[s.ubicacionOrigen.latitud, s.ubicacionOrigen.longitud], [s.ubicacionDestino.latitud, s.ubicacionDestino.longitud]];
      }
      capa.fijarRuta(ruta);
    }
  }

  function encuadrar() {
    var s = estado.servicio;
    if (!s) return;
    var puntos = [];
    if (estado.vivo) puntos.push([estado.vivo.latitud, estado.vivo.longitud]);
    var objetivo = s.estado === 'EN_CURSO' ? s.ubicacionDestino : s.ubicacionOrigen;
    if (objetivo) puntos.push([objetivo.latitud, objetivo.longitud]);
    estado.capa.encuadrar(puntos);
  }

  function pintar() {
    if (!estado.panel || !estado.servicio) return;
    var vivo = estado.vivo;
    var vista = F.vistaPasajero(estado.servicio, vivo, Date.now(), estado.espera);
    if (vivo && F.senalPerdida(vivo, Date.now(), 20000)) vista.subtitulo = 'Sin señal del conductor · ' + vista.subtitulo;
    estado.panel.render(vista);
  }

  /** Cada cambio de estado del servicio (aceptado, llegó, en curso). */
  function actualizar(servicio) {
    var cambioFase = !estado.servicio || F.fase(estado.servicio) !== F.fase(servicio) || estado.servicio.id !== servicio.id;
    if (!estado.servicio || estado.servicio.id !== servicio.id) estado.vivo = null;
    estado.servicio = servicio;
    if (!estado.panel) crearPanel();
    cargarEspera();
    dibujarMapa();
    pintar();
    if (cambioFase) encuadrar();
  }

  /** Posición en vivo del conductor (≈ 1 por segundo). */
  function posicion(p) {
    if (!estado.servicio || !estado.capa || p.servicioId !== estado.servicio.id) return;
    var anterior = estado.vivo;
    var rumbo = anterior && F.distanciaMetros({ lat: anterior.latitud, lng: anterior.longitud }, { lat: p.latitud, lng: p.longitud }) > 3
      ? F.rumbo({ lat: anterior.latitud, lng: anterior.longitud }, { lat: p.latitud, lng: p.longitud }) : undefined;
    estado.vivo = { fase: p.fase, latitud: p.latitud, longitud: p.longitud, distanciaRestanteKm: p.distanciaRestanteKm,
      etaMinutos: p.etaMinutos, recibidoEn: Date.now() };
    estado.capa.moverMoto(p.latitud, p.longitud, rumbo);
    if (!anterior) encuadrar();
    pintar();
  }

  function ocultar() {
    if (estado.ticker) raiz.clearInterval(estado.ticker);
    if (estado.confirmando) raiz.clearTimeout(estado.confirmando);
    if (estado.panel) estado.panel.destruir();
    if (estado.capa) estado.capa.limpiar();
    var grilla = raiz.document.querySelector('.ride-request-container');
    if (grilla) grilla.classList.remove('ride-request-container--viaje');
    estado = { servicio: null, vivo: null, espera: estado.espera, panel: null, mapa: null, capa: null, ticker: null, confirmando: null, hidratando: false, rutaDe: null };
  }

  raiz.ViajePasajero = { iniciar: iniciar, actualizar: actualizar, posicion: posicion, ocultar: ocultar, activo: function () { return !!estado.panel; } };
})(window);
