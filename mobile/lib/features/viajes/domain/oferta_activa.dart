/// Lo que el servidor dice de una solicitud que aún espera conductor
/// (`GET /pasajero/solicitud-activa`): el extra y en qué ola del despacho va.
/// La app solo lo muestra; la ola y los avisados los calcula el servidor.
class OfertaActiva {
  const OfertaActiva({required this.servicioId, this.topeExtra, this.despacho});

  factory OfertaActiva.fromJson(Map<String, dynamic> j) => OfertaActiva(
    servicioId: j['servicioId'] as String? ?? '',
    topeExtra: (j['topeExtra'] as num?)?.toDouble(),
    despacho: j['despacho'] is Map<String, dynamic>
        ? AvisoDespacho.fromJson(j['despacho'] as Map<String, dynamic>)
        : null,
  );

  final String servicioId;

  /// Tope del extra voluntario por viaje.
  final double? topeExtra;
  final AvisoDespacho? despacho;
}

/// Ola del despacho por radio («Ola 2 de 4 · radio 2,5 km»).
class AvisoDespacho {
  const AvisoDespacho({
    required this.ola,
    required this.totalOlas,
    required this.conductoresAvisados,
    this.radioKm,
    this.segundosSiguienteOla,
  });

  factory AvisoDespacho.fromJson(Map<String, dynamic> j) => AvisoDespacho(
    ola: (j['ola'] as num?)?.toInt() ?? 1,
    totalOlas: (j['totalOlas'] as num?)?.toInt() ?? 1,
    conductoresAvisados: (j['conductoresAvisados'] as num?)?.toInt() ?? 0,
    radioKm: (j['radioKm'] as num?)?.toDouble(),
    segundosSiguienteOla: (j['segundosSiguienteOla'] as num?)?.toInt(),
  );

  /// 1 = la primera.
  final int ola;
  final int totalOlas;
  final int conductoresAvisados;

  /// null = sin tope.
  final double? radioKm;

  /// null = ya está en la última.
  final int? segundosSiguienteOla;

  bool get ultima => ola >= totalOlas;
}
