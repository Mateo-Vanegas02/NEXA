/**
 * NEXA | Sistema de niveles (pasajero y conductor).
 * Barra de nivel + modal de beneficios + toast de XP + celebración de subida.
 * Se activa con <body data-nivel-rol="pasajero|conductor">.
 * Todo el texto del servidor se inserta con textContent (nunca innerHTML).
 */
(function () {
  'use strict';

  const rol = document.body && document.body.dataset.nivelRol;
  if (!rol) return;

  // Los niveles empiezan en 1 y el del pasajero no tiene techo: del 5 en adelante se repiten icono y color.
  const ICONOS = ['fa-seedling', 'fa-medal', 'fa-medal', 'fa-crown', 'fa-gem'];
  const nombre = (nivel) => 'Nivel ' + nivel;
  // Las claves incluyen el id del usuario: dos cuentas en el mismo navegador no se mezclan.
  const claveVisto = (n) => 'nexa_niveles_visto_' + rol + '_' + (n.usuarioId || 'anon');
  const claveCelebrado = (n) => 'nexa_niveles_celebrado_' + rol + '_' + (n.usuarioId || 'anon');
  const REFRESCO_MS = 60000;

  let estado = null;
  let barra = null;
  let toastZone = null;
  let overlay = null;
  let ultimoFoco = null;

  // ── utilidades ───────────────────────────────────────────
  function el(tag, clase, texto) {
    const e = document.createElement(tag);
    if (clase) e.className = clase;
    if (texto != null) e.textContent = texto;
    return e;
  }
  function icono(clase) {
    const i = el('i', 'fas ' + clase);
    i.setAttribute('aria-hidden', 'true');
    return i;
  }
  function leer(key) {
    try { return JSON.parse(localStorage.getItem(key)); } catch (e) { return null; }
  }
  function guardar(key, valor) {
    try { localStorage.setItem(key, JSON.stringify(valor)); } catch (e) { /* sin almacenamiento */ }
  }
  function pct(f) { return Math.round(f * 100) + '%'; }
  function claseColor(n) { return 'nv-color-' + Math.min(Math.max(n, 1) - 1, 4); }
  function insignia(n, chica) {
    const b = el('span', 'nv-badge' + (chica ? ' nv-badge--sm' : ''));
    b.setAttribute('aria-hidden', 'true');
    b.appendChild(icono(ICONOS[Math.min(Math.max(n, 1) - 1, 4)]));
    return b;
  }

  // Con sesión, el back exige el token CSRF en las peticiones /api/** que no llevan JWT.
  // Los dashboards ya lo traen en un campo oculto (el mismo que usan sus otros fetch).
  function cabeceras() {
    const h = { 'Content-Type': 'application/json' };
    const campo = document.querySelector('input[name="_csrf"]');
    if (campo && campo.value) h['X-CSRF-TOKEN'] = campo.value;
    return h;
  }

  async function api(path, opts) {
    const r = await fetch(path, Object.assign({ credentials: 'same-origin', headers: cabeceras() }, opts));
    if (!r.ok) {
      let msg = 'No se pudo completar la acción';
      try { const j = await r.json(); msg = j.error || j.message || msg; } catch (e) { /* sin cuerpo */ }
      throw new Error(msg);
    }
    return r.status === 204 ? null : r.json();
  }

  // ── barra ────────────────────────────────────────────────
  function montarBarra() {
    const main = document.querySelector('.main') || document.body;
    barra = el('button', 'nv-bar');
    barra.type = 'button';
    barra.id = 'nexa-nivel-bar';
    barra.setAttribute('aria-haspopup', 'dialog');
    barra.addEventListener('click', abrirModal);
    main.insertBefore(barra, main.firstChild);

    toastZone = el('div', 'nv-toast-zone');
    toastZone.setAttribute('role', 'status');
    toastZone.setAttribute('aria-live', 'polite');
    document.body.appendChild(toastZone);
  }

  function pintarBarra() {
    const n = estado;
    barra.hidden = false;
    barra.className = 'nv-bar ' + claseColor(n.nivel);
    barra.replaceChildren();
    barra.setAttribute('aria-label', nombre(n.nivel) + '. Ver beneficios');

    const cuerpo = el('div', 'nv-bar-body');
    const top = el('div', 'nv-bar-top');
    top.appendChild(el('span', 'nv-name', nombre(n.nivel)));
    const maximo = n.xpSiguienteNivel == null;
    top.appendChild(el('span', 'nv-hint', maximo
      ? '¡Nivel máximo! ' + n.xpActual + ' XP'
      : (n.conductor && n.conductor.bloqueadoPorCalidad
        ? 'Cumples los XP de ' + nombre(n.nivel + 1) + ': falta calidad'
        : n.xpFaltante + ' XP para ' + nombre(n.nivel + 1))));
    cuerpo.appendChild(top);

    const track = el('div', 'nv-track');
    track.setAttribute('role', 'progressbar');
    track.setAttribute('aria-label', 'Progreso hacia ' + (n.xpSiguienteNivel == null ? 'el nivel máximo' : nombre(n.nivel + 1)));
    // aria-valuenow siempre dentro de [min, max] (p. ej. conductor con los XP del siguiente nivel pero sin la calidad)
    const vmin = n.xpNivelActual;
    const vmax = Math.max(vmin, maximo ? n.xpActual : n.xpSiguienteNivel);
    track.setAttribute('aria-valuemin', String(vmin));
    track.setAttribute('aria-valuemax', String(vmax));
    track.setAttribute('aria-valuenow', String(Math.min(vmax, Math.max(vmin, n.xpActual))));
    track.setAttribute('aria-valuetext', Math.round(n.progreso * 100) + '% completado');
    const fill = el('div', 'nv-fill');
    track.appendChild(fill);
    cuerpo.appendChild(track);

    barra.appendChild(insignia(n.nivel, false));
    barra.appendChild(cuerpo);
    // anima desde 0 en el siguiente frame
    requestAnimationFrame(() => requestAnimationFrame(() => { fill.style.width = Math.round(n.progreso * 100) + '%'; }));
  }

  // ── modal ────────────────────────────────────────────────
  function abrirModal() {
    ultimoFoco = document.activeElement;
    if (!overlay) {
      overlay = el('div', 'nv-overlay');
      overlay.hidden = true;
      overlay.addEventListener('click', (e) => { if (e.target === overlay) cerrarModal(); });
      document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && !overlay.hidden) cerrarModal();
        if (e.key === 'Tab' && !overlay.hidden) atraparFoco(e);
      });
      document.body.appendChild(overlay);
    }
    pintarModal();
    overlay.hidden = false;
    const cerrar = overlay.querySelector('.nv-close');
    if (cerrar) cerrar.focus();
  }
  function cerrarModal() {
    overlay.hidden = true;
    if (ultimoFoco && ultimoFoco.focus) ultimoFoco.focus();
  }
  function atraparFoco(e) {
    const f = overlay.querySelectorAll('button:not([disabled])');
    if (!f.length) return;
    const primero = f[0], ultimo = f[f.length - 1];
    if (e.shiftKey && document.activeElement === primero) { e.preventDefault(); ultimo.focus(); }
    else if (!e.shiftKey && document.activeElement === ultimo) { e.preventDefault(); primero.focus(); }
  }

  function pintarModal() {
    const n = estado;
    overlay.replaceChildren();
    const modal = el('div', 'nv-modal ' + claseColor(n.nivel));
    modal.setAttribute('role', 'dialog');
    modal.setAttribute('aria-modal', 'true');
    modal.setAttribute('aria-labelledby', 'nv-titulo');

    const head = el('div', 'nv-modal-head');
    head.appendChild(insignia(n.nivel, false));
    const h = el('h2', null, 'Tu ' + nombre(n.nivel).toLowerCase());
    h.id = 'nv-titulo';
    head.appendChild(h);
    const cerrar = el('button', 'nv-close');
    cerrar.type = 'button';
    cerrar.setAttribute('aria-label', 'Cerrar');
    cerrar.appendChild(icono('fa-xmark'));
    cerrar.addEventListener('click', cerrarModal);
    head.appendChild(cerrar);
    modal.appendChild(head);

    modal.appendChild(resumen(n));
    n.niveles.forEach((t) => modal.appendChild(tarjetaNivel(t, n)));
    if (n.conductor) modal.appendChild(seccionConductor(n));
    else modal.appendChild(seccionPasajero(n));
    overlay.appendChild(modal);
  }

  function resumen(n) {
    const p = el('p', 'nv-summary');
    const base = n.conductor ? 'XP de los últimos 90 días: ' : 'XP total: ';
    p.appendChild(el('strong', null, base + n.xpActual));
    p.appendChild(document.createTextNode(n.xpSiguienteNivel == null
      ? ' · Nivel máximo alcanzado.'
      : ' · Te faltan ' + n.xpFaltante + ' XP para ' + nombre(n.nivel + 1) + '.'));
    return p;
  }

  function tarjetaNivel(t, n) {
    const estadoClase = t.nivel === n.nivel ? ' nv-tier--actual' : (t.nivel > n.nivel ? ' nv-tier--bloqueado' : '');
    const card = el('section', 'nv-tier ' + claseColor(t.nivel) + estadoClase);
    const head = el('div', 'nv-tier-head');
    head.appendChild(insignia(t.nivel, true));
    head.appendChild(el('span', 'nv-tier-name', nombre(t.nivel)));
    head.appendChild(el('span', 'nv-tier-meta', t.nivel === n.nivel ? 'Tu nivel' : t.xp + ' XP'));
    card.appendChild(head);
    const lista = el('ul', 'nv-list');
    t.beneficios.forEach((b) => {
      const li = el('li', b.activo ? 'nv-on' : 'nv-off');
      li.appendChild(icono(b.activo ? 'fa-check' : 'fa-lock'));
      const txt = el('span');
      txt.appendChild(el('strong', null, b.titulo + ': '));
      txt.appendChild(document.createTextNode(b.descripcion));
      li.appendChild(txt);
      const sr = el('span', null, b.activo ? ' (desbloqueado)' : ' (bloqueado)');
      sr.style.cssText = 'position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0)';
      li.appendChild(sr);
      lista.appendChild(li);
    });
    if (!t.beneficios.length) lista.appendChild(el('li', 'nv-off', 'Punto de partida.'));
    card.appendChild(lista);
    return card;
  }

  function seccionConductor(n) {
    const c = n.conductor;
    const box = el('div');
    box.appendChild(el('h3', 'nv-section-title', 'Tu comisión'));
    const actual = pct(c.comisionActual);
    const texto = c.comisionSiguiente == null
      ? 'Comisión actual: ' + actual + ' (la más baja).'
      : 'Tu comisión: ' + actual + ' → ' + pct(c.comisionSiguiente) + ' en ' + nombre(n.nivel + 1);
    box.appendChild(el('p', 'nv-summary', texto));

    if (c.requisitosSiguiente.length) {
      box.appendChild(el('h3', 'nv-section-title', 'Requisitos de calidad para ' + nombre(n.nivel + 1)));
      const ul = el('ul', 'nv-list');
      c.requisitosSiguiente.forEach((r) => {
        const li = el('li', r.cumplido ? 'nv-on' : 'nv-no');
        li.appendChild(icono(r.cumplido ? 'fa-check' : 'fa-xmark'));
        li.appendChild(el('span', null, r.texto + (r.cumplido ? ' (cumplido)' : ' (pendiente)')));
        ul.appendChild(li);
      });
      box.appendChild(ul);
    }
    const metricas = [
      'Calificación: ' + (c.calificacion == null ? 'sin datos' : c.calificacion.toFixed(2)),
      'Aceptación: ' + pct(c.aceptacion),
      'Cancelación: ' + pct(c.cancelacion)
    ];
    box.appendChild(el('p', 'nv-note', 'Tus cifras (90 días) — ' + metricas.join(' · ')));
    if (c.bloqueadoPorCalidad) {
      box.appendChild(el('p', 'nv-note', 'Ya tienes los XP del siguiente nivel; sube cuando cumplas los requisitos.'));
    }
    return box;
  }

  function seccionPasajero(n) {
    const box = el('div');
    box.appendChild(el('h3', 'nv-section-title', 'Tus ventajas hoy'));
    const lineas = [];
    lineas.push(n.descuento > 0
      ? 'Descuento en tus viajes: ' + pct(n.descuento)
      : 'Desde el nivel 2 tienes descuento en tus viajes.');
    if (n.prioridadSegundos > 0) lineas.push('Tu solicitud es prioritaria durante ' + n.prioridadSegundos + ' s.');
    lineas.forEach((l) => box.appendChild(el('p', 'nv-note', l)));
    box.appendChild(el('p', 'nv-note', 'Si pasas 90 días sin viajar, bajas un nivel.'));
    return box;
  }

  // ── toast y celebración ──────────────────────────────────
  function toast(texto, nivel) {
    const t = el('div', 'nv-toast ' + claseColor(nivel), texto);
    toastZone.appendChild(t);
    setTimeout(() => t.remove(), 4500);
  }
  function celebrar(n) {
    const wrap = el('div', 'nv-celebrate ' + claseColor(n.nivel));
    wrap.setAttribute('aria-hidden', 'true');
    const card = el('div', 'nv-celebrate-card');
    card.appendChild(insignia(n.nivel, false));
    card.appendChild(el('strong', null, '¡Subiste al ' + nombre(n.nivel).toLowerCase() + '!'));
    card.appendChild(el('span', null, 'Nuevos beneficios desbloqueados'));
    wrap.appendChild(card);
    document.body.appendChild(wrap);
    setTimeout(() => wrap.remove(), 3800);
    toast('¡' + nombre(n.nivel) + ' alcanzado!', n.nivel);
  }

  function revisarCambios(n) {
    const previo = leer(claveVisto(n));
    if (previo && n.xpActual > previo.xp) toast('+' + (n.xpActual - previo.xp) + ' XP', n.nivel);
    const celebrado = leer(claveCelebrado(n));
    if (previo && n.nivel > previo.nivel && (celebrado == null || n.nivel > celebrado)) celebrar(n);
    if (celebrado == null || n.nivel > celebrado) guardar(claveCelebrado(n), n.nivel);
    guardar(claveVisto(n), { xp: n.xpActual, nivel: n.nivel });
  }

  // ── ciclo ────────────────────────────────────────────────
  async function refrescar(silencioso) {
    try {
      const n = await api('/api/niveles/me?rol=' + encodeURIComponent(rol));
      estado = n;
      if (!barra) montarBarra();
      pintarBarra();
      if (!silencioso) revisarCambios(n);
      else guardar(claveVisto(n), { xp: n.xpActual, nivel: n.nivel });
      if (overlay && !overlay.hidden) pintarModal();
    } catch (e) {
      if (barra) barra.hidden = true; // sin datos: no estorba al dashboard
    }
  }

  document.addEventListener('visibilitychange', () => { if (!document.hidden) refrescar(); });
  setInterval(() => { if (!document.hidden) refrescar(); }, REFRESCO_MS);
  window.NexaNiveles = { refrescar: () => refrescar(false) };

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', () => refrescar());
  else refrescar();
})();
