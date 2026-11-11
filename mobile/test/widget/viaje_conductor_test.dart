import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';
import 'package:nexa_mobile/features/viajes/presentation/controllers/viaje_conductor_controller.dart';
import 'package:nexa_mobile/features/viajes/presentation/widgets/viaje_activo_card.dart';

import '../helpers.dart';

/// Controlador que solo cuenta cuántas veces se avanza el viaje.
class _Falso extends ConductorController {
  static int avances = 0;
  static int cancelaciones = 0;

  @override
  Future<ConductorState> build() async => const ConductorState();

  @override
  Future<void> avanzar() async => avances++;

  @override
  Future<void> cancelarActivo() async => cancelaciones++;
}

const _servicio = Servicio(
  id: 'v1',
  estado: EstadoServicio.aceptado,
  tarifa: 9000,
  extraVoluntario: 1000,
  origen: 'Bocagrande',
  destino: 'Centro',
);

Future<void> _montar(
  WidgetTester t,
  FaseConductor fase, {
  PosicionViaje? posicion,
  PosicionPasajero? pasajero,
}) async {
  usarTamano(t, kTamanos[1], textScale: 1.3);
  await t.pumpWidget(
    envolver(
      SingleChildScrollView(
        child: ViajeActivoCard(
          servicio: _servicio,
          fase: fase,
          posicion: posicion,
          pasajero: pasajero,
        ),
      ),
      overrides: [conductorProvider.overrideWith(_Falso.new)],
    ),
  );
  await t.pump();
}

/// Confirma la acción principal deslizando el control hasta el final.
Future<void> _deslizar(WidgetTester t) async {
  await t.drag(find.byIcon(Icons.arrow_forward), const Offset(600, 0));
  await t.pump();
}

void main() {
  setUpAll(iniciarFormatos);
  setUp(() {
    _Falso.avances = 0;
    _Falso.cancelaciones = 0;
  });

  testWidgets(
    'yendo a recoger: botón «Llegué», ETA del servidor y distancia del pasajero',
    (t) async {
      await _montar(
        t,
        FaseConductor.aRecoger,
        posicion: const PosicionViaje(
          fase: 'ACEPTADO',
          latitud: 10.41,
          longitud: -75.51,
          distanciaRestanteKm: 1.2,
          etaMinutos: 4,
        ),
        pasajero: const PosicionPasajero(
          latitud: 10.4,
          longitud: -75.5,
          haceSegundos: 2,
          distanciaRecogidaMetros: 80,
        ),
      );

      expect(find.text('Llegué al punto de recogida'), findsOneWidget);
      expect(find.textContaining('4 min'), findsOneWidget);
      expect(find.textContaining('1.2 km'), findsOneWidget);
      expect(find.textContaining('80 m'), findsOneWidget);
      // Un solo monto, con el extra: sin comisión ni deuda por separado.
      expect(find.textContaining('10.000'), findsOneWidget);
      expect(find.textContaining('omisi'), findsNothing);

      await _deslizar(t);
      expect(_Falso.avances, 1);
    },
  );

  testWidgets('en el punto: espera al pasajero y permite iniciar', (t) async {
    await _montar(t, FaseConductor.enElPunto);

    expect(find.text('Esperando al pasajero'), findsOneWidget);
    expect(find.text('Pasajero recogido'), findsOneWidget);
  });

  testWidgets(
    'finalizar lejos del destino pide confirmar antes de cobrar por lo recorrido',
    (t) async {
      await _montar(
        t,
        FaseConductor.enViaje,
        posicion: const PosicionViaje(
          fase: 'EN_CURSO',
          latitud: 10.41,
          longitud: -75.51,
          distanciaRestanteKm: 2.0,
          etaMinutos: 6,
        ),
      );

      await _deslizar(t);
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('¿Finalizar antes del destino?'), findsOneWidget);
      expect(_Falso.avances, 0, reason: 'aún no confirmó');

      await t.tap(find.text('Finalizar de todos modos'));
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(_Falso.avances, 1);
    },
  );

  testWidgets('finalizar cerca del destino no pregunta nada', (t) async {
    await _montar(
      t,
      FaseConductor.enViaje,
      posicion: const PosicionViaje(
        fase: 'EN_CURSO',
        latitud: 10.41,
        longitud: -75.51,
        distanciaRestanteKm: 0.05,
        etaMinutos: 1,
      ),
    );

    await _deslizar(t);
    expect(find.text('¿Finalizar antes del destino?'), findsNothing);
    expect(_Falso.avances, 1);
  });

  testWidgets('cancelar pide confirmación', (t) async {
    await _montar(t, FaseConductor.aRecoger);

    await t.tap(find.text('Cancelar viaje'));
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('¿Cancelar este viaje?'), findsOneWidget);
    expect(_Falso.cancelaciones, 0);

    await t.tap(find.widgetWithText(FilledButton, 'Cancelar viaje').last);
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(_Falso.cancelaciones, 1);
  });
}
