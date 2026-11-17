// NEXA — Índices propuestos en fase 3.2 (ver docs/auditoria/FASE3_2_INDICES_Y_RESPALDO.md).
//
// Por defecto NO crea nada: solo muestra el plan (MODO="plan"). Para crear sobre la COPIA restaurada:
//   mongosh "<uri-de-la-copia>" --eval 'var BASE="motvirsweb_copia"; var MODO="crear"' --file scripts/atlas/indices-propuestos.js
// Para revertir (borra solo los índices de esta lista):
//   mongosh "<uri>" --eval 'var BASE="motvirsweb_copia"; var MODO="revertir"' --file scripts/atlas/indices-propuestos.js
// Sobre la base de producción (motvirsweb) se niega salvo que se pase también PRODUCCION_APROBADA="<fecha del respaldo verificado>".
// Antes de crear un índice único comprueba que no haya duplicados; si los hay, no lo crea y lo informa.

/* global db, BASE, MODO, PRODUCCION_APROBADA, EJSON */
(function () {
  'use strict';
  const nombreBase = (typeof BASE === 'string' && BASE) ? BASE : 'motvirsweb';
  const modo = (typeof MODO === 'string' && MODO) ? MODO : 'plan';
  const base = db.getSiblingDB(nombreBase);
  if (!['plan', 'crear', 'revertir'].includes(modo)) throw new Error('MODO debe ser plan, crear o revertir');
  if (modo !== 'plan' && nombreBase === 'motvirsweb'
      && !(typeof PRODUCCION_APROBADA === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(PRODUCCION_APROBADA))) {
    throw new Error('Producción: se requiere PRODUCCION_APROBADA="AAAA-MM-DD" (fecha del respaldo verificado)');
  }

  const conductorConValor = (campo) => ({ rol: 'CONDUCTOR', [campo]: { $gt: 0 } });
  // Orden: primero los que no pueden fallar (no únicos), luego los únicos con su verificación previa.
  const propuestos = [
    { id: 'I1', col: 'servicios', nombre: 'estado_fechaFinalizacion', clave: { estado: 1, fechaFinalizacion: 1 }, opciones: {} },
    { id: 'I2', col: 'servicios', nombre: 'pasajero_estado', clave: { 'pasajero._id': 1, estado: 1 }, opciones: {} },
    { id: 'I3', col: 'servicios', nombre: 'conductor_estado', clave: { 'conductor._id': 1, estado: 1 }, opciones: {} },
    { id: 'I4', col: 'Usuarios', nombre: 'email', clave: { email: 1 }, opciones: {} },
    { id: 'I5', col: 'Usuarios', nombre: 'licencia_conductor_unica', clave: { licencia: 1 },
      opciones: { unique: true, partialFilterExpression: conductorConValor('licencia') } },
    { id: 'I6', col: 'Usuarios', nombre: 'soat_conductor_unico', clave: { soat: 1 },
      opciones: { unique: true, partialFilterExpression: conductorConValor('soat') } },
    { id: 'I7', col: 'Usuarios', nombre: 'tarjeta_conductor_unica', clave: { tarjeta_de_propiedad: 1 },
      opciones: { unique: true, partialFilterExpression: conductorConValor('tarjeta_de_propiedad') } },
    { id: 'I8', col: 'avisos_viaje_pendientes', nombre: 'estado_proximoIntento', clave: { estado: 1, proximoIntento: 1 }, opciones: {} },
    { id: 'I9', col: 'avisos_viaje_pendientes', nombre: 'ttl_enviadoEn', clave: { enviadoEn: 1 },
      opciones: { expireAfterSeconds: 7 * 24 * 3600 } },
  ];

  const duplicadosDe = (p) => {
    const filtro = (p.opciones.partialFilterExpression) || {};
    const campos = Object.keys(p.clave);
    const grupo = {};
    campos.forEach((c) => { grupo[c.replace(/\./g, '_')] = '$' + c; });
    const r = base.getCollection(p.col).aggregate([
      { $match: filtro }, { $group: { _id: grupo, n: { $sum: 1 } } }, { $match: { n: { $gt: 1 } } }, { $count: 'grupos' },
    ]).toArray();
    return r.length ? r[0].grupos : 0;
  };

  const informe = { base: nombreBase, modo: modo, resultados: [] };
  propuestos.forEach((p) => {
    let existentes = [];
    try { existentes = base.getCollection(p.col).getIndexes().map((i) => i.name); } catch (e) { /* colección aún no existe */ }
    const fila = { id: p.id, coleccion: p.col, nombre: p.nombre, clave: p.clave, unico: Boolean(p.opciones.unique) };
    if (modo === 'revertir') {
      if (existentes.includes(p.nombre)) { base.getCollection(p.col).dropIndex(p.nombre); fila.accion = 'borrado'; }
      else fila.accion = 'no existía';
    } else {
      const dup = p.opciones.unique ? duplicadosDe(p) : 0;
      fila.duplicadosQueLoImpiden = dup;
      if (existentes.includes(p.nombre)) fila.accion = 'ya existe';
      else if (dup > 0) fila.accion = 'NO se crea: hay duplicados (resolver antes)';
      else if (modo === 'plan') fila.accion = 'se crearía';
      else { base.getCollection(p.col).createIndex(p.clave, Object.assign({ name: p.nombre }, p.opciones)); fila.accion = 'creado'; }
    }
    informe.resultados.push(fila);
  });
  print(EJSON.stringify(informe, null, 2, { relaxed: true }));
})();
