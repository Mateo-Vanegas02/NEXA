// NEXA — Correcciones de datos aprobadas por el propietario en fase 3.2 (17 de noviembre de 2026).
//
//   1. Viajes EN_CURSO atascados hace más de 24 h → CANCELADO por el SISTEMA, sin cargo.
//   2. Campos antiguos del token de recuperación en texto claro → se borran ($unset).
//   3. Colecciones sin uso (Servicio, Vehiculo, creditos_nexa, beneficios_uso, ModeloInfo) → se archivan
//      renombrándolas a archivo_20261117_<nombre> (reversible: MODO="revertir-archivo").
//
// SOLO después del respaldo verificado (docs/auditoria/FASE3_2_INDICES_Y_RESPALDO.md, 5.2–5.3).
// MODO="plan" (por defecto) solo cuenta; MODO="aplicar" escribe. En motvirsweb exige PRODUCCION_APROBADA="AAAA-MM-DD".
// No imprime ids, correos ni nombres: solo cifras.
//
//   mongosh "<uri>" --username <usuario-con-escritura> --file scripts/atlas/correcciones-datos-fase3-2.js
//   (para aplicar, con --eval antes del --file: var MODO="aplicar"; var PRODUCCION_APROBADA="AAAA-MM-DD")

/* global db, BASE, MODO, PRODUCCION_APROBADA, EJSON, NumberLong */
(function () {
  'use strict';
  const nombreBase = (typeof BASE === 'string' && BASE) ? BASE : 'motvirsweb';
  const modo = (typeof MODO === 'string' && MODO) ? MODO : 'plan';
  const base = db.getSiblingDB(nombreBase);
  if (!['plan', 'aplicar', 'revertir-archivo'].includes(modo)) {
    throw new Error('MODO debe ser plan, aplicar o revertir-archivo');
  }
  if (modo !== 'plan' && nombreBase === 'motvirsweb'
      && !(typeof PRODUCCION_APROBADA === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(PRODUCCION_APROBADA))) {
    throw new Error('Producción: se requiere PRODUCCION_APROBADA="AAAA-MM-DD" (fecha del respaldo verificado)');
  }

  const ahora = new Date();
  const informe = { base: nombreBase, modo: modo, fecha: ahora.toISOString() };
  const colecciones = () => base.getCollectionNames();

  // ─────────────── 1. Viajes EN_CURSO atascados ───────────────
  const atascados = { estado: 'EN_CURSO', fechaAceptacion: { $lt: new Date(ahora.getTime() - 24 * 3600 * 1000) } };
  const horas = base.servicios.find(atascados, { _id: 0, fechaAceptacion: 1 }).toArray()
    .map((v) => Math.round((ahora - v.fechaAceptacion) / 36e5));
  informe.viajesAtascados = { encontrados: horas.length, horasDesdeLaAceptacion: horas.sort((a, b) => a - b) };
  if (modo === 'aplicar' && horas.length > 0) {
    const r = base.servicios.updateMany(atascados, { $set: {
      estado: 'CANCELADO', canceladoPor: 'SISTEMA', fechaCancelacion: ahora,
      cargoCancelacion: NumberLong('0'), cargoAcreditadoConductor: false,
      cancelacionAdministrativa: { fecha: ahora, motivo: 'Viaje EN_CURSO atascado más de 24 h; cancelado sin cargo (fase 3.2)' },
    } });
    informe.viajesAtascados.cancelados = r.modifiedCount;
  }

  // ─────────────── 2. Token de recuperación antiguo en texto claro ───────────────
  const camposAntiguos = ['resetPasswordToken', 'resetPasswordTokenExpiry', 'usuario_reset_password_token'];
  const conAntiguo = { $or: camposAntiguos.map((c) => ({ [c]: { $exists: true } })) };
  // El vencimiento con el nombre actual solo se borra si la cuenta no tiene un token vigente con el formato nuevo
  const vencimientoHuerfano = { usuario_reset_password_token_expiry: { $exists: true },
    $or: [{ usuario_reset_password_token_hash: { $exists: false } }, { usuario_reset_password_token_hash: null }] };
  informe.tokensAntiguos = {
    cuentasConCampoAntiguo: base.Usuarios.countDocuments(conAntiguo),
    vencimientosSinToken: base.Usuarios.countDocuments(vencimientoHuerfano),
  };
  if (modo === 'aplicar') {
    const unset = {};
    camposAntiguos.forEach((c) => { unset[c] = ''; });
    informe.tokensAntiguos.cuentasLimpiadas = base.Usuarios.updateMany(conAntiguo, { $unset: unset }).modifiedCount;
    informe.tokensAntiguos.vencimientosBorrados = base.Usuarios.updateMany(vencimientoHuerfano,
      { $unset: { usuario_reset_password_token_expiry: '' } }).modifiedCount;
  }

  // ─────────────── 3. Archivar colecciones sin uso ───────────────
  const sinUso = ['Servicio', 'Vehiculo', 'creditos_nexa', 'beneficios_uso', 'ModeloInfo'];
  const archivo = (c) => 'archivo_20261117_' + c;
  informe.archivo = sinUso.map((c) => {
    const existentes = colecciones();
    const fila = { coleccion: c, destino: archivo(c) };
    if (modo === 'revertir-archivo') {
      if (existentes.includes(archivo(c)) && !existentes.includes(c)) {
        base.getCollection(archivo(c)).renameCollection(c);
        fila.accion = 'restaurada';
      } else {
        fila.accion = 'sin cambios';
      }
      return fila;
    }
    if (!existentes.includes(c)) {
      fila.accion = existentes.includes(archivo(c)) ? 'ya archivada' : 'no existe';
      return fila;
    }
    fila.documentos = base.getCollection(c).countDocuments({});
    if (existentes.includes(archivo(c))) {
      fila.accion = 'NO se archiva: el destino ya existe';
    } else if (modo === 'aplicar') {
      base.getCollection(c).renameCollection(archivo(c));
      fila.accion = 'archivada';
    } else {
      fila.accion = 'se archivaría';
    }
    return fila;
  });

  print(EJSON.stringify(informe, null, 2, { relaxed: true }));
})();
