import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Foto ya leída en memoria, lista para subirse.
class ArchivoImagen {
  const ArchivoImagen({required this.nombre, required this.bytes});

  final String nombre;
  final Uint8List bytes;

  /// Tipo MIME según la extensión (el servidor igualmente valida el contenido real).
  String get tipo {
    final n = nombre.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

enum OrigenImagen { camara, galeria }

/// Elige una foto de la cámara o la galería. Detrás de una interfaz para poder
/// probar las pantallas sin el plugin.
abstract interface class SelectorImagen {
  /// `null` si el usuario cancela. [maxLado] limita el lado mayor en píxeles
  /// (el servidor admite hasta 5 MB por foto).
  Future<ArchivoImagen?> elegir(OrigenImagen origen, {double maxLado = 1600});
}

class SelectorImagenPlugin implements SelectorImagen {
  const SelectorImagenPlugin();

  @override
  Future<ArchivoImagen?> elegir(
    OrigenImagen origen, {
    double maxLado = 1600,
  }) async {
    final foto = await ImagePicker().pickImage(
      source: origen == OrigenImagen.camara
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: maxLado,
      maxHeight: maxLado,
      imageQuality: 85,
    );
    if (foto == null) return null;
    return ArchivoImagen(nombre: foto.name, bytes: await foto.readAsBytes());
  }
}
