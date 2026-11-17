// NEXA — Inspección de MongoDB en SOLO LECTURA (fase 3.2).
//
// Qué hace: lee la versión y topología del servidor, los índices reales de cada colección y estadísticas
// AGREGADAS (conteos, tipos BSON, grupos duplicados) de Usuarios, servicios y las colecciones de soporte.
// Qué NO hace: no escribe, no crea ni borra índices, no imprime correos, nombres, teléfonos, números de documento,
// tokens ni ids. Solo usa find/aggregate/count/getIndexes/explain y comandos de diagnóstico.
//
// Cómo ejecutarlo (con un usuario de Atlas que solo tenga el rol "read" sobre la base):
//   mongosh "mongodb+srv://<cluster>/" --username <usuario-lectura> \
//     --eval 'var BASE="motvirsweb"' --file scripts/atlas/inspeccion-solo-lectura.js > inspeccion.json
// La salida es un único JSON. Revísalo antes de compartirlo (no debería contener datos personales).

/* global db, BASE, printjson, EJSON */
(function () {
  'use strict';
  const nombreBase = (typeof BASE === 'string' && BASE) ? BASE : 'motvirsweb';
  const base = db.getSiblingDB(nombreBase);
  // Lecturas desde un secundario si existe: no carga al primario de producción.
  try { db.getMongo().setReadPref('secondaryPreferred'); } catch (e) { /* conexión directa */ }

  const salida = { base: nombreBase, generadoEn: new Date().toISOString(), soloLectura: true };
  const agregar = (col, pipeline) => base.getCollection(col).aggregate(pipeline, { allowDiskUse: false }).toArray();
  const contar = (col, filtro) => base.getCollection(col).countDocuments(filtro || {});
  const existe = (col) => base.getCollectionNames().includes(col);

  // Conteo de valores por tipo BSON de un campo (incluye "ausente").
  const tipos = (col, campo, filtro) => {
    const r = {};
    agregar(col, [
      { $match: filtro || {} },
      { $group: { _id: { $type: '$' + campo }, n: { $sum: 1 } } },
    ]).forEach((g) => { r[g._id] = g.n; });
    return r;
  };

  // Grupos con el mismo valor (normalizado) en uno o varios campos: SOLO cuántos grupos y cuántos documentos.
  const duplicados = (col, clave, filtro) => {
    const g = agregar(col, [
      { $match: filtro || {} },
      { $group: { _id: clave, n: { $sum: 1 } } },
      { $match: { n: { $gt: 1 } } },
      { $group: { _id: null, grupos: { $sum: 1 }, documentos: { $sum: '$n' }, mayorGrupo: { $max: '$n' } } },
    ]);
    return g.length ? { grupos: g[0].grupos, documentos: g[0].documentos, mayorGrupo: g[0].mayorGrupo }
      : { grupos: 0, documentos: 0, mayorGrupo: 0 };
  };

  const porValor = (col, campo, filtro) => {
    const r = {};
    agregar(col, [{ $match: filtro || {} }, { $group: { _id: '$' + campo, n: { $sum: 1 } } }, { $sort: { n: -1 } }])
      .forEach((g) => { r[g._id === null || g._id === undefined ? '(ausente/null)' : String(g._id)] = g.n; });
    return r;
  };

  // Resumen de un plan de ejecución sin documentos (solo etapas y cifras).
  const plan = (col, filtro, orden) => {
    try {
      let cursor = base.getCollection(col).find(filtro);
      if (orden) cursor = cursor.sort(orden);
      const e = cursor.limit(50).explain('executionStats');
      const etapas = [];
      let nodo = e.queryPlanner && e.queryPlanner.winningPlan;
      while (nodo) {
        // En MongoDB 7 (motor SBE) el plan puede venir envuelto en "queryPlan"
        if (nodo.stage) etapas.push(nodo.stage + (nodo.indexName ? '(' + nodo.indexName + ')' : ''));
        nodo = nodo.queryPlan || nodo.inputStage || (nodo.inputStages && nodo.inputStages[0]) || null;
      }
      const s = e.executionStats || {};
      return { etapas: etapas, devueltos: s.nReturned, docsExaminados: s.totalDocsExamined,
        clavesExaminadas: s.totalKeysExamined, ms: s.executionTimeMillis };
    } catch (err) {
      return { error: err.codeName || String(err.message || err).slice(0, 120) };
    }
  };

  // ─────────────── Servidor ───────────────
  const hola = db.getSiblingDB('admin').runCommand({ hello: 1 });
  salida.servidor = {
    version: db.version(),
    replicaSet: hola.setName || null,
    esMongos: hola.msg === 'isdbgrid',
    // Las transacciones que usa la app exigen replica set o mongos.
    admiteTransacciones: Boolean(hola.setName) || hola.msg === 'isdbgrid',
    nodos: (hola.hosts || []).length,
    logicalSessionTimeoutMinutes: hola.logicalSessionTimeoutMinutes,
  };

  // ─────────────── Colecciones e índices ───────────────
  salida.colecciones = {};
  base.getCollectionInfos({ type: 'collection' }).forEach((info) => {
    const col = info.name;
    salida.colecciones[col] = {
      documentosAprox: base.getCollection(col).estimatedDocumentCount(),
      indices: base.getCollection(col).getIndexes().map((i) => ({
        nombre: i.name, clave: i.key, unico: Boolean(i.unique),
        parcial: i.partialFilterExpression || null, ttlSegundos: i.expireAfterSeconds === undefined ? null : i.expireAfterSeconds,
      })),
    };
  });

  // ─────────────── Usuarios ───────────────
  if (existe('Usuarios')) {
    const U = 'Usuarios';
    const conductor = { rol: 'CONDUCTOR' };
    const correoNormalizado = { $toLower: { $trim: { input: { $ifNull: ['$email', ''] } } } };
    const dupCorreo = (filtro) => duplicados(U, correoNormalizado, Object.assign({ email: { $type: 'string', $ne: '' } }, filtro || {}));
    // Duplicados de correo que cruzan roles (el login por correo no puede elegir cuenta).
    const cruzados = agregar(U, [
      { $match: { email: { $type: 'string', $ne: '' } } },
      { $group: { _id: correoNormalizado, roles: { $addToSet: '$rol' }, n: { $sum: 1 } } },
      { $match: { n: { $gt: 1 } } },
      { $project: { distintosRoles: { $gt: [{ $size: '$roles' }, 1] } } },
      { $group: { _id: '$distintosRoles', grupos: { $sum: 1 } } },
    ]);
    const documento = (campo) => ({
      tipos: tipos(U, campo, conductor),
      cero: contar(U, Object.assign({ [campo]: 0 }, conductor)),
      duplicadosMayoresQueCero: duplicados(U, '$' + campo, Object.assign({ [campo]: { $gt: 0 } }, conductor)),
      presenteEnNoConductores: contar(U, { rol: { $ne: 'CONDUCTOR' }, [campo]: { $exists: true } }),
    });
    salida.usuarios = {
      porRol: porValor(U, 'rol'),
      porClase: porValor(U, '_class'),
      conductoresPorEstado: porValor(U, 'estadoValidacion', conductor),
      email: {
        tipos: tipos(U, 'email'),
        vacioONulo: contar(U, { $or: [{ email: null }, { email: '' }] }),
        conMayusculasOEspacios: contar(U, { email: { $type: 'string', $regex: /[A-Z]|^\s|\s$/ } }),
        duplicadosExactos: duplicados(U, '$email', { email: { $type: 'string', $ne: '' } }),
        duplicadosNormalizados: dupCorreo(),
        duplicadosNormalizadosMismoRol: duplicados(U, { e: correoNormalizado, r: '$rol' }, { email: { $type: 'string', $ne: '' } }),
        gruposQueCruzanRoles: (cruzados.find((g) => g._id === true) || { grupos: 0 }).grupos,
      },
      licencia: documento('licencia'),
      soat: documento('soat'),
      tarjeta_de_propiedad: documento('tarjeta_de_propiedad'),
      recuperacion: {
        conHashDeToken: contar(U, { usuario_reset_password_token_hash: { $exists: true, $ne: null } }),
        conTokenVencido: contar(U, { usuario_reset_password_token_expiry: { $lt: new Date() } }),
        // Formato antiguo en texto plano (debería ser 0)
        conTokenAntiguoEnClaro: contar(U, { $or: [{ resetPasswordToken: { $exists: true } }, { usuario_reset_password_token: { $exists: true } }] }),
      },
      deuda: {
        conDeuda: contar(U, { deuda: { $exists: true } }),
        tiposMonto: tipos(U, 'deuda.monto', { deuda: { $exists: true } }),
      },
    };
  }

  // ─────────────── servicios ───────────────
  if (existe('servicios')) {
    const S = 'servicios';
    const haceUnDia = new Date(Date.now() - 24 * 3600 * 1000);
    salida.servicios = {
      porEstado: porValor(S, 'estado'),
      porCanal: porValor(S, 'canal'),
      tipos: {
        'pasajero._id': tipos(S, 'pasajero._id'),
        'conductor._id': tipos(S, 'conductor._id'),
        fechaHora: tipos(S, 'fechaHora'),
        solicitadoEn: tipos(S, 'solicitadoEn'),
        fechaFinalizacion: tipos(S, 'fechaFinalizacion', { estado: 'FINALIZADO' }),
        tarifa: tipos(S, 'tarifa'),
        cargoCancelacion: tipos(S, 'cargoCancelacion'),
      },
      abiertos: {
        solicitados: contar(S, { estado: 'SOLICITADO' }),
        solicitadosDeMasDeUnDia: contar(S, { estado: 'SOLICITADO', solicitadoEn: { $lt: haceUnDia } }),
        aceptadosOEnCursoDeMasDeUnDia: contar(S, { estado: { $in: ['ACEPTADO', 'EN_CURSO'] }, fechaAceptacion: { $lt: haceUnDia } }),
        finalizadosSinFechaFinalizacion: contar(S, { estado: 'FINALIZADO', fechaFinalizacion: null }),
        finalizadosSinDesgloseDefinitivo: contar(S, { estado: 'FINALIZADO', solicitadoEn: { $ne: null }, 'desglose.definitivo': { $ne: true } }),
      },
      cargos: {
        conCargo: contar(S, { cargoCancelacion: { $gt: 0 } }),
        pagados: contar(S, { cargoCancelacion: { $gt: 0 }, cargoPagadoEn: { $ne: null } }),
        condonados: contar(S, { cargoCancelacion: { $gt: 0 }, cargoCondonadoEn: { $ne: null } }),
        pagadosYCondonados: contar(S, { cargoPagadoEn: { $ne: null }, cargoCondonadoEn: { $ne: null } }),
        abiertos: contar(S, { cargoCancelacion: { $gt: 0 }, cargoPagadoEn: null, cargoCondonadoEn: null }),
      },
      calificaciones: {
        alConductor: contar(S, { calificacionConductor: { $ne: null } }),
        alPasajero: contar(S, { calificacionPasajero: { $ne: null } }),
        marcaRegistradaConductor: contar(S, { calificacionConductorRegistrada: true }),
      },
      // Pasajeros con más de un viaje SOLICITADO a la vez (la regla dice máximo uno)
      pasajerosConVariasSolicitudes: duplicados(S, '$pasajero._id', { estado: 'SOLICITADO' }).grupos,
      conductoresConVariosViajesActivos: duplicados(S, '$conductor._id', { estado: { $in: ['ACEPTADO', 'EN_CURSO'] } }).grupos,
    };

    // Coherencia deuda ↔ cargo: la deuda del pasajero debe apuntar a un viaje cancelado con cargo abierto.
    if (existe('Usuarios')) {
      const r = agregar('Usuarios', [
        { $match: { deuda: { $exists: true } } },
        { $project: { sid: { $convert: { input: '$deuda.servicioId', to: 'objectId', onError: null, onNull: null } } } },
        { $lookup: { from: 'servicios', localField: 'sid', foreignField: '_id', as: 's' } },
        { $project: { estado: {
          $switch: { branches: [
            { case: { $eq: [{ $size: '$s' }, 0] }, then: 'viajeNoEncontrado' },
            { case: { $ne: [{ $arrayElemAt: ['$s.cargoPagadoEn', 0] }, null] }, then: 'cargoYaPagado' },
            { case: { $ne: [{ $arrayElemAt: ['$s.cargoCondonadoEn', 0] }, null] }, then: 'cargoYaCondonado' },
          ], default: 'coherente' } } } },
        { $group: { _id: '$estado', n: { $sum: 1 } } },
      ]);
      salida.coherenciaDeuda = {};
      r.forEach((g) => { salida.coherenciaDeuda[g._id] = g.n; });
    }

    // Planes de las consultas más frecuentes del código (ver docs/auditoria/FASE3_2_INDICES.md)
    const unPasajero = agregar(S, [{ $match: { 'pasajero._id': { $type: 'objectId' } } }, { $sample: { size: 1 } }, { $project: { _id: 0, p: '$pasajero._id' } }]);
    const unConductor = agregar(S, [{ $match: { 'conductor._id': { $type: 'objectId' } } }, { $sample: { size: 1 } }, { $project: { _id: 0, c: '$conductor._id' } }]);
    const p = unPasajero.length ? unPasajero[0].p : null;
    const c = unConductor.length ? unConductor[0].c : null;
    salida.planes = {
      'S1 findByEstado(SOLICITADO)': plan(S, { estado: 'SOLICITADO' }),
      'S2 existsByPasajeroIdAndEstadoIn': p ? plan(S, { 'pasajero._id': p, estado: { $in: ['SOLICITADO', 'ACEPTADO', 'EN_CURSO'] } }) : 'sin datos',
      'S3 findByConductorIdAndEstado': c ? plan(S, { 'conductor._id': c, estado: 'FINALIZADO' }) : 'sin datos',
      'S4 findResumenDeCalidad': c ? plan(S, { 'conductor._id': c, fechaHora: { $gt: new Date(Date.now() - 90 * 864e5) } }) : 'sin datos',
      'S5 historial de cargos del pasajero': p ? plan(S, { 'pasajero._id': p, cargoCancelacion: { $gt: 0 } }, { fechaCancelacion: -1 }) : 'sin datos',
      'S6 findPendientesDeNiveles': plan(S, { estado: 'FINALIZADO', solicitadoEn: { $ne: null }, 'desglose.definitivo': { $ne: true },
        fechaFinalizacion: { $gt: new Date(Date.now() - 7 * 864e5), $lt: new Date() } }),
      'S7 metricasDespachoDesde': plan(S, { solicitadoEn: { $gte: new Date(Date.now() - 30 * 864e5) } }),
      'S8 pagadas/condonadas (admin)': plan(S, { cargoPagadoEn: { $gte: new Date(Date.now() - 30 * 864e5) } }, { cargoPagadoEn: -1 }),
      'U1 findByEmail': plan('Usuarios', { email: '__consulta_sintetica__@example.invalid' }),
      'U2 listarDeudores': plan('Usuarios', { deuda: { $exists: true } }),
    };
  }

  // ─────────────── Colecciones de soporte ───────────────
  if (existe('xp_eventos')) {
    salida.xp_eventos = {
      // Prerrequisito del índice único (viajeId, rol, motivo) que hace idempotente el XP
      duplicadosViajeRolMotivo: duplicados('xp_eventos', { v: '$viajeId', r: '$rol', m: '$motivo' }),
      sinAplicar: contar('xp_eventos', { aplicado: false }),
    };
  }
  if (existe('dispositivos')) {
    salida.dispositivos = { duplicadosDeToken: duplicados('dispositivos', '$token') };
  }
  if (existe('acciones_idempotentes')) {
    salida.acciones_idempotentes = { total: contar('acciones_idempotentes') };
  }
  if (existe('avisos_viaje_pendientes')) {
    salida.avisos_viaje_pendientes = { porEstado: porValor('avisos_viaje_pendientes', 'estado') };
  }

  print(EJSON.stringify(salida, null, 2, { relaxed: true }));
})();
