// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'servicio.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Coordenada _$CoordenadaFromJson(Map<String, dynamic> json) => _Coordenada(
  latitud: (json['latitud'] as num).toDouble(),
  longitud: (json['longitud'] as num).toDouble(),
);

Map<String, dynamic> _$CoordenadaToJson(_Coordenada instance) =>
    <String, dynamic>{
      'latitud': instance.latitud,
      'longitud': instance.longitud,
    };

_Participante _$ParticipanteFromJson(Map<String, dynamic> json) =>
    _Participante(
      id: leerIdParticipante(json, 'id') as String?,
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String?,
      telefono: json['telefono'] as String?,
      calificacion: (json['calificacion'] as num?)?.toDouble(),
      viajes: (json['viajes'] as num?)?.toInt(),
      nivel: (json['nivel'] as num?)?.toInt(),
      vehiculo: json['vehiculo'] as String?,
      placa: json['placa'] as String?,
      fotoUrl: json['fotoUrl'] as String?,
    );

Map<String, dynamic> _$ParticipanteToJson(_Participante instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'email': instance.email,
      'telefono': instance.telefono,
      'calificacion': instance.calificacion,
      'viajes': instance.viajes,
      'nivel': instance.nivel,
      'vehiculo': instance.vehiculo,
      'placa': instance.placa,
      'fotoUrl': instance.fotoUrl,
    };

