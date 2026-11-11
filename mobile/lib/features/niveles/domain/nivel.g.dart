// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nivel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Beneficio _$BeneficioFromJson(Map<String, dynamic> json) => _Beneficio(
  clave: json['clave'] as String,
  titulo: json['titulo'] as String,
  descripcion: json['descripcion'] as String? ?? '',
  nivelRequerido: (json['nivelRequerido'] as num?)?.toInt() ?? 0,
  activo: json['activo'] as bool? ?? false,
);

Map<String, dynamic> _$BeneficioToJson(_Beneficio instance) =>
    <String, dynamic>{
      'clave': instance.clave,
      'titulo': instance.titulo,
      'descripcion': instance.descripcion,
      'nivelRequerido': instance.nivelRequerido,
      'activo': instance.activo,
    };

_NivelInfo _$NivelInfoFromJson(Map<String, dynamic> json) => _NivelInfo(
  nivel: (json['nivel'] as num).toInt(),
  xp: (json['xp'] as num).toInt(),
  descuento: (json['descuento'] as num?)?.toDouble(),
  beneficios:
      (json['beneficios'] as List<dynamic>?)
          ?.map((e) => Beneficio.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Beneficio>[],
  comision: (json['comision'] as num?)?.toDouble(),
);

Map<String, dynamic> _$NivelInfoToJson(_NivelInfo instance) =>
    <String, dynamic>{
      'nivel': instance.nivel,
      'xp': instance.xp,
      'descuento': instance.descuento,
      'beneficios': instance.beneficios,
      'comision': instance.comision,
    };

_Requisito _$RequisitoFromJson(Map<String, dynamic> json) => _Requisito(
  texto: json['texto'] as String,
  cumplido: json['cumplido'] as bool? ?? false,
);

Map<String, dynamic> _$RequisitoToJson(_Requisito instance) =>
    <String, dynamic>{'texto': instance.texto, 'cumplido': instance.cumplido};

_ConductorInfo _$ConductorInfoFromJson(Map<String, dynamic> json) =>
    _ConductorInfo(
      comisionActual: (json['comisionActual'] as num).toDouble(),
      comisionSiguiente: (json['comisionSiguiente'] as num?)?.toDouble(),
      calificacion: (json['calificacion'] as num?)?.toDouble(),
      aceptacion: (json['aceptacion'] as num?)?.toDouble() ?? 0,
      cancelacion: (json['cancelacion'] as num?)?.toDouble() ?? 0,
      requisitosSiguiente:
          (json['requisitosSiguiente'] as List<dynamic>?)
              ?.map((e) => Requisito.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Requisito>[],
      bloqueadoPorCalidad: json['bloqueadoPorCalidad'] as bool? ?? false,
    );

Map<String, dynamic> _$ConductorInfoToJson(_ConductorInfo instance) =>
    <String, dynamic>{
      'comisionActual': instance.comisionActual,
      'comisionSiguiente': instance.comisionSiguiente,
      'calificacion': instance.calificacion,
      'aceptacion': instance.aceptacion,
      'cancelacion': instance.cancelacion,
      'requisitosSiguiente': instance.requisitosSiguiente,
      'bloqueadoPorCalidad': instance.bloqueadoPorCalidad,
    };

_NivelEstado _$NivelEstadoFromJson(Map<String, dynamic> json) => _NivelEstado(
  usuarioId: json['usuarioId'] as String,
  rol: json['rol'] as String,
  nivel: (json['nivel'] as num).toInt(),
  xpActual: (json['xpActual'] as num?)?.toInt() ?? 0,
  xpNivelActual: (json['xpNivelActual'] as num?)?.toInt() ?? 0,
  xpSiguienteNivel: (json['xpSiguienteNivel'] as num?)?.toInt(),
  xpFaltante: (json['xpFaltante'] as num?)?.toInt() ?? 0,
  progreso: (json['progreso'] as num?)?.toDouble() ?? 0,
  descuento: (json['descuento'] as num?)?.toDouble() ?? 0,
  prioridadSegundos: (json['prioridadSegundos'] as num?)?.toInt() ?? 0,
  niveles:
      (json['niveles'] as List<dynamic>?)
          ?.map((e) => NivelInfo.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <NivelInfo>[],
  beneficiosActivos:
      (json['beneficiosActivos'] as List<dynamic>?)
          ?.map((e) => Beneficio.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Beneficio>[],
  conductor: json['conductor'] == null
      ? null
      : ConductorInfo.fromJson(json['conductor'] as Map<String, dynamic>),
);

Map<String, dynamic> _$NivelEstadoToJson(_NivelEstado instance) =>
    <String, dynamic>{
      'usuarioId': instance.usuarioId,
      'rol': instance.rol,
      'nivel': instance.nivel,
      'xpActual': instance.xpActual,
      'xpNivelActual': instance.xpNivelActual,
      'xpSiguienteNivel': instance.xpSiguienteNivel,
      'xpFaltante': instance.xpFaltante,
      'progreso': instance.progreso,
      'descuento': instance.descuento,
      'prioridadSegundos': instance.prioridadSegundos,
      'niveles': instance.niveles,
      'beneficiosActivos': instance.beneficiosActivos,
      'conductor': instance.conductor,
    };
