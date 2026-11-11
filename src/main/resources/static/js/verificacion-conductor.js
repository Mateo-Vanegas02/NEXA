/**
 * NEXA | Panel de admin: ficha de verificación de un conductor.
 *
 * Una sola ventana con el conductor, su vehículo, sus documentos con la validación cruzada (número registrado vs.
 * número leído en la foto), la información que se pidió, la verificación de datos y las decisiones. Sirve también
 * para conductores antiguos, que se registraron antes de que se pidieran vehículo y fotos: lo que falta se muestra
 * como "Sin foto" y se explica cómo pedirlo.
 *
 * Todo lo que viene del servidor se inserta con textContent (nunca innerHTML).
 * Las funciones puras se exportan para pruebas en Node (src/test/js/verificacion-conductor.test.mjs).
 */
(function (raiz, fabrica) {
  const api = fabrica();
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else raiz.VerificacionConductor = api;
})(typeof window !== 'undefined' ? window : globalThis, function () {
  'use strict';

  const BASE = '/api/admin/verificacion/';
  const MESES = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  const DIA_MS = 24 * 60 * 60 * 1000;
  /** Plazo de respuesta aproximado en días corridos (15 días hábiles), solo para dibujar la barra. */
  const PLAZO_TOTAL_DIAS = 21;

  const DOCUMENTOS = [
    { tipo: 'LICENCIA', rotulo: 'Licencia de conducción', ambito: 'CONDUCTOR' },
    { tipo: 'SOAT', rotulo: 'SOAT', ambito: 'VEHÍCULO' },
    { tipo: 'TARJETA_PROPIEDAD', rotulo: 'Tarjeta de propiedad', ambito: 'VEHÍCULO' },
    { tipo: 'TECNOMECANICA', rotulo: 'Tecnomecánica', ambito: 'VEHÍCULO' },
  ];

  /* ---------------- Funciones puras ---------------- */

  /** "en_revision" / "EN_REVISION" → { clave, texto, clase } para la insignia de estado. */
  function estadoConductor(valor) {
    const clave = String(valor || '').toUpperCase();
    const mapa = {
      PENDIENTE: ['Pendiente', 'vc-pill--ambar'],
      EN_REVISION: ['En revisión', 'vc-pill--azul'],
      APROBADO: ['Aprobado', 'vc-pill--verde'],
      RECHAZADO: ['Rechazado', 'vc-pill--rojo'],
    };
    const [texto, clase] = mapa[clave] || [valor || '—', 'vc-pill--gris'];
    return { clave, texto, clase };
  }

  /** Estado de una tarjeta de documento según haya foto y según lo que dio la lectura (si ya se hizo). */
  function estadoDocumento(tieneFoto, lectura) {
    if (!tieneFoto) return { clave: 'SIN_FOTO', texto: 'Sin foto', clase: 'vc-pill--gris' };
    if (!lectura) return { clave: 'SIN_REVISAR', texto: 'Sin revisar', clase: 'vc-pill--ambar' };
    switch (lectura.resultado) {
      case 'COINCIDE': return { clave: 'COINCIDE', texto: 'Coincide', clase: 'vc-pill--verde' };
      case 'DIFERENTE': return { clave: 'DIFERENTE', texto: 'No coincide', clase: 'vc-pill--rojo' };
      default: return { clave: 'NO_LEGIBLE', texto: 'No legible', clase: 'vc-pill--ambar' };
    }
  }

  /** Resultado de la fuente (placa o licencia) en palabras. */
  function estadoFuente(status) {
    switch (status) {
      case 'VERIFIED': return { texto: 'Verificado', clase: 'vc-pill--verde' };
      case 'NOT_FOUND': return { texto: 'No encontrado', clase: 'vc-pill--rojo' };
      case 'MISMATCH': return { texto: 'No coincide', clase: 'vc-pill--rojo' };
      default: return { texto: 'Por verificar', clase: 'vc-pill--ambar' };
    }
  }

  /** "2026-11-10" (o [2026, 11, 10]) → "10 nov 2026"; cualquier otra cosa → "—". */
  function formatoFecha(valor) {
    let y, m, d;
    if (Array.isArray(valor) && valor.length >= 3) [y, m, d] = valor;
    else {
      const t = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(valor || ''));
      if (!t) return '—';
      y = +t[1]; m = +t[2]; d = +t[3];
    }
    return `${d} ${MESES[m - 1]} ${y}`;
  }

  /** Días corridos que faltan para el plazo (negativo si ya pasó); null si no hay plazo. */
  function diasHasta(plazo, hoy) {
    let y, m, d;
    if (Array.isArray(plazo) && plazo.length >= 3) [y, m, d] = plazo;
    else {
      const t = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(plazo || ''));
      if (!t) return null;
      y = +t[1]; m = +t[2]; d = +t[3];
    }
    const fin = Date.UTC(y, m - 1, d);
    const ahora = Date.UTC(hoy.getFullYear(), hoy.getMonth(), hoy.getDate());
    return Math.round((fin - ahora) / DIA_MS);
  }

  /** Fracción (0..1) del plazo ya consumida, para la barra. */
  function avancePlazo(diasRestantes) {
    if (diasRestantes == null) return 0;
    return Math.min(1, Math.max(0, 1 - diasRestantes / PLAZO_TOTAL_DIAS));
  }

  /**
   * Documentos que le tocan al vehículo mostrado, por tipo, quedándose con el más reciente. La licencia es del
   * conductor; los demás son del vehículo (los que no dicen de cuál se aceptan solo si hay un único vehículo).
   */
  function documentosPorTipo(docs, vehiculo, hayUnSoloVehiculo) {
    const resultado = {};
    [...(docs || [])]
      .sort((a, b) => String(b.subidoEn || '').localeCompare(String(a.subidoEn || '')))
      .forEach((d) => {
        if (resultado[d.tipo]) return;
        const esDeVehiculo = d.tipo !== 'LICENCIA';
        if (esDeVehiculo) {
          const pertenece = d.vehiculoId ? (vehiculo && d.vehiculoId === vehiculo.id) : (!!vehiculo && hayUnSoloVehiculo) || !vehiculo;
          if (!pertenece) return;
        }
        resultado[d.tipo] = d;
      });
    return resultado;
  }

  /** Un conductor es "antiguo" si no tiene vehículos ni fotos: se registró antes de que se pidieran. */
  function esConductorAntiguo(vehiculos, docs) {
    return !(vehiculos && vehiculos.length) && !(docs && docs.length);
  }

  /* ---------------- Vista (solo navegador) ---------------- */

  function el(tag, clase, texto) {
    const e = document.createElement(tag);
    if (clase) e.className = clase;
    if (texto !== undefined && texto !== null) e.textContent = texto;
    return e;
  }

  function icono(clases) {
    const i = document.createElement('i');
    i.className = clases;
    i.setAttribute('aria-hidden', 'true');
    return i;
  }

  function pill(texto, clase) {
    return el('span', 'vc-pill ' + clase, texto);
  }

  function csrf() {
    const campo = document.querySelector('input[name="_csrf"]');
    return campo && campo.value ? campo.value : '';
  }

  async function llamar(metodo, ruta, cuerpo) {
    const cab = { Accept: 'application/json' };
    if (metodo !== 'GET') {
      cab['X-CSRF-TOKEN'] = csrf();
      if (cuerpo) cab['Content-Type'] = 'application/json';
    }
    const r = await fetch(BASE + ruta, {
      method: metodo, headers: cab, credentials: 'same-origin', body: cuerpo ? JSON.stringify(cuerpo) : undefined,
    });
    let datos = null;
    try { datos = await r.json(); } catch (e) { /* sin cuerpo */ }
    if (!r.ok) {
      const msg = r.status === 403 && !(datos && datos.message && datos.message !== 'Forbidden')
        ? 'Tu sesión venció o no tienes permiso. Recarga la página e intenta de nuevo.'
        : (datos && (datos.error || datos.message)) || 'No se pudo completar la operación';
      throw new Error(msg);
    }
    return datos;
  }

  let datosActuales = null;
  /** El correo vive en la fila de la tabla ({@code d}), no en el estado cargado. */
  function correoActual() { return datosActuales && datosActuales.d ? datosActuales.d.email : null; }
  let lecturas = new Map();

  function fila(rotulo, valor, clase) {
    const f = el('div', 'vc-fila');
    f.appendChild(el('dt', null, rotulo));
    const dd = el('dd', clase || null);
    if (valor instanceof Node) dd.appendChild(valor); else dd.textContent = (valor === undefined || valor === null || valor === '') ? '—' : valor;
    f.appendChild(dd);
    return f;
  }

  function tarjeta(titulo, iconoClase) {
    const t = el('section', 'vc-card');
    const cab = el('header', 'vc-card-cab');
    cab.appendChild(icono(iconoClase));
    cab.appendChild(el('h4', null, titulo));
    t.appendChild(cab);
    return t;
  }

  function numeroODeclarado(valor) {
    return valor && valor !== 'No disponible' && valor !== 'null' ? valor : null;
  }

  /* --- Cabecera --- */
  function cabecera(d, est) {
    const e = estadoConductor((est && est.estadoValidacion) || d.estado);
    const cab = el('header', 'vc-head');
    const avatar = el('div', 'vc-avatar');
    if (d.foto) {
      const img = document.createElement('img');
      img.src = d.foto; img.alt = 'Foto de perfil de ' + d.nombre; img.width = 44; img.height = 44;
      img.addEventListener('error', () => img.replaceWith(icono('fas fa-user')));
      avatar.appendChild(img);
    } else {
      avatar.appendChild(icono('fas fa-user'));
    }
    cab.appendChild(avatar);
    const titulos = el('div', 'vc-titulos');
    const h = el('h3', null, d.nombre);
    h.id = 'vc-titulo';
    titulos.appendChild(h);
    titulos.appendChild(el('p', null, 'Solicitud de acceso como conductor'));
    cab.appendChild(titulos);
    cab.appendChild(pill(e.texto, e.clase));
    const cerrar = el('button', 'vc-cerrar');
    cerrar.type = 'button';
    cerrar.setAttribute('aria-label', 'Cerrar');
    cerrar.appendChild(icono('fas fa-xmark'));
    cerrar.addEventListener('click', () => window.closeModal && window.closeModal());
    cab.appendChild(cerrar);
    return cab;
  }

  /* --- Conductor y vehículo --- */
  function tarjetaConductor(d, est) {
    const t = tarjeta('Conductor', 'fas fa-id-card');
    const dl = el('dl', 'vc-datos');
    dl.appendChild(fila('Email', d.email));
    dl.appendChild(fila('Teléfono', numeroODeclarado(d.telefono)));
    dl.appendChild(fila('Licencia', numeroODeclarado(d.licencia)));
    const e = estadoConductor((est && est.estadoValidacion) || d.estado);
    dl.appendChild(fila('Estado de validación', pill(e.texto, e.clase)));
    t.appendChild(dl);
    return t;
  }

  function tarjetaVehiculo(d, vehiculos, seleccionado, docsPorTipo, alElegir) {
    const t = tarjeta(vehiculos.length > 1 ? 'Vehículos del conductor (' + vehiculos.length + ')' : 'Vehículo', 'fas fa-motorcycle');
    if (!vehiculos.length) {
      t.appendChild(el('p', 'vc-vacio', 'Sin vehículo registrado. Se registró antes de que se pidiera el vehículo en el registro.'));
      const dl = el('dl', 'vc-datos');
      dl.appendChild(fila('SOAT N.º', numeroODeclarado(d.soat)));
      dl.appendChild(fila('Tarjeta de propiedad N.º', numeroODeclarado(d.tarjeta)));
      t.appendChild(dl);
      return t;
    }
    if (vehiculos.length > 1) {
      t.appendChild(el('p', 'vc-nota', 'Solo uno está activo y lo elige el conductor.'));
      const tabs = el('div', 'vc-tabs');
      tabs.setAttribute('role', 'tablist');
      vehiculos.forEach((v) => {
        const b = el('button', 'vc-tab' + (v === seleccionado ? ' vc-tab--activa' : ''));
        b.type = 'button';
        b.setAttribute('role', 'tab');
        b.setAttribute('aria-selected', String(v === seleccionado));
        b.appendChild(el('strong', null, v.placa || 'Sin placa'));
        b.appendChild(el('span', null, [v.marca, v.modelo].filter(Boolean).join(' ')));
        b.appendChild(v.verificado ? (v.activo ? pill('En servicio', 'vc-pill--verde') : pill('Inactivo', 'vc-pill--gris'))
          : pill('En revisión', 'vc-pill--ambar'));
        b.addEventListener('click', () => alElegir(v));
        tabs.appendChild(b);
      });
      t.appendChild(tabs);
    }
    const placa = el('div', 'vc-placa', seleccionado.placa || '—');
    placa.setAttribute('aria-label', 'Placa ' + (seleccionado.placa || 'no registrada'));
    t.appendChild(placa);
    const dl = el('dl', 'vc-datos vc-datos--2');
    dl.appendChild(fila('Marca', seleccionado.marca));
    dl.appendChild(fila('Modelo', seleccionado.modelo));
    dl.appendChild(fila('Color', seleccionado.color));
    dl.appendChild(fila('Tecnomecánica N.º', docsPorTipo.TECNOMECANICA && docsPorTipo.TECNOMECANICA.numeroDeclarado));
    dl.appendChild(fila('SOAT N.º', (docsPorTipo.SOAT && docsPorTipo.SOAT.numeroDeclarado) || numeroODeclarado(d.soat)));
    dl.appendChild(fila('Tarjeta de propiedad N.º',
      (docsPorTipo.TARJETA_PROPIEDAD && docsPorTipo.TARJETA_PROPIEDAD.numeroDeclarado) || numeroODeclarado(d.tarjeta)));
    const estadoVehiculo = !seleccionado.verificado ? pill('En revisión', 'vc-pill--ambar')
      : (seleccionado.activo ? pill('Activo', 'vc-pill--verde') : pill('Inactivo', 'vc-pill--gris'));
    dl.appendChild(fila('Estado del vehículo', estadoVehiculo));
    dl.appendChild(fila('Registrado', seleccionado.fechaRegistro ? formatoFecha(seleccionado.fechaRegistro) : null));
    t.appendChild(dl);
    if (!seleccionado.verificado) {
      const b = el('button', 'vc-btn vc-btn--aprobar', 'Aprobar vehículo');
      b.type = 'button';
      b.addEventListener('click', async () => {
        b.disabled = true;
        try { await llamar('POST', 'vehiculos/' + encodeURIComponent(seleccionado.id) + '/aprobar'); refrescar(); }
        catch (e) { b.disabled = false; avisar(e.message); }
      });
      t.appendChild(b);
    }
    return t;
  }

  /* --- Documentos y validación cruzada --- */
  function tarjetaDocumentos(d, docsPorTipo, hayDocs) {
    const t = tarjeta('Documentos y validación cruzada', 'fas fa-file-shield');
    t.appendChild(el('p', 'vc-nota', 'El número registrado debe coincidir con el leído en la foto.'));
    const grid = el('div', 'vc-docs');
    DOCUMENTOS.forEach((def) => {
      const doc = docsPorTipo[def.tipo];
      const lectura = doc ? lecturas.get(doc.id) : null;
      const est = estadoDocumento(!!doc, lectura);
      const c = el('article', 'vc-doc');
      const foto = el('div', 'vc-doc-foto');
      if (doc) {
        const url = BASE + 'documentos/' + encodeURIComponent(doc.id) + '/archivo';
        const enlace = document.createElement('a');
        enlace.href = url; enlace.target = '_blank'; enlace.rel = 'noopener';
        enlace.setAttribute('aria-label', 'Abrir la foto de ' + def.rotulo);
        const img = document.createElement('img');
        img.src = url; img.loading = 'lazy'; img.alt = def.rotulo + ' de ' + d.nombre;
        enlace.appendChild(img);
        foto.appendChild(enlace);
      } else {
        foto.appendChild(icono('far fa-image'));
        foto.appendChild(el('span', null, 'Sin foto'));
      }
      c.appendChild(foto);
      c.appendChild(el('h5', null, def.rotulo));
      c.appendChild(el('small', 'vc-doc-ambito', def.ambito));
      const registrado = (doc && doc.numeroDeclarado)
        || (def.tipo === 'LICENCIA' ? numeroODeclarado(d.licencia) : def.tipo === 'SOAT' ? numeroODeclarado(d.soat)
          : def.tipo === 'TARJETA_PROPIEDAD' ? numeroODeclarado(d.tarjeta) : null);
      const dl = el('dl', 'vc-doc-num');
      dl.appendChild(fila('Número registrado', registrado));
      const leido = lectura ? (lectura.leido || 'Sin leer') : (doc ? 'Sin leer' : '—');
      dl.appendChild(fila('Leído en la foto', leido, lectura && lectura.resultado === 'DIFERENTE' ? 'vc-rojo' : null));
      c.appendChild(dl);
      c.appendChild(pill(est.texto, est.clase));
      if (doc) {
        const b = el('button', 'vc-btn vc-btn--suave', lectura ? 'Leer de nuevo' : 'Leer número de la foto');
        b.type = 'button';
        b.addEventListener('click', async () => {
          b.disabled = true; b.textContent = 'Leyendo…';
          try {
            lecturas.set(doc.id, await llamar('POST', 'documentos/' + encodeURIComponent(doc.id) + '/leer'));
            repintar();
          } catch (e) { b.disabled = false; b.textContent = 'Leer número de la foto'; avisar(e.message); }
        });
        c.appendChild(b);
      }
      grid.appendChild(c);
    });
    t.appendChild(grid);
    return t;
  }

  /* --- Información solicitada --- */
  function tarjetaInformacion(est, ejecutar) {
    const t = tarjeta('En revisión · información solicitada', 'fas fa-envelope-open-text');
    t.classList.add('vc-card--azul');
    t.appendChild(el('p', 'vc-etiqueta', 'Lo que falta'));
    const lista = el('ul', 'vc-lista');
    String(est.revisionMensaje || '—').split(/\n|;/).map((x) => x.trim()).filter(Boolean)
      .forEach((x) => lista.appendChild(el('li', null, x)));
    t.appendChild(lista);
    const dias = diasHasta(est.revisionPlazo, new Date());
    const plazo = el('div', 'vc-plazo');
    plazo.appendChild(el('span', null, 'Plazo de respuesta'));
    plazo.appendChild(el('span', dias != null && dias < 0 ? 'vc-rojo' : null,
      'Vence el ' + formatoFecha(est.revisionPlazo) + (dias == null ? '' : dias < 0 ? ' · vencido' : ' · quedan ' + dias + (dias === 1 ? ' día' : ' días'))));
    t.appendChild(plazo);
    const barra = el('div', 'vc-barra');
    barra.setAttribute('aria-hidden', 'true');
    const relleno = el('div', 'vc-barra-relleno');
    relleno.style.width = Math.round(avancePlazo(dias) * 100) + '%';
    barra.appendChild(relleno);
    t.appendChild(barra);
    t.appendChild(el('p', 'vc-alerta', 'Si el conductor no responde a tiempo, la solicitud se rechaza automáticamente y se le avisa por correo.'));
    const b = el('button', 'vc-btn vc-btn--suave', 'Marcar respuesta recibida');
    b.type = 'button';
    b.addEventListener('click', () => ejecutar(() => llamar('POST', 'info-recibida', { email: correoActual() }), true));
    t.appendChild(b);
    return t;
  }

  /* --- Verificación de datos --- */
  function fechaHora(v) {
    if (!v) return '';
    const f = new Date(v);
    return Number.isNaN(f.getTime()) ? '' : f.toLocaleString('es-CO', { dateStyle: 'medium', timeStyle: 'short' });
  }

  function tarjetaVerificacion(est, ejecutar, puedeActuar) {
    const t = tarjeta('Verificación de datos', 'fas fa-shield-halved');
    const cab = t.querySelector('.vc-card-cab');
    cab.appendChild(el('small', 'vc-fuente', 'Fuente configurada: ' + (est.proveedor || '—')));
    const u = est.ultimaVerificacion;
    const pastillas = el('div', 'vc-resultados');
    [['Placa', u && u.resultadoPlaca], ['Licencia', u && u.resultadoDocumento]].forEach(([rotulo, valor]) => {
      const e = estadoFuente(valor);
      const caja = el('div', 'vc-resultado');
      caja.appendChild(el('span', null, rotulo));
      caja.appendChild(pill(e.texto, e.clase));
      pastillas.appendChild(caja);
    });
    t.appendChild(pastillas);
    t.appendChild(el('p', 'vc-nota', 'Placa: ' + (est.placa || 'No registrada') + ' · Licencia: ' + (est.documentoEnmascarado || '—')));
    t.appendChild(el('p', 'vc-nota', u
      ? 'Última verificación: ' + (u.resultado || '') + ' · fuente ' + (u.fuente || '—') + ' · ' + fechaHora(u.fecha) + ' · ' + (u.adminEmail || '—')
      : 'Última verificación: sin registro'));
    if (est.decision) {
      const dec = est.decision;
      t.appendChild(el('p', 'vc-nota', 'Decisión: ' + dec.accion + ' · ' + (dec.adminEmail || '—') + ' · ' + fechaHora(dec.fecha)
        + (dec.motivo ? ' · Motivo: ' + dec.motivo : '')));
    }
    if (!puedeActuar) return t;

    const f1 = el('div', 'vc-form');
    const owner = el('input', 'vc-campo');
    owner.type = 'text'; owner.maxLength = 12; owner.setAttribute('aria-label', 'Documento del propietario');
    owner.placeholder = 'Documento del propietario (opcional, solo si la fuente lo exige)';
    const bv = el('button', 'vc-btn vc-btn--suave', 'Verificar con la fuente');
    bv.type = 'button';
    bv.addEventListener('click', () => ejecutar(() => llamar('POST', 'verificar',
      { email: correoActual(), ownerDocument: owner.value.trim() || null }), false));
    f1.append(owner, bv);

    const f2 = el('div', 'vc-form');
    const sel = el('select', 'vc-campo vc-campo--corto');
    sel.setAttribute('aria-label', 'Resultado de la revisión manual');
    [['VERIFIED', 'Verificado'], ['NOT_FOUND', 'No encontrado'], ['MISMATCH', 'No coincide']].forEach(([v, x]) => {
      const o = el('option', null, x); o.value = v; sel.appendChild(o);
    });
    const nota = el('input', 'vc-campo');
    nota.type = 'text'; nota.maxLength = 300; nota.setAttribute('aria-label', 'Nota de la revisión manual');
    nota.placeholder = 'Nota de la revisión manual (mín. 5 caracteres)';
    const bm = el('button', 'vc-btn vc-btn--suave', 'Marcar manualmente');
    bm.type = 'button';
    bm.addEventListener('click', () => ejecutar(() => llamar('POST', 'manual',
      { email: correoActual(), resultado: sel.value, nota: nota.value }), false));
    f2.append(sel, nota, bm);
    t.append(f1, f2);
    return t;
  }

  /* --- Pie con la decisión: aprobar, enviar a revisión o rechazar --- */
  function pie(ejecutar, enRevision) {
    const p = el('footer', 'vc-pie');
    const motivo = el('input', 'vc-campo');
    motivo.type = 'text'; motivo.maxLength = 300; motivo.setAttribute('aria-label', 'Motivo o información que falta');
    motivo.placeholder = 'Motivo o qué falta (obligatorio para revisión y rechazo)';
    const exigir = (texto) => {
      if (motivo.value.trim().length >= 5) return true;
      avisar(texto); motivo.focus(); return false;
    };
    const a = el('button', 'vc-btn vc-btn--aprobar', 'Aprobar');
    a.type = 'button';
    a.prepend(icono('fas fa-check'));
    a.addEventListener('click', () => ejecutar(() => llamar('POST', 'decision',
      { email: correoActual(), aprobar: true, motivo: motivo.value.trim() || null }), true));
    const v = el('button', 'vc-btn vc-btn--azul', enRevision ? 'Actualizar revisión' : 'Enviar a revisión');
    v.type = 'button';
    v.prepend(icono('fas fa-magnifying-glass'));
    v.addEventListener('click', () => {
      if (!exigir('Escribe qué información falta (mínimo 5 caracteres); se le envía al conductor por correo.')) return;
      ejecutar(() => llamar('POST', 'solicitar-info', { email: correoActual(), mensaje: motivo.value.trim() }), true);
    });
    const r = el('button', 'vc-btn vc-btn--rechazar', 'Rechazar');
    r.type = 'button';
    r.prepend(icono('fas fa-xmark'));
    r.addEventListener('click', () => {
      if (!exigir('Escribe el motivo del rechazo (mínimo 5 caracteres).')) return;
      ejecutar(() => llamar('POST', 'decision', { email: correoActual(), aprobar: false, motivo: motivo.value.trim() }), true);
    });
    p.append(motivo, a, v, r);
    return p;
  }

  function avisar(texto) {
    const m = document.getElementById('vc-mensaje');
    if (m) { m.textContent = texto; m.hidden = !texto; }
  }

  /* --- Armado --- */
  let vehiculoElegido = null;

  function pintar() {
    const cont = document.getElementById('vc-contenedor');
    if (!cont || !datosActuales) return;
    const { d, est, vehiculos, docs, avisoCarga } = datosActuales;
    const enRevision = est && est.estadoValidacion === 'EN_REVISION';
    const pendiente = est && (est.estadoValidacion === 'PENDIENTE' || enRevision);
    if (!vehiculoElegido || !vehiculos.includes(vehiculoElegido)) {
      vehiculoElegido = vehiculos.find((v) => v.activo) || vehiculos[0] || null;
    }
    const porTipo = documentosPorTipo(docs, vehiculoElegido, vehiculos.length <= 1);

    const ejecutar = async (accion, recargarPagina) => {
      avisar('');
      cont.querySelectorAll('button').forEach((b) => { b.disabled = true; });
      try {
        await accion();
        if (recargarPagina) { window.location.reload(); return; }
        await refrescar();
      } catch (e) {
        cont.querySelectorAll('button').forEach((b) => { b.disabled = false; });
        avisar(e.message);
      }
    };

    cont.replaceChildren(cabecera(d, est));
    const cuerpo = el('div', 'vc-cuerpo');
    const dos = el('div', 'vc-dos');
    dos.appendChild(tarjetaConductor(d, est));
    dos.appendChild(tarjetaVehiculo(d, vehiculos, vehiculoElegido, porTipo, (v) => { vehiculoElegido = v; pintar(); }));
    cuerpo.appendChild(dos);

    if (esConductorAntiguo(vehiculos, docs)) {
      const aviso = el('div', 'vc-aviso');
      aviso.appendChild(icono('fas fa-circle-info'));
      aviso.appendChild(el('p', null, 'Este conductor se registró antes de que se pidieran el vehículo y las fotos de los documentos, por eso no hay nada que '
        + 'contrastar. Usa "Enviar a revisión" para pedirle que los suba; mientras tanto solo se pueden revisar los números que dio.'));
      cuerpo.appendChild(aviso);
    }
    if (avisoCarga) cuerpo.appendChild(el('p', 'vc-alerta', avisoCarga));

    cuerpo.appendChild(tarjetaDocumentos(d, porTipo, docs.length > 0));
    if (est) {
      if (enRevision) cuerpo.appendChild(tarjetaInformacion(est, ejecutar));
      cuerpo.appendChild(tarjetaVerificacion(est, ejecutar, pendiente));
    }
    const msg = el('p', 'vc-mensaje');
    msg.id = 'vc-mensaje'; msg.hidden = true; msg.setAttribute('role', 'alert');
    cuerpo.appendChild(msg);
    cont.appendChild(cuerpo);
    if (pendiente) cont.appendChild(pie(ejecutar, enRevision));
  }

  function repintar() { pintar(); }

  async function refrescar() {
    if (!datosActuales) return;
    await cargar(datosActuales.d);
  }

  async function cargar(d) {
    const q = '?email=' + encodeURIComponent(d.email);
    const [est, vehs, docs] = await Promise.allSettled([
      llamar('GET', 'estado' + q), llamar('GET', 'vehiculos' + q), llamar('GET', 'documentos' + q),
    ]);
    const cont = document.getElementById('vc-contenedor');
    if (est.status === 'rejected') {
      cont.replaceChildren(cabecera(d, null), el('p', 'vc-alerta', est.reason.message || 'No se pudo cargar la verificación'));
      return;
    }
    datosActuales = {
      d,
      est: est.value,
      vehiculos: vehs.status === 'fulfilled' ? vehs.value : [],
      docs: docs.status === 'fulfilled' ? docs.value : [],
      avisoCarga: vehs.status === 'rejected' || docs.status === 'rejected'
        ? 'No se pudieron cargar los vehículos o documentos. Recarga para intentarlo de nuevo.' : null,
    };
    pintar();
  }

  /** Abre la ficha. {@code d} = {nombre, email, telefono, licencia, soat, tarjeta, estado} (de la fila de la tabla). */
  function abrir(d) {
    const modal = document.getElementById('infoModal');
    const cont = document.getElementById('vc-contenedor');
    if (!modal || !cont) return;
    lecturas = new Map();
    vehiculoElegido = null;
    datosActuales = null;
    cont.replaceChildren(cabecera(d, null), el('p', 'vc-cargando', 'Cargando la verificación…'));
    modal.style.display = 'flex';
    document.body.style.overflow = 'hidden';
    cargar(d);
  }

  return {
    estadoConductor, estadoDocumento, estadoFuente, formatoFecha, diasHasta, avancePlazo,
    documentosPorTipo, esConductorAntiguo, abrir,
  };
});
