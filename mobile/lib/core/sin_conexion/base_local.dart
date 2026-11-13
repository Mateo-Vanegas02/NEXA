import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'almacen_sin_conexion.dart';
import 'reglas_sin_conexion.dart';

part 'base_local.g.dart';

/// Cola de acciones hechas sin señal, en orden.
@DataClassName('FilaPendiente')
class Pendientes extends Table {
  IntColumn get orden => integer().autoIncrement()();
  TextColumn get llave => text().unique()();
  TextColumn get tipo => text()();
  TextColumn get servicioId => text()();
  DateTimeColumn get ocurridoEn => dateTime()();
  RealColumn get latitud => real().nullable()();
  RealColumn get longitud => real().nullable()();
  IntColumn get intentos => integer().withDefault(const Constant(0))();
}

/// Posiciones del conductor guardadas sin señal.
@DataClassName('FilaPunto')
class PuntosGuardados extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get latitud => real()();
  RealColumn get longitud => real()();
  DateTimeColumn get tomadoEn => dateTime()();
}

/// Última copia del viaje por rol (JSON de la vista del servidor).
@DataClassName('FilaInstantanea')
class Instantaneas extends Table {
  TextColumn get clave => text()();
  TextColumn get json => text()();
  DateTimeColumn get guardadaEn => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {clave};
}

/// Base SQLite del teléfono (drift): transacciones y orden garantizado para la
/// cola. Se abre como `nexa_local.sqlite` en los documentos de la app.
@DriftDatabase(tables: [Pendientes, PuntosGuardados, Instantaneas])
class BaseLocal extends _$BaseLocal implements AlmacenSinConexion {
  BaseLocal([QueryExecutor? ejecutor])
    : super(ejecutor ?? driftDatabase(name: 'nexa_local'));

  @override
  int get schemaVersion => 1;

  @override
  Future<void> encolar(AccionPendiente a) => into(pendientes).insert(
    PendientesCompanion.insert(
      llave: a.llave,
      tipo: a.tipo.name,
      servicioId: a.servicioId,
      ocurridoEn: a.ocurridoEn,
      latitud: Value(a.latitud),
      longitud: Value(a.longitud),
    ),
    mode: InsertMode.insertOrIgnore,
  );

  @override
  Future<List<AccionPendiente>> cola() async {
    final filas = await (select(
      pendientes,
    )..orderBy([(t) => OrderingTerm.asc(t.orden)])).get();
    return [
      for (final f in filas)
        if (TipoPendiente.values.asNameMap()[f.tipo] case final tipo?)
          AccionPendiente(
            llave: f.llave,
            tipo: tipo,
            servicioId: f.servicioId,
            ocurridoEn: f.ocurridoEn,
            latitud: f.latitud,
            longitud: f.longitud,
            intentos: f.intentos,
          ),
    ];
  }

  @override
  Future<void> quitar(String llave) =>
      (delete(pendientes)..where((t) => t.llave.equals(llave))).go();

  @override
  Future<void> sumarIntento(String llave) => customUpdate(
    'UPDATE pendientes SET intentos = intentos + 1 WHERE llave = ?',
    variables: [Variable.withString(llave)],
    updates: {pendientes},
  );

  @override
  Future<void> guardarPunto(PuntoGuardado p) => transaction(() async {
    await into(puntosGuardados).insert(
      PuntosGuardadosCompanion.insert(
        latitud: p.latitud,
        longitud: p.longitud,
        tomadoEn: p.tomadoEn,
      ),
    );
    // Solo los últimos: un corte muy largo no llena el teléfono.
    await customStatement(
      'DELETE FROM puntos_guardados WHERE id NOT IN '
      '(SELECT id FROM puntos_guardados ORDER BY id DESC LIMIT ?)',
      [ReglasSinConexion.maxPuntos],
    );
  });

  @override
  Future<List<PuntoGuardado>> puntos({
    int limite = ReglasSinConexion.puntosPorLote,
  }) async {
    final filas =
        await (select(puntosGuardados)
              ..orderBy([(t) => OrderingTerm.asc(t.id)])
              ..limit(limite))
            .get();
    return [
      for (final f in filas)
        PuntoGuardado(
          id: f.id,
          latitud: f.latitud,
          longitud: f.longitud,
          tomadoEn: f.tomadoEn,
        ),
    ];
  }

  @override
  Future<void> quitarPuntos(List<int> ids) =>
      (delete(puntosGuardados)..where((t) => t.id.isIn(ids))).go();

  @override
  Future<void> guardarInstantanea(String clave, String json) =>
      into(instantaneas).insertOnConflictUpdate(
        InstantaneasCompanion.insert(
          clave: clave,
          json: json,
          guardadaEn: DateTime.now(),
        ),
      );

  @override
  Future<({String json, DateTime en})?> instantanea(String clave) async {
    final f = await (select(
      instantaneas,
    )..where((t) => t.clave.equals(clave))).getSingleOrNull();
    return f == null ? null : (json: f.json, en: f.guardadaEn);
  }

  @override
  Future<void> borrarInstantanea(String clave) =>
      (delete(instantaneas)..where((t) => t.clave.equals(clave))).go();

  @override
  Future<void> vaciar() => transaction(() async {
    await delete(pendientes).go();
    await delete(puntosGuardados).go();
    await delete(instantaneas).go();
  });
}
