import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/selector_imagen.dart';
import '../domain/perfil.dart';

/// Perfil contra el backend real (`/api/perfil`).
class ApiPerfilRepository implements PerfilRepository {
  ApiPerfilRepository(this._dio);

  final Dio _dio;

  @override
  Future<PerfilUsuario> obtener() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/perfil');
      return PerfilUsuario.fromJson(r.data ?? const {});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<PerfilUsuario> actualizar({
    required String nombre,
    required String telefono,
  }) async {
    try {
      final r = await _dio.put<Map<String, dynamic>>(
        '/perfil',
        data: {'nombre': nombre, 'telefono': telefono},
      );
      return PerfilUsuario.fromJson(r.data ?? const {});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<PerfilUsuario> subirFoto(ArchivoImagen foto) async {
    try {
      final r = await _dio.put<Map<String, dynamic>>(
        '/perfil/foto',
        data: FormData.fromMap({
          'foto': MultipartFile.fromBytes(
            foto.bytes,
            filename: foto.nombre,
            contentType: DioMediaType.parse(foto.tipo),
          ),
        }),
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return PerfilUsuario.fromJson(r.data ?? const {});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<PerfilUsuario> quitarFoto() async {
    try {
      final r = await _dio.delete<Map<String, dynamic>>('/perfil/foto');
      return PerfilUsuario.fromJson(r.data ?? const {});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<Uint8List?> descargarFoto(String usuarioId) async {
    try {
      final r = await _dio.get<List<int>>(
        '/usuarios/$usuarioId/foto',
        options: Options(responseType: ResponseType.bytes),
      );
      final datos = r.data;
      return (datos == null || datos.isEmpty)
          ? null
          : Uint8List.fromList(datos);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw AppException.from(e);
    }
  }
}

/// Perfil simulado (modo demo): vive en memoria.
class MockPerfilRepository implements PerfilRepository {
  Uint8List? _foto;

  PerfilUsuario _perfil = const PerfilUsuario(
    id: 'mock',
    rol: 'PASAJERO',
    nombre: 'Usuario NEXA',
    email: 'demo@nexa.co',
    telefono: '3001234567',
  );

  @override
  Future<PerfilUsuario> obtener() async => _perfil;

  @override
  Future<PerfilUsuario> actualizar({
    required String nombre,
    required String telefono,
  }) async => _perfil = _perfil.copyWith(nombre: nombre, telefono: telefono);

  @override
  Future<PerfilUsuario> subirFoto(ArchivoImagen foto) async {
    _foto = foto.bytes;
    return _perfil = _perfil.copyWith(tieneFoto: true);
  }

  @override
  Future<PerfilUsuario> quitarFoto() async {
    _foto = null;
    return _perfil = _perfil.copyWith(tieneFoto: false);
  }

  @override
  Future<Uint8List?> descargarFoto(String usuarioId) async => _foto;
}
