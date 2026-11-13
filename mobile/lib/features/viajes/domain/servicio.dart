import 'package:freezed_annotation/freezed_annotation.dart';

part 'servicio.freezed.dart';
part 'servicio.g.dart';

enum EstadoServicio {
  @JsonValue('SOLICITADO')
  solicitado,
  @JsonValue('ACEPTADO')
  aceptado,
  @JsonValue('EN_CURSO')
  enCurso,
  @JsonValue('FINALIZADO')
  finalizado,
  @JsonValue('CANCELADO')
  cancelado;

  /// Nombre tal cual lo envía el backend.
  String get codigo => switch (this) {
    solicitado => 'SOLICITADO',
    aceptado => 'ACEPTADO',
    enCurso => 'EN_CURSO',
    finalizado => 'FINALIZADO',
    cancelado => 'CANCELADO',
  };

  bool get activo => this == solicitado || this == aceptado || this == enCurso;
}

@freezed
abstract class Coordenada with _$Coordenada {
  const factory Coordenada({
    required double latitud,
    required double longitud,
  }) = _Coordenada;

  factory Coordenada.fromJson(Map<String, dynamic> json) =>
      _$CoordenadaFromJson(json);
}

/// Id del pasajero o del conductor tal como venga: texto, `idString`, o el
/// objeto que serializaba el servidor antes (`{timestamp, date}`) que no trae
/// el id y se descarta. Así un viaje no deja de leerse por este campo.
Object? leerIdParticipante(Map<dynamic, dynamic> json, String clave) {
  final id = json[clave];
  if (id is String) return id;
  final texto = json['idString'];
  return texto is String ? texto : null;
}

@freezed
abstract class Participante with _$Participante {
  const factory Participante({
    @JsonKey(readValue: leerIdParticipante) String? id,
    @Default('') String nombre,
    String? email,
    String? telefono,
    // Ficha del conductor que el backend completa al aceptar el viaje.
    double? calificacion,
    int? viajes,
    int? nivel,
    String? vehiculo,
    String? placa,
    String? fotoUrl,
  }) = _Participante;

  factory Participante.fromJson(Map<String, dynamic> json) =>
      _$ParticipanteFromJson(json);
}

@freezed
abstract class Servicio with _$Servicio {
  const Servicio._();

  const factory Servicio({
    required String id,
    required EstadoServicio estado,
    Participante? pasajero,
    Participante? conductor,
    @Default('') String origen,
    @Default('') String destino,
    @Default(0) double distanciaKM,
    Coordenada? ubicacionOrigen,
    Coordenada? ubicacionDestino,
    DateTime? fechaHora,
    DateTime? fechaLlegada,
    DateTime? fechaInicio,
    DateTime? fechaFinalizacion,
    @Default(0) double duracionEstimadaMin,
    // Trazado por calles (polyline codificada de OSRM); null = línea recta.
    String? rutaGeometria,
    @Default(0) double tarifa,
    @Default(0) double extraVoluntario,
    @Default(0) double deudaCobrada,
    @Default(false) bool finalizadoAntesDelDestino,
    double? fraccionCobrada,
    String? metodoPago,
    double? calificacionConductor,
    double? calificacionPasajero,
    @Default(0) int nivelPasajero,
    @Default(0) int xpGanadoPasajero,
    @Default(0) int xpGanadoConductor,
    // Lo que ganaría el conductor con esta solicitud (solo en su lista).
    double? gananciaEstimada,
  }) = _Servicio;

  factory Servicio.fromJson(Map<String, dynamic> json) =>
      _$ServicioFromJson(json);
}

/// Desglose que ve el pasajero (`/api/niveles/viajes/{id}/desglose`).
@freezed
abstract class DesglosePasajero with _$DesglosePasajero {
  const factory DesglosePasajero({
    @Default(0) double tarifa,
    @Default(0) double descuentoNivel,
    @Default(0) double recargoEspera,
    @Default(0) double extraVoluntario,
    @Default(0) double totalPasajero,
    @Default(0) double deudaAnterior,
    @Default(0) double totalAPagar,
  }) = _DesglosePasajero;

