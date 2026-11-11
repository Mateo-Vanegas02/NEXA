/// Modelos del panel de satisfacción del admin (contrato v0.2,
/// `docs/CONTRATO_SATISFACCION.md`). Son clases inmutables con `fromJson`
/// escrito a mano: no necesitan `build_runner`.
///
/// La app no calcula nada de esto: lo entrega la Lambda `nexa-satisfaccion`.
library;

import 'package:flutter/foundation.dart';

typedef Json = Map<String, dynamic>;

double _dbl(Object? v) => v is num ? v.toDouble() : 0;
double? _dblN(Object? v) => v is num ? v.toDouble() : null;
int _int(Object? v) => v is num ? v.toInt() : 0;
int? _intN(Object? v) => v is num ? v.toInt() : null;
String _str(Object? v) => v is String ? v : '';
String? _strN(Object? v) => v is String && v.isNotEmpty ? v : null;
bool _bool(Object? v) => v == true;
Json _obj(Object? v) => v is Map<Object?, Object?>
    ? Map<String, dynamic>.from(v)
    : <String, dynamic>{};
List<Object?> _crudos(Object? v) => v is List<Object?> ? v : const [];
List<Json> _lista(Object? v) => [
  for (final e in _crudos(v))
    if (e is Map<Object?, Object?>) Map<String, dynamic>.from(e),
];
DateTime? _fecha(Object? v) => v is String ? DateTime.tryParse(v) : null;
/// Sin modelo entrenado con viajes reales todavía (`modo` distinto de `real`).
bool _sinModelo(Object? v) => v != 'real';

/// Lado de la satisfacción: la nota que pone el pasajero o la que pone el conductor.
enum Lado {
  pasajero,
  conductor;

  static Lado desde(Object? v) =>
      v == 'conductor' ? Lado.conductor : Lado.pasajero;
}

@immutable
class ResumenLado {
  const ResumenLado({
    required this.satisfechosPct,
    required this.variacionPts,
    required this.tasaRespuestaPct,
    required this.calificaciones,
  });

  factory ResumenLado.fromJson(Json j) => ResumenLado(
    satisfechosPct: _dblN(j['satisfechosPct']),
    variacionPts: _dblN(j['variacionPts']),
    tasaRespuestaPct: _dbl(j['tasaRespuestaPct']),
    calificaciones: _int(j['calificaciones']),
  );

  /// `null` si no hubo calificaciones en el período.
  final double? satisfechosPct;

  /// Diferencia con el período anterior de igual duración (`null` si no hay base).
  final double? variacionPts;
  final double tasaRespuestaPct;
  final int calificaciones;
}

@immutable
class PuntoTendencia {
  const PuntoTendencia({
    required this.semana,
    this.pasajeroPct,
    this.conductorPct,
  });

  factory PuntoTendencia.fromJson(Json j) => PuntoTendencia(
    semana: _str(j['semana']),
    pasajeroPct: _dblN(j['pasajeroPct']),
    conductorPct: _dblN(j['conductorPct']),
  );

  /// Semana ISO, p. ej. `2026-W44`.
  final String semana;
  final double? pasajeroPct;
  final double? conductorPct;
}

@immutable
class Resumen {
  const Resumen({
    required this.sinModelo,
    required this.pasajero,
    required this.conductor,
    required this.tendencia,
    required this.riesgoTotal,
    this.factorPrincipal,
  });

  factory Resumen.fromJson(Json j) => Resumen(
    sinModelo: _sinModelo(j['modo']),
    pasajero: ResumenLado.fromJson(_obj(j['pasajero'])),
    conductor: ResumenLado.fromJson(_obj(j['conductor'])),
    tendencia: [
      for (final p in _lista(j['tendencia'])) PuntoTendencia.fromJson(p),
    ],
    riesgoTotal: _int(j['riesgoTotal']),
    factorPrincipal: _strN(_obj(j['factorPrincipal'])['etiqueta']),
  );

  /// `true` mientras no hay un modelo entrenado con viajes reales: no hay factores ni riesgo.
  final bool sinModelo;
  final ResumenLado pasajero;
  final ResumenLado conductor;
  final List<PuntoTendencia> tendencia;
  final int riesgoTotal;
  final String? factorPrincipal;
}

