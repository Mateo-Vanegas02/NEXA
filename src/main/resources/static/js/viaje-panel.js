/*
 * Panel flotante del viaje en curso (pasajero y conductor). Arma el esqueleto una vez y luego solo actualiza
 * textos y estados con la vista que entrega ViajeFases; nunca inserta datos como HTML.
 *
 *   const panel = ViajePanel.crear(contenedor, { rol: 'conductor', acciones: { llegue, iniciar, finalizar, cancelar, maps } });
 *   panel.render(vista);   // vista = ViajeFases.vistaPasajero(...) | vistaConductor(...)
 *   panel.destruir();
 */
(function (raiz, fabrica) {
  var api = fabrica(raiz);
  if (typeof module === 'object' && module.exports) module.exports = api;
  else raiz.ViajePanel = api;
})(typeof self !== 'undefined' ? self : this, function (raiz) {
  'use strict';

  function el(etiqueta, clase, texto) {
    var nodo = raiz.document.createElement(etiqueta);
    if (clase) nodo.className = clase;
    if (texto != null) nodo.textContent = texto;
    return nodo;
  }

  function boton(clase, texto, alHacerClic) {
    var b = el('button', 'vp-btn ' + clase, texto);
    b.type = 'button';
    if (alHacerClic) b.addEventListener('click', alHacerClic);
    return b;
  }

  function mostrar(nodo, visible) {
    nodo.hidden = !visible;
  }

  function crear(contenedor, opciones) {
    opciones = opciones || {};
    var acc = opciones.acciones || {};
    var esConductor = opciones.rol === 'conductor';

    var raizPanel = el('section', 'vp-panel');
    raizPanel.setAttribute('aria-label', 'Viaje en curso');

    // Encabezado
    var etiqueta = el('span', 'vp-chip');
    var titulo = el('h2', 'vp-titulo');
    var subtitulo = el('p', 'vp-subtitulo');
    subtitulo.setAttribute('aria-live', 'polite');
    var encabezado = el('header', 'vp-encabezado');
    encabezado.append(etiqueta, titulo, subtitulo);

    // Pasos (4 barras) y avance del viaje
    var pasos = el('div', 'vp-pasos');
    pasos.setAttribute('role', 'presentation');
    var barras = [0, 1, 2, 3].map(function () { var b = el('span', 'vp-paso'); pasos.appendChild(b); return b; });
    var avanceCaja = el('div', 'vp-avance');
    var avance = el('span', 'vp-avance-relleno');
    avanceCaja.appendChild(avance);

    // Aviso de espera (cronómetro)
    var espera = el('div', 'vp-espera');
    var esperaReloj = el('strong', 'vp-espera-reloj');
    var esperaTexto = el('span', 'vp-espera-texto');
    var esperaRecargo = el('span', 'vp-espera-recargo');
    espera.append(esperaReloj, esperaTexto, esperaRecargo);

    // Persona (conductor para el pasajero; pasajero para el conductor)
    var persona = el('div', 'vp-persona');
    var avatar = el('div', 'vp-avatar');
    var avatarIniciales = el('span', 'vp-avatar-iniciales');
    var avatarImg = el('img', 'vp-avatar-img');
    avatarImg.alt = '';
    avatarImg.hidden = true;
    avatar.append(avatarImg, avatarIniciales);
    var nombre = el('div', 'vp-nombre');
    var calificacion = el('span', 'vp-calificacion');
    var nivel = el('span', 'vp-nivel');
    var meta = el('div', 'vp-meta');
    meta.append(calificacion, nivel);
    var datos = el('div', 'vp-persona-datos');
    datos.append(nombre, meta);
    var filaPersona = el('div', 'vp-persona-fila');
    filaPersona.append(avatar, datos);
    var vehiculoFila = el('div', 'vp-vehiculo');
    var vehiculoTexto = el('span', 'vp-vehiculo-texto');
    var placa = el('span', 'vp-placa');
    vehiculoFila.append(vehiculoTexto, placa);
    var seguimiento = el('p', 'vp-seguimiento');
    seguimiento.setAttribute('aria-live', 'polite');
    persona.append(filaPersona, vehiculoFila, seguimiento);

    // Resumen del viaje
    var resumen = el('div', 'vp-resumen');
    var origen = el('div', 'vp-parada');
    origen.append(el('span', 'vp-punto vp-punto-origen'));
    var origenTexto = el('span', 'vp-parada-texto');
    origen.appendChild(origenTexto);
    var destino = el('div', 'vp-parada');
    destino.append(el('span', 'vp-punto vp-punto-destino'));
    var destinoTexto = el('span', 'vp-parada-texto');
    destino.appendChild(destinoTexto);
    var pago = el('div', 'vp-pago');
    var pagoMetodo = el('span', 'vp-chip-pago');
    var pagoExtra = el('span', 'vp-chip-extra');
    var pagoTotal = el('strong', 'vp-total');
    pago.append(pagoMetodo, pagoExtra, pagoTotal);
    resumen.append(origen, destino, pago);

    // Acciones
    var acciones = el('div', 'vp-acciones');
    var btnMaps = boton('vp-btn-contorno', 'Abrir en Maps', acc.maps);
    var btnLlegue = boton('vp-btn-primario', 'Llegué', acc.llegue);
    var btnIniciar = boton('vp-btn-primario', 'Iniciar viaje', acc.iniciar);
    var btnFinalizar = boton('vp-btn-primario', 'Finalizar viaje', acc.finalizar);
    var ayuda = el('p', 'vp-ayuda');
    var btnCancelar = boton('vp-btn-peligro', 'Cancelar viaje', acc.cancelar);
    var notaCancelar = el('p', 'vp-nota', opciones.notaCancelar || '');
    if (esConductor) acciones.append(btnMaps, btnLlegue, btnIniciar, btnFinalizar, ayuda, btnCancelar);
    else acciones.append(btnCancelar, notaCancelar);

    raizPanel.append(encabezado, pasos, avanceCaja, espera, persona, resumen, acciones);
    contenedor.appendChild(raizPanel);

    function render(vista) {
      if (!vista) return;
      raizPanel.dataset.fase = vista.fase;
      etiqueta.textContent = vista.etiqueta;
      titulo.textContent = vista.titulo;
      subtitulo.textContent = vista.subtitulo;
      barras.forEach(function (b, i) {
        b.className = 'vp-paso' + (i + 1 < vista.paso ? ' vp-paso-hecho' : i + 1 === vista.paso ? ' vp-paso-actual' : '');
      });
      var hayAvance = typeof vista.progreso === 'number';
      mostrar(avanceCaja, hayAvance);
      if (hayAvance) avance.style.width = Math.round(vista.progreso * 100) + '%';

      mostrar(espera, !!vista.espera);
      if (vista.espera) {
        esperaReloj.textContent = vista.espera.reloj;
        esperaTexto.textContent = vista.espera.aviso || 'Tiempo de espera';
        esperaRecargo.textContent = vista.espera.recargo > 0 ? 'Recargo: ' + raiz.ViajeFases.formatoCOP(vista.espera.recargo) : '';
        mostrar(esperaRecargo, vista.espera.recargo > 0);
      }

      var p = vista.persona;
      nombre.textContent = p.nombre;
      avatarIniciales.textContent = p.iniciales;
      if (p.fotoUrl) { avatarImg.src = p.fotoUrl; avatarImg.hidden = false; avatarIniciales.hidden = true; }
      else { avatarImg.removeAttribute('src'); avatarImg.hidden = true; avatarIniciales.hidden = false; }
      calificacion.textContent = p.calificacion != null ? '★ ' + raiz.ViajeFases.formatoCalificacion(p.calificacion) : '';
      mostrar(calificacion, p.calificacion != null);
      nivel.textContent = p.nivel != null ? 'Nivel ' + p.nivel : '';
      mostrar(nivel, p.nivel != null);
      mostrar(vehiculoFila, !!vista.vehiculo);
      if (vista.vehiculo) { vehiculoTexto.textContent = vista.vehiculo.texto; placa.textContent = vista.vehiculo.placa; mostrar(placa, !!vista.vehiculo.placa); }
      seguimiento.textContent = vista.seguimiento || '';
      mostrar(seguimiento, !!vista.seguimiento);

      origenTexto.textContent = vista.paradas.origen;
      destinoTexto.textContent = vista.paradas.destino;
      if (esConductor) {
        mostrar(pagoMetodo, false);
        mostrar(pagoExtra, false);
        pagoTotal.textContent = 'Cobras ' + vista.cobro + ' en efectivo';
        btnLlegue.hidden = vista.fase !== 'A_RECOGER';
        btnLlegue.disabled = !vista.puedeLlegar;
        btnIniciar.hidden = vista.fase !== 'EN_EL_PUNTO';
        btnFinalizar.hidden = vista.fase !== 'EN_VIAJE';
        btnFinalizar.disabled = !vista.puedeFinalizar;
        btnCancelar.hidden = false; // el conductor siempre puede cancelar (si no, un viaje trabado no tendría salida)
        var texto = '';
        if (vista.fase === 'A_RECOGER' && !vista.puedeLlegar) texto = 'Podrás marcar «Llegué» cuando estés en el punto de recogida.';
        if (vista.fase === 'EN_VIAJE' && vista.finalizaAntes) {
          texto = 'Si el pasajero se baja antes de llegar, finaliza aquí: se cobra según lo recorrido (antes de la mitad, la mitad del viaje).';
        }
        ayuda.textContent = texto;
        mostrar(ayuda, !!texto);
      } else {
        pagoMetodo.textContent = vista.pago.metodo;
        mostrar(pagoMetodo, true);
        pagoExtra.textContent = vista.pago.extra > 0 ? '+' + raiz.ViajeFases.formatoCOP(vista.pago.extra) + ' extra' : '';
        mostrar(pagoExtra, vista.pago.extra > 0);
        pagoTotal.textContent = raiz.ViajeFases.formatoCOP(vista.pago.total);
        btnCancelar.hidden = !vista.puedeCancelar;
        // En viaje no se cancela: la nota explica qué pasa si el pasajero se baja antes del destino
        var hayNota = typeof vista.nota === 'string';
        notaCancelar.textContent = hayNota ? vista.nota : (opciones.notaCancelar || '');
        notaCancelar.hidden = hayNota ? !vista.nota : (!vista.puedeCancelar || !notaCancelar.textContent);
      }
    }

    function destruir() {
      if (raizPanel.parentNode) raizPanel.parentNode.removeChild(raizPanel);
    }

    return { elemento: raizPanel, render: render, destruir: destruir };
  }

  return { crear: crear };
});
