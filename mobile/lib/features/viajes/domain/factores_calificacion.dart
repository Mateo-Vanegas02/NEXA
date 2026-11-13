/// Factores que se marcan al calificar (copia del catálogo del servidor,
/// `dominio/regla/FactoresCalificacion` en `main`). Solo se guardan los
/// códigos; el texto sale del `.arb`.
///
/// Con menos de [notaSatisfecho] estrellas se marca qué falló; desde ahí, qué
/// estuvo bien (el mismo corte del modelo de satisfacción). El servidor
/// responde 400 si un código no existe o contradice la nota.
class FactorCalificacion {
  const FactorCalificacion(this.codigo, {required this.positivo});

  final String codigo;
  final bool positivo;
}

abstract final class FactoresCalificacion {
  static const notaSatisfecho = 4.0;

  /// Lo que el pasajero marca sobre el conductor y el viaje.
  static const delPasajero = [
    FactorCalificacion('ACEPTACION_LENTA', positivo: false),
    FactorCalificacion('LLEGADA_TARDE', positivo: false),
    FactorCalificacion('DEJO_ANTES_DEL_DESTINO', positivo: false),
    FactorCalificacion('PRECIO', positivo: false),
    FactorCalificacion('RUTA_LARGA', positivo: false),
    FactorCalificacion('CONDUCCION', positivo: false),
    FactorCalificacion('ACEPTACION_RAPIDA', positivo: true),
    FactorCalificacion('LLEGO_A_TIEMPO', positivo: true),
    FactorCalificacion('BUEN_PRECIO', positivo: true),
    FactorCalificacion('BUENA_RUTA', positivo: true),
    FactorCalificacion('CONDUCCION_SEGURA', positivo: true),
    FactorCalificacion('AMABLE', positivo: true),
  ];

  static bool satisfecho(double nota) => nota >= notaSatisfecho;

  /// Los factores que tienen sentido para esa nota.
  static List<FactorCalificacion> paraNota(double nota) => [
    for (final f in delPasajero)
      if (f.positivo == satisfecho(nota)) f,
  ];

  /// Deja solo los elegidos que siguen valiendo para la nota (al cambiar de
  /// 5 a 2 estrellas, los positivos se descartan), en el orden del catálogo.
  static List<String> validos(double nota, Iterable<String> elegidos) {
    final set = elegidos.toSet();
    return [
      for (final f in paraNota(nota))
        if (set.contains(f.codigo)) f.codigo,
    ];
  }
}