@immutable
class FactorImportancia {
  const FactorImportancia({
    required this.variable,
    required this.etiqueta,
    required this.pesoPct,
  });

  factory FactorImportancia.fromJson(Json j) => FactorImportancia(
    variable: _str(j['variable']),
    etiqueta: _str(j['etiqueta']),
    pesoPct: _dbl(j['pesoPct']),
  );

  final String variable;
  final String etiqueta;
  final double pesoPct;
}

@immutable
class Tramo {
  const Tramo({
    required this.etiqueta,
    required this.satisfechosPct,
    required this.viajes,
  });

  factory Tramo.fromJson(Json j) => Tramo(
    etiqueta: _str(j['etiqueta']),
    satisfechosPct: _dbl(j['satisfechosPct']),
    viajes: _int(j['viajes']),
  );

  final String etiqueta;
  final double satisfechosPct;
  final int viajes;
}

@immutable
class CurvaFactor {
  const CurvaFactor({
    required this.variable,
    required this.etiqueta,
    required this.tramos,
    this.hallazgo,
  });

  factory CurvaFactor.fromJson(Json j) => CurvaFactor(
    variable: _str(j['variable']),
    etiqueta: _str(j['etiqueta']),
    tramos: [for (final t in _lista(j['tramos'])) Tramo.fromJson(t)],
    hallazgo: _strN(j['hallazgo']),
  );

  final String variable;
  final String etiqueta;
  final List<Tramo> tramos;

  /// Frase lista para mostrar que resume la curva (la redacta el servidor).
  final String? hallazgo;
}

@immutable
class Factores {
  const Factores({
    required this.lado,
    required this.sinModelo,
    required this.importancia,
    required this.otrosCantidad,
    required this.otrosPesoMaximoPct,
    required this.curvas,
  });

  factory Factores.fromJson(Json j) {
    final otros = _obj(j['otrosFactores']);
    return Factores(
      lado: Lado.desde(j['lado']),
      sinModelo: _sinModelo(j['modo']),
      importancia: [
        for (final f in _lista(j['importancia'])) FactorImportancia.fromJson(f),
      ],
      otrosCantidad: _int(otros['cantidad']),
      otrosPesoMaximoPct: _dbl(otros['pesoMaximoPct']),
      curvas: [for (final c in _lista(j['curvas'])) CurvaFactor.fromJson(c)],
    );
  }

  final Lado lado;
  final bool sinModelo;

  /// Ordenada de mayor a menor peso (la entrega así el servidor).
  final List<FactorImportancia> importancia;
  final int otrosCantidad;
  final double otrosPesoMaximoPct;
  final List<CurvaFactor> curvas;
}

enum Severidad { alta, media }

@immutable
class MotivoRiesgo {
  const MotivoRiesgo({required this.texto, required this.severidad});

  factory MotivoRiesgo.fromJson(Json j) => MotivoRiesgo(
    texto: _str(j['texto']),
    severidad: j['severidad'] == 'alta' ? Severidad.alta : Severidad.media,
  );

  final String texto;
  final Severidad severidad;
}

@immutable
class ViajeRiesgo {
  const ViajeRiesgo({
    required this.id,
    required this.fecha,
    required this.origen,
    required this.destino,
    required this.distanciaKm,
    required this.lado,
    required this.probabilidadNo,
    required this.motivos,
  });

  factory ViajeRiesgo.fromJson(Json j) => ViajeRiesgo(
    id: _str(j['id']),
    fecha: _fecha(j['fecha']),
    origen: _str(j['origen']),
    destino: _str(j['destino']),
    distanciaKm: _dbl(j['distanciaKm']),
    lado: Lado.desde(j['lado']),
    probabilidadNo: _dbl(j['probabilidadNo']),
    motivos: [for (final m in _lista(j['motivos'])) MotivoRiesgo.fromJson(m)],
  );

  final String id;
  final DateTime? fecha;
  final String origen;
  final String destino;
  final double distanciaKm;
  final Lado lado;

