/**
 * NEXA | Panel admin: métricas del despacho por olas (GET /api/admin/despacho/metricas?dias=N).
 * Sirven para calibrar nexa.despacho.* en modelo-nexa.properties con datos reales.
 * Funciones puras exportadas para Node (src/test/js/despacho-metricas.test.mjs); la vista usa textContent.
 */
(function (raiz, fabrica) {
  const api = fabrica();
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else {
    raiz.DespachoMetricas = api;
    if (typeof document !== 'undefined') document.addEventListener('DOMContentLoaded', api.iniciar);
  }
})(typeof window !== 'undefined' ? window : globalThis, function () {
  'use strict';

  const MINIMO_DATOS = 30;

  function segundos(v) { return v == null ? '—' : Math.round(v) + ' s'; }
  function km(v) { return v == null ? '—' : String(v).replace('.', ',') + ' km'; }
  function pct(v) { return v == null ? '—' : String(v).replace('.', ',') + ' %'; }

  /** Lectura en palabras de las métricas, para orientar el ajuste. */
  function sugerencia(m) {
    if (!m || m.aceptadas - (m.aceptadasSinMedicion || 0) < MINIMO_DATOS) {
      const n = m ? m.aceptadas - (m.aceptadasSinMedicion || 0) : 0;
      return 'Aún hay pocos datos (' + n + ' viajes medidos). Espera a tener al menos ' + MINIMO_DATOS
        + ' antes de cambiar la calibración.';
    }
    const olas = m.olas || [];
    const primera = olas[0] || { porcentaje: 0 };
    const ultima = olas[olas.length - 1] || { porcentaje: 0 };
    if (m.porcentajeSinConductor > 15) {
      return 'Más del 15 % de las solicitudes se queda sin conductor: conviene acortar los tiempos entre olas o ampliar el tope de la última.';
    }
    if (ultima.porcentaje > 40) {
      return 'Muchos viajes se toman en la última ola: los primeros radios avisan a muy pocos conductores. Prueba radios iniciales más grandes.';
    }
    if (primera.porcentaje > 70 && (primera.medianaSegundos || 0) < 15) {
      return 'Casi todo se toma rápido en la primera ola: la calibración funciona; si quieres recogidas más cortas, puedes bajar el primer radio.';
    }
    return 'La distribución entre olas es razonable. Revisa de nuevo en unas semanas.';
  }

  function el(tag, clase, texto) {
    const e = document.createElement(tag);
    if (clase) e.className = clase;
    if (texto !== undefined) e.textContent = texto;
    return e;
  }

  function pintar(cont, m) {
    const kpis = el('div', 'dm-kpis');
    [['Solicitudes', String(m.solicitudes)], ['Aceptadas', String(m.aceptadas)],
      ['Sin conductor o canceladas', pct(m.porcentajeSinConductor)], ['Tiempo para aceptar (mediana)', segundos(m.medianaSegundosAceptar)],
      ['9 de cada 10 en menos de', segundos(m.p90SegundosAceptar)], ['Distancia de recogida (mediana)', km(m.medianaDistanciaKm)]]
      .forEach(([r, v]) => {
        const k = el('div', 'dm-kpi');
        k.appendChild(el('span', null, r));
        k.appendChild(el('strong', null, v));
        kpis.appendChild(k);
      });
    const tabla = el('table', 'dm-tabla');
    const cab = el('tr');
    ['Ola', 'Desde', 'Radio', 'Aceptadas', '% del total', 'Tiempo (mediana)', 'Distancia (mediana)']
      .forEach((t) => { const th = el('th', null, t); th.scope = 'col'; cab.appendChild(th); });
    const thead = el('thead'); thead.appendChild(cab); tabla.appendChild(thead);
    const tbody = el('tbody');
    (m.olas || []).forEach((o) => {
      const tr = el('tr');
      [String(o.ola), o.desdeSegundos + ' s', o.radioKm == null ? 'Toda la zona' : km(o.radioKm), String(o.aceptadas),
        pct(o.porcentaje), segundos(o.medianaSegundos), km(o.medianaDistanciaKm)].forEach((t) => tr.appendChild(el('td', null, t)));
      tbody.appendChild(tr);
    });
    tabla.appendChild(tbody);
    const envoltura = el('div', 'dm-tabla-wrap'); envoltura.appendChild(tabla);
    cont.replaceChildren(kpis, envoltura, el('p', 'dm-sugerencia', sugerencia(m)));
  }

  async function cargar() {
    const cont = document.getElementById('dm-contenido');
    const sel = document.getElementById('dm-dias');
    if (!cont || !sel) return;
    cont.replaceChildren(el('p', 'dm-estado', 'Cargando métricas…'));
    try {
      const r = await fetch('/api/admin/despacho/metricas?dias=' + encodeURIComponent(sel.value),
        { credentials: 'same-origin', headers: { Accept: 'application/json' } });
      if (!r.ok) throw new Error('No se pudieron cargar las métricas del despacho');
      pintar(cont, await r.json());
    } catch (e) {
      cont.replaceChildren(el('p', 'dm-estado dm-error', e.message));
    }
  }

  function iniciar() {
    const sel = document.getElementById('dm-dias');
    if (!sel) return;
    sel.addEventListener('change', cargar);
    cargar();
  }

  return { sugerencia, segundos, km, pct, iniciar };
});
