import 'dart:typed_data';

import '../../../core/utils/selector_imagen.dart';

/// Perfil del usuario autenticado (`GET /api/perfil`).
class PerfilUsuario {
  const PerfilUsuario({
    required this.id,
    required this.rol,
    required this.nombre,
    required this.email,
    this.telefono,
    this.estadoValidacion,
    this.tieneFoto = false,
  });

  factory PerfilUsuario.fromJson(Map<String, dynamic> j) => PerfilUsuario(
    id: j['id']?.toString() ?? '',
    rol: j['rol']?.toString() ?? '',
    nombre: j['nombre'] as String? ?? '',
    email: j['email'] as String? ?? '',
    telefono: j['telefono']?.toString(),
    estadoValidacion: j['estadoValidacion'] as String?,
    tieneFoto: j['tieneFoto'] == true,
  );

  final String id;
  final String rol;
  final String nombre;
  final String email;
  final String? telefono;
  final String? estadoValidacion;
  final bool tieneFoto;

  PerfilUsuario copyWith({String? nombre, String? telefono, bool? tieneFoto}) =>
      PerfilUsuario(
        id: id,
        rol: rol,
        nombre: nombre ?? this.nombre,
        email: email,
        telefono: telefono ?? this.telefono,
        estadoValidacion: estadoValidacion,
        tieneFoto: tieneFoto ?? this.tieneFoto,
      );
}

abstract interface class PerfilRepository {
  Future<PerfilUsuario> obtener();

  /// Cambia nombre y teléfono; el correo no se edita.
  Future<PerfilUsuario> actualizar({
    required String nombre,
    required String telefono,
  });

  /// Sube o reemplaza la foto de perfil (JPG/PNG/WebP, máx. 5 MB).
  Future<PerfilUsuario> subirFoto(ArchivoImagen foto);

  Future<PerfilUsuario> quitarFoto();

  /// Bytes de la foto de [usuarioId], o `null` si no tiene.
  Future<Uint8List?> descargarFoto(String usuarioId);
}
