/**
 * NEXA | Solicitudes de viaje del conductor: lista "Cerca de ti" + mapa con pines de precio.
 *
 * - La lista viene de GET /conductor/servicios-disponibles (?lat&lng si hay ubicación).
 * - Despacho por olas: el servidor solo entrega las solicitudes que le tocan a este conductor según su cercanía
 *   y el tiempo que lleva esperando cada una; por eso reporta su posición (POST /conductor/ubicacion) y la
 *   lista se pide de nuevo al llegar un aviso y cada 20 s.
 * - En tiempo real llegan por /topic/servicios-disponibles: solicitudes nuevas (estado SOLICITADO)
 *   y retiros {id, estado:'RETIRADO', motivo:'TOMADO'|'CANCELADO'}.
 * - Cada solicitud nueva llega al conductor como una tarjeta emergente (estilo Uber) en cualquier
 *   sección del panel, con Aceptar / Ahora no. No hay cuenta regresiva: la solicitud sigue vigente
 *   para todos hasta que un conductor la acepte o el pasajero la cancele.
 * - "Ahora no" (o rechazar desde la lista) no la oculta: queda en la lista y en el mapa, pero pasa
 *   al final y se marca como vista. Solo se recuerda en este navegador y no avisa a nadie.
 * - Aceptar es atómico en el servidor: si otro conductor ganó, responde 409 y la tarjeta queda
 *   como "viaje tomado".
 *
 * Todo se arma con nodos (textContent); nunca innerHTML con datos del servidor.
 * Las funciones puras se exportan para pruebas en Node (src/test/js/solicitudes-conductor.test.mjs).
 */
