import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/l10n/gen/app_localizations.dart';
import 'package:nexa_mobile/features/viajes/presentation/widgets/hoja_sos.dart';

void main() {
  Future<List<bool>> abrir(WidgetTester t) async {
    final resultados = <bool>[];
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async =>
                    resultados.add(await mostrarHojaSos(context)),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();
    return resultados;
  }

  testWidgets('mantener presionado hasta cerrar el anillo confirma', (t) async {
    final resultados = await abrir(t);
    expect(find.text('Mantén presionado para llamar'), findsOneWidget);

    final gesto = await t.startGesture(t.getCenter(find.text('123')));
    // El toque se reconoce a los 100 ms y el anillo arranca en el cuadro
    // siguiente.
    await t.pump(const Duration(milliseconds: 150));
    await t.pump(const Duration(milliseconds: 16));
    await t.pump(const Duration(milliseconds: 700));
    expect(resultados, isEmpty);
    await t.pump(const Duration(milliseconds: 900));
    await gesto.up();
    await t.pumpAndSettle();

    expect(resultados, [true]);
  });

  testWidgets('soltar antes de tiempo no llama', (t) async {
    final resultados = await abrir(t);

    final gesto = await t.startGesture(t.getCenter(find.text('123')));
    await t.pump(const Duration(milliseconds: 150));
    await t.pump(const Duration(milliseconds: 16));
    await t.pump(const Duration(milliseconds: 500));
    await gesto.up();
    await t.pumpAndSettle();
    expect(resultados, isEmpty);
    expect(find.text('Mantén presionado para llamar'), findsOneWidget);

    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(resultados, [false]);
  });
}
