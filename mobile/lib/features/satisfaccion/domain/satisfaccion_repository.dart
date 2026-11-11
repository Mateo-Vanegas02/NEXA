import 'satisfaccion.dart';

/// Acceso a la Lambda `nexa-satisfaccion` (contrato v0.1). Solo para el rol admin.
abstract interface class SatisfaccionRepository {
  Future<Resumen> resumen({required DateTime desde, required DateTime hasta});

  Future<Factores> factores(Lado lado);

  /// Todos los viajes en riesgo; la app los filtra por lado.
  Future<Riesgo> riesgo();

  Future<ModeloInfo> modelo();

  /// Lanza un entrenamiento y devuelve su id. Con [demo] entrena con datos
  /// sintéticos (cuando aún no hay datos suficientes).
  Future<String> entrenar({bool demo = false});

  Future<Entrenamiento> entrenamiento(String id);

  Future<void> cancelarEntrenamiento(String id);

  Future<Programacion> guardarProgramacion(Programacion p);
}
