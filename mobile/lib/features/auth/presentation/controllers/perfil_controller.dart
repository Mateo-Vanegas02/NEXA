import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../core/utils/selector_imagen.dart';
import '../../domain/perfil.dart';
import '../../domain/vehiculo.dart';

/// Perfil del usuario: se carga al abrir la pantalla y se actualiza al guardar.
class PerfilController extends AsyncNotifier<PerfilUsuario> {
  @override
  Future<PerfilUsuario> build() => ref.read(perfilRepositoryProvider).obtener();

  PerfilRepository get _repo => ref.read(perfilRepositoryProvider);

  /// Guarda nombre y teléfono. Los errores se propagan para mostrarlos en el formulario.
  Future<void> guardar({
    required String nombre,
    required String telefono,
  }) async {
    state = AsyncData(
      await _repo.actualizar(nombre: nombre, telefono: telefono),
    );
  }

  /// Sube o reemplaza la foto de perfil.
  Future<void> cambiarFoto(ArchivoImagen foto) async {
    state = AsyncData(await _repo.subirFoto(foto));
  }

  Future<void> quitarFoto() async {
    state = AsyncData(await _repo.quitarFoto());
  }
}

final perfilProvider =
    AsyncNotifierProvider.autoDispose<PerfilController, PerfilUsuario>(
      PerfilController.new,
    );

/// Bytes de la foto de perfil (o `null` si no tiene). Se vuelve a pedir cada vez
/// que el perfil cambia, p. ej. tras subir una foto nueva.
final fotoPerfilProvider = FutureProvider.autoDispose<Uint8List?>((ref) async {
  final perfil = ref.watch(perfilProvider).asData?.value;
  if (perfil == null || !perfil.tieneFoto) return null;
  return ref.read(perfilRepositoryProvider).descargarFoto(perfil.id);
});

/// La moto activa del conductor (la primera si ninguna está activa); null si
/// no tiene o si falla: el perfil no se bloquea por esto.
final motoActivaProvider = FutureProvider.autoDispose<VehiculoConductor?>((
  ref,
) async {
  try {
    final lista = await ref.watch(vehiculosRepositoryProvider).listar();
    if (lista.isEmpty) return null;
    return lista.firstWhere((v) => v.activo, orElse: () => lista.first);
  } on Object {
    return null;
  }
});
