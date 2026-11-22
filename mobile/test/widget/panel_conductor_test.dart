import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/features/auth/domain/auth.dart';
import 'package:nexa_mobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:nexa_mobile/features/viajes/presentation/conductor/ganancias_screen.dart';
import 'package:nexa_mobile/features/viajes/presentation/conductor/inicio_conductor_screen.dart';

import '../helpers.dart';

class _Sesion extends SesionController {
  @override
  SesionState build() => const SesionState(
    sesion: Sesion(
      token: 't',
      rol: Rol.conductor,
      email: 'conductor@nexa.co',
      userId: 'c',
    ),
    inicializado: true,
  );
}

Future<void> _ratos(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Panel del conductor con el botón grande de conexión, y ganancias con barras.
void main() {
  setUpAll(iniciarFormatos);

  for (final tam in [kTamanos[0], kTamanos[1]]) {
    testWidgets(
      'el botón grande conecta y desconecta (${tam.width.toInt()}x${tam.height.toInt()})',
      (t) async {
        usarTamano(t, tam, textScale: 1.3);
        final semantica = t.ensureSemantics();
        await t.pumpWidget(
          envolver(
            const InicioConductorScreen(),
            overrides: [sesionProvider.overrideWith(_Sesion.new)],
          ),
        );
        await _ratos(t, 800);

        expect(find.text('Fuera de línea'), findsOneWidget);
        expect(find.text('¿Listo para rodar?'), findsOneWidget);
        expect(find.text('Desliza para conectarte'), findsOneWidget);

        await t.tap(find.bySemanticsLabel('Conectarme'));
        await _ratos(t, 800);
        expect(find.text('En línea'), findsOneWidget);
        expect(find.text('Buscando solicitudes cerca de ti'), findsOneWidget);
        // El interruptor de arriba y el botón de la hoja.
        expect(find.bySemanticsLabel('Desconectarme'), findsWidgets);

        await t.tap(find.bySemanticsLabel('Desconectarme').first);
        await _ratos(t, 800);
        expect(find.text('Fuera de línea'), findsOneWidget);
        semantica.dispose();
      },
    );
  }

  testWidgets('ganancias: total, saldo y lista sin desbordes', (t) async {
    usarTamano(t, kTamanos[0], textScale: 1.3);
    await t.pumpWidget(
      envolver(
        const GananciasScreen(),
        overrides: [sesionProvider.overrideWith(_Sesion.new)],
      ),
    );
    await _ratos(t, 800);
    expect(find.text('Semana'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
