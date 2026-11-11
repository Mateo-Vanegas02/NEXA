import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/app.dart';
import 'package:nexa_mobile/core/providers.dart';
import 'package:nexa_mobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:nexa_mobile/features/satisfaccion/data/satisfaccion_repository_mock.dart';
import 'package:nexa_mobile/features/satisfaccion/domain/satisfaccion.dart';
import 'package:nexa_mobile/features/satisfaccion/presentation/controllers/satisfaccion_controller.dart';
import 'package:nexa_mobile/features/satisfaccion/presentation/screens/factores_screen.dart';
import 'package:nexa_mobile/features/satisfaccion/presentation/screens/modelo_screen.dart';
import 'package:nexa_mobile/features/satisfaccion/presentation/screens/programar_sheet.dart';
import 'package:nexa_mobile/features/satisfaccion/presentation/screens/resumen_screen.dart';
import 'package:nexa_mobile/features/satisfaccion/presentation/screens/riesgo_screen.dart';

import '../helpers.dart';

final _hoy = DateTime(2026, 11, 8, 10);

/// Mock sin modelo publicado y sin datos (pantalla "Datos insuficientes").
class _MockSinModelo extends MockSatisfaccionRepository {
  _MockSinModelo() : super(reloj: () => _hoy, retardo: Duration.zero);

  @override
  Future<ModeloInfo> modelo() async =>
      ModeloInfo.fromJson(
        FixturesSatisfaccion.modelo(version: null, datosSuficientes: false),
      );
}

List<Override> _overrides({MockSatisfaccionRepository? repo}) => [
  mockSatisfaccionProvider.overrideWithValue(
    repo ??
        MockSatisfaccionRepository(reloj: () => _hoy, retardo: Duration.zero),
  ),
  relojSatisfaccionProvider.overrideWithValue(() => _hoy),
];

