import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexa_mobile/core/errors/app_exception.dart';
import 'package:nexa_mobile/core/geocoding/geocoding_service.dart';
import 'package:nexa_mobile/core/providers.dart';
import 'package:nexa_mobile/features/auth/domain/auth.dart';
import 'package:nexa_mobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:nexa_mobile/features/viajes/data/mock_backend.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';
import 'package:nexa_mobile/features/viajes/presentation/pasajero/solicitar_viaje_screen.dart';

import '../helpers.dart';

class _Sesion extends SesionController {
  @override
  SesionState build() => const SesionState(
    sesion: Sesion(token: 't', rol: Rol.pasajero, email: 'demo@nexa.co'),
    inicializado: true,
  );
}

/// Repositorio cuyo `cotizar` y `solicitar` se controlan desde cada test.
class _Repo extends MockPasajeroRepository {
  _Repo(super.b, {this.cotizacion, this.falla});

  final Cotizacion? cotizacion;
  final AppException? falla;
  final List<SolicitudViaje> solicitudes = [];
  int cotizaciones = 0;

  @override
  Future<Cotizacion> cotizar(Coordenada origen, Coordenada destino) async {
    cotizaciones++;
    if (falla != null && cotizaciones == 1) throw falla!;
    return cotizacion ??
        const Cotizacion(
          distanciaKm: 4.6,
          tarifa: 9000,
          descuento: 90,
          precio: 8910,
          totalAPagar: 8910,
        );
  }

  @override
  Future<Servicio> solicitar(SolicitudViaje solicitud) {
    solicitudes.add(solicitud);
    return super.solicitar(solicitud);
  }
}

Future<void> _ratos(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

const _castillo = Lugar(
  nombre: 'Castillo de San Felipe',
  detalle: 'Cartagena, Bolívar',
  punto: LatLng(10.4236, -75.5391),
);

/// Botón principal: el único `FilledButton` cuyo texto empieza por "Pedir NEXA".
Finder _finderBoton() => find.ancestor(
  of: find.textContaining('Pedir NEXA'),
  matching: find.byType(FilledButton),
);

FilledButton _boton(WidgetTester t) => t.widget<FilledButton>(_finderBoton());

Future<void> _tocar(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
}

Future<void> _montar(WidgetTester t, _Repo repo) async {
  usarTamano(t, kTamanos[2]);
  final Override sesion = sesionProvider.overrideWith(_Sesion.new);
  await t.pumpWidget(
    envolver(
      const SolicitarViajeScreen(destinoInicial: _castillo),
      overrides: [sesion, pasajeroRepositoryProvider.overrideWithValue(repo)],
    ),
  );
  await _ratos(t, 600);
}

void main() {
  setUpAll(iniciarFormatos);

  testWidgets('muestra el precio del servidor y el ahorro por nivel', (
    t,
  ) async {
    final repo = _Repo(MockBackend());
    await _montar(t, repo);

    expect(repo.cotizaciones, 1);
    expect(find.text('Moto NEXA'), findsOneWidget);
    expect(find.textContaining('Tu nivel te ahorra'), findsOneWidget);
    expect(find.textContaining('Pedir NEXA · '), findsOneWidget);
    expect(find.textContaining('8.910'), findsWidgets);
    expect(_boton(t).onPressed, isNotNull);
    // Ya no hay precio ajustable por el pasajero: lo fija el servidor.
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);
  });

  testWidgets('el desglose aparece solo al pedirlo', (t) async {
    final repo = _Repo(MockBackend());
    await _montar(t, repo);

    expect(find.text('Descuento por nivel'), findsNothing);
    await _tocar(t, find.text('Ver desglose'));
    await t.pump();
    expect(find.text('Descuento por nivel'), findsOneWidget);
    expect(find.text('Ocultar desglose'), findsOneWidget);
    await _tocar(t, find.text('Ocultar desglose'));
    await t.pump();
    expect(find.text('Descuento por nivel'), findsNothing);
  });

  testWidgets('con cargo pendiente exige aceptarlo antes de solicitar', (
    t,
  ) async {
    final repo = _Repo(
      MockBackend(),
      cotizacion: const Cotizacion(
        distanciaKm: 4.6,
        tarifa: 9000,
        descuento: 0,
        precio: 9000,
        deudaPendiente: 3000,
        totalAPagar: 12000,
      ),
    );
    await _montar(t, repo);

    // Con un cargo pendiente el desglose se muestra solo.
    expect(find.text('Cargo pendiente por cancelación'), findsOneWidget);
    expect(find.textContaining('12.000'), findsWidgets);
    expect(_boton(t).onPressed, isNull, reason: 'falta aceptar el cargo');

    await _tocar(t, find.byType(CheckboxListTile));
    await t.pump();
    expect(_boton(t).onPressed, isNotNull);

    await _tocar(t, _finderBoton());
    await _ratos(t, 400);
    expect(repo.solicitudes.single.aceptaDeuda, isTrue);
  });

  testWidgets(
    'si el servidor rechaza la zona, muestra el motivo y permite reintentar',
    (t) async {
      final repo = _Repo(
        MockBackend(),
        falla: const AppException(
          ErrorKind.validacion,
          'El servicio solo está disponible en Cartagena',
          statusCode: 400,
        ),
      );
      await _montar(t, repo);

      expect(
        find.textContaining('solo está disponible en Cartagena'),
        findsOneWidget,
      );
      expect(_boton(t).onPressed, isNull);

      await _tocar(t, find.text('Reintentar'));
      await _ratos(t, 400);
      expect(repo.cotizaciones, 2);
      expect(find.textContaining('solo está disponible'), findsNothing);
      expect(_boton(t).onPressed, isNotNull);
    },
  );
}
