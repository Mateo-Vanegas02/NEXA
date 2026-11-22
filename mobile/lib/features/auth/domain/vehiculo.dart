/// Moto registrada por el conductor (`GET /api/conductor/vehiculos`).
class VehiculoConductor {
  const VehiculoConductor({
    required this.id,
    required this.placa,
    this.marca = '',
    this.modelo = '',
    this.color = '',
    this.activo = false,
    this.verificado = false,
  });

  factory VehiculoConductor.fromJson(Map<String, dynamic> j) =>
      VehiculoConductor(
        id: j['id'] as String? ?? '',
        placa: j['placa'] as String? ?? '',
        marca: j['marca'] as String? ?? '',
        modelo: j['modelo'] as String? ?? '',
        color: j['color'] as String? ?? '',
        activo: j['activo'] as bool? ?? false,
        verificado: j['verificado'] as bool? ?? false,
      );

  final String id;
  final String placa;
  final String marca;
  final String modelo;
  final String color;

  /// La moto con la que trabaja ahora (una por conductor).
  final bool activo;

  /// NEXA ya revisó sus documentos.
  final bool verificado;
}

abstract interface class VehiculosRepository {
  Future<List<VehiculoConductor>> listar();
}
