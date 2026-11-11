/// Datos del pasajero que se muestran en el encabezado del dashboard.
class PerfilPasajero {
  const PerfilPasajero({required this.nombre, this.calificacion, this.viajes});

  /// Lee `GET /api/pasajero/perfil` (`nombreCompleto`; calificación y viajes
  /// son opcionales porque el backend aún no los expone).
  factory PerfilPasajero.fromBackend(Map<String, dynamic> json) =>
      PerfilPasajero(
        nombre:
            (json['nombreCompleto'] ?? json['nombre'] ?? json['email'] ?? '')
                as String,
        calificacion: (json['calificacion'] as num?)?.toDouble(),
        viajes: (json['viajes'] as num?)?.toInt(),
      );

  final String nombre;
  final double? calificacion;
  final int? viajes;

  /// Iniciales para el avatar (máx. 2).
  String get iniciales {
    final partes = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    final a = partes.first[0];
    final b = partes.length > 1 ? partes[1][0] : '';
    return (a + b).toUpperCase();
  }
}
