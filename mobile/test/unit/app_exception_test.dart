import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/errors/app_exception.dart';

DioException _dio(int? status, [Object? data]) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    response: status == null
        ? null
        : Response<Object?>(
            requestOptions: req,
            statusCode: status,
            data: data,
          ),
  );
}

void main() {
  test('sin respuesta → error de red', () {
    expect(AppException.from(_dio(null)).kind, ErrorKind.red);
  });

  test('401 usa el mensaje del backend', () {
    final e = AppException.from(_dio(401, {'error': 'Credenciales malas'}));
    expect(e.kind, ErrorKind.noAutenticado);
    expect(e.mensaje, 'Credenciales malas');
  });

  test('403 sin cuerpo usa mensaje por defecto', () {
    final e = AppException.from(_dio(403));
    expect(e.kind, ErrorKind.prohibido);
    expect(e.statusCode, 403);
  });

  test('404, 400 y 500 se clasifican', () {
    expect(AppException.from(_dio(404)).kind, ErrorKind.noEncontrado);
    expect(
      AppException.from(_dio(400, {'error': 'x'})).kind,
      ErrorKind.validacion,
    );
    expect(AppException.from(_dio(500)).kind, ErrorKind.servidor);
  });

  test('una AppException se conserva y otros errores son desconocidos', () {
    const original = AppException(ErrorKind.red, 'm');
    expect(AppException.from(original), same(original));
    expect(AppException.from(StateError('x')).kind, ErrorKind.desconocido);
  });

  test('DioException con AppException interna la reutiliza', () {
    const inner = AppException(ErrorKind.prohibido, 'interno');
    final d = DioException(
      requestOptions: RequestOptions(path: '/'),
      error: inner,
    );
    expect(AppException.from(d), same(inner));
  });
}
