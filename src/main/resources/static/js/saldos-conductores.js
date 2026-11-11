/**
 * NEXA | Panel admin: saldo de cada conductor con NEXA (GET /api/admin/conductores/saldos?dias=N).
 * Todo el texto del servidor se inserta con textContent. Funciones puras en src/test/js/saldos-conductores.test.mjs.
 */
(function (raiz, fabrica) {
  const api = fabrica();
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else {
    raiz.SaldosConductores = api;
    if (typeof document !== 'undefined') document.addEventListener('DOMContentLoaded', api.iniciar);
  }
})(typeof window !== 'undefined' ? window : globalThis, function () {
  'use strict';

  function pesos(n) {
    return '$' + Math.round(Number(n) || 0).toLocaleString('es-CO');
  }

  /** Cómo se pinta el saldo: a favor de NEXA (debe), a favor del conductor, o al día. */
  function estadoSaldo(saldo) {
    const v = Math.round(Number(saldo) || 0);
    if (v > 0) return { texto: pesos(v), clase: 'estado-pill--ambar', titulo: 'Le debe a NEXA' };
    if (v < 0) return { texto: pesos(-v), clase: 'estado-pill--verde', titulo: 'NEXA le debe' };
    return { texto: pesos(0), clase: 'estado-pill--gris', titulo: 'Al día' };
  }

  function el(tag, clase, texto) {
    const e = document.createElement(tag);
    if (clase) e.className = clase;
    if (texto !== undefined) e.textContent = texto;
    return e;
  }

  function pintar(cuerpo, filas) {
    if (!filas.length) {
      const tr = el('tr');
      const td = el('td', 'no-data', 'Sin viajes en el periodo.');
      td.colSpan = 8;
      tr.appendChild(td);
      cuerpo.replaceChildren(tr);
      return;
    }
    cuerpo.replaceChildren(...filas.map((s) => {
      const tr = el('tr');
      [s.nombre || '—', String(s.viajes), pesos(s.cobradoEfectivo), pesos(s.ganado), pesos(s.comisionNexa),
        pesos(s.deudasCobradas), pesos(s.cargosAFavor)].forEach((t) => tr.appendChild(el('td', null, t)));
      const e = estadoSaldo(s.saldoConNexa);
      const td = el('td');
      const pill = el('span', 'estado-pill ' + e.clase, e.texto);
      pill.title = e.titulo;
      td.appendChild(pill);
      tr.appendChild(td);
      return tr;
    }));
  }

  async function cargar() {
    const cuerpo = document.getElementById('saldos-cuerpo');
    const sel = document.getElementById('saldos-dias');
    if (!cuerpo || !sel) return;
    try {
      const r = await fetch('/api/admin/conductores/saldos?dias=' + encodeURIComponent(sel.value),
        { credentials: 'same-origin', headers: { Accept: 'application/json' } });
      if (!r.ok) throw new Error('No se pudieron cargar los saldos de los conductores');
      pintar(cuerpo, await r.json());
    } catch (e) {
      const tr = el('tr');
      const td = el('td', 'no-data', e.message);
      td.colSpan = 8;
      tr.appendChild(td);
      cuerpo.replaceChildren(tr);
    }
  }

  function iniciar() {
    const sel = document.getElementById('saldos-dias');
    if (!sel) return;
    sel.addEventListener('change', cargar);
    cargar();
  }

  return { estadoSaldo, pesos, iniciar };
});
