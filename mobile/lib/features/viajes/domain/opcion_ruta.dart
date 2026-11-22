/// Qué tiene de especial una ruta ofrecida (lo marca el servidor).
enum EtiquetaRuta { rapida, corta, alternativa }

/// Una ruta desde la posición del conductor hasta su objetivo (la recogida o
/// el destino), calculada por el servidor con OSRM
/// (`POST /api/conductor/rutas/{id}`). La primera es la sugerida.
class OpcionRuta {
  const OpcionRuta({
    required this.indice,
    required this.geometria,
    required this.distanciaKm,
    required this.duracionMin,
    required this.etiqueta,
  });

  factory OpcionRuta.fromJson(Map<String, dynamic> j) => OpcionRuta(
    indice: (j['indice'] as num?)?.toInt() ?? 0,
    geometria: j['geometria'] as String? ?? '',
    distanciaKm: (j['distanciaKm'] as num?)?.toDouble() ?? 0,
    duracionMin: (j['duracionMin'] as num?)?.toDouble() ?? 0,
    etiqueta: switch (j['etiqueta']) {
      'RAPIDA' => EtiquetaRuta.rapida,
      'CORTA' => EtiquetaRuta.corta,
      _ => EtiquetaRuta.alternativa,
    },
  );

  /// Índice que se envía al elegirla.
  final int indice;

  /// Trazado como polyline codificada (precisión 5).
  final String geometria;
  final double distanciaKm;
  final double duracionMin;
  final EtiquetaRuta etiqueta;
}
