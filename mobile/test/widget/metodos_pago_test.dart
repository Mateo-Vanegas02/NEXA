import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/features/viajes/presentation/widgets/metodos_pago.dart';

import '../helpers.dart';

void main() {
  for (final escala in [1.0, 2.0]) {
    testWidgets('solo el efectivo se puede elegir; lo demás, próximamente '
        '($escala)', (t) async {
      usarTamano(t, const Size(360, 640), textScale: escala);
      String? elegido = 'sin elegir';
      await t.pumpWidget(
        envolver(
          Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async =>
                    elegido = await elegirMetodoPago(context, 'efectivo'),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      expect(find.text('¿Cómo vas a pagar?'), findsOneWidget);
      expect(find.text('Próximamente'), findsNWidgets(2));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      await t.tap(find.text('Tarjeta'));
      await t.pumpAndSettle();
      expect(
        find.text('¿Cómo vas a pagar?'),
        findsOneWidget,
        reason: 'no cierra',
      );

      await t.tap(find.text('Efectivo'));
      await t.pumpAndSettle();
      expect(elegido, 'efectivo');
      expect(t.takeException(), isNull);
    });
  }
}