  factory DesglosePasajero.fromJson(Map<String, dynamic> json) =>
      _$DesglosePasajeroFromJson(json);
}

/// Desglose que ve el conductor.
@freezed
abstract class DesgloseConductor with _$DesgloseConductor {
  const factory DesgloseConductor({
    @Default(0) double recargoEspera,
    @Default(0) double extraVoluntario,
    @Default(0) double gananciaConductor,

    /// Lo que el conductor cobra en efectivo al pasajero (tarifa más el cargo
    /// anterior del pasajero, si se cobró con este viaje). El conductor no ve
    /// la comisión ni la deuda por separado.
    @Default(0) double cobrarAlPasajero,
  }) = _DesgloseConductor;

  factory DesgloseConductor.fromJson(Map<String, dynamic> json) =>
      _$DesgloseConductorFromJson(json);
}

@freezed
abstract class Ingreso with _$Ingreso {
  const factory Ingreso({
    required String fecha,
    @Default(0) double monto,
    @Default(0) double montoBruto,
    @Default('') String descripcion,
  }) = _Ingreso;

  factory Ingreso.fromJson(Map<String, dynamic> json) =>
      _$IngresoFromJson(json);
}

/// Datos para solicitar un viaje. El precio y la distancia los calcula el servidor
/// (`POST /pasajero/cotizar` antes y de nuevo al solicitar); la app no los envía.
class SolicitudViaje {
  const SolicitudViaje({
    required this.origen,
    required this.destino,
    required this.ubicacionOrigen,
    required this.ubicacionDestino,
    this.ubicacionPasajero,
    this.metodoPago = 'efectivo',
    this.aceptaDeuda = false,
  });

  final String origen;
  final String destino;
  final Coordenada ubicacionOrigen;
  final Coordenada ubicacionDestino;

  /// Dónde está el pasajero (GPS). El servidor exige que el punto de recogida
  /// quede a 300 m o menos de esta posición.
  final Coordenada? ubicacionPasajero;
  final String metodoPago;

  /// El pasajero aceptó que su cargo pendiente por cancelación se cobre en este viaje.
  final bool aceptaDeuda;

  Map<String, dynamic> toJson() => {
    'origen': origen,
    'destino': destino,
    'ubicacionOrigen': ubicacionOrigen.toJson(),
    'ubicacionDestino': ubicacionDestino.toJson(),
    'ubicacionPasajero': ?ubicacionPasajero?.toJson(),
    'fechaHora': DateTime.now().toIso8601String(),
    'metodoPago': metodoPago,
    'aceptaDeuda': aceptaDeuda,
  };
}

/// Precio del viaje según el servidor (`POST /pasajero/cotizar`).
class Cotizacion {
  const Cotizacion({
    required this.distanciaKm,
    required this.tarifa,
    required this.descuento,
    required this.precio,
    this.multiplicador = 1,
    this.deudaPendiente = 0,
    required this.totalAPagar,
    this.duracionMin = 0,
    this.rutaGeometria,
  });

  factory Cotizacion.fromJson(Map<String, dynamic> j) => Cotizacion(
    distanciaKm: (j['distanciaKm'] as num?)?.toDouble() ?? 0,
    tarifa: (j['tarifa'] as num?)?.toDouble() ?? 0,
    descuento: (j['descuento'] as num?)?.toDouble() ?? 0,
    precio: (j['precio'] as num?)?.toDouble() ?? 0,
    multiplicador: (j['multiplicador'] as num?)?.toDouble() ?? 1,
    deudaPendiente: (j['deudaPendiente'] as num?)?.toDouble() ?? 0,
    totalAPagar: (j['totalAPagar'] as num?)?.toDouble() ?? 0,
    duracionMin: (j['duracionMin'] as num?)?.toDouble() ?? 0,
    rutaGeometria: j['rutaGeometria'] as String?,
  );

  /// Minutos de la ruta según el servidor (0 si no los dio).
  final double duracionMin;

