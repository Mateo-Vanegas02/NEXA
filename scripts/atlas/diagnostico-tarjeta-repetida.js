// NEXA — Diagnóstico en SOLO LECTURA de conductores que comparten tarjeta de propiedad (fase 3.2).
//
// Regla decidida por el propietario (17 nov 2026): una moto no puede estar registrada por más de un conductor.
// Para cada grupo de conductores con la misma tarjeta compara, sin imprimir valores: si comparten placa, SOAT o
// licencia, si el número guardado coincide con el que declararon al subir la foto (documentos_conductor), su estado
// y cuántos viajes tienen. Ayuda a distinguir un error de digitación de una moto realmente compartida.
//
//   mongosh "<uri>" --quiet --username <usuario-lectura> --file scripts/atlas/diagnostico-tarjeta-repetida.js
// Con --eval "var MOSTRAR_IDS=true" antes del --file muestra además el _id de cada conductor (para buscarlo en
// Compass o en el panel del admin). Esa salida es para el propietario: no la compartas.

/* global db, BASE, MOSTRAR_IDS, EJSON */
(function () {
  'use strict';
  const base = db.getSiblingDB((typeof BASE === 'string' && BASE) ? BASE : 'motvirsweb');
  const mostrarIds = typeof MOSTRAR_IDS !== 'undefined' && MOSTRAR_IDS === true;
  try { db.getMongo().setReadPref('secondaryPreferred'); } catch (e) { /* conexión directa */ }

  const grupos = base.Usuarios.aggregate([
    { $match: { rol: 'CONDUCTOR', tarjeta_de_propiedad: { $gt: 0 } } },
    { $group: { _id: '$tarjeta_de_propiedad', ids: { $push: '$_id' }, n: { $sum: 1 } } },
    { $match: { n: { $gt: 1 } } },
  ]).toArray();

  const declarado = (conductorId, tipo) => {
    const d = base.documentos_conductor.find({ conductorId: conductorId.toHexString(), tipo: tipo })
      .sort({ subidoEn: -1 }).limit(1).toArray();
    return d.length ? String(d[0].numeroDeclarado) : null;
  };
  const comparar = (doc, guardado) => (doc === null ? 'sin documento' : (doc === String(guardado) ? 'coincide' : 'difiere'));

  const salida = { base: base.getName(), gruposConTarjetaRepetida: grupos.length, grupos: [] };
  grupos.forEach((g, i) => {
    const conductores = base.Usuarios.find({ _id: { $in: g.ids } },
      { _id: 1, estadoValidacion: 1, soat: 1, licencia: 1, tarjeta_de_propiedad: 1 }).toArray()
      .sort((a, b) => a._id.getTimestamp() - b._id.getTimestamp());
    const placasDe = (id) => base.Vehiculos.find({ $or: [{ 'conductor._id': id }, { 'conductorAsignado.$id': id }] },
      { placa: 1 }).toArray().map((v) => String(v.placa || '').toUpperCase()).filter((p) => p);
    const placas = conductores.map((c) => placasDe(c._id));
    const todas = placas.flat();
    const miembros = conductores.map((c, j) => {
      const m = {
        etiqueta: String.fromCharCode(65 + j),
        registradoEl: c._id.getTimestamp().toISOString().slice(0, 10),
        estadoValidacion: c.estadoValidacion || null,
        viajesFinalizados: base.servicios.countDocuments({ 'conductor._id': c._id, estado: 'FINALIZADO' }),
        vehiculos: placas[j].length,
        fotoTarjeta: comparar(declarado(c._id, 'TARJETA_PROPIEDAD'), c.tarjeta_de_propiedad),
        fotoSoat: comparar(declarado(c._id, 'SOAT'), c.soat),
      };
      if (mostrarIds) m.id = c._id.toHexString();
      return m;
    });
    salida.grupos.push({
      grupo: i + 1,
      conductores: g.n,
      compartenPlaca: new Set(todas).size < todas.length,
      compartenSoat: new Set(conductores.map((c) => String(c.soat))).size < conductores.length,
      compartenLicencia: new Set(conductores.map((c) => String(c.licencia))).size < conductores.length,
      miembros: miembros,
    });
  });

  // Placas repetidas en Vehiculos (el código declara la placa única, pero el índice no existe en Atlas)
  const placas = base.Vehiculos.aggregate([
    { $match: { placa: { $type: 'string', $ne: '' } } },
    { $group: { _id: { $toUpper: { $trim: { input: '$placa' } } }, n: { $sum: 1 } } },
    { $match: { n: { $gt: 1 } } }, { $count: 'grupos' },
  ]).toArray();
  salida.placasRepetidasEnVehiculos = placas.length ? placas[0].grupos : 0;

  print(EJSON.stringify(salida, null, 2, { relaxed: true }));
})();
