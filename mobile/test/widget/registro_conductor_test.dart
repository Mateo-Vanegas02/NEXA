import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_mobile/core/l10n/gen/app_localizations.dart';
import 'package:nexa_mobile/core/providers.dart';
import 'package:nexa_mobile/core/theme/app_theme.dart';
import 'package:nexa_mobile/features/auth/presentation/screens/registro_conductor_screen.dart';

import 'package:nexa_mobile/core/widgets/nexa_widgets.dart';

import '../helpers.dart';
import '../helpers_foto.dart';

/// App mínima con router: el formulario navega a /login al terminar.
Widget _app(SelectorFalso selector) {
  final router = GoRouter(
    initialLocation: '/registro/conductor',
    routes: [
      GoRoute(
        path: '/registro/conductor',
        builder: (_, _) => const RegistroConductorScreen(),
      ),
      GoRoute(
        path: '/registro',
        builder: (_, _) => const Text('PANTALLA REGISTRO'),
      ),
      GoRoute(path: '/login', builder: (_, _) => const Text('PANTALLA LOGIN')),
    ],
  );
  return ProviderScope(
    overrides: [
      ...overridesTest(),
      selectorImagenProvider.overrideWithValue(selector),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.dark,
      locale: const Locale('es', 'CO'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    ),
  );
}

Future<void> _escribir(WidgetTester t, String etiqueta, String texto) async {
  // La etiqueta va encima del campo (NexaTextField), no dentro.
  final nexa = find.widgetWithText(NexaTextField, etiqueta);
  final campo = nexa.evaluate().isNotEmpty
      ? find.descendant(of: nexa, matching: find.byType(TextFormField))
      : find.widgetWithText(TextFormField, etiqueta);
  await t.ensureVisible(campo);
  await t.enterText(campo, texto);
}

Future<void> _foto(WidgetTester t, String etiqueta) async {
  final boton = find.text(etiqueta);
  await t.ensureVisible(boton);
  await t.pumpAndSettle();
  await t.tap(boton);
  await t.pumpAndSettle();
  await t.tap(find.text('Elegir de la galería'));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('sin llenar nada muestra los errores y las fotos que faltan', (
    t,
  ) async {
    usarTamano(t, kTamanos[1]);
    await t.pumpWidget(_app(SelectorFalso()));
    await t.pumpAndSettle();

    final enviar = find.text('Enviar solicitud');
    await t.ensureVisible(enviar);
    await t.pumpAndSettle();
    await t.tap(enviar);
    await t.pumpAndSettle();

    expect(find.text('Este campo es obligatorio'), findsWidgets);
    expect(find.text('Adjunta la foto de este documento'), findsWidgets);
    expect(find.text('PANTALLA LOGIN'), findsNothing);
  });

  testWidgets('formulario completo con 4 fotos envía y vuelve al login', (
    t,
  ) async {
    usarTamano(t, kTamanos[1]);
    final selector = SelectorFalso();
    await t.pumpWidget(_app(selector));
    await t.pumpAndSettle();

    final l = AppLocalizations.of(
      t.element(find.byType(RegistroConductorScreen)),
    );
    await _escribir(t, l.nombreCompleto, 'Carlos Gomez');
    await _escribir(t, l.email, 'carlos@x.co');
    await _escribir(t, l.telefono, '3001234567');
    await _escribir(t, l.password, 'Clave123');
    await _escribir(t, l.confirmarPassword, 'Clave123');
    await _escribir(t, l.regPlaca, 'abc123');
    await _escribir(t, l.marca, 'Bajaj');
    await _escribir(t, l.modelo, 'Boxer');
    await _escribir(t, l.color, 'Negro');
    await _escribir(t, l.licencia, '123456789');
    await _escribir(t, l.tarjetaPropiedad, '12345678');
    await _escribir(t, l.soat, '123456789012');
    await _escribir(t, l.tecnomecanica, '123456');
    await _foto(t, l.docLicencia);
    await _foto(t, l.docTarjeta);
    await _foto(t, l.docSoat);
    await _foto(t, l.docTecno);
    expect(selector.pedidos, hasLength(4));
    expect(find.text(l.fotoLista), findsNWidgets(4));

    final enviar = find.text('Enviar solicitud');
    await t.ensureVisible(enviar);
    await t.pumpAndSettle();
    await t.tap(enviar);
    // El popup de marca tiene un halo que pulsa sin parar: no se puede usar pumpAndSettle.
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(seconds: 1));

    expect(find.text('Solicitud enviada'), findsOneWidget);
    await t.tap(find.text('Aceptar'));
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('PANTALLA LOGIN'), findsOneWidget);
  });
}
