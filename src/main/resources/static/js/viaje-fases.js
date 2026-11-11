/*
 * Fases del viaje en curso (pasajero y conductor): lógica pura, sin DOM. La pantalla la arma viaje-panel.js.
 * Los números de negocio (espera, radio de llegada) los entrega el servidor; aquí solo se formatean y se combinan.
 *
 * Fases: A_RECOGER (el conductor va hacia la recogida) → EN_EL_PUNTO (llegada registrada, espera) → EN_VIAJE.
 */
(function (raiz, fabrica) {
  var api = fabrica();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else raiz.ViajeFases = api;
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  var PASO = { A_RECOGER: 2, EN_EL_PUNTO: 3, EN_VIAJE: 4 };

  function formatoCOP(n) {
    return '$' + Math.round(Number(n) || 0).toLocaleString('es-CO');
  }

  /** "850 m" por debajo del kilómetro; "1,4 km" por encima. */
  function formatoDistancia(km) {
    var k = Math.max(0, Number(km) || 0);
    if (k < 1) return (Math.round(k * 100) * 10) + ' m';
    return (Math.round(k * 10) / 10).toFixed(1).replace('.', ',') + ' km';
  }

  function formatoMinutos(min) {
    var m = Math.max(0, Math.round(Number(min) || 0));
    return m + ' min';
  }

  function formatoReloj(seg) {
    var s = Math.max(0, Math.floor(Number(seg) || 0));
    var h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), r = s % 60;
    var mm = (m < 10 ? '0' : '') + m, rr = (r < 10 ? '0' : '') + r;
    return h > 0 ? h + ':' + mm + ':' + rr : mm + ':' + rr;
  }

  /** "Andrés Ríos" → "AR"; vacío → "?". */
  function iniciales(nombre) {
    var partes = String(nombre || '').trim().split(/\s+/).filter(Boolean);
    if (!partes.length) return '?';
    var a = partes[0].charAt(0), b = partes.length > 1 ? partes[partes.length - 1].charAt(0) : '';
    return (a + b).toUpperCase();
  }

  /** Decodifica una polyline de precisión 5 (la que entrega OSRM) a [[lat, lng], ...]. */
  function decodificarPolyline(texto) {
    var puntos = [];
    if (!texto) return puntos;
    var i = 0, lat = 0, lng = 0;
    while (i < texto.length) {
      for (var eje = 0; eje < 2; eje++) {
        var desplazamiento = 0, resultado = 0, byte;
        do {
          if (i >= texto.length) return puntos;
          byte = texto.charCodeAt(i++) - 63;
          resultado |= (byte & 0x1f) << desplazamiento;
          desplazamiento += 5;
        } while (byte >= 0x20);
        var delta = (resultado & 1) ? ~(resultado >> 1) : (resultado >> 1);
        if (eje === 0) lat += delta; else lng += delta;
      }
      puntos.push([lat / 1e5, lng / 1e5]);
    }
    return puntos;
  }

  /** Distancia en metros entre dos puntos {lat, lng} (haversine). Solo para la pantalla: el servidor valida. */
  function distanciaMetros(a, b) {
    var R = 6371008.8, rad = Math.PI / 180;
    var dLat = (b.lat - a.lat) * rad, dLng = (b.lng - a.lng) * rad;
    var h = Math.sin(dLat / 2) * Math.sin(dLat / 2)
      + Math.cos(a.lat * rad) * Math.cos(b.lat * rad) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
    return 2 * R * Math.asin(Math.min(1, Math.sqrt(h)));
  }

  /** Rumbo en grados (0 = norte) del movimiento de a hacia b. */
  function rumbo(a, b) {
    var rad = Math.PI / 180;
    var y = Math.sin((b.lng - a.lng) * rad) * Math.cos(b.lat * rad);
    var x = Math.cos(a.lat * rad) * Math.sin(b.lat * rad)
      - Math.sin(a.lat * rad) * Math.cos(b.lat * rad) * Math.cos((b.lng - a.lng) * rad);
    return (Math.atan2(y, x) / rad + 360) % 360;
  }

  /** Avance del viaje 0..1 según lo que falta; nunca se queda en 0 ni marca 100 % antes de llegar. */
  function progresoViaje(restanteKm, totalKm) {
    var total = Number(totalKm) || 0, resta = Number(restanteKm);
    if (!(total > 0) || !isFinite(resta)) return 0.05;
    return Math.min(0.98, Math.max(0.05, 1 - resta / total));
  }

  /** Recargo por espera (misma regla del servidor, ModeloTarifa.recargoEspera), solo para mostrarlo en vivo. */
  function recargoEspera(segundos, espera) {
    if (!espera) return 0;
    var min = Math.max(0, Number(segundos) || 0) / 60;
    var cobrables = Math.max(0, Math.min(min, espera.maxMinutos) - espera.graciaMinutos);
    return Math.round((Number(espera.valorMinuto) || 0) * cobrables);
  }

  function segundosDesde(fecha, ahoraMs) {
    var t = Date.parse(fecha);
    return isNaN(t) ? 0 : Math.max(0, Math.floor((ahoraMs - t) / 1000));
  }

  var AVISO_FINALIZAR_ANTES = 'Solo tu conductor finaliza el viaje. Si te bajas antes de llegar y le pides terminar '
    + 'antes de la mitad del recorrido, pagas la mitad del viaje; pasada la mitad, pagas el viaje completo.';

  /** Fase de un servicio: la llegada registrada separa "a recoger" de "en el punto". */
  function fase(servicio) {
    if (!servicio) return 'A_RECOGER';
    if (servicio.estado === 'EN_CURSO') return 'EN_VIAJE';
    return servicio.fechaLlegada ? 'EN_EL_PUNTO' : 'A_RECOGER';
  }

  /** Posición en vivo válida para la fase actual (la del servidor trae su propia fase). */
  function vivoDeFase(vivo, f) {
    if (!vivo) return null;
    var esperada = f === 'EN_VIAJE' ? 'EN_CURSO' : 'ACEPTADO';
    return vivo.fase === esperada ? vivo : null;
  }

  function textoDireccion(valor, porDefecto) {
    return valor ? String(valor) : porDefecto;
  }

  function personaDe(p, rolEtiqueta) {
    p = p || {};
    return {
      nombre: p.nombre || rolEtiqueta,
      iniciales: iniciales(p.nombre),
      fotoUrl: p.fotoUrl || null,
      calificacion: typeof p.calificacion === 'number' ? p.calificacion : null,
      nivel: typeof p.nivel === 'number' && p.nivel > 0 ? p.nivel : null,
    };
  }

  function formatoCalificacion(c) {
    return (Math.round(c * 10) / 10).toFixed(1).replace('.', ',');
  }

  /**
   * Lo que ve el pasajero. {@code servicio} es su vista del viaje; {@code vivo} la última posición del conductor
   * ({fase, distanciaRestanteKm, etaMinutos}) o null; {@code espera} la configuración de espera del servidor.
   */
  function vistaPasajero(servicio, vivo, ahoraMs, espera) {
    var f = fase(servicio);
    var v = vivoDeFase(vivo, f);
    var c = servicio.conductor || {};
    var total = (Number(servicio.tarifa) || 0) + (Number(servicio.extraVoluntario) || 0);
    var vista = {
      fase: f, paso: PASO[f], etiqueta: '', titulo: '', subtitulo: '', espera: null,
      persona: personaDe(c, 'Tu conductor'),
      vehiculo: c.vehiculo || c.placa ? { texto: c.vehiculo || 'Moto', placa: c.placa || '' } : null,
      paradas: { origen: textoDireccion(servicio.origen, 'Punto de recogida'), destino: textoDireccion(servicio.destino, 'Destino') },
      pago: { metodo: servicio.metodoPago || 'Efectivo', extra: Number(servicio.extraVoluntario) || 0, total: total },
      puedeCancelar: f !== 'EN_VIAJE',
    };
    if (f === 'A_RECOGER') {
      vista.etiqueta = 'CONDUCTOR EN CAMINO';
      vista.titulo = v ? (v.etaMinutos <= 1 ? 'Llega en 1 min' : 'Llega en ' + formatoMinutos(v.etaMinutos)) : 'Tu conductor va hacia ti';
      vista.subtitulo = v ? 'Está a ' + formatoDistancia(v.distanciaRestanteKm) + ' de tu punto de recogida'
        : 'Esperando la ubicación de tu conductor…';
    } else if (f === 'EN_EL_PUNTO') {
      var seg = segundosDesde(servicio.fechaLlegada, ahoraMs);
      vista.etiqueta = 'TU CONDUCTOR LLEGÓ';
      vista.titulo = 'Tu conductor te está esperando';
      vista.subtitulo = 'Lleva ' + formatoReloj(seg) + ' en el punto de recogida';
      if (espera) {
        vista.espera = {
          reloj: formatoReloj(seg),
          aviso: 'Los primeros ' + espera.graciaMinutos + ' min no tienen costo; después se suman '
            + formatoCOP(espera.valorMinuto) + ' por minuto (máx. ' + formatoCOP(Math.round(espera.valorMinuto * (espera.maxMinutos - espera.graciaMinutos))) + ').',
          recargo: recargoEspera(seg, espera),
        };
      }
    } else {
      vista.etiqueta = 'EN VIAJE';
      vista.titulo = v ? (v.etaMinutos <= 1 ? 'Llegas en 1 min' : 'Llegas en ' + formatoMinutos(v.etaMinutos)) : 'Vas hacia tu destino';
      vista.subtitulo = v ? 'Te faltan ' + formatoDistancia(v.distanciaRestanteKm) : 'Disfruta tu viaje';
      vista.progreso = v ? progresoViaje(v.distanciaRestanteKm, servicio.distanciaKM) : null;
      vista.nota = AVISO_FINALIZAR_ANTES;
    }
    return vista;
  }

  /**
   * Lo que ve el conductor. {@code vivo} es lo que respondió el servidor al reportar su posición; {@code ctx} lleva
   * {distanciaDestinoM, radioDestinoM, radioRecogidaM, distanciaRecogidaM, seguimiento (texto del pasajero)}.
   */
  function vistaConductor(servicio, vivo, ahoraMs, ctx) {
    ctx = ctx || {};
    var f = fase(servicio);
    var v = vivoDeFase(vivo, f);
    var p = servicio.pasajero || {};
    var vista = {
      fase: f, paso: PASO[f], etiqueta: '', titulo: '', subtitulo: '', espera: null,
      persona: personaDe(p, 'Pasajero'),
      vehiculo: null,
      paradas: { origen: textoDireccion(servicio.origen, 'Punto de recogida'), destino: textoDireccion(servicio.destino, 'Destino') },
      cobro: formatoCOP(servicio.tarifa),
      seguimiento: ctx.seguimiento || null,
      puedeLlegar: false, puedeIniciar: f === 'EN_EL_PUNTO', puedeFinalizar: false,
    };
    if (f === 'A_RECOGER') {
      vista.etiqueta = 'VAS A RECOGER';
      vista.titulo = v ? 'Recogida en ' + formatoMinutos(v.etaMinutos) : 'Ve al punto de recogida';
      vista.subtitulo = (v ? formatoDistancia(v.distanciaRestanteKm) + ' · ' : '') + vista.paradas.origen;
      vista.puedeLlegar = typeof ctx.distanciaRecogidaM === 'number' && typeof ctx.radioRecogidaM === 'number'
        && ctx.distanciaRecogidaM <= ctx.radioRecogidaM;
    } else if (f === 'EN_EL_PUNTO') {
      var seg = segundosDesde(servicio.fechaLlegada, ahoraMs);
      vista.etiqueta = 'ESPERANDO AL PASAJERO';
      vista.titulo = 'Esperando · ' + formatoReloj(seg);
      vista.subtitulo = 'La espera se cobra al finalizar';
      if (ctx.espera) vista.espera = { reloj: formatoReloj(seg), recargo: recargoEspera(seg, ctx.espera) };
    } else {
      vista.etiqueta = 'EN VIAJE';
      vista.titulo = v ? 'Llegas en ' + formatoMinutos(v.etaMinutos) : 'Lleva al pasajero a su destino';
      vista.subtitulo = (v ? formatoDistancia(v.distanciaRestanteKm) + ' · ' : '') + vista.paradas.destino;
      vista.progreso = v ? progresoViaje(v.distanciaRestanteKm, servicio.distanciaKM) : null;
      // El conductor puede finalizar en cualquier tramo: si el pasajero se baja antes, se cobra según lo recorrido
      vista.puedeFinalizar = true;
      vista.finalizaAntes = !(typeof ctx.distanciaDestinoM === 'number' && typeof ctx.radioDestinoM === 'number'
        && ctx.distanciaDestinoM <= ctx.radioDestinoM);
    }
    return vista;
  }

  /**
   * ¿Se envía ya la posición del conductor al servidor? {@code ultimo} = {lat, lng, en} del último envío o null.
   * Durante el viaje es más frecuente que en la espera de solicitudes: mínimo 3 s, ≥ 10 m o latido de 8 s.
   */
  function debeReportarViaje(ultimo, actual, ahoraMs) {
    if (!ultimo) return true;
    var dt = ahoraMs - ultimo.en;
    if (dt < 3000) return false;
    return dt >= 8000 || distanciaMetros(ultimo, actual) >= 10;
  }

  /** Enlace para seguir la ruta en la app de mapas del teléfono (el conductor navega con la suya). */
  function enlaceMaps(lat, lng) {
    return 'https://www.google.com/maps/dir/?api=1&travelmode=driving&destination=' + encodeURIComponent(lat + ',' + lng);
  }

  /** Mensaje para el pasajero cuando el conductor dejó de reportar: "Sin señal del conductor". */
  function senalPerdida(vivo, ahoraMs, vigenciaMs) {
    if (!vivo || typeof vivo.recibidoEn !== "number") return false;
    return ahoraMs - vivo.recibidoEn > (vigenciaMs || 20000);
  }

  return {
    formatoCOP: formatoCOP, formatoDistancia: formatoDistancia, formatoMinutos: formatoMinutos, formatoReloj: formatoReloj,
    formatoCalificacion: formatoCalificacion, iniciales: iniciales, decodificarPolyline: decodificarPolyline,
    distanciaMetros: distanciaMetros, rumbo: rumbo, progresoViaje: progresoViaje, recargoEspera: recargoEspera,
    fase: fase, vistaPasajero: vistaPasajero, vistaConductor: vistaConductor, debeReportarViaje: debeReportarViaje,
    enlaceMaps: enlaceMaps, senalPerdida: senalPerdida,
  };
});
