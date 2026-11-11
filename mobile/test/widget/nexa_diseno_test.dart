import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/theme/app_theme.dart';
import 'package:nexa_mobile/core/widgets/nexa_diseno.dart';

Widget _app(Widget hijo) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, child: hijo)),
  ),
);

/// Piezas del rediseño oscuro.
void main() {
  testWidgets('NexaDeslizar confirma al arrastrar hasta el final', (t) async {
    var confirmado = 0;
    await t.pumpWidget(
      _app(
        NexaDeslizar(
          texto: 'Desliza: Pasajero recogido',
          onConfirmado: () => confirmado++,
        ),
      ),
    );
    await t.drag(find.byIcon(Icons.arrow_forward), const Offset(400, 0));
    await t.pumpAndSettle();
    expect(confirmado, 1);
  });

  testWidgets('NexaDeslizar no confirma con un arrastre corto', (t) async {
    var confirmado = 0;
    await t.pumpWidget(
      _app(NexaDeslizar(texto: 'Confirmar', onConfirmado: () => confirmado++)),
    );
    await t.drag(find.byIcon(Icons.arrow_forward), const Offset(60, 0));
    await t.pumpAndSettle();
    expect(confirmado, 0);
  });

  testWidgets(
    'NexaDeslizar se confirma con un toque para lectores de pantalla',
    (t) async {
      var confirmado = 0;
      final semantica = t.ensureSemantics();
      await t.pumpWidget(
        _app(
          NexaDeslizar(texto: 'Confirmar', onConfirmado: () => confirmado++),
        ),
      );
      t.semantics.tap(find.semantics.byLabel('Confirmar'));
      expect(confirmado, 1);
      semantica.dispose();
    },
  );

  testWidgets('NexaDeslizar deshabilitado no responde', (t) async {
    await t.pumpWidget(
      _app(const NexaDeslizar(texto: 'Confirmar', onConfirmado: null)),
    );
    await t.drag(find.byIcon(Icons.arrow_forward), const Offset(400, 0));
    await t.pumpAndSettle();
    expect(find.text('Confirmar'), findsOneWidget);
  });

  testWidgets('NexaAvatarAnillo anuncia el avance y limita el rango', (
    t,
  ) async {
    final semantica = t.ensureSemantics();
    await t.pumpWidget(
      _app(const NexaAvatarAnillo(iniciales: 'FS', progreso: 1.7)),
    );
    expect(find.text('FS'), findsOneWidget);
    expect(find.bySemanticsLabel('Avance de nivel 100 %'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('NexaBarraFlotante muestra la etiqueta solo del activo', (
    t,
  ) async {
    var elegido = -1;
    await t.pumpWidget(
      _app(
        NexaBarraFlotante(
          items: const [
            NexaItemBarra(icono: Icons.home, etiqueta: 'Inicio'),
            NexaItemBarra(icono: Icons.history, etiqueta: 'Historial'),
          ],
          indice: 0,
          onSeleccion: (i) => elegido = i,
        ),
      ),
    );
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Historial'), findsNothing);
    await t.tap(find.byIcon(Icons.history));
    expect(elegido, 1);
  });

  testWidgets('NexaChipCristal y NexaHojaInferior muestran su contenido', (
    t,
  ) async {
    await t.pumpWidget(
      _app(
        const NexaHojaInferior(
          child: NexaChipCristal(
            texto: '3 motos cerca',
            icono: Icons.two_wheeler,
          ),
        ),
      ),
    );
    expect(find.text('3 motos cerca'), findsOneWidget);
  });
}