_Servicio _$ServicioFromJson(Map<String, dynamic> json) => _Servicio(
  id: json['id'] as String,
  estado: $enumDecode(_$EstadoServicioEnumMap, json['estado']),
  pasajero: json['pasajero'] == null
      ? null
      : Participante.fromJson(json['pasajero'] as Map<String, dynamic>),
  conductor: json['conductor'] == null
      ? null
      : Participante.fromJson(json['conductor'] as Map<String, dynamic>),
  origen: json['origen'] as String? ?? '',
  destino: json['destino'] as String? ?? '',
  distanciaKM: (json['distanciaKM'] as num?)?.toDouble() ?? 0,
  ubicacionOrigen: json['ubicacionOrigen'] == null
      ? null
      : Coordenada.fromJson(json['ubicacionOrigen'] as Map<String, dynamic>),
  ubicacionDestino: json['ubicacionDestino'] == null
      ? null
      : Coordenada.fromJson(json['ubicacionDestino'] as Map<String, dynamic>),
  fechaHora: json['fechaHora'] == null
      ? null
      : DateTime.parse(json['fechaHora'] as String),
  fechaLlegada: json['fechaLlegada'] == null
      ? null
      : DateTime.parse(json['fechaLlegada'] as String),
  fechaInicio: json['fechaInicio'] == null
      ? null
      : DateTime.parse(json['fechaInicio'] as String),
  fechaFinalizacion: json['fechaFinalizacion'] == null
      ? null
      : DateTime.parse(json['fechaFinalizacion'] as String),
  duracionEstimadaMin: (json['duracionEstimadaMin'] as num?)?.toDouble() ?? 0,
  rutaGeometria: json['rutaGeometria'] as String?,
  pasosRuta:
      (json['pasosRuta'] as List<dynamic>?)
          ?.map((e) => PasoRuta.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PasoRuta>[],
  tarifa: (json['tarifa'] as num?)?.toDouble() ?? 0,
  extraVoluntario: (json['extraVoluntario'] as num?)?.toDouble() ?? 0,
  deudaCobrada: (json['deudaCobrada'] as num?)?.toDouble() ?? 0,
  finalizadoAntesDelDestino:
      json['finalizadoAntesDelDestino'] as bool? ?? false,
  fraccionCobrada: (json['fraccionCobrada'] as num?)?.toDouble(),
  metodoPago: json['metodoPago'] as String?,
  calificacionConductor: (json['calificacionConductor'] as num?)?.toDouble(),
  calificacionPasajero: (json['calificacionPasajero'] as num?)?.toDouble(),
  nivelPasajero: (json['nivelPasajero'] as num?)?.toInt() ?? 0,
  xpGanadoPasajero: (json['xpGanadoPasajero'] as num?)?.toInt() ?? 0,
  xpGanadoConductor: (json['xpGanadoConductor'] as num?)?.toInt() ?? 0,
  gananciaEstimada: (json['gananciaEstimada'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ServicioToJson(_Servicio instance) => <String, dynamic>{
  'id': instance.id,
  'estado': _$EstadoServicioEnumMap[instance.estado]!,
  'pasajero': instance.pasajero,
  'conductor': instance.conductor,
  'origen': instance.origen,
  'destino': instance.destino,
  'distanciaKM': instance.distanciaKM,
  'ubicacionOrigen': instance.ubicacionOrigen,
  'ubicacionDestino': instance.ubicacionDestino,
  'fechaHora': instance.fechaHora?.toIso8601String(),
  'fechaLlegada': instance.fechaLlegada?.toIso8601String(),
  'fechaInicio': instance.fechaInicio?.toIso8601String(),
  'fechaFinalizacion': instance.fechaFinalizacion?.toIso8601String(),
  'duracionEstimadaMin': instance.duracionEstimadaMin,
  'rutaGeometria': instance.rutaGeometria,
  'pasosRuta': instance.pasosRuta,
  'tarifa': instance.tarifa,
  'extraVoluntario': instance.extraVoluntario,
  'deudaCobrada': instance.deudaCobrada,
  'finalizadoAntesDelDestino': instance.finalizadoAntesDelDestino,
  'fraccionCobrada': instance.fraccionCobrada,
  'metodoPago': instance.metodoPago,
  'calificacionConductor': instance.calificacionConductor,
  'calificacionPasajero': instance.calificacionPasajero,
  'nivelPasajero': instance.nivelPasajero,
  'xpGanadoPasajero': instance.xpGanadoPasajero,
  'xpGanadoConductor': instance.xpGanadoConductor,
  'gananciaEstimada': instance.gananciaEstimada,
};

const _$EstadoServicioEnumMap = {
  EstadoServicio.solicitado: 'SOLICITADO',
  EstadoServicio.aceptado: 'ACEPTADO',
  EstadoServicio.enCurso: 'EN_CURSO',
  EstadoServicio.finalizado: 'FINALIZADO',
  EstadoServicio.cancelado: 'CANCELADO',
};

_DesglosePasajero _$DesglosePasajeroFromJson(Map<String, dynamic> json) =>
    _DesglosePasajero(
      tarifa: (json['tarifa'] as num?)?.toDouble() ?? 0,
      descuentoNivel: (json['descuentoNivel'] as num?)?.toDouble() ?? 0,
      recargoEspera: (json['recargoEspera'] as num?)?.toDouble() ?? 0,
      extraVoluntario: (json['extraVoluntario'] as num?)?.toDouble() ?? 0,
      totalPasajero: (json['totalPasajero'] as num?)?.toDouble() ?? 0,
      deudaAnterior: (json['deudaAnterior'] as num?)?.toDouble() ?? 0,
      totalAPagar: (json['totalAPagar'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$DesglosePasajeroToJson(_DesglosePasajero instance) =>
    <String, dynamic>{
      'tarifa': instance.tarifa,
      'descuentoNivel': instance.descuentoNivel,
      'recargoEspera': instance.recargoEspera,
      'extraVoluntario': instance.extraVoluntario,
      'totalPasajero': instance.totalPasajero,
      'deudaAnterior': instance.deudaAnterior,
      'totalAPagar': instance.totalAPagar,
    };

_DesgloseConductor _$DesgloseConductorFromJson(Map<String, dynamic> json) =>
    _DesgloseConductor(
      recargoEspera: (json['recargoEspera'] as num?)?.toDouble() ?? 0,
      extraVoluntario: (json['extraVoluntario'] as num?)?.toDouble() ?? 0,
      gananciaConductor: (json['gananciaConductor'] as num?)?.toDouble() ?? 0,
      cobrarAlPasajero: (json['cobrarAlPasajero'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$DesgloseConductorToJson(_DesgloseConductor instance) =>
    <String, dynamic>{
      'recargoEspera': instance.recargoEspera,
      'extraVoluntario': instance.extraVoluntario,
      'gananciaConductor': instance.gananciaConductor,
      'cobrarAlPasajero': instance.cobrarAlPasajero,
    };

_Ingreso _$IngresoFromJson(Map<String, dynamic> json) => _Ingreso(
  fecha: json['fecha'] as String,
  monto: (json['monto'] as num?)?.toDouble() ?? 0,
  montoBruto: (json['montoBruto'] as num?)?.toDouble() ?? 0,
  descripcion: json['descripcion'] as String? ?? '',
  hora: json['hora'] as String?,
);

Map<String, dynamic> _$IngresoToJson(_Ingreso instance) => <String, dynamic>{
  'fecha': instance.fecha,
  'monto': instance.monto,
  'montoBruto': instance.montoBruto,
  'descripcion': instance.descripcion,
  'hora': instance.hora,
};
