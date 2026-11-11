import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../errors/app_exception.dart';
import 'token_storage.dart';

/// Marca de petición pública (login): no lleva token ni dispara cierre de sesión.
const String kSinToken = 'sinToken';

/// Crea el cliente Dio con interceptores: token, mapeo de errores y logging (solo debug).
/// [prefijo] se agrega a la URL base (`/api` para el backend; vacío para la Lambda).
///
/// El backend no tiene refresh de token (ver docs/PENDIENTES_BACKEND.md): ante un
/// 401 en una ruta autenticada se invoca [onSesionExpirada] para cerrar sesión.
Dio crearDio({
  required TokenStorage tokens,
  required void Function() onSesionExpirada,
  String? baseUrl,
  String prefijo = '/api',
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${baseUrl ?? Env.apiBaseUrl}$prefijo',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final publica = options.extra[kSinToken] == true;
        final token = publica ? null : await tokens.leer();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) {
        final publica = e.requestOptions.extra[kSinToken] == true;
        if (e.response?.statusCode == 401 && !publica) {
          onSesionExpirada();
        }
        handler.next(e.copyWith(error: AppException.from(e)));
      },
    ),
  );
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(requestHeader: false, responseBody: false),
    );
  }
  return dio;
}