/// Deja correr los futuros simulados sin esperar a que el skeleton se detenga.
Future<void> _asentar(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(iniciarFormatos);

  testWidgets('resumen: indicadores y accesos con modelo real', (t) async {
    usarTamano(t, const Size(390, 844));
    await t.pumpWidget(
      envolver(const ResumenScreen(), overrides: _overrides()),
    );
    await _asentar(t);
    expect(find.text('Satisfacción'), findsOneWidget);
    expect(find.text('86 %'), findsOneWidget);
    expect(find.text('79 %'), findsOneWidget);
    expect(find.textContaining('Sin modelo todavía.'), findsNothing);
    expect(find.text('Califica el 41 %'), findsOneWidget);
    expect(find.text('Tendencia semanal'), findsOneWidget);
    expect(find.text('Viajes en riesgo'), findsOneWidget);
    expect(find.text('Factores'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('factores: cambia de lado y de curva', (t) async {
    usarTamano(t, const Size(390, 844));
    await t.pumpWidget(
      envolver(const FactoresScreen(), overrides: _overrides()),
    );
    await _asentar(t);
    expect(find.text('Espera hasta que un conductor acepta'), findsOneWidget);
    expect(find.text('93 %'), findsOneWidget);
    await t.ensureVisible(find.text('Retraso'));
    await t.pump();
    await t.tap(find.text('Retraso'));
    await _asentar(t);
    expect(find.text('A tiempo'), findsOneWidget);
    await t.ensureVisible(find.text('Conductor'));
    await t.pump();
    await t.tap(find.text('Conductor'));
    await _asentar(t);
    expect(find.text('Espera al pasajero en el punto'), findsOneWidget);
    expect(find.text('0–2 min'), findsOneWidget);
  });

  testWidgets('viajes en riesgo: filtra por lado', (t) async {
    usarTamano(t, const Size(390, 844));
    await t.pumpWidget(envolver(const RiesgoScreen(), overrides: _overrides()));
    await _asentar(t);
    expect(find.text('Todos · 7'), findsOneWidget);
    expect(find.textContaining('Viaje #A7F3'), findsOneWidget);
    expect(find.text('71 %'), findsOneWidget);
    await t.tap(find.text('Conductor · 2'));
    await _asentar(t);
    expect(find.textContaining('Viaje #A7F3'), findsNothing);
    expect(find.textContaining('Viaje #C219'), findsOneWidget);
  });

  testWidgets('modelo: métricas, programación e historial', (t) async {
    usarTamano(t, const Size(390, 844));
    await t.pumpWidget(envolver(const ModeloScreen(), overrides: _overrides()));
    await _asentar(t);
    expect(find.text('Versión 3 · TensorFlow'), findsOneWidget);
    expect(find.text('No supera'), findsNWidgets(2));
    expect(find.text('Entrenar ahora'), findsOneWidget);
    expect(find.text('Domingos · 02:00'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Historial'), 200);
    expect(find.text('Publicado'), findsOneWidget);
    expect(find.text('Faltan datos'), findsOneWidget);
  });

  testWidgets('sin modelo y sin datos: muestra el avance de los datos', (
    t,
  ) async {
    usarTamano(t, const Size(390, 844));
    await t.pumpWidget(
      envolver(
        const ModeloScreen(),
        overrides: _overrides(repo: _MockSinModelo()),
      ),
    );
    await _asentar(t);
    expect(find.text('Aún no hay datos para entrenar'), findsOneWidget);
    expect(find.text('112 / 300'), findsOneWidget);
    expect(find.text('3 / 30'), findsOneWidget);
  });

  testWidgets('programar: valida días y guarda', (t) async {
    usarTamano(t, const Size(390, 844));
    final repo = MockSatisfaccionRepository(
      reloj: () => _hoy,
      retardo: Duration.zero,
    );
    await t.pumpWidget(
      envolver(
        Consumer(
          builder: (context, ref, _) {
            final m = ref.watch(modeloProvider).value;
            return Scaffold(
              body: m == null
                  ? const SizedBox()
                  : ProgramarSheet(inicial: m.programacion),
            );
          },
        ),
        overrides: _overrides(repo: repo),
      ),
    );
    await _asentar(t);
    expect(find.text('Programar entrenamiento'), findsOneWidget);
    // Quitar el domingo deja la programación sin días: no se puede guardar.
    await t.tap(find.text('D'));
    await t.pump();
    expect(find.text('Elige al menos un día.'), findsOneWidget);
    await t.tap(find.text('L'));
    await t.pump();
    await t.tap(find.text('Diario'));
    await t.pump();
    await t.scrollUntilVisible(find.text('Guardar programación'), 200);
    await t.tap(find.text('Guardar programación'));
    await _asentar(t);
    // Los futuros del mock se resuelven fuera del reloj falso de la prueba.
    final guardado = await t.runAsync(repo.modelo);
    expect(guardado?.programacion.frecuencia, Frecuencia.diaria);
  });

  testWidgets('admin: entra al panel y no ve pantallas de pasajero', (t) async {
    usarTamano(t, const Size(390, 844));
    final c = ProviderContainer(
      overrides: [...overridesTest(), ..._overrides()],
    );
    addTearDown(c.dispose);
    // El login simulado espera 300 ms reales: se hace fuera del reloj falso.
    await t.runAsync(
      () => c.read(sesionProvider.notifier).login('admin@nexa.co', '123456'),
    );
    await t.pumpWidget(
      UncontrolledProviderScope(container: c, child: const NexaApp()),
    );
    await _asentar(t);
    expect(find.text('86 %'), findsOneWidget);
    expect(find.text('Satisfacción'), findsWidgets);
    await t.ensureVisible(find.text('Viajes en riesgo'));
    await t.pump();
    await t.tap(find.text('Viajes en riesgo'));
    await _asentar(t);
    expect(find.text('Todos · 7'), findsOneWidget);
  });

  for (final tam in kTamanos) {
    testWidgets('resumen sin desbordes en ${tam.width.toInt()}x'
        '${tam.height.toInt()} con letra al 200 %', (t) async {
      usarTamano(t, tam, textScale: 2);
      await t.pumpWidget(
        envolver(const ResumenScreen(), overrides: _overrides()),
      );
      await _asentar(t);
      expect(t.takeException(), isNull);
    });
  }
}
