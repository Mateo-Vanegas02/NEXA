import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/nivel.dart';
import '../domain/niveles_repository.dart';

class ApiNivelesRepository implements NivelesRepository {
  ApiNivelesRepository(this._dio);
  final Dio _dio;

  @override
  Future<NivelEstado> me(String rol) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '/niveles/me',
        queryParameters: {'rol': rol},
      );
      return NivelEstado.fromJson(r.data!);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
