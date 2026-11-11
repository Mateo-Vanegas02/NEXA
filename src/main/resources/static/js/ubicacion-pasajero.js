/**
 * NEXA | Ubicación del pasajero en tiempo real y punto de recogida (reglas puras).
 * La posición del pasajero sale siempre de su GPS (navigator.geolocation.watchPosition): no se escribe a mano.
 * El punto de recogida arranca ahí, pero el pasajero puede moverlo con el pin, siempre cerca de donde está y
 * pegado a una calle. Estas funciones deciden cuándo volver a geocodificar, cuándo la cotización quedó vieja,
 * hasta dónde se puede mover el pin y cómo explicar los errores.
 * Se prueban en Node (src/test/js/ubicacion-pasajero.test.mjs).
 */
(function (raiz, fabrica) {
  const api = fabrica();
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else raiz.UbicacionPasajero = api;
})(typeof window !== 'undefined' ? window : globalThis, function () {
  'use strict';

  /** Moverse menos que esto no cambia la dirección mostrada (y no gasta consultas a Nominatim). */
  const METROS_GEOCODIFICAR = 50;
  /** Si el pasajero se aleja más que esto del punto cotizado, se vuelve a cotizar. */
  const METROS_RECOTIZAR = 150;
  /** Precisión (radio en metros) desde la que se avisa que la ubicación puede no ser exacta. */
  const PRECISION_BAJA = 150;
  /** Una posición más vieja que esto no sirve para pedir viaje. */
  const VIGENCIA_MS = 2 * 60 * 1000;
  /** Hasta dónde puede alejar el pasajero su punto de recogida (igual que nexa.recogida.radio-max-metros). */
  const RADIO_RECOGIDA_M = 300;
  /** Si pegar el punto a la calle lo mueve más que esto, se respeta lo que marcó el pasajero. */
  const MAX_AJUSTE_CALLE_M = 120;
  const MARGEN_BORDE_M = 5;

  /** Seguimiento hasta la recogida: no más de uno cada 3 s; se envía si se movió 10 m o, quieto, cada 10 s (latido). */
  const SEGUIMIENTO_MIN_MS = 3000;
  const SEGUIMIENTO_LATIDO_MS = 10000;
  const SEGUIMIENTO_METROS = 10;

  const OPCIONES_GPS = { enableHighAccuracy: true, maximumAge: 5000, timeout: 20000 };

  /** Distancia en metros entre dos puntos {lat, lng} (haversine). */
  function distanciaMetros(a, b) {
    if (!a || !b) return Infinity;
    const R = 6371000;
    const rad = (g) => (g * Math.PI) / 180;
    const dLat = rad(b.lat - a.lat);
    const dLng = rad(b.lng - a.lng);
    const h = Math.sin(dLat / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLng / 2) ** 2;
    return 2 * R * Math.asin(Math.min(1, Math.sqrt(h)));
  }

  function debeGeocodificar(ultimaGeocodificada, actual) {
    return !ultimaGeocodificada || distanciaMetros(ultimaGeocodificada, actual) >= METROS_GEOCODIFICAR;
  }

  /** ¿Hay que recotizar porque el pasajero se movió desde el punto con que se cotizó? */
  function debeRecotizar(origenCotizado, actual) {
    return !!origenCotizado && !!actual && distanciaMetros(origenCotizado, actual) > METROS_RECOTIZAR;
  }

  function precisionBaja(precisionMetros) {
    return precisionMetros == null || precisionMetros > PRECISION_BAJA;
  }

  function vigente(posicion, ahoraMs) {
    return !!posicion && ahoraMs - posicion.tiempo <= VIGENCIA_MS;
  }

  /** ¿El punto de recogida está dentro del radio permitido alrededor del pasajero? */
  function recogidaValida(pasajero, recogida) {
    return !!pasajero && !!recogida && distanciaMetros(pasajero, recogida) <= RADIO_RECOGIDA_M;
  }

  /**
   * Acerca el punto de recogida hasta el borde del radio permitido, en la misma dirección en que lo arrastró el
   * pasajero. Así el pin nunca "se escapa": se queda donde más cerca puede estar de lo que pidió.
   */
  function limitarAlRadio(pasajero, recogida) {
    if (!pasajero || !recogida) return recogida;
    const metros = distanciaMetros(pasajero, recogida);
    if (metros <= RADIO_RECOGIDA_M || metros === 0) return recogida;
    // Un poco antes del borde: el redondeo no debe dejarlo "por fuera" ni para el servidor
    const factor = (RADIO_RECOGIDA_M - MARGEN_BORDE_M) / metros;
    return {
      lat: pasajero.lat + (recogida.lat - pasajero.lat) * factor,
      lng: pasajero.lng + (recogida.lng - pasajero.lng) * factor,
    };
  }

  /** Se acepta pegar el punto a la calle solo si el ajuste es pequeño; si no, manda lo que marcó el pasajero. */
  function aceptarAjusteACalle(marcado, enLaCalle) {
    return !!enLaCalle && distanciaMetros(marcado, enLaCalle) <= MAX_AJUSTE_CALLE_M;
  }

  /** Texto del campo de recogida: dirección y, si el pin se movió, a qué distancia del pasajero quedó. */
  function textoRecogida(direccion, metrosDesdePasajero) {
    const base = direccion || 'Punto de recogida';
    const m = Math.round(Number(metrosDesdePasajero) || 0);
    return m >= 20 ? base + ' · a ' + m + ' m de ti' : base;
  }

  /** Texto para el campo de origen. */
  function textoOrigen(direccion, precisionMetros) {
    const base = direccion ? 'Tu ubicación: ' + direccion : 'Tu ubicación actual';
    return precisionMetros != null && precisionMetros > PRECISION_BAJA
      ? base + ' (±' + Math.round(precisionMetros) + ' m)'
      : base;
  }

  /** Mensaje para el pasajero según el error de la geolocalización (GeolocationPositionError.code). */
  function mensajeError(codigo, soportado) {
    if (soportado === false) return 'Tu navegador no permite obtener la ubicación. Usa un navegador actualizado para pedir viajes.';
    switch (codigo) {
      case 1: return 'Activa el permiso de ubicación para NEXA (ícono del candado junto a la dirección del sitio) y recarga la página. Sin tu ubicación no podemos enviarte un conductor.';
      case 2: return 'No pudimos detectar tu ubicación. Revisa que el GPS esté encendido y que tengas señal.';
      case 3: return 'Tu ubicación está tardando en llegar. Revisa que el GPS esté encendido; seguimos intentando.';
      default: return 'No pudimos obtener tu ubicación.';
    }
  }

  /**
   * ¿Hay que avisarle al servidor dónde está el pasajero? {@code ultimo} = {lat, lng, en} del último envío (o null).
   * Quieto también se reenvía cada 10 s: el servidor oculta al conductor una posición de más de 30 s.
   */
  function debeReportarSeguimiento(ultimo, actual, ahoraMs) {
    if (!actual) return false;
    if (!ultimo) return true;
    const pasado = ahoraMs - ultimo.en;
    if (pasado >= SEGUIMIENTO_LATIDO_MS) return true;
    if (pasado < SEGUIMIENTO_MIN_MS) return false;
    return distanciaMetros(ultimo, actual) >= SEGUIMIENTO_METROS;
  }

  return {
    SEGUIMIENTO_MIN_MS, SEGUIMIENTO_LATIDO_MS, SEGUIMIENTO_METROS, debeReportarSeguimiento,
    METROS_GEOCODIFICAR, METROS_RECOTIZAR, PRECISION_BAJA, VIGENCIA_MS, OPCIONES_GPS,
    RADIO_RECOGIDA_M, MAX_AJUSTE_CALLE_M,
    distanciaMetros, debeGeocodificar, debeRecotizar, precisionBaja, vigente, textoOrigen, mensajeError,
    recogidaValida, limitarAlRadio, aceptarAjusteACalle, textoRecogida,
  };
});
