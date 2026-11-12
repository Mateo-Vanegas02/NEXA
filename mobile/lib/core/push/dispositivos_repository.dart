import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

/// Token de FCM del teléfono en el servidor (`PUT|DELETE /api/dispositivos`).
abstract class DispositivosRepository {
  Future<void> registrar(String token);
  Future<void> quitar(String token);
}

class ApiDispositivosRepository implements DispositivosRepository {
  ApiDispositivosRepository(this._dio);
  final Dio _dio;

  @override
  Future<void> registrar(String token) async {
    try {
      await _dio.put<Object?>(
        '/dispositivos',
        data: {'token': token, 'plataforma': 'ANDROID'},
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> quitar(String token) async {
    try {
      await _dio.delete<Object?>('/dispositivos', data: {'token': token});
    } catch (e) {
      throw AppException.from(e);
    }
  }
}

/// Modo demostración y pruebas: recuerda lo registrado.
class DispositivosEnMemoria implements DispositivosRepository {
  final Set<String> tokens = {};

  @override
  Future<void> registrar(String token) async => tokens.add(token);

  @override
  Future<void> quitar(String token) async => tokens.remove(token);
}
