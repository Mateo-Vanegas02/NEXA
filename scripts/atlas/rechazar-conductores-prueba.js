// NEXA — Rechazar cuentas de conductor de PRUEBA que comparten tarjeta de propiedad (fase 3.2, 17 nov 2026).
//
// Decisión del propietario: los dos conductores con la tarjeta repetida son cuentas de prueba → RECHAZADO.
// Además se les quita la tarjeta (el índice único I7 cuenta a todo conductor, aprobado o no, y así el número
// queda libre para un conductor real). Su historial (viajes, XP, calificaciones, vehículo) no se toca.
// El estado y la tarjeta anteriores se guardan en `rechazoAdministrativo` para poder revertir.
//
// Uso (ids separados por coma, tomados del diagnóstico con MOSTRAR_IDS):
//   plan:      --eval "var CONDUCTORES='id1,id2'"
//   aplicar:   --eval "var CONDUCTORES='id1,id2'; var MODO='aplicar'; var PRODUCCION_APROBADA='AAAA-MM-DD'"
//   revertir:  --eval "var CONDUCTORES='id1,id2'; var MODO='revertir'; var PRODUCCION_APROBADA='AAAA-MM-DD'"
// Se niega si algún id no es un conductor o si no comparten todos la misma tarjeta.

/* global db, BASE, MODO, CONDUCTORES, PRODUCCION_APROBADA, EJSON, ObjectId */
(function () {
  'use strict';
  const nombreBase = (typeof BASE === 'string' && BASE) ? BASE : 'motvirsweb';
  const modo = (typeof MODO === 'string' && MODO) ? MODO : 'plan';
  const base = db.getSiblingDB(nombreBase);
  if (!['plan', 'aplicar', 'revertir'].includes(modo)) throw new Error('MODO debe ser plan, aplicar o revertir');
  if (modo !== 'plan' && nombreBase === 'motvirsweb'
      && !(typeof PRODUCCION_APROBADA === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(PRODUCCION_APROBADA))) {
    throw new Error('Producción: se requiere PRODUCCION_APROBADA="AAAA-MM-DD" (fecha del respaldo verificado)');
  }
  if (typeof CONDUCTORES !== 'string' || !CONDUCTORES.trim()) throw new Error('Falta CONDUCTORES="id1,id2"');
  const ids = CONDUCTORES.split(',').map((s) => s.trim()).filter((s) => s).map((s) => new ObjectId(s));
  if (ids.length < 2) throw new Error('Se esperan al menos dos ids');

  const docs = base.Usuarios.find({ _id: { $in: ids } },
    { rol: 1, estadoValidacion: 1, tarjeta_de_propiedad: 1, rechazoAdministrativo: 1 }).toArray();
  if (docs.length !== ids.length || docs.some((d) => d.rol !== 'CONDUCTOR')) {
    throw new Error('Algún id no existe o no es un conductor; no se hace nada');
  }
  const informe = { base: nombreBase, modo: modo, conductores: ids.length };
  const ahora = new Date();

  if (modo === 'revertir') {
    let restaurados = 0;
    docs.filter((d) => d.rechazoAdministrativo && d.rechazoAdministrativo.motivo === 'CUENTA_DE_PRUEBA').forEach((d) => {
      const r = d.rechazoAdministrativo;
      const set = { estadoValidacion: r.estadoAnterior };
      if (r.tarjetaAnterior !== undefined && r.tarjetaAnterior !== null) set.tarjeta_de_propiedad = r.tarjetaAnterior;
      restaurados += base.Usuarios.updateOne({ _id: d._id, estadoValidacion: 'RECHAZADO' },
        { $set: set, $unset: { rechazoAdministrativo: '' } }).modifiedCount;
    });
    informe.restaurados = restaurados;
    print(EJSON.stringify(informe, null, 2, { relaxed: true }));
    return;
  }

  const pendientes = docs.filter((d) => !(d.rechazoAdministrativo && d.rechazoAdministrativo.motivo === 'CUENTA_DE_PRUEBA'));
  const tarjetas = new Set(pendientes.map((d) => String(d.tarjeta_de_propiedad)));
  if (pendientes.length > 0 && (pendientes.length !== docs.length || tarjetas.size !== 1)) {
    throw new Error('Los conductores indicados no comparten la misma tarjeta; no se hace nada');
  }
  informe.estadosActuales = docs.map((d) => d.estadoValidacion).sort();
  informe.porRechazar = pendientes.length;

  if (modo === 'aplicar' && pendientes.length > 0) {
    let rechazados = 0;
    pendientes.forEach((d) => {
      rechazados += base.Usuarios.updateOne({ _id: d._id, rol: 'CONDUCTOR', rechazoAdministrativo: { $exists: false } }, {
        $set: { estadoValidacion: 'RECHAZADO', rechazoAdministrativo: {
          motivo: 'CUENTA_DE_PRUEBA', fecha: ahora, estadoAnterior: d.estadoValidacion,
          tarjetaAnterior: d.tarjeta_de_propiedad === undefined ? null : d.tarjeta_de_propiedad,
          nota: 'Cuenta de prueba con tarjeta repetida; rechazada y tarjeta liberada (fase 3.2)' } },
        $unset: { tarjeta_de_propiedad: '' },
      }).modifiedCount;
    });
    informe.rechazados = rechazados;
  }

  const repetidas = base.Usuarios.aggregate([
    { $match: { rol: 'CONDUCTOR', tarjeta_de_propiedad: { $gt: 0 } } },
    { $group: { _id: '$tarjeta_de_propiedad', n: { $sum: 1 } } }, { $match: { n: { $gt: 1 } } }, { $count: 'g' },
  ]).toArray();
  informe.gruposConTarjetaRepetida = repetidas.length ? repetidas[0].g : 0;
  print(EJSON.stringify(informe, null, 2, { relaxed: true }));
})();