  /// Probabilidad de que la persona de ese lado no haya quedado satisfecha (0–1).
  final double probabilidadNo;
  final List<MotivoRiesgo> motivos;
}

@immutable
class Riesgo {
  const Riesgo({
    required this.umbral,
    required this.sinModelo,
    required this.viajes,
  });

  factory Riesgo.fromJson(Json j) => Riesgo(
    umbral: _dbl(j['umbral']),
    sinModelo: _sinModelo(j['modo']),
    viajes: [for (final v in _lista(j['viajes'])) ViajeRiesgo.fromJson(v)],
  );

  final double umbral;
  final bool sinModelo;
  final List<ViajeRiesgo> viajes;

  int cuantos(Lado? lado) =>
      lado == null ? viajes.length : viajes.where((v) => v.lado == lado).length;
}

@immutable
class MetricaLado {
  const MetricaLado({
    required this.redPrAuc,
    required this.regresionPrAuc,
    required this.supera,
  });

  factory MetricaLado.fromJson(Json j) => MetricaLado(
    redPrAuc: _dblN(j['redPrAuc']),
    regresionPrAuc: _dblN(j['regresionPrAuc']),
    supera: _bool(j['supera']),
  );

  final double? redPrAuc;
  final double? regresionPrAuc;

  /// `true` si la red supera a la regresión logística.
  final bool supera;
}

@immutable
class DatosLado {
  const DatosLado({required this.calificaciones, required this.no});

  factory DatosLado.fromJson(Json j) =>
      DatosLado(calificaciones: _int(j['calificaciones']), no: _int(j['no']));

  final int calificaciones;
  final int no;
}

@immutable
class DatosModelo {
  const DatosModelo({
    required this.pasajero,
    required this.conductor,
    required this.minimoCalificaciones,
    required this.minimoNo,
    required this.suficientes,
  });

  factory DatosModelo.fromJson(Json j) {
    final m = _obj(j['minimos']);
    return DatosModelo(
      pasajero: DatosLado.fromJson(_obj(j['pasajero'])),
      conductor: DatosLado.fromJson(_obj(j['conductor'])),
      minimoCalificaciones: _int(m['calificaciones']),
      minimoNo: _int(m['no']),
      suficientes: _bool(j['suficientes']),
    );
  }

  final DatosLado pasajero;
  final DatosLado conductor;
  final int minimoCalificaciones;
  final int minimoNo;
  final bool suficientes;
}

enum Frecuencia {
  diaria('diaria'),
  semanal('semanal'),
  cadaHoras('cada_horas');

  const Frecuencia(this.json);
  final String json;

  static Frecuencia desde(Object? v) =>
      values.firstWhere((f) => f.json == v, orElse: () => Frecuencia.semanal);
}

enum DiaSemana {
  lun('LUN'),
  mar('MAR'),
  mie('MIE'),
  jue('JUE'),
  vie('VIE'),
  sab('SAB'),
  dom('DOM');

  const DiaSemana(this.json);
  final String json;

  static DiaSemana? desde(Object? v) {
    for (final d in values) {
      if (d.json == v) return d;
    }
    return null;
  }
}

@immutable
class Programacion {
  const Programacion({
    required this.activa,
    required this.frecuencia,
    required this.dias,
    required this.hora,
    required this.soloConDatosNuevos,
    required this.minimoViajesNuevos,
    required this.publicarSoloSiMejora,
    this.cadaHoras,
    this.proxima,
  });

  factory Programacion.fromJson(Json j) => Programacion(
    activa: _bool(j['activa']),
    frecuencia: Frecuencia.desde(j['frecuencia']),
    dias: {for (final d in _crudos(j['dias'])) ?DiaSemana.desde(d)},
    hora: _strN(j['hora']) ?? '02:00',
    cadaHoras: _intN(j['cadaHoras']),
    soloConDatosNuevos: _bool(j['soloConDatosNuevos']),
    minimoViajesNuevos: _int(j['minimoViajesNuevos']),
    publicarSoloSiMejora: _bool(j['publicarSoloSiMejora']),
    proxima: _fecha(j['proxima']),
  );

