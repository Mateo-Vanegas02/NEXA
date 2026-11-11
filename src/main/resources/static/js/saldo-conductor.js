/**
 * NEXA | Billetera del conductor: su saldo con NEXA (GET /conductor/saldo?dias=N).
 * Como todo se cobra en efectivo, el conductor recibe el total del viaje y se queda con su ganancia: la
 * diferencia es de NEXA. Las funciones puras se prueban en src/test/js/saldo-conductor.test.mjs.
 */
(function (raiz, fabrica) {
  const api = fabrica();
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else {
    raiz.SaldoConductor = api;
    if (typeof document !== 'undefined') document.addEventListener('DOMContentLoaded', api.iniciar);
  }
})(typeof window !== 'undefined' ? window : globalThis, function () {
  'use strict';

  function pesos(n) {
    return '$' + Math.round(Number(n) || 0).toLocaleString('es-CO');
  }

  /** Cómo se le explica el saldo al conductor: a quién le debe quién, y cuánto. */
  function resumen(s) {
    const saldo = Math.round(Number(s && s.saldoConNexa) || 0);
    if (saldo > 0) {
      return { titulo: 'Le debes a NEXA', monto: pesos(saldo), clase: 'saldo--debe',
        nota: 'Es la comisión de tus viajes, que cobraste en efectivo junto con la tarifa.' };
    }
    if (saldo < 0) {
      return { titulo: 'NEXA te debe', monto: pesos(-saldo), clase: 'saldo--favor',
        nota: 'Incluye los cargos por cancelación que te reconocimos.' };
    }
    return { titulo: 'Estás al día', monto: pesos(0), clase: 'saldo--cero', nota: 'No tienes saldo pendiente con NEXA.' };
  }

  function el(tag, clase, texto) {
    const e = document.createElement(tag);
    if (clase) e.className = clase;
    if (texto !== undefined) e.textContent = texto;
    return e;
  }

  function pintar(cont, s) {
    const r = resumen(s);
    const caja = el('div', 'saldo-total ' + r.clase);
    caja.appendChild(el('span', null, r.titulo));
    caja.appendChild(el('strong', null, r.monto));
    caja.appendChild(el('small', null, r.nota));

    const detalle = el('dl', 'saldo-detalle');
    [['Viajes', String(s.viajes)], ['Cobrado en efectivo', pesos(s.cobradoEfectivo)],
      ['Tus ganancias', pesos(s.ganado)],
      ['Cargos a tu favor', pesos(s.cargosAFavor)]].forEach(([rot, val]) => {
      const fila = el('div');
      fila.appendChild(el('dt', null, rot));
      fila.appendChild(el('dd', null, val));
      detalle.appendChild(fila);
    });
    cont.replaceChildren(caja, detalle);
  }

  async function cargar() {
    const cont = document.getElementById('saldoContenido');
    const sel = document.getElementById('saldoDias');
    if (!cont || !sel) return;
    cont.replaceChildren(el('p', 'saldo-estado', 'Calculando tu saldo…'));
    try {
      const r = await fetch('/conductor/saldo?dias=' + encodeURIComponent(sel.value),
        { credentials: 'same-origin', headers: { Accept: 'application/json' } });
      if (!r.ok) throw new Error('No pudimos calcular tu saldo ahora. Intenta más tarde.');
      pintar(cont, await r.json());
    } catch (e) {
      cont.replaceChildren(el('p', 'saldo-estado saldo-error', e.message));
    }
  }

  function iniciar() {
    const sel = document.getElementById('saldoDias');
    if (!sel) return;
    sel.addEventListener('change', cargar);
    cargar();
  }

  return { resumen, pesos, iniciar };
});
