import 'package:dio/dio.dart';

/// Tipos de fallo que entiende la capa de presentación.
enum ErrorKind {
  red,
  noAutenticado,
  prohibido,
  noEncontrado,
  validacion,
  servidor,
  desconocido,
}

class AppException implements Exception {
  const AppException(this.kind, this.mensaje, {this.statusCode});

  final ErrorKind kind;
  final String mensaje;
  final int? statusCode;

  @override
  String toString() => 'AppException($kind, $statusCode, $mensaje)';

  /// Convierte cualquier error (Dio u otro) en [AppException].
  /// El backend responde `{ "error": "mensaje" }` en 4xx.
  static AppException from(Object error) {
    if (error is AppException) return error;
    if (error is DioException) {
      final inner = error.error;
      if (inner is AppException) return inner;
      final status = error.response?.statusCode;
      if (status == null) {
        return const AppException(
          ErrorKind.red,
          'Sin conexión con el servidor. Revisa tu internet.',
        );
      }
      final msg = _mensajeDe(error.response?.data);
      return switch (status) {
        401 => AppException(
          ErrorKind.noAutenticado,
          msg ?? 'Credenciales inválidas o sesión vencida.',
          statusCode: status,
        ),
        403 => AppException(
          ErrorKind.prohibido,
          msg ?? 'No tienes permiso para esta acción.',
          statusCode: status,
        ),
        404 => AppException(
          ErrorKind.noEncontrado,
          msg ?? 'No se encontró el recurso.',
          statusCode: status,
        ),
        >= 400 && < 500 => AppException(
          ErrorKind.validacion,
          msg ?? 'Solicitud inválida.',
          statusCode: status,
        ),
        _ => AppException(
          ErrorKind.servidor,
          msg ?? 'Error del servidor. Intenta más tarde.',
          statusCode: status,
        ),
      };
    }
    return AppException(ErrorKind.desconocido, error.toString());
  }

  static String? _mensajeDe(Object? data) {
    if (data is Map<String, dynamic>) {
      final e = data['error'] ?? data['message'];
      if (e is String && e.isNotEmpty) return e;
    }
    return null;
  }
}