(function (raiz, fabrica) {
  const api = fabrica();
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else raiz.SolicitudesConductor = api;
})(typeof window !== 'undefined' ? window : globalThis, function () {
  'use strict';

  const RADIO_TIERRA_KM = 6371;
  /** Igual que el ProveedorRutas del servidor: línea recta × 1,3 se parece a la distancia por calles. */
  const FACTOR_CALLES = 1.3;
  /** Velocidad media en moto por la ciudad para estimar el tiempo hasta la recogida. */
  const VELOCIDAD_KMH = 25;
  const CLAVE_VISTAS = 'nexa.solicitudesVistas';
  /** Tarjetas emergentes visibles a la vez; el resto espera su turno. */
  const MAX_OFERTAS = 3;
  /** La tarjeta emergente se retira sola (la solicitud sigue en la lista, sin marcarse como vista). */
  const OFERTA_VISIBLE_MS = 45000;
  /** Comisión de respaldo (nivel 1 del conductor) si la página no la trae. */
  const COMISION_POR_DEFECTO = 0.2;
  /** Desde cuántos minutos esperando se avisa "Lleva N min esperando". */
  const ESPERA_AVISO_MIN = 5;
  /** Recogida a esta distancia o menos: "Cerca de ti". */
  const CERCA_KM = 1.5;
  /** Ganancia neta por km recorrido (recogida + viaje) desde la que se marca "Buen pago". Por calibrar en el piloto. */
  const BUEN_PAGO_POR_KM = 1100;

  /* Reporte de posición al servidor (despacho por olas): cada pocos segundos si se movió, y siempre un latido. */
  const REPORTE_MIN_MS = 5000;
  const REPORTE_LATIDO_MS = 30000;
  const REPORTE_MOVIMIENTO_KM = 0.03;
  /** La lista se vuelve a pedir sola: el conductor puede entrar al radio de una solicitud sin que llegue un aviso. */
  const RECARGA_PERIODICA_MS = 20000;

  /* ---------------- Funciones puras ---------------- */

  function distanciaKm(a, b) {
    const rad = (g) => (g * Math.PI) / 180;
    const dLat = rad(b.lat - a.lat);
    const dLng = rad(b.lng - a.lng);
    const h = Math.sin(dLat / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLng / 2) ** 2;
    return 2 * RADIO_TIERRA_KM * Math.asin(Math.min(1, Math.sqrt(h)));
  }

  /**
   * ¿Toca avisar al servidor dónde está el conductor? {@code ultimo} es lo último que se envió
   * ({lat, lng, en, disponible}) o null. Se envía si cambió su disponibilidad, si pasó el latido (30 s)
   * o si, pasados 5 s, se movió al menos 30 m.
   */
  function debeReportar(ultimo, actual, ahoraMs, disponible) {
    if (!actual) return false;
    if (!ultimo) return true;
    if (disponible !== ultimo.disponible) return true;
    const pasado = ahoraMs - ultimo.en;
    if (pasado >= REPORTE_LATIDO_MS) return true;
    if (pasado < REPORTE_MIN_MS) return false;
    return distanciaKm(ultimo, actual) >= REPORTE_MOVIMIENTO_KM;
  }

  /** Distancia estimada por calles y minutos hasta la recogida (null si no hay ubicación). */
  function estimarRecogida(posicion, servicio) {
    const o = servicio && servicio.ubicacionOrigen;
    if (!posicion || !o) return null;
    const km = distanciaKm(posicion, { lat: o.latitud, lng: o.longitud }) * FACTOR_CALLES;
    return { km, minutos: Math.max(1, Math.round((km / VELOCIDAD_KMH) * 60)) };
  }

  function formatoKm(km) {
    return km.toFixed(1).replace('.', ',') + ' km';
  }

  function formatoCOP(n) {
    return '$' + Math.round(Number(n) || 0).toLocaleString('es-CO');
  }

  function iniciales(nombre) {
    const partes = String(nombre || '').trim().split(/\s+/).filter(Boolean);
    if (!partes.length) return '?';
    const ultima = partes.length > 1 ? partes[partes.length - 1][0] : '';
    return (partes[0][0] + ultima).toUpperCase();
  }

  /**
   * El servidor guarda la hora de Colombia sin zona ("2026-10-22T10:42:00"): se interpreta como UTC−5
   * para que "Hace N min" no dependa de la zona horaria del navegador.
   */
  function parsearFechaColombia(texto) {
    if (!texto) return null;
    const s = String(texto);
    const conZona = /[zZ]|[+-]\d{2}:?\d{2}$/.test(s) ? s : s + '-05:00';
    const d = new Date(conZona);
    return isNaN(d.getTime()) ? null : d;
  }

  function momentoSolicitud(servicio) {
    return parsearFechaColombia(servicio.solicitadoEn) || parsearFechaColombia(servicio.fechaHora);
  }

  function haceTexto(fecha, ahora) {
    if (!fecha) return '';
    const min = Math.floor((ahora.getTime() - fecha.getTime()) / 60000);
    if (min < 1) return 'Hace un momento';
    if (min < 60) return `Hace ${min} min`;
    const h = Math.floor(min / 60);
    return h < 24 ? `Hace ${h} h` : 'Hace más de un día';
  }

  function horaTexto(fecha) {
    if (!fecha) return '';
    return fecha.toLocaleTimeString('es-CO', { hour: 'numeric', minute: '2-digit', timeZone: 'America/Bogota' });
  }

  /**
   * Lo que el conductor se queda con la solicitud: (1 − comisión) × tarifa bruta (la del modelo, antes del
   * descuento del pasajero, que absorbe la plataforma) más el extra voluntario si lo hay (va completo).
   * null si la solicitud no trae precio.
   */
  function gananciaConductor(s, comision) {
    const bruta = s && s.desglose && s.desglose.tarifaBruta > 0 ? s.desglose.tarifaBruta : (s && s.tarifa) || 0;
    if (!(bruta > 0)) return null;
    const phi = Number.isFinite(comision) && comision >= 0 && comision < 1 ? comision : COMISION_POR_DEFECTO;
    return Math.round((1 - phi) * bruta) + Math.max(0, Number(s.extraVoluntario) || 0);
  }

  /** Pesos que gana por km del viaje (null si no hay distancia o ganancia). */
  function gananciaPorKm(ganancia, kmViaje) {
    return ganancia > 0 && kmViaje > 0 ? ganancia / kmViaje : null;
  }

  /**
   * Etiquetas de la tarjeta, de más a menos importante: [{ texto, tono: 'verde'|'ambar'|'cian' }].
   * contexto: { comision, posicion, ahora }.
   */
  function etiquetas(s, contexto) {
    const out = [];
    const ahora = contexto.ahora || new Date();
    const extra = Number(s.extraVoluntario) || 0;
    if (extra > 0) out.push({ texto: `+${formatoCOP(extra)} extra`, tono: 'verde' });
    const desde = momentoSolicitud(s);
    const min = desde ? Math.floor((ahora.getTime() - desde.getTime()) / 60000) : 0;
    if (min >= ESPERA_AVISO_MIN) out.push({ texto: `Lleva ${min < 60 ? min + ' min' : Math.floor(min / 60) + ' h'} esperando`, tono: 'ambar' });
    const rec = estimarRecogida(contexto.posicion, s);
    const ganancia = gananciaConductor(s, contexto.comision);
    const kmTotal = (s.distanciaKM > 0 ? s.distanciaKM : 0) + (rec ? rec.km : 0);
    if (ganancia && kmTotal > 0 && ganancia / kmTotal >= BUEN_PAGO_POR_KM) out.push({ texto: 'Buen pago', tono: 'cian' });
    if (rec && rec.km <= CERCA_KM) out.push({ texto: 'Cerca de ti', tono: 'cian' });
    return out;
  }

  /** 'cercanas' necesita ubicación; sin ella (o en 'recientes') se ordena por la más nueva primero. */
  function ordenar(lista, modo, posicion) {
    const copia = lista.slice();
    if (modo === 'cercanas' && posicion) {
      return copia.sort((a, b) => (estimarRecogida(posicion, a)?.km ?? Infinity) - (estimarRecogida(posicion, b)?.km ?? Infinity));
    }
    if (modo === 'recientes') {
      return copia.sort((a, b) => (momentoSolicitud(b)?.getTime() ?? 0) - (momentoSolicitud(a)?.getTime() ?? 0));
    }
    return copia; // 'prioridad': el orden del servidor (nivel del pasajero y cercanía)
  }

  /** Igual que `ordenar`, pero las ya vistas (y no aceptadas) van al final conservando su orden relativo. */
  function ordenarConVistas(lista, modo, posicion, vistas) {
    const ordenadas = ordenar(lista, modo, posicion);
    return ordenadas.filter((s) => !vistas.has(s.id)).concat(ordenadas.filter((s) => vistas.has(s.id)));
  }

  /** Solicitudes que merecen tarjeta emergente: no vistas y que aún no se le mostraron en esta carga. */
  function ofertasNuevas(lista, vistas, yaOfrecidas) {
    return lista.filter((s) => !vistas.has(s.id) && !yaOfrecidas.has(s.id));
  }

  /**
   * Aplica un mensaje del tópico al estado. Devuelve el nuevo estado y qué hacer:
   * 'recargar' (llegó una solicitud nueva), 'tomado'/'cancelado' (sobre la seleccionada) o null.
   */
  function aplicarMensaje(estado, msg) {
    if (!msg || !msg.id) return { estado, accion: null };
    if (msg.estado === 'SOLICITADO') return { estado, accion: 'recargar' };
    // El pasajero subió su extra voluntario: se vuelve a leer la lista y la solicitud vuelve a emerger
    if (msg.estado === 'OFERTA_SUBIDA') {
      return { estado, accion: estado.lista.some((s) => s.id === msg.id) ? 'oferta-subida' : null };
    }
    if (msg.estado !== 'RETIRADO') return { estado, accion: null };

    const estaba = estado.lista.find((s) => s.id === msg.id);
    if (!estaba) return { estado, accion: null };
    const lista = estado.lista.filter((s) => s.id !== msg.id);
    const tomados = new Map(estado.tomados);
    const esSeleccionada = estado.seleccionadoId === msg.id;
    if (msg.motivo === 'TOMADO' && esSeleccionada) {
      tomados.set(msg.id, estaba); // se queda a la vista con el aviso, hasta que la descarte
      return { estado: { ...estado, lista, tomados }, accion: 'tomado' };
    }
    return {
      estado: { ...estado, lista, tomados, seleccionadoId: esSeleccionada ? null : estado.seleccionadoId },
      accion: esSeleccionada ? 'cancelado' : null,
    };
  }

  /* ---------------- Vista (solo navegador) ---------------- */

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

  function leerVistas() {
    try {
      return new Set(JSON.parse(sessionStorage.getItem(CLAVE_VISTAS) || '[]'));
    } catch (e) {
      return new Set();
    }
  }

  function guardarVistas(set) {
    try {
      sessionStorage.setItem(CLAVE_VISTAS, JSON.stringify([...set].slice(-200)));
    } catch (e) { /* sin almacenamiento: solo dura esta visita */ }
  }

  /**
   * opciones: {
   *   obtenerMapa: () => L.Map, csrf: () => string, aviso: (texto) => void,
   *   puedeOfrecer: () => boolean   // false si está en un viaje o apagó las notificaciones
   *   comision: () => number        // φ de este conductor (0–1) para calcular "Ganas $X"
   *   abrirLista: (id) => void      // lleva a la sección Solicitudes con esa solicitud abierta
   * }
   */
  function iniciar(opciones) {
    const $ = (id) => document.getElementById(id);
    const els = {
      lista: $('scLista'),
      contador: $('scContador'),
      chipMapa: $('scChipMapa'),
      orden: $('scOrden'),
      ordenTexto: $('scOrdenTexto'),
      conexion: $('scConexion'),
      conexionTexto: $('scConexionTexto'),
    };
    if (!els.lista) return null;

    let estado = { lista: [], tomados: new Map(), seleccionadoId: null };
    let vistas = leerVistas();
    const ofrecidas = new Set(); // ya se le mostró su tarjeta emergente en esta carga de la página
    const ofertas = new Map(); // id -> { el, temporizador }
    const contenedorOfertas = crear('div', 'sc-ofertas');
    contenedorOfertas.setAttribute('aria-live', 'polite');
    document.body.append(contenedorOfertas);
    let modo = 'prioridad';
    let posicion = null;
    let conectado = false;
    let cargando = false;
    let capas = { pines: new Map(), tu: null, recogida: null, viaje: null, destino: null };

    const MODOS = [
      ['prioridad', 'Prioridad NEXA'],
      ['cercanas', 'Más cercanas'],
      ['recientes', 'Más recientes'],
    ];

    function comision() {
      return typeof opciones.comision === 'function' ? opciones.comision() : COMISION_POR_DEFECTO;
    }

    function chipsDe(s) {
      return etiquetas(s, { comision: comision(), posicion, ahora: new Date() })
        .map((e) => crear('span', 'sc-chip sc-chip-' + e.tono, e.texto));
    }

    /** "Ganas $X" y, si hay distancia, "$Y por km" (null si la solicitud no trae precio). */
    function resumenGanancia(s) {
      const g = gananciaConductor(s, comision());
      if (g == null) return null;
      const porKm = gananciaPorKm(g, s.distanciaKM);
      return { ganancia: g, texto: `Ganas ${formatoCOP(g)}`, porKm: porKm ? `${formatoCOP(porKm)} por km` : null };
    }

    /* --- Datos --- */
    function visibles() {
      const tomados = [...estado.tomados.values()];
      const libres = ordenarConVistas(estado.lista.filter((s) => !estado.tomados.has(s.id)), modo, posicion, vistas);
      return tomados.concat(libres);
    }

    function recargar() {
      if (cargando) return;
      cargando = true;
      const q = posicion ? `?lat=${encodeURIComponent(posicion.lat)}&lng=${encodeURIComponent(posicion.lng)}` : '';
      fetch('/conductor/servicios-disponibles' + q, { headers: { Accept: 'application/json' } })
        .then((r) => {
          if (!r.ok) throw new Error('HTTP ' + r.status);
          return r.json();
        })
        .then((lista) => {
          estado = { ...estado, lista: Array.isArray(lista) ? lista : [] };
          if (estado.seleccionadoId && !estado.lista.some((s) => s.id === estado.seleccionadoId)
              && !estado.tomados.has(estado.seleccionadoId)) {
            estado.seleccionadoId = null;
          }
          pintar();
          retirarOfertasQueYaNoExisten();
          ofrecerNuevas();
        })
        .catch(() => {
          pintarError();
        })
        .finally(() => { cargando = false; });
    }

    /* --- Lista --- */
    function pintar() {
      const items = visibles();
      const disponibles = items.filter((s) => !estado.tomados.has(s.id)).length;
      els.contador.textContent = String(disponibles);
      els.chipMapa.textContent = disponibles === 1 ? '1 solicitud cerca de ti' : `${disponibles} solicitudes cerca de ti`;
      if (!items.length) {
        els.lista.replaceChildren(vacio());
      } else {
        els.lista.replaceChildren(...items.map(tarjeta));
      }
      pintarMapa(items);
    }

    function vacio() {
      const v = crear('div', 'sc-vacio');
      const radar = crear('div', 'sc-vacio-icono');
      radar.append(icono('fas fa-satellite-dish'));
      const chip = crear('span', 'sc-chip-vivo' + (conectado ? '' : ' off'), conectado ? 'Escuchando en tiempo real' : 'Reconectando…');
      v.append(radar, crear('h4', null, 'Aún no hay solicitudes cerca'),
        crear('p', null, 'Te avisaremos apenas un pasajero pida un viaje. Mantén esta pantalla abierta.'), chip);
      return v;
    }

    function pintarError() {
      const v = crear('div', 'sc-vacio sc-error');
      const ic = crear('div', 'sc-vacio-icono');
      ic.append(icono('fas fa-triangle-exclamation'));
      const btn = crear('button', 'sc-btn sc-btn-sec', 'Reintentar');
      btn.type = 'button';
      btn.addEventListener('click', recargar);
      v.append(ic, crear('h4', null, 'No pudimos cargar las solicitudes'), crear('p', null, 'Revisa tu conexión e inténtalo de nuevo.'), btn);
      els.lista.replaceChildren(v);
    }

    function tarjeta(s) {
      const sel = estado.seleccionadoId === s.id;
      const tomado = estado.tomados.has(s.id);
      const vista = vistas.has(s.id) && !tomado;
      const card = crear('article', 'sc-card' + (sel ? ' sel' : '') + (tomado ? ' tomado' : '') + (vista ? ' vista' : ''));
      card.dataset.id = s.id;

      const cab = crear('button', 'sc-cab');
      cab.type = 'button';
      cab.setAttribute('aria-expanded', String(sel));
      const nombre = (s.pasajero && s.pasajero.nombre) || 'Pasajero';
      const av = crear('span', 'sc-avatar');
      if (s.pasajero && s.pasajero.fotoUrl) {
        const img = document.createElement('img');
        img.src = s.pasajero.fotoUrl;
        img.alt = '';
        img.width = 36;
        img.height = 36;
        img.loading = 'lazy';
        img.addEventListener('error', () => { img.remove(); av.textContent = iniciales(nombre); });
        av.append(img);
      } else {
        av.textContent = iniciales(nombre);
      }
      const quien = crear('span', 'sc-quien');
      quien.append(crear('strong', null, nombre), crear('small', null, haceTexto(momentoSolicitud(s), new Date())));
      const precio = crear('span', 'sc-precio');
      const gan = resumenGanancia(s);
      precio.append(crear('strong', null, formatoCOP(s.tarifa)), crear('small', gan ? 'sc-ganas' : null, gan ? gan.texto : metodoPago(s)));
      cab.append(av, quien, precio);
      cab.addEventListener('click', () => seleccionar(sel ? null : s.id));

      const ruta = crear('div', 'sc-ruta');
      const o = crear('p');
      o.append(icono('fas fa-location-dot'), crear('span', null, s.origen || 'Origen'));
      const d = crear('p');
      d.append(icono('fas fa-flag'), crear('span', 'sc-destino', s.destino || 'Destino'));
      ruta.append(o, d);

      const chips = crear('div', 'sc-chips');
      const rec = estimarRecogida(posicion, s);
      if (rec) chips.append(crear('span', 'sc-chip sc-chip-rec', `Recogida a ${formatoKm(rec.km)} (~${rec.minutos} min)`));
      if (s.distanciaKM > 0) {
        const g = resumenGanancia(s);
        chips.append(crear('span', 'sc-chip', `Viaje ${formatoKm(s.distanciaKM)}` + (g && g.porKm ? ` · ${g.porKm}` : '')));
      }
      chipsDe(s).forEach((c) => chips.append(c));
      if (vista) chips.append(crear('span', 'sc-chip sc-chip-vista', 'Ya la viste'));

      card.append(cab, ruta, chips);
      if (sel || tomado) card.append(detalle(s, tomado));
      return card;
    }

    function metodoPago(s) {
      const m = String(s.metodoPago || 'EFECTIVO').toUpperCase();
      return m === 'EFECTIVO' ? 'Efectivo' : m.charAt(0) + m.slice(1).toLowerCase();
    }

    function detalle(s, tomado) {
      const det = crear('div', 'sc-detalle');
      const hora = horaTexto(momentoSolicitud(s));
      if (hora) {
        const p = crear('p', 'sc-hora');
        p.append(icono('far fa-clock'), crear('span', null, `Solicitado a las ${hora}`));
        det.append(p);
      }
      if (tomado) {
        const a = crear('div', 'sc-aviso sc-aviso-tomado');
        a.setAttribute('role', 'status');
        a.append(icono('fas fa-triangle-exclamation'), crear('span', null, 'Otro conductor ya tomó este viaje. Ya no está disponible.'));
        det.append(a);
      } else {
        const a = crear('div', 'sc-aviso');
        a.append(icono('fas fa-receipt'), crear('span', null, `Precio calculado por NEXA según zona y distancia. El pasajero paga en ${metodoPago(s).toLowerCase()}.`));
        det.append(a);
      }
      const acciones = crear('div', 'sc-acciones');
      const aceptar = crear('button', 'sc-btn sc-btn-ok');
      aceptar.type = 'button';
      aceptar.append(icono('fas fa-check'), document.createTextNode(' Aceptar'));
      aceptar.disabled = tomado;
      aceptar.addEventListener('click', () => aceptarSolicitud(s, aceptar));
      const rechazar = crear('button', 'sc-btn sc-btn-no');
      rechazar.type = 'button';
      rechazar.append(icono('fas fa-xmark'), document.createTextNode(tomado ? ' Descartar' : ' Ahora no'));
      rechazar.addEventListener('click', () => (tomado ? descartarTomada(s.id) : marcarVista(s.id)));
      acciones.append(aceptar, rechazar);
      det.append(acciones);
      return det;
    }

    /* --- Acciones --- */
    function seleccionar(id) {
      estado = { ...estado, seleccionadoId: id };
      pintar();
      if (id) {
        const card = els.lista.querySelector(`[data-id="${CSS.escape(id)}"]`);
        if (card) card.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        encuadrar(id);
      }
    }

    /** "Ahora no": sigue disponible para todos y en el mapa, pero baja al final de MI lista. */
    function marcarVista(id) {
      vistas.add(id);
      guardarVistas(vistas);
      quitarOferta(id);
      estado = { ...estado, seleccionadoId: estado.seleccionadoId === id ? null : estado.seleccionadoId };
      pintar();
    }

    /** Una solicitud ya tomada por otro deja de mostrarse cuando el conductor la descarta. */
    function descartarTomada(id) {
      const tomados = new Map(estado.tomados);
      tomados.delete(id);
      estado = { ...estado, tomados, seleccionadoId: estado.seleccionadoId === id ? null : estado.seleccionadoId };
      pintar();
    }

    /** Envía la aceptación. Resuelve 'ok', 'tomado' (otro conductor ganó) o 'error'. */
    function enviarAceptacion(s) {
      return fetch(`/conductor/aceptar-servicio/${encodeURIComponent(s.id)}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': opciones.csrf() },
      })
        .then((r) => {
          if (r.ok) {
            // El modal de "Servicio aceptado" lo abre el aviso del WebSocket del conductor
            estado = { ...estado, lista: estado.lista.filter((x) => x.id !== s.id), seleccionadoId: null };
            pintar();
            opciones.aviso('Servicio aceptado. Dirígete al punto de recogida.');
            return 'ok';
          }
          if (r.status === 409) {
            const tomados = new Map(estado.tomados);
            tomados.set(s.id, s);
            estado = { ...estado, tomados, lista: estado.lista.filter((x) => x.id !== s.id) };
            pintar();
            return 'tomado';
          }
          return r.text().then((t) => { throw new Error(t || 'No se pudo aceptar el servicio'); });
        })
        .catch((e) => {
          opciones.aviso(e.message && e.message.length < 160 ? e.message : 'No se pudo aceptar el servicio');
          pintar();
          return 'error';
        });
    }

    function aceptarSolicitud(s, boton) {
      boton.disabled = true;
      boton.lastChild.textContent = ' Aceptando…';
      enviarAceptacion(s).then(() => quitarOferta(s.id));
    }

    /* --- Tarjetas emergentes (estilo Uber) --- */
    function ofertaPuede() {
      return typeof opciones.puedeOfrecer !== 'function' || opciones.puedeOfrecer();
    }

    function ofrecerNuevas() {
      if (!ofertaPuede()) return;
      const lugar = MAX_OFERTAS - ofertas.size;
      if (lugar <= 0) { pintarResto(); return; }
      // Entran las más recientes; se apilan de modo que la más nueva quede arriba
      const nuevas = ofertasNuevas(estado.lista, vistas, ofrecidas)
        .sort((a, b) => (momentoSolicitud(b)?.getTime() ?? 0) - (momentoSolicitud(a)?.getTime() ?? 0))
        .slice(0, lugar)
        .reverse();
      nuevas.forEach(mostrarOferta);
      pintarResto();
    }

    function pintarResto() {
      let resto = contenedorOfertas.querySelector('.sc-oferta-resto');
      const pendientes = ofertaPuede() ? ofertasNuevas(estado.lista, vistas, ofrecidas).length : 0;
      if (!pendientes) { if (resto) resto.remove(); return; }
      if (!resto) {
        resto = crear('button', 'sc-oferta-resto');
        resto.type = 'button';
        resto.addEventListener('click', () => opciones.abrirLista && opciones.abrirLista(null));
        contenedorOfertas.append(resto);
      }
      resto.textContent = pendientes === 1 ? '1 solicitud más en tu lista' : `${pendientes} solicitudes más en tu lista`;
    }

    function mostrarOferta(s) {
      if (ofertas.has(s.id)) return;
      ofrecidas.add(s.id);
      const nombre = (s.pasajero && s.pasajero.nombre) || 'Pasajero';
      const el = crear('article', 'sc-oferta');
      el.dataset.id = s.id;
      el.setAttribute('role', 'group');
      el.setAttribute('aria-label', `Nueva solicitud de ${nombre} por ${formatoCOP(s.tarifa)}`);

      const cab = crear('div', 'sc-oferta-cab');
      const etiq = chipsDe(s);
      cab.append(crear('span', 'sc-oferta-et', 'Nueva solicitud'));
      // Con una sola etiqueta cabe en la cabecera; con más, va en su propia fila
      if (etiq.length === 1) cab.append(etiq[0]);
      cab.append(crear('span', 'sc-oferta-metodo', metodoPago(s)));
      const filaEtiquetas = etiq.length > 1 ? crear('div', 'sc-oferta-etiquetas') : null;
      if (filaEtiquetas) etiq.forEach((c) => filaEtiquetas.append(c));
      const fila = crear('button', 'sc-oferta-fila');
      fila.type = 'button';
      fila.title = 'Ver en el mapa';
      const av = crear('span', 'sc-avatar', iniciales(nombre));
      if (s.pasajero && s.pasajero.fotoUrl) {
        const img = document.createElement('img');
        img.src = s.pasajero.fotoUrl;
        img.alt = '';
        img.width = 36;
        img.height = 36;
        img.addEventListener('error', () => { img.remove(); av.textContent = iniciales(nombre); });
        av.textContent = '';
        av.append(img);
      }
      const quien = crear('span', 'sc-quien');
      quien.append(crear('strong', null, nombre));
      const rec = estimarRecogida(posicion, s);
      quien.append(crear('small', null, rec ? `Recogida a ${formatoKm(rec.km)} (~${rec.minutos} min)` : haceTexto(momentoSolicitud(s), new Date())));
      const precio = crear('span', 'sc-precio');
      precio.append(crear('strong', null, formatoCOP(s.tarifa)));
      const gan = resumenGanancia(s);
      if (gan) precio.append(crear('small', 'sc-ganas', gan.texto));
      fila.append(av, quien, precio);
      fila.addEventListener('click', () => { opciones.abrirLista && opciones.abrirLista(s.id); });

      const ruta = crear('div', 'sc-ruta');
      const o = crear('p');
      o.append(icono('fas fa-location-dot'), crear('span', null, s.origen || 'Origen'));
      const d = crear('p');
      d.append(icono('fas fa-flag'), crear('span', 'sc-destino', s.destino || 'Destino'));
      ruta.append(o, d);
      if (s.distanciaKM > 0) {
        ruta.append(crear('small', 'sc-oferta-viaje', `Viaje de ${formatoKm(s.distanciaKM)}` + (gan && gan.porKm ? ` · ${gan.porKm}` : '')));
      }

      const acciones = crear('div', 'sc-acciones');
      const aceptar = crear('button', 'sc-btn sc-btn-ok');
      aceptar.type = 'button';
      aceptar.append(icono('fas fa-check'), document.createTextNode(' Aceptar'));
      aceptar.addEventListener('click', () => {
        aceptar.disabled = true;
        aceptar.lastChild.textContent = ' Aceptando…';
        enviarAceptacion(s).then((r) => {
          if (r === 'tomado') ofertaTomada(s.id); else quitarOferta(s.id);
        });
      });
      const ahoraNo = crear('button', 'sc-btn sc-btn-no');
      ahoraNo.type = 'button';
      ahoraNo.append(icono('fas fa-xmark'), document.createTextNode(' Ahora no'));
      ahoraNo.addEventListener('click', () => marcarVista(s.id));
      acciones.append(aceptar, ahoraNo);

      el.append(cab);
      if (filaEtiquetas) el.append(filaEtiquetas);
      el.append(fila, ruta, acciones);
      contenedorOfertas.prepend(el);
      const temporizador = setTimeout(() => quitarOferta(s.id), OFERTA_VISIBLE_MS);
      ofertas.set(s.id, { el, temporizador });
    }

    function quitarOferta(id) {
      const o = ofertas.get(id);
      if (!o) return;
      clearTimeout(o.temporizador);
      o.el.remove();
      ofertas.delete(id);
      ofrecerNuevas(); // si había otras esperando turno, entra la siguiente
    }

    /** Otro conductor ganó: la tarjeta lo dice unos segundos y se va. */
    function ofertaTomada(id) {
      const o = ofertas.get(id);
      if (!o) return;
      clearTimeout(o.temporizador);
      o.el.classList.add('tomada');
      o.el.querySelector('.sc-acciones').replaceWith(crear('p', 'sc-oferta-aviso', 'Otro conductor ya tomó este viaje.'));
      o.temporizador = setTimeout(() => quitarOferta(id), 4000);
    }

    function retirarOfertasQueYaNoExisten() {
      for (const id of [...ofertas.keys()]) {
        if (!estado.lista.some((x) => x.id === id)) quitarOferta(id);
      }
    }

    /* --- Mapa --- */
    function pinIcono(s, sel) {
      const el = crear('div', 'sc-pin' + (sel ? ' sel' : '') + (estado.tomados.has(s.id) ? ' tomado' : '') + (vistas.has(s.id) ? ' vista' : ''));
      el.append(icono('fas fa-motorcycle'), crear('span', null, formatoCOP(s.tarifa)));
      return L.divIcon({ className: 'sc-pin-wrap', html: el, iconSize: [0, 0], iconAnchor: [0, 0] });
    }

    function quitarRuta(mapa) {
      ['recogida', 'viaje', 'destino'].forEach((k) => {
        if (capas[k]) { mapa.removeLayer(capas[k]); capas[k] = null; }
      });
    }

    function pintarMapa(items) {
      const mapa = opciones.obtenerMapa();
      if (!mapa || typeof L === 'undefined') return;
      const vivos = new Set(items.map((s) => s.id));
      for (const [id, m] of capas.pines) {
        if (!vivos.has(id)) { mapa.removeLayer(m); capas.pines.delete(id); }
      }
      items.forEach((s) => {
        const o = s.ubicacionOrigen;
        if (!o) return;
        const sel = estado.seleccionadoId === s.id;
        let m = capas.pines.get(s.id);
        if (!m) {
          m = L.marker([o.latitud, o.longitud], { icon: pinIcono(s, sel), keyboard: true, title: (s.pasajero && s.pasajero.nombre) || 'Solicitud' });
          m.on('click', () => seleccionar(s.id));
          m.addTo(mapa);
          capas.pines.set(s.id, m);
        } else {
          m.setIcon(pinIcono(s, sel));
        }
        m.setZIndexOffset(sel ? 1000 : 0);
      });
      pintarTu(mapa);
      quitarRuta(mapa);
      const s = items.find((x) => x.id === estado.seleccionadoId);
      if (s && s.ubicacionOrigen) {
        const recogida = [s.ubicacionOrigen.latitud, s.ubicacionOrigen.longitud];
        if (posicion) {
          capas.recogida = L.polyline([[posicion.lat, posicion.lng], recogida], { color: '#00c4ff', weight: 3, dashArray: '6 8', interactive: false }).addTo(mapa);
        }
        if (s.ubicacionDestino) {
          const destino = [s.ubicacionDestino.latitud, s.ubicacionDestino.longitud];
          capas.viaje = L.polyline([recogida, destino], { color: '#22c55e', weight: 3, interactive: false }).addTo(mapa);
          capas.destino = L.circleMarker(destino, { radius: 6, color: '#ffffff', weight: 2, fillColor: '#22c55e', fillOpacity: 1, interactive: false }).addTo(mapa);
        }
      }
    }

    function pintarTu(mapa) {
      if (!posicion) return;
      if (!capas.tu) {
        const el = crear('div', 'sc-tu');
        el.append(crear('span', 'sc-tu-punto'), crear('span', 'sc-tu-et', 'Tú'));
        capas.tu = L.marker([posicion.lat, posicion.lng], {
          icon: L.divIcon({ className: 'sc-tu-wrap', html: el, iconSize: [36, 52], iconAnchor: [18, 18] }),
          interactive: false, keyboard: false, zIndexOffset: -100,
        }).addTo(mapa);
      } else {
        capas.tu.setLatLng([posicion.lat, posicion.lng]);
      }
    }

    function encuadrar(id) {
      const mapa = opciones.obtenerMapa();
      const s = visibles().find((x) => x.id === id);
      if (!mapa || !s || !s.ubicacionOrigen) return;
      const puntos = [[s.ubicacionOrigen.latitud, s.ubicacionOrigen.longitud]];
      if (s.ubicacionDestino) puntos.push([s.ubicacionDestino.latitud, s.ubicacionDestino.longitud]);
      if (posicion) puntos.push([posicion.lat, posicion.lng]);
      mapa.fitBounds(puntos, { padding: [60, 60], maxZoom: 16 });
    }

    /* --- Orden, ubicación y conexión --- */
    function pintarOrden() {
      const actual = MODOS.find((m) => m[0] === modo);
      els.ordenTexto.textContent = actual[1];
    }

    if (els.orden) {
      els.orden.addEventListener('click', () => {
        let i = MODOS.findIndex((m) => m[0] === modo);
        do { i = (i + 1) % MODOS.length; } while (MODOS[i][0] === 'cercanas' && !posicion);
        modo = MODOS[i][0];
        pintarOrden();
        pintar();
      });
    }

    let reportado = null;

    /** Avisa al servidor dónde está (solo si toca): con eso decide qué solicitudes le llegan en cada ola. */
    function reportarPosicion() {
      if (!posicion) return;
      const disponible = typeof opciones.disponible === 'function' ? opciones.disponible() : true;
      const ahora = Date.now();
      if (!debeReportar(reportado, posicion, ahora, disponible)) return;
      reportado = { lat: posicion.lat, lng: posicion.lng, en: ahora, disponible };
      fetch('/conductor/ubicacion', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': opciones.csrf() },
        body: JSON.stringify({ latitud: posicion.lat, longitud: posicion.lng, disponible }),
      }).catch(() => { reportado = null; /* se reintenta en el próximo ciclo */ });
    }

    function seguirUbicacion() {
      if (!navigator.geolocation) return;
      let primera = true;
      navigator.geolocation.watchPosition(
        ({ coords }) => {
          posicion = { lat: coords.latitude, lng: coords.longitude };
          reportarPosicion();
          if (primera) {
            primera = false;
            recargar(); // con ubicación el servidor ordena también por cercanía
          } else {
            pintar();
          }
        },
        () => { /* sin permiso: no se muestran distancias de recogida */ },
        { enableHighAccuracy: false, maximumAge: 5000, timeout: 20000 }
      );
    }

    function estadoConexion(ok) {
      conectado = ok;
      if (els.conexion) {
        els.conexion.classList.toggle('off', !ok);
        els.conexionTexto.textContent = ok ? 'En línea · escuchando en tiempo real' : 'Sin conexión · reintentando';
      }
      if (ok) recargar();
      else if (!visibles().length) pintar();
    }

    function alMensaje(msg) {
      const r = aplicarMensaje(estado, msg);
      estado = r.estado;
      if (msg && msg.estado === 'RETIRADO' && msg.id) {
        if (msg.motivo === 'TOMADO') ofertaTomada(msg.id); else quitarOferta(msg.id);
      }
      if (r.accion === 'oferta-subida') {
        // Un extra nuevo es motivo para mirarla otra vez: deja de contar como "vista" y se vuelve a ofrecer
        vistas.delete(msg.id);
        guardarVistas(vistas);
        ofrecidas.delete(msg.id);
        recargar();
      } else if (r.accion === 'recargar') recargar();
      else if (r.accion === 'cancelado') opciones.aviso('El pasajero canceló la solicitud que estabas revisando.');
      if (r.accion !== 'recargar' && r.accion !== 'oferta-subida') pintar();
    }

    // "Hace N min" se refresca solo cada minuto
    setInterval(() => { if (document.visibilityState === 'visible' && estado.lista.length) pintar(); }, 60000);

    // Latido: aunque el navegador no emita posiciones nuevas (quieto), se sigue avisando que está en línea
    setInterval(reportarPosicion, REPORTE_MIN_MS);
    setInterval(() => { if (document.visibilityState === 'visible' && conectado) recargar(); }, RECARGA_PERIODICA_MS);

    pintarOrden();
    seguirUbicacion();

    return {
      recargar,
      seleccionar: (id) => {
        const existe = visibles().some((x) => x.id === id);
        seleccionar(existe ? id : null);
      },
      alMensaje,
      estadoConexion,
      posicion: () => posicion,
      redibujarMapa: () => pintarMapa(visibles()),
      verTodas: () => {
        const mapa = opciones.obtenerMapa();
        const puntos = visibles().filter((x) => x.ubicacionOrigen).map((x) => [x.ubicacionOrigen.latitud, x.ubicacionOrigen.longitud]);
        if (posicion) puntos.push([posicion.lat, posicion.lng]);
        if (mapa && puntos.length) mapa.fitBounds(puntos, { padding: [60, 60], maxZoom: 15 });
      },
    };
  }

  return {
    distanciaKm,
    debeReportar,
    estimarRecogida,
    formatoKm,
    formatoCOP,
    iniciales,
    parsearFechaColombia,
    haceTexto,
    ordenar,
    ordenarConVistas,
    ofertasNuevas,
    gananciaConductor,
    gananciaPorKm,
    etiquetas,
    aplicarMensaje,
    iniciar,
  };
});
