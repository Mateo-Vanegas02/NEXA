// Datos SINTÉTICOS para probar inspeccion-solo-lectura.js en CI (nunca contra Atlas).
// Siembra duplicados y casos raros conocidos para comprobar que el script los cuenta sin imprimirlos.
/* global db, BASE */
(function () {
  'use strict';
  const base = db.getSiblingDB(typeof BASE === 'string' ? BASE : 'nexa_inspeccion_ci');
  if (!/^nexa_inspeccion_ci/.test(base.getName())) {
    throw new Error('Solo se siembra una base de prueba nexa_inspeccion_ci*');
  }
  base.dropDatabase();
  const U = base.Usuarios;
  const id = () => new ObjectId();
  const pasajeros = [id(), id(), id()];
  const conductores = [id(), id(), id()];
  U.insertMany([
    { _id: pasajeros[0], email: 'repetido.sintetico@example.invalid', rol: 'PASAJERO', _class: 'PASAJERO' },
    { _id: pasajeros[1], email: ' Repetido.Sintetico@example.invalid', rol: 'PASAJERO', _class: 'PASAJERO' },
    { _id: pasajeros[2], email: 'deudor.sintetico@example.invalid', rol: 'PASAJERO', _class: 'PASAJERO' },
    { _id: conductores[0], email: 'repetido.sintetico@example.invalid', rol: 'CONDUCTOR', _class: 'CONDUCTOR',
      estadoValidacion: 'APROBADO', licencia: NumberLong(900001), soat: NumberLong(800001), tarjeta_de_propiedad: NumberLong(700001) },
    { _id: conductores[1], email: 'c2.sintetico@example.invalid', rol: 'CONDUCTOR', _class: 'CONDUCTOR',
      estadoValidacion: 'PENDIENTE', licencia: NumberLong(900001), soat: NumberLong(0), tarjeta_de_propiedad: NumberLong(700002) },
    { _id: conductores[2], email: 'c3.sintetico@example.invalid', rol: 'CONDUCTOR', _class: 'CONDUCTOR',
      estadoValidacion: 'APROBADO', licencia: '900003', soat: NumberLong(800003), tarjeta_de_propiedad: NumberLong(700003) },
  ]);
  const S = base.servicios;
  const cancelado = id();
  S.insertMany([
    { _id: cancelado, estado: 'CANCELADO', pasajero: { _id: pasajeros[2] }, cargoCancelacion: NumberLong(3000),
      fechaCancelacion: new Date(), canal: 'WEB' },
    { estado: 'SOLICITADO', pasajero: { _id: pasajeros[0] }, solicitadoEn: new Date(Date.now() - 3 * 864e5), canal: 'APP' },
    { estado: 'SOLICITADO', pasajero: { _id: pasajeros[0] }, solicitadoEn: new Date(), canal: 'APP' },
    { estado: 'FINALIZADO', pasajero: { _id: pasajeros[1] }, conductor: { _id: conductores[0] },
      fechaHora: new Date(), fechaFinalizacion: new Date(), solicitadoEn: new Date(), tarifa: 5000,
      cargoPagadoEn: new Date(), cargoCondonadoEn: new Date() },
    { estado: 'FINALIZADO', pasajero: { _id: pasajeros[1].toHexString() }, conductor: { _id: conductores[1] },
      fechaHora: '2026-01-01T00:00:00', tarifa: 4000 },
  ]);
  U.updateOne({ _id: pasajeros[2] }, { $set: { deuda: { servicioId: cancelado.toHexString(), monto: NumberLong(3000), creadaEn: new Date() } } });
  base.xp_eventos.insertMany([
    { viajeId: 'v1', rol: 'PASAJERO', motivo: 'VIAJE', xp: 10, aplicado: true },
    { viajeId: 'v1', rol: 'PASAJERO', motivo: 'VIAJE', xp: 10, aplicado: false },
  ]);
  base.dispositivos.insertOne({ token: 'token-sintetico', usuarioId: pasajeros[0] });
  print('sembrado ' + base.getName());
})();
