/*
 * Capa del mapa para el viaje en curso (Leaflet): pines de recogida y destino, moto del conductor y la ruta.
 * Compartida por el panel del pasajero y el del conductor; no toca el DOM fuera del mapa que recibe.
 */
(function (raiz, fabrica) {
  raiz.ViajeMapa = fabrica(raiz);
})(typeof self !== 'undefined' ? self : this, function (raiz) {
  'use strict';

  function pin(L, mapa, lat, lng, texto, clase) {
    var icono = L.divIcon({
      className: '', iconSize: [0, 0], iconAnchor: [0, 0],
      html: '<span class="vp-etiqueta-pin ' + clase + '" style="position:absolute;transform:translate(-50%,-130%)"></span>',
    });
    var m = L.marker([lat, lng], { icon: icono, interactive: false, keyboard: false }).addTo(mapa);
    var nodo = m.getElement && m.getElement();
    var etiqueta = nodo && nodo.querySelector('.vp-etiqueta-pin');
    if (etiqueta) etiqueta.textContent = texto; // el texto nunca se arma como HTML
    return m;
  }

  function crear(mapa) {
    var L = raiz.L;
    var capas = { recogida: null, destino: null, pasajero: null, moto: null, rutaHecha: null, rutaFalta: null };
    var rutaCompleta = [];
    var ultimoRumbo = 0;

    function quitar(clave) {
      if (capas[clave]) { mapa.removeLayer(capas[clave]); capas[clave] = null; }
    }

    function fijarPin(clave, lat, lng, texto, clase) {
      quitar(clave);
      capas[clave] = pin(L, mapa, lat, lng, texto, clase);
    }

    function dibujarRuta(indiceActual) {
      quitar('rutaHecha');
      quitar('rutaFalta');
      if (rutaCompleta.length < 2) return;
      var i = Math.max(0, Math.min(indiceActual || 0, rutaCompleta.length - 1));
      if (i > 0) capas.rutaHecha = L.polyline(rutaCompleta.slice(0, i + 1), { color: '#00c4ff', weight: 5, opacity: .9 }).addTo(mapa);
      capas.rutaFalta = L.polyline(rutaCompleta.slice(i), { color: '#00c4ff', weight: 4, opacity: .8, dashArray: '2 9', lineCap: 'round' }).addTo(mapa);
    }

    /** Punto de la ruta más cercano a la posición (para pintar lo recorrido); búsqueda lineal, la ruta es corta. */
    function indiceMasCercano(lat, lng) {
      var mejor = 0, mejorD = Infinity;
      for (var i = 0; i < rutaCompleta.length; i++) {
        var dx = rutaCompleta[i][0] - lat, dy = rutaCompleta[i][1] - lng, d = dx * dx + dy * dy;
        if (d < mejorD) { mejorD = d; mejor = i; }
      }
      return mejor;
    }

    return {
      fijarRecogida: function (lat, lng) { fijarPin('recogida', lat, lng, 'Recogida', 'vp-etiqueta-recogida'); },
      fijarDestino: function (lat, lng) { fijarPin('destino', lat, lng, 'Destino', 'vp-etiqueta-destino'); },
      fijarPasajero: function (lat, lng, nombre) { fijarPin('pasajero', lat, lng, nombre || 'Pasajero', 'vp-etiqueta-pasajero'); },
      quitarPasajero: function () { quitar('pasajero'); },
      fijarRuta: function (puntos) { rutaCompleta = puntos || []; dibujarRuta(0); },
      moverMoto: function (lat, lng, rumbo) {
        if (typeof rumbo === 'number') ultimoRumbo = rumbo;
        if (!capas.moto) {
          var icono = L.divIcon({
            className: 'vp-marcador-moto', iconSize: [38, 38], iconAnchor: [19, 19],
            html: '<div class="vp-moto" aria-hidden="true">➤</div>',
          });
          capas.moto = L.marker([lat, lng], { icon: icono, interactive: false, keyboard: false, zIndexOffset: 1000 }).addTo(mapa);
        } else {
          capas.moto.setLatLng([lat, lng]);
        }
        var nodo = capas.moto.getElement && capas.moto.getElement();
        var disco = nodo && nodo.querySelector('.vp-moto');
        if (disco) disco.style.transform = 'rotate(' + (ultimoRumbo - 90) + 'deg)';
        if (rutaCompleta.length > 1) dibujarRuta(indiceMasCercano(lat, lng));
      },
      /** Encuadra lo que importa: moto, recogida o destino según la fase. */
      encuadrar: function (puntos) {
        var validos = (puntos || []).filter(function (p) { return p && isFinite(p[0]) && isFinite(p[1]); });
        // El panel flota sobre el mapa: a la izquierda en pantallas grandes, abajo en el celular
        var ancho = raiz.matchMedia && raiz.matchMedia('(max-width: 720px)').matches;
        var arriba = ancho ? [40, 40] : [440, 60];
        var abajo = ancho ? [40, Math.round(mapa.getSize().y * 0.55) + 20] : [60, 60];
        if (validos.length === 1) {
          mapa.setView(validos[0], Math.max(mapa.getZoom(), 16), { animate: false });
        } else if (validos.length > 1) {
          mapa.fitBounds(L.latLngBounds(validos), { paddingTopLeft: arriba, paddingBottomRight: abajo, maxZoom: 17, animate: false });
        }
      },
      limpiar: function () { Object.keys(capas).forEach(quitar); rutaCompleta = []; },
    };
  }

  return { crear: crear };
});
