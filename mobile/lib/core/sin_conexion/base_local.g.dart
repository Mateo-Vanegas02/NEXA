// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_local.dart';

// ignore_for_file: type=lint
class $PendientesTable extends Pendientes
    with TableInfo<$PendientesTable, FilaPendiente> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendientesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ordenMeta = const VerificationMeta('orden');
  @override
  late final GeneratedColumn<int> orden = GeneratedColumn<int>(
    'orden',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _llaveMeta = const VerificationMeta('llave');
  @override
  late final GeneratedColumn<String> llave = GeneratedColumn<String>(
    'llave',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _servicioIdMeta = const VerificationMeta(
    'servicioId',
  );
  @override
  late final GeneratedColumn<String> servicioId = GeneratedColumn<String>(
    'servicio_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ocurridoEnMeta = const VerificationMeta(
    'ocurridoEn',
  );
  @override
  late final GeneratedColumn<DateTime> ocurridoEn = GeneratedColumn<DateTime>(
    'ocurrido_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudMeta = const VerificationMeta(
    'latitud',
  );
  @override
  late final GeneratedColumn<double> latitud = GeneratedColumn<double>(
    'latitud',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudMeta = const VerificationMeta(
    'longitud',
  );
  @override
  late final GeneratedColumn<double> longitud = GeneratedColumn<double>(
    'longitud',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intentosMeta = const VerificationMeta(
    'intentos',
  );
  @override
  late final GeneratedColumn<int> intentos = GeneratedColumn<int>(
    'intentos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    orden,
    llave,
    tipo,
    servicioId,
    ocurridoEn,
    latitud,
    longitud,
    intentos,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pendientes';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaPendiente> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('orden')) {
      context.handle(
        _ordenMeta,
        orden.isAcceptableOrUnknown(data['orden']!, _ordenMeta),
      );
    }
    if (data.containsKey('llave')) {
      context.handle(
        _llaveMeta,
        llave.isAcceptableOrUnknown(data['llave']!, _llaveMeta),
      );
    } else if (isInserting) {
      context.missing(_llaveMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('servicio_id')) {
      context.handle(
        _servicioIdMeta,
        servicioId.isAcceptableOrUnknown(data['servicio_id']!, _servicioIdMeta),
      );
    } else if (isInserting) {
      context.missing(_servicioIdMeta);
    }
    if (data.containsKey('ocurrido_en')) {
      context.handle(
        _ocurridoEnMeta,
        ocurridoEn.isAcceptableOrUnknown(data['ocurrido_en']!, _ocurridoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_ocurridoEnMeta);
    }
    if (data.containsKey('latitud')) {
      context.handle(
        _latitudMeta,
        latitud.isAcceptableOrUnknown(data['latitud']!, _latitudMeta),
      );
    }
    if (data.containsKey('longitud')) {
      context.handle(
        _longitudMeta,
        longitud.isAcceptableOrUnknown(data['longitud']!, _longitudMeta),
      );
    }
    if (data.containsKey('intentos')) {
      context.handle(
        _intentosMeta,
        intentos.isAcceptableOrUnknown(data['intentos']!, _intentosMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {orden};
  @override
  FilaPendiente map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaPendiente(
      orden: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}orden'],
      )!,
      llave: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}llave'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      servicioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}servicio_id'],
      )!,
      ocurridoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ocurrido_en'],
      )!,
      latitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitud'],
      ),
      longitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitud'],
      ),
      intentos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intentos'],
      )!,
    );
  }

  @override
  $PendientesTable createAlias(String alias) {
    return $PendientesTable(attachedDatabase, alias);
  }
}