  /// Trazado por calles (polyline codificada); null = línea recta.
  final String? rutaGeometria;

  final double distanciaKm;

  /// Tarifa del viaje antes del descuento por nivel.
  final double tarifa;
  final double descuento;

  /// Lo que cuesta el viaje con el descuento aplicado.
  final double precio;
  final double multiplicador;

  /// Cargo por cancelación que se cobra junto con este viaje.
  final double deudaPendiente;
  final double totalAPagar;

  bool get tieneDeuda => deudaPendiente > 0;
}

/// Dónde está el pasajero mientras el conductor va a recogerlo
/// (`GET /conductor/pasajero-ubicacion/{id}`).
class PosicionPasajero {
  const PosicionPasajero({
    required this.latitud,
    required this.longitud,
    required this.haceSegundos,
    required this.distanciaRecogidaMetros,
  });

  factory PosicionPasajero.fromJson(Map<String, dynamic> j) => PosicionPasajero(
    latitud: (j['latitud'] as num).toDouble(),
    longitud: (j['longitud'] as num).toDouble(),
    haceSegundos: (j['haceSegundos'] as num?)?.toInt() ?? 0,
    distanciaRecogidaMetros:
        (j['distanciaRecogidaMetros'] as num?)?.toInt() ?? 0,
  );

  final double latitud;
  final double longitud;
  final int haceSegundos;

  /// Distancia del pasajero al punto de recogida.
  final int distanciaRecogidaMetros;
}

/// Saldo del conductor con NEXA en los últimos días (`GET /conductor/saldo`).
/// Es la vista del conductor: sin comisión ni deudas de los pasajeros.
class SaldoConductor {
  const SaldoConductor({
    this.dias = 30,
    this.viajes = 0,
    this.cobradoEfectivo = 0,
    this.ganado = 0,
    this.cargosAFavor = 0,
    this.saldoConNexa = 0,
  });

  factory SaldoConductor.fromJson(Map<String, dynamic> j) => SaldoConductor(
    dias: (j['dias'] as num?)?.toInt() ?? 30,
    viajes: (j['viajes'] as num?)?.toInt() ?? 0,
    cobradoEfectivo: (j['cobradoEfectivo'] as num?)?.toDouble() ?? 0,
    ganado: (j['ganado'] as num?)?.toDouble() ?? 0,
    cargosAFavor: (j['cargosAFavor'] as num?)?.toDouble() ?? 0,
    saldoConNexa: (j['saldoConNexa'] as num?)?.toDouble() ?? 0,
  );

  final int dias;
  final int viajes;
  final double cobradoEfectivo;
  final double ganado;
  final double cargosAFavor;

  /// Positivo: el conductor le debe a NEXA lo cobrado de más en efectivo;
  /// negativo: NEXA le debe a él.
  final double saldoConNexa;
}

/// Dónde va el conductor, con la distancia y el ETA que calcula el servidor
/// (`GET /pasajero/posicion-conductor/{id}`).
class PosicionViaje {
  const PosicionViaje({
    required this.fase,
    required this.latitud,
    required this.longitud,
    required this.distanciaRestanteKm,
    required this.etaMinutos,
  });

  factory PosicionViaje.fromJson(Map<String, dynamic> j) => PosicionViaje(
    fase: j['fase'] as String? ?? '',
    latitud: (j['latitud'] as num).toDouble(),
    longitud: (j['longitud'] as num).toDouble(),
    distanciaRestanteKm: (j['distanciaRestanteKm'] as num?)?.toDouble() ?? 0,
    etaMinutos: (j['etaMinutos'] as num?)?.toInt() ?? 0,
  );

  /// `ACEPTADO` (va a recoger) o `EN_CURSO` (va al destino).
  final String fase;
  final double latitud;
  final double longitud;
  final double distanciaRestanteKm;
  final int etaMinutos;
}

/// Estado de aprobación de un conductor (campo `estadoValidacion` del backend).
enum EstadoAprobacion { pendiente, aprobado, rechazado }
