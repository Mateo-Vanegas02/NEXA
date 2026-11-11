import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/providers.dart';
import 'package:nexa_mobile/core/utils/selector_imagen.dart';
import 'package:nexa_mobile/features/auth/domain/auth.dart';
import 'package:nexa_mobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:nexa_mobile/features/auth/presentation/screens/perfil_screen.dart';

import '../helpers.dart';
import '../helpers_foto.dart';

class _SesionFija extends SesionController {
  @override
  SesionState build() => const SesionState(
    sesion: Sesion(token: 't', rol: Rol.pasajero, email: 'demo@nexa.co'),
    inicializado: true,
  );
}

Override get _sesion => sesionProvider.overrideWith(_SesionFija.new);

void main() {
  testWidgets('se sube la foto de perfil y luego se quita', (t) async {
    usarTamano(t, kTamanos[1]);
    final selector = SelectorFalso();
    await t.pumpWidget(
      envolver(
        const PerfilScreen(),
        overrides: [
          _sesion,
          selectorImagenProvider.overrideWithValue(selector),
        ],
      ),
    );
    await t.pumpAndSettle();
    CircleAvatar avatar() =>
        t.widget<CircleAvatar>(find.byType(CircleAvatar).first);
    expect(avatar().backgroundImage, isNull);

    await t.tap(find.byIcon(Icons.photo_camera));
    await t.pumpAndSettle();
    expect(find.text('Quitar foto'), findsNothing, reason: 'aún no tiene foto');
    await t.tap(find.text('Elegir de la galería'));
    await t.pumpAndSettle();

    expect(selector.pedidos, [OrigenImagen.galeria]);
    expect(find.text('Foto actualizada'), findsOneWidget);
    expect(avatar().backgroundImage, isA<MemoryImage>());

    await t.tap(find.byIcon(Icons.photo_camera));
    await t.pumpAndSettle();
    await t.tap(find.text('Quitar foto'));
    await t.pumpAndSettle();
    expect(find.text('Foto eliminada'), findsOneWidget);
    expect(avatar().backgroundImage, isNull);
  });

  testWidgets('cancelar la cámara no cambia nada', (t) async {
    usarTamano(t, kTamanos[1]);
    final selector = SelectorFalso(cancela: true);
    await t.pumpWidget(
      envolver(
        const PerfilScreen(),
        overrides: [
          _sesion,
          selectorImagenProvider.overrideWithValue(selector),
        ],
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.photo_camera));
    await t.pumpAndSettle();
    await t.tap(find.text('Tomar foto'));
    await t.pumpAndSettle();

    expect(selector.pedidos, [OrigenImagen.camara]);
    expect(find.text('Foto actualizada'), findsNothing);
  });

  testWidgets('el perfil muestra nombre y teléfono y se puede editar', (
    t,
  ) async {
    usarTamano(t, kTamanos[1]);
    await t.pumpWidget(envolver(const PerfilScreen(), overrides: [_sesion]));
    await t.pumpAndSettle();

    expect(find.text('Usuario NEXA'), findsOneWidget);
    expect(find.textContaining('3001234567'), findsOneWidget);

    await t.tap(find.text('Editar perfil'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField).first, 'Luis Mora');
    await t.tap(find.text('Guardar'));
    await t.pumpAndSettle();

    expect(find.text('Luis Mora'), findsOneWidget);
    expect(find.text('Perfil actualizado'), findsOneWidget);
  });

  testWidgets('el formulario valida el teléfono antes de guardar', (t) async {
    usarTamano(t, kTamanos[1]);
    await t.pumpWidget(envolver(const PerfilScreen(), overrides: [_sesion]));
    await t.pumpAndSettle();

    await t.tap(find.text('Editar perfil'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField).last, '123');
    await t.tap(find.text('Guardar'));
    await t.pumpAndSettle();

    // El formulario sigue abierto y no se guardó nada.
    expect(find.text('Perfil actualizado'), findsNothing);
    expect(find.text('Cancelar'), findsOneWidget);
  });
}
