import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/satisfaccion.dart';
import '../domain/satisfaccion_repository.dart';

String _dia(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Cliente de la Lambda `nexa-satisfaccion`. El [Dio] ya apunta a su Function
/// URL y agrega el JWT del admin (ver `satisfaccionDioProvider`).
class ApiSatisfaccionRepository implements SatisfaccionRepository {
  ApiSatisfaccionRepository(this._dio);
  final Dio _dio;

  Future<Json> _get(String ruta, [Map<String, Object?>? query]) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        ruta,
        queryParameters: query,
      );
      return r.data ?? <String, dynamic>{};
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<Resumen> resumen({
    required DateTime desde,
    required DateTime hasta,
  }) async => Resumen.fromJson(
    await _get('/resumen', {'desde': _dia(desde), 'hasta': _dia(hasta)}),
  );

  @override
  Future<Factores> factores(Lado lado) async =>
      Factores.fromJson(await _get('/factores', {'lado': lado.name}));

  @override
  Future<Riesgo> riesgo() async =>
      Riesgo.fromJson(await _get('/riesgo', {'lado': 'todos', 'limite': 50}));

  @override
  Future<ModeloInfo> modelo() async =>
      ModeloInfo.fromJson(await _get('/modelo'));

  @override
  Future<String> entrenar({bool demo = false}) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/entrenamientos',
        queryParameters: demo ? {'demo': true} : null,
      );
      return r.data?['id'] as String? ?? '';
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<Entrenamiento> entrenamiento(String id) async =>
      Entrenamiento.fromJson(await _get('/entrenamientos/$id'));

  @override
  Future<void> cancelarEntrenamiento(String id) async {
    try {
      await _dio.delete<void>('/entrenamientos/$id');
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<Programacion> guardarProgramacion(Programacion p) async {
    try {
      final r = await _dio.put<Map<String, dynamic>>(
        '/programacion',
        data: p.toJson(),
      );
      return Programacion.fromJson(r.data ?? <String, dynamic>{});
    } catch (e) {
      throw AppException.from(e);
    }
  }
}

/// Se usa cuando la app real no tiene `SATISFACCION_URL`: cada consulta falla
/// con un mensaje claro en vez de llamar a una URL vacía.
class SatisfaccionNoConfigurada implements SatisfaccionRepository {
  const SatisfaccionNoConfigurada();

  static const _error = AppException(
    ErrorKind.servidor,
    'El servicio de satisfacción aún no está configurado en esta versión de la app.',
  );

  @override
  Future<Resumen> resumen({required DateTime desde, required DateTime hasta}) =>
      Future.error(_error);

  @override
  Future<Factores> factores(Lado lado) => Future.error(_error);

  @override
  Future<Riesgo> riesgo() => Future.error(_error);

  @override
  Future<ModeloInfo> modelo() => Future.error(_error);

  @override
  Future<String> entrenar({bool demo = false}) => Future.error(_error);

  @override
  Future<Entrenamiento> entrenamiento(String id) => Future.error(_error);

  @override
  Future<void> cancelarEntrenamiento(String id) => Future.error(_error);

  @override
  Future<Programacion> guardarProgramacion(Programacion p) =>
      Future.error(_error);
}
