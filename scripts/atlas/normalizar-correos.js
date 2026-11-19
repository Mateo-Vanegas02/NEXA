// Normalización de correo por rol. Plan por defecto; nunca imprime correos completos ni ids.
/* global db, BASE, MODO, PRODUCCION_APROBADA, EJSON */
(function () {
  'use strict';
  const nombreBase = typeof BASE === 'string' && BASE ? BASE : 'motvirsweb';
  const modo = typeof MODO === 'string' && MODO ? MODO : 'plan';
  if (!['plan', 'aplicar', 'indice'].includes(modo)) throw new Error('MODO debe ser plan, aplicar o indice');
  if (modo !== 'plan' && nombreBase === 'motvirsweb'
      && !(typeof PRODUCCION_APROBADA === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(PRODUCCION_APROBADA))) {
    throw new Error('Producción: falta PRODUCCION_APROBADA con la fecha del respaldo verificado');
  }
  const base = db.getSiblingDB(nombreBase);
  const normalizar = (s) => typeof s === 'string' ? s.trim().toLowerCase() : s;
  const enmascarar = (s) => {
    const partes = s.split('@');
    return (partes[0][0] || '*') + '***@' + (partes[1] || '***');
  };
  const usuarios = base.Usuarios.find({}, { email: 1, rol: 1 }).toArray();
  const grupos = new Map();
  usuarios.forEach((u) => {
    if (typeof u.email !== 'string') return;
    const clave = u.rol + '\u0000' + normalizar(u.email);
    grupos.set(clave, (grupos.get(clave) || 0) + 1);
  });
  const afectados = usuarios.filter((u) => typeof u.email === 'string' && u.email !== normalizar(u.email));
  const colisionesTotales = [...grupos.values()].filter((n) => n > 1).length;
  if (modo === 'indice') {
    if (afectados.length || colisionesTotales) {
      throw new Error('No se crea el índice: quedan correos sin normalizar o colisiones por rol');
    }
    base.Usuarios.createIndex({ email: 1, rol: 1 }, { unique: true, name: 'email_rol_unique_idx' });
    print(EJSON.stringify({ base: nombreBase, modo, indice: 'email_rol_unique_idx' }));
    return;
  }
  const informe = { base: nombreBase, modo, afectados: afectados.length, colisiones: 0,
    cuentas: [], actualizados: 0, copiasServicio: 0, copiasDispositivo: 0 };
  afectados.forEach((u) => {
    const nuevo = normalizar(u.email);
    const colision = grupos.get(u.rol + '\u0000' + nuevo) > 1;
    informe.cuentas.push({ correo: enmascarar(nuevo), rol: u.rol, colision });
    if (colision) { informe.colisiones++; return; }
    if (modo !== 'aplicar') return;
    const escrito = base.Usuarios.updateOne({ _id: u._id, email: u.email, rol: u.rol },
      { $set: { email: nuevo } }).modifiedCount;
    informe.actualizados += escrito;
    if (!escrito) return; // cambió durante el plan; no tocar las copias
    if (u.rol === 'PASAJERO') {
      informe.copiasServicio += base.servicios.updateMany({ 'pasajero._id': u._id,
        'pasajero.email': u.email }, { $set: { 'pasajero.email': nuevo } }).modifiedCount;
    }
    // La versión actual de dispositivos solo guarda usuarioId y token; se corrigen
    // copias antiguas si las hubiera, siempre ligadas al mismo usuario y valor leído.
    ['email', 'correo'].forEach((campo) => {
      const filtro = { usuarioId: u._id }; filtro[campo] = u.email;
      const cambio = { $set: {} }; cambio.$set[campo] = nuevo;
      informe.copiasDispositivo += base.dispositivos.updateMany(filtro, cambio).modifiedCount;
    });
  });
  print(EJSON.stringify(informe, null, 2, { relaxed: true }));
})();
