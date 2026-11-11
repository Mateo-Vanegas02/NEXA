import 'dart:convert';
import 'dart:typed_data';

import 'package:nexa_mobile/core/utils/selector_imagen.dart';

/// PNG válido de 1×1 píxel (para que `Image.memory` / `MemoryImage` lo decodifiquen).
final Uint8List kPngMinimo = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// Cámara/galería de mentira: devuelve siempre la misma foto (o `null` = cancelar).
class SelectorFalso implements SelectorImagen {
  SelectorFalso({this.cancela = false});

  final bool cancela;
  final List<OrigenImagen> pedidos = [];

  @override
  Future<ArchivoImagen?> elegir(
    OrigenImagen origen, {
    double maxLado = 1600,
  }) async {
    pedidos.add(origen);
    if (cancela) return null;
    return ArchivoImagen(nombre: 'foto.png', bytes: kPngMinimo);
  }
}
