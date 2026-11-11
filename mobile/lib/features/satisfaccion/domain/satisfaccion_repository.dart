import 'satisfaccion.dart';

/// Acceso a la Lambda `nexa-satisfaccion` (contrato v0.1). Solo para el rol admin.
abstract interface class SatisfaccionRepository {
  Future<Resumen> resumen({required DateTime desde, required DateTime hasta});

  Future<Factores> factores(Lado lado);

  /// Todos los viajes en riesgo; la app los filtra por lado.
  Future<Riesgo> riesgo();

  Future<ModeloInfo> modelo();

  /// Lanza un entrenamiento con viajes reales y devuelve su id (422 si aún no
  /// hay datos suficientes, 409 si ya hay uno en curso).
  Future<String> entrenar();

  Future<Entrenamiento> entrenamiento(String id);

  Future<void> cancelarEntrenamiento(String id);

  Future<Programacion> guardarProgramacion(Programacion p);
}