  /// Programación por defecto cuando el servidor aún no tiene una.
  static const Programacion porDefecto = Programacion(
    activa: false,
    frecuencia: Frecuencia.semanal,
    dias: {DiaSemana.dom},
    hora: '02:00',
    soloConDatosNuevos: true,
    minimoViajesNuevos: 20,
    publicarSoloSiMejora: true,
  );

  final bool activa;
  final Frecuencia frecuencia;
  final Set<DiaSemana> dias;

  /// `HH:mm` en hora de Bogotá.
  final String hora;
  final int? cadaHoras;
  final bool soloConDatosNuevos;
  final int minimoViajesNuevos;
  final bool publicarSoloSiMejora;

  /// Próxima ejecución calculada por el servidor.
  final DateTime? proxima;

  Json toJson() => {
    'activa': activa,
    'frecuencia': frecuencia.json,
    'dias': frecuencia == Frecuencia.semanal
        ? [
            for (final d in DiaSemana.values)
              if (dias.contains(d)) d.json,
          ]
        : <String>[],
    'hora': hora,
    'cadaHoras': frecuencia == Frecuencia.cadaHoras ? cadaHoras : null,
    'soloConDatosNuevos': soloConDatosNuevos,
    'minimoViajesNuevos': minimoViajesNuevos,
    'publicarSoloSiMejora': publicarSoloSiMejora,
  };

  Programacion copyWith({
    bool? activa,
    Frecuencia? frecuencia,
    Set<DiaSemana>? dias,
    String? hora,
    int? cadaHoras,
    bool? soloConDatosNuevos,
    bool? publicarSoloSiMejora,
  }) => Programacion(
    activa: activa ?? this.activa,
    frecuencia: frecuencia ?? this.frecuencia,
    dias: dias ?? this.dias,
    hora: hora ?? this.hora,
    cadaHoras: cadaHoras ?? this.cadaHoras,
    soloConDatosNuevos: soloConDatosNuevos ?? this.soloConDatosNuevos,
    minimoViajesNuevos: minimoViajesNuevos,
    publicarSoloSiMejora: publicarSoloSiMejora ?? this.publicarSoloSiMejora,
    proxima: proxima,
  );

  /// Validación local para no enviar algo que el servidor rechazará (400).
  bool get esValida => switch (frecuencia) {
    Frecuencia.diaria => true,
    Frecuencia.semanal => dias.isNotEmpty,
    Frecuencia.cadaHoras =>
      cadaHoras != null && cadaHoras! >= 1 && cadaHoras! <= 168,
  };
}

enum EstadoEntrenamiento {
  enCola('EN_COLA'),
  exportando('EXPORTANDO'),
  entrenando('ENTRENANDO'),
  comparando('COMPARANDO'),
  publicando('PUBLICANDO'),
  publicado('PUBLICADO', esFinal: true),
  guardadoSinPublicar('GUARDADO_SIN_PUBLICAR', esFinal: true),
  sinDatosNuevos('SIN_DATOS_NUEVOS', esFinal: true),
  fallido('FALLIDO', esFinal: true),
  cancelado('CANCELADO', esFinal: true),
  faltanDatos('DATOS_INSUFICIENTES', esFinal: true);

  const EstadoEntrenamiento(this.json, {this.esFinal = false});
  final String json;
  final bool esFinal;

  static EstadoEntrenamiento desde(Object? v) => values.firstWhere(
    (e) => e.json == v,
    orElse: () => EstadoEntrenamiento.fallido,
  );
}

enum EstadoPaso {
  hecho,
  enCurso,
  pendiente;

  static EstadoPaso desde(Object? v) => switch (v) {
    'hecho' => EstadoPaso.hecho,
    'en_curso' => EstadoPaso.enCurso,
    _ => EstadoPaso.pendiente,
  };
}

/// Pasos del entrenamiento, en orden.
enum PasoEntrenamiento { exportar, entrenar, comparar, publicar }

