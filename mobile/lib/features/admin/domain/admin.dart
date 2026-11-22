import 'dart:typed_data';

/// Operación en vivo (`GET /api/admin/operacion`).
class OperacionAdmin {
  const OperacionAdmin({
    this.viajesHoy = 0,
    this.finalizadosHoy = 0,
    this.canceladosHoy = 0,
    this.enCurso = 0,
    this.yendoARecoger = 0,
    this.solicitudesAbiertas = 0,
    this.conductoresEnLinea = 0,
    this.conductoresDisponibles = 0,
    this.conductoresPendientes = 0,
    this.flota = const [],
    this.alertas = const [],
  });

  factory OperacionAdmin.fromJson(Map<String, dynamic> j) {
    int n(String k) => (j[k] as num?)?.toInt() ?? 0;
    return OperacionAdmin(
      viajesHoy: n('viajesHoy'),
      finalizadosHoy: n('finalizadosHoy'),
      canceladosHoy: n('canceladosHoy'),
      enCurso: n('enCurso'),
      yendoARecoger: n('yendoARecoger'),
      solicitudesAbiertas: n('solicitudesAbiertas'),
      conductoresEnLinea: n('conductoresEnLinea'),
      conductoresDisponibles: n('conductoresDisponibles'),
      conductoresPendientes: n('conductoresPendientes'),
      flota: [
        for (final e in (j['flota'] as List<dynamic>? ?? const []))
          PosicionFlota.fromJson(e as Map<String, dynamic>),
      ],
      alertas: [
        for (final e in (j['alertas'] as List<dynamic>? ?? const []))
          AlertaAdmin.fromJson(e as Map<String, dynamic>),
      ],
    );
  }

  final int viajesHoy;
  final int finalizadosHoy;
  final int canceladosHoy;
  final int enCurso;
  final int yendoARecoger;
  final int solicitudesAbiertas;
  final int conductoresEnLinea;
  final int conductoresDisponibles;
  final int conductoresPendientes;
  final List<PosicionFlota> flota;
  final List<AlertaAdmin> alertas;
}

/// Una moto en línea (sin identificar al conductor).
class PosicionFlota {
  const PosicionFlota({
    required this.latitud,
    required this.longitud,
    this.disponible = true,
  });

  factory PosicionFlota.fromJson(Map<String, dynamic> j) => PosicionFlota(
    latitud: (j['latitud'] as num?)?.toDouble() ?? 0,
    longitud: (j['longitud'] as num?)?.toDouble() ?? 0,
    disponible: j['disponible'] as bool? ?? true,
  );

  final double latitud;
  final double longitud;
  final bool disponible;
}

enum TipoAlerta {
  solicitudSinConductor,
  documentoVencido,
  conductoresPorAprobar,
  otra,
}

class AlertaAdmin {
  const AlertaAdmin({
    required this.tipo,
    required this.texto,
    this.servicioId,
    this.minutos = 0,
  });

  factory AlertaAdmin.fromJson(Map<String, dynamic> j) => AlertaAdmin(
    tipo: switch (j['tipo']) {
      'SOLICITUD_SIN_CONDUCTOR' => TipoAlerta.solicitudSinConductor,
      'CONDUCTORES_POR_APROBAR' => TipoAlerta.conductoresPorAprobar,
      'DOCUMENTO_VENCIDO' => TipoAlerta.documentoVencido,
      _ => TipoAlerta.otra,
    },
    texto: j['texto'] as String? ?? '',
    servicioId: j['servicioId'] as String?,
    minutos: (j['minutos'] as num?)?.toInt() ?? 0,
  );

  final TipoAlerta tipo;

  /// Texto armado por el servidor.
  final String texto;
  final String? servicioId;
  final int minutos;
}

/// Estado de un conductor en la revisión (los del servidor).
enum EstadoRevision {
  pendiente('PENDIENTE'),
  enRevision('EN_REVISION'),
  aprobado('APROBADO'),
  rechazado('RECHAZADO');

  const EstadoRevision(this.api);
  final String api;

  static EstadoRevision? leer(String? v) {
    for (final e in values) {
      if (e.api == v) return e;
    }
    return null;
  }
}

