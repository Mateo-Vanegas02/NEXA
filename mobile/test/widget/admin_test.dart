import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/providers.dart';
import 'package:nexa_mobile/features/admin/data/admin_repository_impl.dart';
import 'package:nexa_mobile/features/admin/domain/admin.dart';
import 'package:nexa_mobile/features/admin/presentation/screens/conductores_screen.dart';
import 'package:nexa_mobile/features/admin/presentation/screens/operacion_screen.dart';
import 'package:nexa_mobile/features/admin/presentation/screens/revision_conductor_screen.dart';

import '../helpers.dart';

/// Repositorio de prueba que recuerda las decisiones.
class _Repo extends MockAdminRepository {
  final decisiones = <(String, bool, bool)>[];

  @override
  Future<void> decidir(
    String email, {
    required bool aprobar,
    required String motivo,
    bool marcarVerificado = false,
  }) async {
    decisiones.add((email, aprobar, marcarVerificado));
    await super.decidir(
      email,
      aprobar: aprobar,
      motivo: motivo,
      marcarVerificado: marcarVerificado,
    );
  }
}

Future<void> _ratos(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(iniciarFormatos);

  for (final tam in kTamanos) {
    testWidgets('operación en vivo: cifras, flota y alertas (${tam.width})', (
      t,
    ) async {
      usarTamano(t, tam, textScale: 1.3);
      await t.pumpWidget(envolver(const OperacionScreen()));
      await _ratos(t, 500);
      expect(find.text('Hoy en NEXA'), findsOneWidget);
      expect(find.text('46'), findsOneWidget);
      expect(find.text('Flota en línea'), findsOneWidget);
      expect(find.textContaining('sin conductor hace 6 min'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('conductores pendientes y aprobar con verificación manual', (
    t,
  ) async {
    usarTamano(t, kTamanos[1], textScale: 1.3);
    final repo = _Repo();
    await t.pumpWidget(
      envolver(
        const ConductoresScreen(),
        overrides: [adminRepositoryProvider.overrideWithValue(repo)],
      ),
    );
    await _ratos(t, 500);
    expect(find.text('Andrés Quintero'), findsOneWidget);
    expect(find.text('Luisa Márquez'), findsOneWidget);

    await t.pumpWidget(
      envolver(
        const RevisionConductorScreen(
          conductor: ConductorRevision(
            email: 'andres@nexa.co',
            nombre: 'Andrés Quintero',
            estado: EstadoRevision.pendiente,
          ),
        ),
        overrides: [adminRepositoryProvider.overrideWithValue(repo)],
      ),
    );
    await _ratos(t, 500);
    expect(find.text('DTE54H'), findsOneWidget);
    expect(find.text('SOAT'), findsOneWidget);
    expect(t.takeException(), isNull);

    await t.ensureVisible(find.text('Aprobar'));
    await t.pump();
    await t.tap(find.text('Aprobar'));
    await _ratos(t, 400);
    // Sin verificación previa, el botón del diálogo espera la casilla.
    final confirmar = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, 'Aprobar'),
    );
    expect(t.widget<FilledButton>(confirmar).onPressed, isNull);
    await t.tap(find.byType(Checkbox));
    await t.pump();
    await t.tap(confirmar);
    await _ratos(t, 500);
    expect(repo.decisiones, [('andres@nexa.co', true, true)]);
  });

  testWidgets('rechazar exige un motivo', (t) async {
    usarTamano(t, kTamanos[1]);
    final repo = _Repo();
    await t.pumpWidget(
      envolver(
        const RevisionConductorScreen(
          conductor: ConductorRevision(
            email: 'luisa@nexa.co',
            nombre: 'Luisa Márquez',
            estado: EstadoRevision.pendiente,
          ),
        ),
        overrides: [adminRepositoryProvider.overrideWithValue(repo)],
      ),
    );
    await _ratos(t, 500);
    await t.ensureVisible(find.text('Rechazar'));
    await t.pump();
    await t.tap(find.text('Rechazar'));
    await _ratos(t, 400);
    final confirmar = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(FilledButton),
    );
    expect(t.widget<FilledButton>(confirmar).onPressed, isNull);
    await t.enterText(find.byType(TextField), 'Licencia ilegible');
    await t.pump();
    await t.tap(confirmar);
    await _ratos(t, 500);
    expect(repo.decisiones, [('luisa@nexa.co', false, false)]);
  });

  test('lee la operación y el conductor como los envía el servidor', () {
    final o = OperacionAdmin.fromJson({
      'viajesHoy': 3,
      'flota': [
        {'latitud': 10.4, 'longitud': -75.5, 'disponible': false},
      ],
      'alertas': [
        {'tipo': 'CONDUCTORES_POR_APROBAR', 'texto': '2 conductores'},
      ],
    });
    expect(o.viajesHoy, 3);
    expect(o.flota.single.disponible, isFalse);
    expect(o.alertas.single.tipo, TipoAlerta.conductoresPorAprobar);
    final c = ConductorRevision.fromJson({
      'email': 'a@b.co',
      'nombre_y_Apellido': 'Ana Ruiz',
      'ntelefono': 3001112233,
      'estadoValidacion': 'EN_REVISION',
    });
    expect(c.nombre, 'Ana Ruiz');
    expect(c.telefono, '3001112233');
    expect(c.estado, EstadoRevision.enRevision);
  });
}