class FilaPendiente extends DataClass implements Insertable<FilaPendiente> {
  final int orden;
  final String llave;
  final String tipo;
  final String servicioId;
  final DateTime ocurridoEn;
  final double? latitud;
  final double? longitud;
  final int intentos;
  const FilaPendiente({
    required this.orden,
    required this.llave,
    required this.tipo,
    required this.servicioId,
    required this.ocurridoEn,
    this.latitud,
    this.longitud,
    required this.intentos,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['orden'] = Variable<int>(orden);
    map['llave'] = Variable<String>(llave);
    map['tipo'] = Variable<String>(tipo);
    map['servicio_id'] = Variable<String>(servicioId);
    map['ocurrido_en'] = Variable<DateTime>(ocurridoEn);
    if (!nullToAbsent || latitud != null) {
      map['latitud'] = Variable<double>(latitud);
    }
    if (!nullToAbsent || longitud != null) {
      map['longitud'] = Variable<double>(longitud);
    }
    map['intentos'] = Variable<int>(intentos);
    return map;
  }

  PendientesCompanion toCompanion(bool nullToAbsent) {
    return PendientesCompanion(
      orden: Value(orden),
      llave: Value(llave),
      tipo: Value(tipo),
      servicioId: Value(servicioId),
      ocurridoEn: Value(ocurridoEn),
      latitud: latitud == null && nullToAbsent
          ? const Value.absent()
          : Value(latitud),
      longitud: longitud == null && nullToAbsent
          ? const Value.absent()
          : Value(longitud),
      intentos: Value(intentos),
    );
  }

  factory FilaPendiente.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaPendiente(
      orden: serializer.fromJson<int>(json['orden']),
      llave: serializer.fromJson<String>(json['llave']),
      tipo: serializer.fromJson<String>(json['tipo']),
      servicioId: serializer.fromJson<String>(json['servicioId']),
      ocurridoEn: serializer.fromJson<DateTime>(json['ocurridoEn']),
      latitud: serializer.fromJson<double?>(json['latitud']),
      longitud: serializer.fromJson<double?>(json['longitud']),
      intentos: serializer.fromJson<int>(json['intentos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'orden': serializer.toJson<int>(orden),
      'llave': serializer.toJson<String>(llave),
      'tipo': serializer.toJson<String>(tipo),
      'servicioId': serializer.toJson<String>(servicioId),
      'ocurridoEn': serializer.toJson<DateTime>(ocurridoEn),
      'latitud': serializer.toJson<double?>(latitud),
      'longitud': serializer.toJson<double?>(longitud),
      'intentos': serializer.toJson<int>(intentos),
    };
  }

  FilaPendiente copyWith({
    int? orden,
    String? llave,
    String? tipo,
    String? servicioId,
    DateTime? ocurridoEn,
    Value<double?> latitud = const Value.absent(),
    Value<double?> longitud = const Value.absent(),
    int? intentos,
  }) => FilaPendiente(
    orden: orden ?? this.orden,
    llave: llave ?? this.llave,
    tipo: tipo ?? this.tipo,
    servicioId: servicioId ?? this.servicioId,
    ocurridoEn: ocurridoEn ?? this.ocurridoEn,
    latitud: latitud.present ? latitud.value : this.latitud,
    longitud: longitud.present ? longitud.value : this.longitud,
    intentos: intentos ?? this.intentos,
  );
  FilaPendiente copyWithCompanion(PendientesCompanion data) {
    return FilaPendiente(
      orden: data.orden.present ? data.orden.value : this.orden,
      llave: data.llave.present ? data.llave.value : this.llave,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      servicioId: data.servicioId.present
          ? data.servicioId.value
          : this.servicioId,
      ocurridoEn: data.ocurridoEn.present
          ? data.ocurridoEn.value
          : this.ocurridoEn,
      latitud: data.latitud.present ? data.latitud.value : this.latitud,
      longitud: data.longitud.present ? data.longitud.value : this.longitud,
      intentos: data.intentos.present ? data.intentos.value : this.intentos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaPendiente(')
          ..write('orden: $orden, ')
          ..write('llave: $llave, ')
          ..write('tipo: $tipo, ')
          ..write('servicioId: $servicioId, ')
          ..write('ocurridoEn: $ocurridoEn, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('intentos: $intentos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    orden,
    llave,
    tipo,
    servicioId,
    ocurridoEn,
    latitud,
    longitud,
    intentos,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaPendiente &&
          other.orden == this.orden &&
          other.llave == this.llave &&
          other.tipo == this.tipo &&
          other.servicioId == this.servicioId &&
          other.ocurridoEn == this.ocurridoEn &&
          other.latitud == this.latitud &&
          other.longitud == this.longitud &&
          other.intentos == this.intentos);
}

class PendientesCompanion extends UpdateCompanion<FilaPendiente> {
  final Value<int> orden;
  final Value<String> llave;
  final Value<String> tipo;
  final Value<String> servicioId;
  final Value<DateTime> ocurridoEn;
  final Value<double?> latitud;
  final Value<double?> longitud;
  final Value<int> intentos;
  const PendientesCompanion({
    this.orden = const Value.absent(),
    this.llave = const Value.absent(),
    this.tipo = const Value.absent(),
    this.servicioId = const Value.absent(),
    this.ocurridoEn = const Value.absent(),
    this.latitud = const Value.absent(),
    this.longitud = const Value.absent(),
    this.intentos = const Value.absent(),
  });
  PendientesCompanion.insert({
    this.orden = const Value.absent(),
    required String llave,
    required String tipo,
    required String servicioId,
    required DateTime ocurridoEn,
    this.latitud = const Value.absent(),
    this.longitud = const Value.absent(),
    this.intentos = const Value.absent(),
  }) : llave = Value(llave),
       tipo = Value(tipo),
       servicioId = Value(servicioId),
       ocurridoEn = Value(ocurridoEn);
  static Insertable<FilaPendiente> custom({
    Expression<int>? orden,
    Expression<String>? llave,
    Expression<String>? tipo,
    Expression<String>? servicioId,
    Expression<DateTime>? ocurridoEn,
    Expression<double>? latitud,
    Expression<double>? longitud,
    Expression<int>? intentos,
  }) {
    return RawValuesInsertable({
      if (orden != null) 'orden': orden,
      if (llave != null) 'llave': llave,
      if (tipo != null) 'tipo': tipo,
      if (servicioId != null) 'servicio_id': servicioId,
      if (ocurridoEn != null) 'ocurrido_en': ocurridoEn,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
      if (intentos != null) 'intentos': intentos,
    });
  }

  PendientesCompanion copyWith({
    Value<int>? orden,
    Value<String>? llave,
    Value<String>? tipo,
    Value<String>? servicioId,
    Value<DateTime>? ocurridoEn,
    Value<double?>? latitud,
    Value<double?>? longitud,
    Value<int>? intentos,
  }) {
    return PendientesCompanion(
      orden: orden ?? this.orden,
      llave: llave ?? this.llave,
      tipo: tipo ?? this.tipo,
      servicioId: servicioId ?? this.servicioId,
      ocurridoEn: ocurridoEn ?? this.ocurridoEn,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      intentos: intentos ?? this.intentos,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (orden.present) {
      map['orden'] = Variable<int>(orden.value);
    }
    if (llave.present) {
      map['llave'] = Variable<String>(llave.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (servicioId.present) {
      map['servicio_id'] = Variable<String>(servicioId.value);
    }
    if (ocurridoEn.present) {
      map['ocurrido_en'] = Variable<DateTime>(ocurridoEn.value);
    }
    if (latitud.present) {
      map['latitud'] = Variable<double>(latitud.value);
    }
    if (longitud.present) {
      map['longitud'] = Variable<double>(longitud.value);
    }
    if (intentos.present) {
      map['intentos'] = Variable<int>(intentos.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendientesCompanion(')
          ..write('orden: $orden, ')
          ..write('llave: $llave, ')
          ..write('tipo: $tipo, ')
          ..write('servicioId: $servicioId, ')
          ..write('ocurridoEn: $ocurridoEn, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('intentos: $intentos')
          ..write(')'))
        .toString();
  }
}

class $PuntosGuardadosTable extends PuntosGuardados
    with TableInfo<$PuntosGuardadosTable, FilaPunto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PuntosGuardadosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _latitudMeta = const VerificationMeta(
    'latitud',
  );
  @override
  late final GeneratedColumn<double> latitud = GeneratedColumn<double>(
    'latitud',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudMeta = const VerificationMeta(
    'longitud',
  );
  @override
  late final GeneratedColumn<double> longitud = GeneratedColumn<double>(
    'longitud',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tomadoEnMeta = const VerificationMeta(
    'tomadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> tomadoEn = GeneratedColumn<DateTime>(
    'tomado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, latitud, longitud, tomadoEn];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puntos_guardados';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaPunto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('latitud')) {
      context.handle(
        _latitudMeta,
        latitud.isAcceptableOrUnknown(data['latitud']!, _latitudMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudMeta);
    }
    if (data.containsKey('longitud')) {
      context.handle(
        _longitudMeta,
        longitud.isAcceptableOrUnknown(data['longitud']!, _longitudMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudMeta);
    }
    if (data.containsKey('tomado_en')) {
      context.handle(
        _tomadoEnMeta,
        tomadoEn.isAcceptableOrUnknown(data['tomado_en']!, _tomadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_tomadoEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaPunto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaPunto(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      latitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitud'],
      )!,
      longitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitud'],
      )!,
      tomadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}tomado_en'],
      )!,
    );
  }

  @override
  $PuntosGuardadosTable createAlias(String alias) {
    return $PuntosGuardadosTable(attachedDatabase, alias);
  }
}

class FilaPunto extends DataClass implements Insertable<FilaPunto> {
  final int id;
  final double latitud;
  final double longitud;
  final DateTime tomadoEn;
  const FilaPunto({
    required this.id,
    required this.latitud,
    required this.longitud,
    required this.tomadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['latitud'] = Variable<double>(latitud);
    map['longitud'] = Variable<double>(longitud);
    map['tomado_en'] = Variable<DateTime>(tomadoEn);
    return map;
  }

  PuntosGuardadosCompanion toCompanion(bool nullToAbsent) {
    return PuntosGuardadosCompanion(
      id: Value(id),
      latitud: Value(latitud),
      longitud: Value(longitud),
      tomadoEn: Value(tomadoEn),
    );
  }

  factory FilaPunto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaPunto(
      id: serializer.fromJson<int>(json['id']),
      latitud: serializer.fromJson<double>(json['latitud']),
      longitud: serializer.fromJson<double>(json['longitud']),
      tomadoEn: serializer.fromJson<DateTime>(json['tomadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'latitud': serializer.toJson<double>(latitud),
      'longitud': serializer.toJson<double>(longitud),
      'tomadoEn': serializer.toJson<DateTime>(tomadoEn),
    };
  }

  FilaPunto copyWith({
    int? id,
    double? latitud,
    double? longitud,
    DateTime? tomadoEn,
  }) => FilaPunto(
    id: id ?? this.id,
    latitud: latitud ?? this.latitud,
    longitud: longitud ?? this.longitud,
    tomadoEn: tomadoEn ?? this.tomadoEn,
  );
  FilaPunto copyWithCompanion(PuntosGuardadosCompanion data) {
    return FilaPunto(
      id: data.id.present ? data.id.value : this.id,
      latitud: data.latitud.present ? data.latitud.value : this.latitud,
      longitud: data.longitud.present ? data.longitud.value : this.longitud,
      tomadoEn: data.tomadoEn.present ? data.tomadoEn.value : this.tomadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaPunto(')
          ..write('id: $id, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('tomadoEn: $tomadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, latitud, longitud, tomadoEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaPunto &&
          other.id == this.id &&
          other.latitud == this.latitud &&
          other.longitud == this.longitud &&
          other.tomadoEn == this.tomadoEn);
}

class PuntosGuardadosCompanion extends UpdateCompanion<FilaPunto> {
  final Value<int> id;
  final Value<double> latitud;
  final Value<double> longitud;
  final Value<DateTime> tomadoEn;
  const PuntosGuardadosCompanion({
    this.id = const Value.absent(),
    this.latitud = const Value.absent(),
    this.longitud = const Value.absent(),
    this.tomadoEn = const Value.absent(),
  });
  PuntosGuardadosCompanion.insert({
    this.id = const Value.absent(),
    required double latitud,
    required double longitud,
    required DateTime tomadoEn,
  }) : latitud = Value(latitud),
       longitud = Value(longitud),
       tomadoEn = Value(tomadoEn);
  static Insertable<FilaPunto> custom({
    Expression<int>? id,
    Expression<double>? latitud,
    Expression<double>? longitud,
    Expression<DateTime>? tomadoEn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
      if (tomadoEn != null) 'tomado_en': tomadoEn,
    });
  }

  PuntosGuardadosCompanion copyWith({
    Value<int>? id,
    Value<double>? latitud,
    Value<double>? longitud,
    Value<DateTime>? tomadoEn,
  }) {
    return PuntosGuardadosCompanion(
      id: id ?? this.id,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      tomadoEn: tomadoEn ?? this.tomadoEn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (latitud.present) {
      map['latitud'] = Variable<double>(latitud.value);
    }
    if (longitud.present) {
      map['longitud'] = Variable<double>(longitud.value);
    }
    if (tomadoEn.present) {
      map['tomado_en'] = Variable<DateTime>(tomadoEn.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PuntosGuardadosCompanion(')
          ..write('id: $id, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('tomadoEn: $tomadoEn')
          ..write(')'))
        .toString();
  }
}

class $InstantaneasTable extends Instantaneas
    with TableInfo<$InstantaneasTable, FilaInstantanea> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstantaneasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _claveMeta = const VerificationMeta('clave');
  @override
  late final GeneratedColumn<String> clave = GeneratedColumn<String>(
    'clave',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _guardadaEnMeta = const VerificationMeta(
    'guardadaEn',
  );
  @override
  late final GeneratedColumn<DateTime> guardadaEn = GeneratedColumn<DateTime>(
    'guardada_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [clave, json, guardadaEn];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instantaneas';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaInstantanea> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('clave')) {
      context.handle(
        _claveMeta,
        clave.isAcceptableOrUnknown(data['clave']!, _claveMeta),
      );
    } else if (isInserting) {
      context.missing(_claveMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('guardada_en')) {
      context.handle(
        _guardadaEnMeta,
        guardadaEn.isAcceptableOrUnknown(data['guardada_en']!, _guardadaEnMeta),
      );
    } else if (isInserting) {
      context.missing(_guardadaEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clave};
  @override
  FilaInstantanea map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaInstantanea(
      clave: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clave'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      guardadaEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}guardada_en'],
      )!,
    );
  }

  @override
  $InstantaneasTable createAlias(String alias) {
    return $InstantaneasTable(attachedDatabase, alias);
  }
}

class FilaInstantanea extends DataClass implements Insertable<FilaInstantanea> {
  final String clave;
  final String json;
  final DateTime guardadaEn;
  const FilaInstantanea({
    required this.clave,
    required this.json,
    required this.guardadaEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['clave'] = Variable<String>(clave);
    map['json'] = Variable<String>(json);
    map['guardada_en'] = Variable<DateTime>(guardadaEn);
    return map;
  }

  InstantaneasCompanion toCompanion(bool nullToAbsent) {
    return InstantaneasCompanion(
      clave: Value(clave),
      json: Value(json),
      guardadaEn: Value(guardadaEn),
    );
  }

  factory FilaInstantanea.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaInstantanea(
      clave: serializer.fromJson<String>(json['clave']),
      json: serializer.fromJson<String>(json['json']),
      guardadaEn: serializer.fromJson<DateTime>(json['guardadaEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clave': serializer.toJson<String>(clave),
      'json': serializer.toJson<String>(json),
      'guardadaEn': serializer.toJson<DateTime>(guardadaEn),
    };
  }

  FilaInstantanea copyWith({
    String? clave,
    String? json,
    DateTime? guardadaEn,
  }) => FilaInstantanea(
    clave: clave ?? this.clave,
    json: json ?? this.json,
    guardadaEn: guardadaEn ?? this.guardadaEn,
  );
  FilaInstantanea copyWithCompanion(InstantaneasCompanion data) {
    return FilaInstantanea(
      clave: data.clave.present ? data.clave.value : this.clave,
      json: data.json.present ? data.json.value : this.json,
      guardadaEn: data.guardadaEn.present
          ? data.guardadaEn.value
          : this.guardadaEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaInstantanea(')
          ..write('clave: $clave, ')
          ..write('json: $json, ')
          ..write('guardadaEn: $guardadaEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(clave, json, guardadaEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaInstantanea &&
          other.clave == this.clave &&
          other.json == this.json &&
          other.guardadaEn == this.guardadaEn);
}

class InstantaneasCompanion extends UpdateCompanion<FilaInstantanea> {
  final Value<String> clave;
  final Value<String> json;
  final Value<DateTime> guardadaEn;
  final Value<int> rowid;
  const InstantaneasCompanion({
    this.clave = const Value.absent(),
    this.json = const Value.absent(),
    this.guardadaEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstantaneasCompanion.insert({
    required String clave,
    required String json,
    required DateTime guardadaEn,
    this.rowid = const Value.absent(),
  }) : clave = Value(clave),
       json = Value(json),
       guardadaEn = Value(guardadaEn);
  static Insertable<FilaInstantanea> custom({
    Expression<String>? clave,
    Expression<String>? json,
    Expression<DateTime>? guardadaEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clave != null) 'clave': clave,
      if (json != null) 'json': json,
      if (guardadaEn != null) 'guardada_en': guardadaEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstantaneasCompanion copyWith({
    Value<String>? clave,
    Value<String>? json,
    Value<DateTime>? guardadaEn,
    Value<int>? rowid,
  }) {
    return InstantaneasCompanion(
      clave: clave ?? this.clave,
      json: json ?? this.json,
      guardadaEn: guardadaEn ?? this.guardadaEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clave.present) {
      map['clave'] = Variable<String>(clave.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (guardadaEn.present) {
      map['guardada_en'] = Variable<DateTime>(guardadaEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstantaneasCompanion(')
          ..write('clave: $clave, ')
          ..write('json: $json, ')
          ..write('guardadaEn: $guardadaEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$BaseLocal extends GeneratedDatabase {
  _$BaseLocal(QueryExecutor e) : super(e);
  $BaseLocalManager get managers => $BaseLocalManager(this);
  late final $PendientesTable pendientes = $PendientesTable(this);
  late final $PuntosGuardadosTable puntosGuardados = $PuntosGuardadosTable(
    this,
  );
  late final $InstantaneasTable instantaneas = $InstantaneasTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    pendientes,
    puntosGuardados,
    instantaneas,
  ];
}

typedef $$PendientesTableCreateCompanionBuilder = PendientesCompanion Function({
  Value<int> orden,
  required String llave,
  required String tipo,
  required String servicioId,
  required DateTime ocurridoEn,
  Value<double?> latitud,
  Value<double?> longitud,
  Value<int> intentos,
});
typedef $$PendientesTableUpdateCompanionBuilder = PendientesCompanion Function({
  Value<int> orden,
  Value<String> llave,
  Value<String> tipo,
  Value<String> servicioId,
  Value<DateTime> ocurridoEn,
  Value<double?> latitud,
  Value<double?> longitud,
  Value<int> intentos,
});

class $$PendientesTableFilterComposer
    extends Composer<_$BaseLocal, $PendientesTable> {
  $$PendientesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get llave => $composableBuilder(
    column: $table.llave,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servicioId => $composableBuilder(
    column: $table.servicioId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ocurridoEn => $composableBuilder(
    column: $table.ocurridoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intentos => $composableBuilder(
    column: $table.intentos,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendientesTableOrderingComposer
    extends Composer<_$BaseLocal, $PendientesTable> {
  $$PendientesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get llave => $composableBuilder(
    column: $table.llave,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servicioId => $composableBuilder(
    column: $table.servicioId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ocurridoEn => $composableBuilder(
    column: $table.ocurridoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intentos => $composableBuilder(
    column: $table.intentos,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendientesTableAnnotationComposer
    extends Composer<_$BaseLocal, $PendientesTable> {
  $$PendientesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get orden =>
      $composableBuilder(column: $table.orden, builder: (column) => column);

  GeneratedColumn<String> get llave =>
      $composableBuilder(column: $table.llave, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get servicioId => $composableBuilder(
    column: $table.servicioId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get ocurridoEn => $composableBuilder(
    column: $table.ocurridoEn,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitud =>
      $composableBuilder(column: $table.latitud, builder: (column) => column);

  GeneratedColumn<double> get longitud =>
      $composableBuilder(column: $table.longitud, builder: (column) => column);

  GeneratedColumn<int> get intentos =>
      $composableBuilder(column: $table.intentos, builder: (column) => column);
}

class $$PendientesTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $PendientesTable,
          FilaPendiente,
          $$PendientesTableFilterComposer,
          $$PendientesTableOrderingComposer,
          $$PendientesTableAnnotationComposer,
          $$PendientesTableCreateCompanionBuilder,
          $$PendientesTableUpdateCompanionBuilder,
          (
            FilaPendiente,
            BaseReferences<_$BaseLocal, $PendientesTable, FilaPendiente>,
          ),
          FilaPendiente,
          PrefetchHooks Function()
        > {
  $$PendientesTableTableManager(_$BaseLocal db, $PendientesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendientesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendientesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendientesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> orden = const Value.absent(),
                Value<String> llave = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> servicioId = const Value.absent(),
                Value<DateTime> ocurridoEn = const Value.absent(),
                Value<double?> latitud = const Value.absent(),
                Value<double?> longitud = const Value.absent(),
                Value<int> intentos = const Value.absent(),
              }) => PendientesCompanion(
                orden: orden,
                llave: llave,
                tipo: tipo,
                servicioId: servicioId,
                ocurridoEn: ocurridoEn,
                latitud: latitud,
                longitud: longitud,
                intentos: intentos,
              ),
          createCompanionCallback:
              ({
                Value<int> orden = const Value.absent(),
                required String llave,
                required String tipo,
                required String servicioId,
                required DateTime ocurridoEn,
                Value<double?> latitud = const Value.absent(),
                Value<double?> longitud = const Value.absent(),
                Value<int> intentos = const Value.absent(),
              }) => PendientesCompanion.insert(
                orden: orden,
                llave: llave,
                tipo: tipo,
                servicioId: servicioId,
                ocurridoEn: ocurridoEn,
                latitud: latitud,
                longitud: longitud,
                intentos: intentos,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendientesTable, FilaPendiente>(table),
                  BaseReferences<_$BaseLocal, $PendientesTable, FilaPendiente>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendientesTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $PendientesTable,
      FilaPendiente,
      $$PendientesTableFilterComposer,
      $$PendientesTableOrderingComposer,
      $$PendientesTableAnnotationComposer,
      $$PendientesTableCreateCompanionBuilder,
      $$PendientesTableUpdateCompanionBuilder,
      (
        FilaPendiente,
        BaseReferences<_$BaseLocal, $PendientesTable, FilaPendiente>,
      ),
      FilaPendiente,
      PrefetchHooks Function()
    >;
typedef $$PuntosGuardadosTableCreateCompanionBuilder =
    PuntosGuardadosCompanion Function({
      Value<int> id,
      required double latitud,
      required double longitud,
      required DateTime tomadoEn,
    });
typedef $$PuntosGuardadosTableUpdateCompanionBuilder =
    PuntosGuardadosCompanion Function({
      Value<int> id,
      Value<double> latitud,
      Value<double> longitud,
      Value<DateTime> tomadoEn,
    });

class $$PuntosGuardadosTableFilterComposer
    extends Composer<_$BaseLocal, $PuntosGuardadosTable> {
  $$PuntosGuardadosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get tomadoEn => $composableBuilder(
    column: $table.tomadoEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PuntosGuardadosTableOrderingComposer
    extends Composer<_$BaseLocal, $PuntosGuardadosTable> {
  $$PuntosGuardadosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get tomadoEn => $composableBuilder(
    column: $table.tomadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PuntosGuardadosTableAnnotationComposer
    extends Composer<_$BaseLocal, $PuntosGuardadosTable> {
  $$PuntosGuardadosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get latitud =>
      $composableBuilder(column: $table.latitud, builder: (column) => column);

  GeneratedColumn<double> get longitud =>
      $composableBuilder(column: $table.longitud, builder: (column) => column);

  GeneratedColumn<DateTime> get tomadoEn =>
      $composableBuilder(column: $table.tomadoEn, builder: (column) => column);
}

class $$PuntosGuardadosTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $PuntosGuardadosTable,
          FilaPunto,
          $$PuntosGuardadosTableFilterComposer,
          $$PuntosGuardadosTableOrderingComposer,
          $$PuntosGuardadosTableAnnotationComposer,
          $$PuntosGuardadosTableCreateCompanionBuilder,
          $$PuntosGuardadosTableUpdateCompanionBuilder,
          (
            FilaPunto,
            BaseReferences<_$BaseLocal, $PuntosGuardadosTable, FilaPunto>,
          ),
          FilaPunto,
          PrefetchHooks Function()
        > {
  $$PuntosGuardadosTableTableManager(
    _$BaseLocal db,
    $PuntosGuardadosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PuntosGuardadosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PuntosGuardadosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PuntosGuardadosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> latitud = const Value.absent(),
                Value<double> longitud = const Value.absent(),
                Value<DateTime> tomadoEn = const Value.absent(),
              }) => PuntosGuardadosCompanion(
                id: id,
                latitud: latitud,
                longitud: longitud,
                tomadoEn: tomadoEn,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double latitud,
                required double longitud,
                required DateTime tomadoEn,
              }) => PuntosGuardadosCompanion.insert(
                id: id,
                latitud: latitud,
                longitud: longitud,
                tomadoEn: tomadoEn,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PuntosGuardadosTable, FilaPunto>(table),
                  BaseReferences<_$BaseLocal, $PuntosGuardadosTable, FilaPunto>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PuntosGuardadosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $PuntosGuardadosTable,
      FilaPunto,
      $$PuntosGuardadosTableFilterComposer,
      $$PuntosGuardadosTableOrderingComposer,
      $$PuntosGuardadosTableAnnotationComposer,
      $$PuntosGuardadosTableCreateCompanionBuilder,
      $$PuntosGuardadosTableUpdateCompanionBuilder,
      (
        FilaPunto,
        BaseReferences<_$BaseLocal, $PuntosGuardadosTable, FilaPunto>,
      ),
      FilaPunto,
      PrefetchHooks Function()
    >;
typedef $$InstantaneasTableCreateCompanionBuilder =
    InstantaneasCompanion Function({
      required String clave,
      required String json,
      required DateTime guardadaEn,
      Value<int> rowid,
    });
typedef $$InstantaneasTableUpdateCompanionBuilder =
    InstantaneasCompanion Function({
      Value<String> clave,
      Value<String> json,
      Value<DateTime> guardadaEn,
      Value<int> rowid,
    });

class $$InstantaneasTableFilterComposer
    extends Composer<_$BaseLocal, $InstantaneasTable> {
  $$InstantaneasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get guardadaEn => $composableBuilder(
    column: $table.guardadaEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InstantaneasTableOrderingComposer
    extends Composer<_$BaseLocal, $InstantaneasTable> {
  $$InstantaneasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get guardadaEn => $composableBuilder(
    column: $table.guardadaEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InstantaneasTableAnnotationComposer
    extends Composer<_$BaseLocal, $InstantaneasTable> {
  $$InstantaneasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clave =>
      $composableBuilder(column: $table.clave, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get guardadaEn => $composableBuilder(
    column: $table.guardadaEn,
    builder: (column) => column,
  );
}

class $$InstantaneasTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $InstantaneasTable,
          FilaInstantanea,
          $$InstantaneasTableFilterComposer,
          $$InstantaneasTableOrderingComposer,
          $$InstantaneasTableAnnotationComposer,
          $$InstantaneasTableCreateCompanionBuilder,
          $$InstantaneasTableUpdateCompanionBuilder,
          (
            FilaInstantanea,
            BaseReferences<_$BaseLocal, $InstantaneasTable, FilaInstantanea>,
          ),
          FilaInstantanea,
          PrefetchHooks Function()
        > {
  $$InstantaneasTableTableManager(_$BaseLocal db, $InstantaneasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstantaneasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstantaneasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstantaneasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clave = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> guardadaEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstantaneasCompanion(
                clave: clave,
                json: json,
                guardadaEn: guardadaEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clave,
                required String json,
                required DateTime guardadaEn,
                Value<int> rowid = const Value.absent(),
              }) => InstantaneasCompanion.insert(
                clave: clave,
                json: json,
                guardadaEn: guardadaEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InstantaneasTable, FilaInstantanea>(table),
                  BaseReferences<
                    _$BaseLocal,
                    $InstantaneasTable,
                    FilaInstantanea
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InstantaneasTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $InstantaneasTable,
      FilaInstantanea,
      $$InstantaneasTableFilterComposer,
      $$InstantaneasTableOrderingComposer,
      $$InstantaneasTableAnnotationComposer,
      $$InstantaneasTableCreateCompanionBuilder,
      $$InstantaneasTableUpdateCompanionBuilder,
      (
        FilaInstantanea,
        BaseReferences<_$BaseLocal, $InstantaneasTable, FilaInstantanea>,
      ),
      FilaInstantanea,
      PrefetchHooks Function()
    >;

class $BaseLocalManager {
  final _$BaseLocal _db;
  $BaseLocalManager(this._db);
  $$PendientesTableTableManager get pendientes =>
      $$PendientesTableTableManager(_db, _db.pendientes);
  $$PuntosGuardadosTableTableManager get puntosGuardados =>
      $$PuntosGuardadosTableTableManager(_db, _db.puntosGuardados);
  $$InstantaneasTableTableManager get instantaneas =>
      $$InstantaneasTableTableManager(_db, _db.instantaneas);
}
