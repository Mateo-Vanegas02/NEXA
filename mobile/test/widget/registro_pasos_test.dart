import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/features/auth/presentation/screens/registro_conductor_screen.dart';
import 'package:nexa_mobile/features/auth/presentation/screens/registro_screen.dart';

import 'package:nexa_mobile/core/widgets/nexa_widgets.dart';

import '../helpers.dart';

Future<void> _escribir(WidgetTester t, String etiqueta, String texto) async {
  // La etiqueta va encima del campo (NexaTextField), no dentro.
  final nexa = find.widgetWithText(NexaTextField, etiqueta);
  final campo = nexa.evaluate().isNotEmpty
      ? find.descendant(of: nexa, matching: find.byType(TextFormField))
      : find.widgetWithText(TextFormField, etiqueta);
  await t.ensureVisible(campo);
  await t.enterText(campo, texto);
}

/// Registro de pasajero en dos pasos y avance de documentos del conductor.
void main() {
  for (final tam in [kTamanos[0], kTamanos[1]]) {
    group('${tam.width.toInt()}x${tam.height.toInt()}', () {
      testWidgets('pasajero: el paso 1 valida antes de pasar a la contraseña', (
        t,
      ) async {
        usarTamano(t, tam, textScale: 1.3);
        await t.pumpWidget(envolver(const RegistroScreen()));
        await t.pump();
        expect(find.text('Paso 1 de 2'), findsOneWidget);

        await t.ensureVisible(find.widgetWithText(FilledButton, 'Continuar'));
        await t.tap(find.widgetWithText(FilledButton, 'Continuar'));
        await t.pump();
        expect(find.text('Este campo es obligatorio'), findsWidgets);
        expect(find.text('Paso 1 de 2'), findsOneWidget);
        expect(find.text('Elige tu contraseña'), findsNothing);
      });

      testWidgets('pasajero: pasa al paso 2 y vuelve sin perder los datos', (
        t,
      ) async {
        usarTamano(t, tam, textScale: 1.3);
        await t.pumpWidget(envolver(const RegistroScreen()));
        await t.pump();
        await _escribir(t, 'Nombre completo', 'Frank Salcedo');
        await _escribir(
          t,
          'Teléfono (10 dígitos, empieza con 3)',
          '3001234567',
        );
        await _escribir(t, 'Correo', 'frank@correo.com');
        await t.ensureVisible(find.widgetWithText(FilledButton, 'Continuar'));
        await t.tap(find.widgetWithText(FilledButton, 'Continuar'));
        await t.pump();

        expect(find.text('Paso 2 de 2'), findsOneWidget);
        expect(find.text('Elige tu contraseña'), findsOneWidget);
        expect(find.text('Crear cuenta'), findsOneWidget);
        expect(find.text('Confirmar contraseña'), findsOneWidget);

        await t.tap(find.byTooltip('Volver'));
        await t.pump();
        expect(find.text('Paso 1 de 2'), findsOneWidget);
        expect(find.text('Frank Salcedo'), findsOneWidget);
      });

      testWidgets('conductor: muestra el avance de documentos en 0 de 4', (
        t,
      ) async {
        usarTamano(t, tam, textScale: 1.3);
        await t.pumpWidget(envolver(const RegistroConductorScreen()));
        await t.pump();
        final avance = find.text('0 de 4 listos');
        await t.ensureVisible(avance);
        expect(avance, findsOneWidget);
        expect(find.text('Faltan 4 para enviar tu solicitud.'), findsOneWidget);
        expect(find.text('Paso 2 de 2'), findsOneWidget);
      });
    });
  }
}