/// Conductor en la lista del admin (`GET /api/admin/conductores?estado=`).
class ConductorRevision {
  const ConductorRevision({
    required this.email,
    this.nombre = '',
    this.telefono,
    this.fechaRegistro,
    this.estado,
    this.revisionMensaje,
  });

  factory ConductorRevision.fromJson(Map<String, dynamic> j) =>
      ConductorRevision(
        email: j['email'] as String? ?? '',
        nombre:
            (j['nombre_y_Apellido'] ?? j['nombre'] ?? j['nombreYApellido'])
                as String? ??
            '',
        telefono: j['ntelefono']?.toString(),
        fechaRegistro: DateTime.tryParse(j['fechaRegistro']?.toString() ?? ''),
        estado: EstadoRevision.leer(j['estadoValidacion'] as String?),
        revisionMensaje: j['revisionMensaje'] as String?,
      );

  final String email;
  final String nombre;
  final String? telefono;
  final DateTime? fechaRegistro;
  final EstadoRevision? estado;
  final String? revisionMensaje;
}

/// Foto de un documento que subió el conductor, con el número que declaró.
class DocumentoRevision {
  const DocumentoRevision({
    required this.id,
    required this.tipo,
    this.numeroDeclarado,
    this.contentType = '',
    this.subidoEn,
    this.venceEl,
  });

  factory DocumentoRevision.fromJson(Map<String, dynamic> j) =>
      DocumentoRevision(
        id: j['id'] as String? ?? '',
        tipo: j['tipo'] as String? ?? '',
        numeroDeclarado: j['numeroDeclarado'] as String?,
        contentType: j['contentType'] as String? ?? '',
        subidoEn: DateTime.tryParse(j['subidoEn']?.toString() ?? ''),
        venceEl: DateTime.tryParse(j['venceEl']?.toString() ?? ''),
      );

  /// La tarjeta de propiedad no vence; los demás sí.
  bool get vence => tipo != 'TARJETA_PROPIEDAD';

  final String id;

  /// LICENCIA, TARJETA_PROPIEDAD, SOAT o TECNOMECANICA.
  final String tipo;
  final String? numeroDeclarado;
  final String contentType;
  final DateTime? subidoEn;

  /// Vencimiento anotado por un admin (null si falta).
  final DateTime? venceEl;

  bool get esImagen => contentType.startsWith('image/');
}

/// Moto registrada por un conductor, vista por el admin.
class VehiculoRevision {
  const VehiculoRevision({
    required this.id,
    required this.placa,
    this.marca = '',
    this.modelo = '',
    this.color = '',
    this.verificado = false,
  });

  factory VehiculoRevision.fromJson(Map<String, dynamic> j) => VehiculoRevision(
    id: j['id'] as String? ?? '',
    placa: j['placa'] as String? ?? '',
    marca: j['marca'] as String? ?? '',
    modelo: j['modelo'] as String? ?? '',
    color: j['color'] as String? ?? '',
    verificado: j['verificado'] as bool? ?? false,
  );

  final String id;
  final String placa;
  final String marca;
  final String modelo;
  final String color;
  final bool verificado;
}

/// Lo que se necesita para decidir sobre un conductor.
class ExpedienteConductor {
  const ExpedienteConductor({
    required this.documentos,
    required this.vehiculos,
    this.verificado = false,
  });

  final List<DocumentoRevision> documentos;
  final List<VehiculoRevision> vehiculos;

  /// La última verificación (automática o manual) dio VERIFIED: ya se puede
  /// aprobar sin otro paso.
  final bool verificado;
}

abstract interface class AdminRepository {
  Future<OperacionAdmin> operacion();
  Future<List<ConductorRevision>> conductores(EstadoRevision estado);
  Future<ExpedienteConductor> expediente(String email);
  Future<Uint8List> archivo(String documentoId);

  /// Aprueba (tras marcarlo verificado a mano si hace falta) o rechaza.
  Future<void> decidir(
    String email, {
    required bool aprobar,
    required String motivo,
    bool marcarVerificado = false,
  });

  /// Anota (o borra con null) la fecha de vencimiento leída en la foto.
  Future<void> fijarVencimiento(String documentoId, DateTime? venceEl);

  /// Pide al conductor información adicional (queda EN_REVISION).
  Future<void> pedirInformacion(String email, String mensaje);
}