@immutable
class Entrenamiento {
  const Entrenamiento({
    required this.id,
    required this.estado,
    required this.progresoPct,
    required this.pasos,
    this.epoca,
    this.epocas,
    this.detalleExportar,
    this.mensaje,
    this.terminaEstimado,
  });

  factory Entrenamiento.fromJson(Json j) {
    final p = _obj(j['pasos']);
    return Entrenamiento(
      id: _str(j['id']),
      estado: EstadoEntrenamiento.desde(j['estado']),
      progresoPct: _int(j['progresoPct']),
      epoca: _intN(j['epoca']),
      epocas: _intN(j['epocas']),
      pasos: {
        for (final paso in PasoEntrenamiento.values)
          paso: EstadoPaso.desde(p[paso.name]),
      },
      detalleExportar: _strN(j['detalleExportar']),
      mensaje: _strN(j['mensaje']),
      terminaEstimado: _fecha(j['terminaEstimado']),
    );
  }

  final String id;
  final EstadoEntrenamiento estado;
  final int progresoPct;
  final int? epoca;
  final int? epocas;
  final Map<PasoEntrenamiento, EstadoPaso> pasos;
  final String? detalleExportar;
  final String? mensaje;
  final DateTime? terminaEstimado;
}

@immutable
class RegistroEntrenamiento {
  const RegistroEntrenamiento({
    required this.id,
    required this.fecha,
    required this.programado,
    required this.estado,
    this.version,
    this.mensaje,
  });

  factory RegistroEntrenamiento.fromJson(Json j) => RegistroEntrenamiento(
    id: _str(j['id']),
    fecha: _fecha(j['fecha']),
    programado: j['origen'] == 'programado',
    version: _intN(j['version']),
    estado: EstadoEntrenamiento.desde(j['estado']),
    mensaje: _strN(j['mensaje']),
  );

  final String id;
  final DateTime? fecha;
  final bool programado;
  final int? version;
  final EstadoEntrenamiento estado;
  final String? mensaje;
}

@immutable
class ModeloInfo {
  const ModeloInfo({
    required this.sinModelo,
    required this.viajes,
    required this.variables,
    required this.pasajero,
    required this.conductor,
    required this.datos,
    required this.programacion,
    required this.historial,
    this.version,
    this.entrenadoEn,
    this.entrenamientoActivo,
  });

  factory ModeloInfo.fromJson(Json j) {
    final m = _obj(j['metricas']);
    final activo = j['entrenamientoActivo'];
    final prog = j['programacion'];
    return ModeloInfo(
      version: _intN(j['version']),
      entrenadoEn: _fecha(j['entrenadoEn']),
      viajes: _int(j['viajes']),
      variables: _int(j['variables']),
      sinModelo: _sinModelo(j['modo']),
      pasajero: MetricaLado.fromJson(_obj(m['pasajero'])),
      conductor: MetricaLado.fromJson(_obj(m['conductor'])),
      datos: DatosModelo.fromJson(_obj(j['datos'])),
      programacion: prog is Map<Object?, Object?>
          ? Programacion.fromJson(_obj(prog))
          : Programacion.porDefecto,
      entrenamientoActivo: activo is Map<Object?, Object?>
          ? Entrenamiento.fromJson(_obj(activo))
          : null,
      historial: [
        for (final h in _lista(j['historial']))
          RegistroEntrenamiento.fromJson(h),
      ],
    );
  }

  /// `null` si nunca se ha publicado un modelo.
  final int? version;
  final DateTime? entrenadoEn;
  final int viajes;
  final int variables;
  final bool sinModelo;
  final MetricaLado pasajero;
  final MetricaLado conductor;
  final DatosModelo datos;
  final Programacion programacion;
  final Entrenamiento? entrenamientoActivo;
  final List<RegistroEntrenamiento> historial;

  ModeloInfo conProgramacion(Programacion p) => ModeloInfo(
    version: version,
    entrenadoEn: entrenadoEn,
    viajes: viajes,
    variables: variables,
    sinModelo: sinModelo,
    pasajero: pasajero,
    conductor: conductor,
    datos: datos,
    programacion: p,
    entrenamientoActivo: entrenamientoActivo,
    historial: historial,
  );
}
