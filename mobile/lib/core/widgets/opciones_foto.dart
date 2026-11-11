import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';

enum OpcionFoto { camara, galeria, quitar }

/// Hoja inferior para elegir de dónde sale una foto (o quitarla).
/// Devuelve `null` si el usuario la cierra sin elegir.
Future<OpcionFoto?> mostrarOpcionesFoto(
  BuildContext context, {
  bool conQuitar = false,
}) {
  final l = AppLocalizations.of(context);
  return showModalBottomSheet<OpcionFoto>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l.tomarFoto),
            onTap: () => Navigator.of(ctx).pop(OpcionFoto.camara),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l.elegirGaleria),
            onTap: () => Navigator.of(ctx).pop(OpcionFoto.galeria),
          ),
          if (conQuitar)
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(l.quitarFoto),
              onTap: () => Navigator.of(ctx).pop(OpcionFoto.quitar),
            ),
        ],
      ),
    ),
  );
}
