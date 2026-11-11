import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/utils/jwt.dart';
import '../../../core/utils/selector_imagen.dart';
import '../../viajes/domain/servicio.dart';
import '../domain/auth.dart';

/// Autenticación contra el backend real (`POST /api/auth/login`).
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._dio, this._tokens);

  final Dio _dio;
  final TokenStorage _tokens;

  @override
  Future<Sesion> login(String email, String password) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(extra: {kSinToken: true}),
      );
      final token = r.data?['token'] as String?;
      if (token == null) {
        throw const AppException(ErrorKind.servidor, 'Respuesta sin token.');
      }
      final sesion = _sesionDeToken(token, email);
      await _tokens.guardar(token);
      return sesion;
    } catch (e) {
      throw _cuentaSinAprobar(e) ?? AppException.from(e);
    }
  }

  /// Un conductor sin aprobar recibe 403 con `estadoValidacion` (PENDIENTE,
  /// EN_REVISION o RECHAZADO) y, si hay, el `motivo` que dejó el administrador.
  AppException? _cuentaSinAprobar(Object e) {
    if (e is! DioException) return null;
    final datos = e.response?.data;
    if (e.response?.statusCode != 403 ||
        datos is! Map<String, dynamic> ||
        datos['estadoValidacion'] is! String) {
      return null;
    }
    final base = datos['error'] as String? ?? 'Tu cuenta aún no está aprobada.';
    final motivo = datos['motivo'];
    return AppException(
      ErrorKind.prohibido,
      motivo is String && motivo.isNotEmpty ? '$base Motivo: $motivo' : base,
      statusCode: 403,
    );
  }

  @override
  Future<Sesion> registrarPasajero(RegistroPasajero datos) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/registro/pasajero',
        data: {
          'nombre': datos.nombre,
          'email': datos.email,
          'telefono': datos.telefono,
          'password': datos.password,
        },
        options: Options(extra: {kSinToken: true}),
      );
    } catch (e) {
      throw AppException.from(e);
    }
    // El registro no devuelve token: se inicia sesión con las mismas credenciales.
    return login(datos.email, datos.password);
  }

  @override
  Future<void> registrarConductor(RegistroConductor d) async {
    MultipartFile foto(ArchivoImagen f) => MultipartFile.fromBytes(
      f.bytes,
      filename: f.nombre,
      contentType: DioMediaType.parse(f.tipo),
    );
    final form = FormData.fromMap({
      'nombre': d.nombre,
      'email': d.email,
      'telefono': d.telefono,
      'password': d.password,
      'confirmPassword': d.password,
      'licencia': d.licencia,
      'placa': d.placa,
      'marca': d.marca,
      'modelo': d.modelo,
      'color': d.color,
      'tarjetaPropiedad': d.tarjetaPropiedad,
      'soat': d.soat,
      'tecnomecanica': d.tecnomecanica,
      'fotoLicencia': foto(d.fotoLicencia),
      'fotoTarjetaPropiedad': foto(d.fotoTarjetaPropiedad),
      'fotoSoat': foto(d.fotoSoat),
      'fotoTecnomecanica': foto(d.fotoTecnomecanica),
    });
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/registro/conductor',
        data: form,
        // Cuatro fotos: la subida puede tardar con datos móviles.
        options: Options(
          extra: {kSinToken: true},
          sendTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<Sesion?> restaurar() async {
    final token = await _tokens.leer();
    if (token == null) return null;
    try {
      final payload = decodificarJwt(token);
      final exp = payload['exp'];
      if (exp is int &&
          DateTime.fromMillisecondsSinceEpoch(exp * 1000)
              .isBefore(DateTime.now())) {
        await _tokens.borrar();
        return null;
      }
      return _sesionDeToken(token, payload['sub'] as String? ?? '');
    } on Object {
      await _tokens.borrar();
      return null;
    }
  }

  @override
  Future<void> logout() => _tokens.borrar();

  @override
  Future<EstadoAprobacion> estadoAprobacion() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/conductor/perfil');
      final v = (r.data?['estadoValidacion'] as String? ?? 'PENDIENTE')
          .toUpperCase();
      return switch (v) {
        'APROBADO' => EstadoAprobacion.aprobado,
        'RECHAZADO' => EstadoAprobacion.rechazado,
        _ => EstadoAprobacion.pendiente,
      };
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Sesion _sesionDeToken(String token, String emailFallback) {
    final p = decodificarJwt(token);
    final roles = p['roles'];
    final rol = Rol.desdeAuthorities(roles is List ? roles : [roles]);
    if (rol == null) {
      throw const AppException(
        ErrorKind.prohibido,
        'Tu cuenta no tiene un rol compatible con la app.',
      );
    }
    return Sesion(
      token: token,
      rol: rol,
      email: p['sub'] as String? ?? emailFallback,
      userId: p['userId']?.toString(),
    );
  }
}
