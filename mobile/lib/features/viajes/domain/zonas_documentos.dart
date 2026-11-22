/// Zona con más solicitudes recientes (`GET /api/conductor/zonas`): el centro
/// de una celda de ~550 m, nunca el punto de un pasajero.
class ZonaDemanda {
  const ZonaDemanda({
    required this.latitud,
    required this.longitud,
    this.solicitudes = 0,
    this.intensidad = 0,
  });

  factory ZonaDemanda.fromJson(Map<String, dynamic> j) => ZonaDemanda(
    latitud: (j['latitud'] as num?)?.toDouble() ?? 0,
    longitud: (j['longitud'] as num?)?.toDouble() ?? 0,
    solicitudes: (j['solicitudes'] as num?)?.toInt() ?? 0,
    intensidad: (j['intensidad'] as num?)?.toDouble() ?? 0,
  );

  final double latitud;
  final double longitud;
  final int solicitudes;

  /// 0..1 (1 = la zona con más solicitudes).
  final double intensidad;
}

/// Vigencia de un documento (la calcula el servidor con la fecha que anotó el
/// admin).
enum Vigencia { noVence, sinFecha, vigente, porVencer, vencido }

Vigencia leerVigencia(String? v) => switch (v) {
  'NO_VENCE' => Vigencia.noVence,
  'VIGENTE' => Vigencia.vigente,
  'POR_VENCER' => Vigencia.porVencer,
  'VENCIDO' => Vigencia.vencido,
  _ => Vigencia.sinFecha,
};

/// Documento del conductor con su vencimiento (`GET /api/conductor/documentos`).
class MiDocumento {
  const MiDocumento({
    required this.id,
    required this.tipo,
    this.venceEl,
    this.vigencia = Vigencia.sinFecha,
    this.diasRestantes,
  });

  factory MiDocumento.fromJson(Map<String, dynamic> j) => MiDocumento(
    id: j['id'] as String? ?? '',
    tipo: j['tipo'] as String? ?? '',
    venceEl: DateTime.tryParse(j['venceEl']?.toString() ?? ''),
    vigencia: leerVigencia(j['vigencia'] as String?),
    diasRestantes: (j['diasRestantes'] as num?)?.toInt(),
  );

  final String id;

  /// LICENCIA, TARJETA_PROPIEDAD, SOAT o TECNOMECANICA.
  final String tipo;
  final DateTime? venceEl;
  final Vigencia vigencia;
  final int? diasRestantes;
}

abstract interface class ZonasDocumentosRepository {
  Future<List<ZonaDemanda>> zonas();
  Future<List<MiDocumento>> misDocumentos();
}
