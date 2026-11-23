import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexa_mobile/core/geocoding/geocoding_service.dart';
import 'package:nexa_mobile/features/viajes/presentation/pasajero/elegir_lugar_screen.dart';
import 'package:nexa_mobile/features/viajes/presentation/pasajero/solicitar_viaje_screen.dart';

import '../helpers.dart';

Future<void> _ratos(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Pantalla "Tu ruta" abierta desde la de confirmar viaje; el resultado se
/// guarda para comprobarlo.
class _Anfitrion extends StatefulWidget {
  const _Anfitrion({required this.esOrigen});
  final bool esOrigen;

  @override
  State<_Anfitrion> createState() => _AnfitrionState();
}

class _AnfitrionState extends State<_Anfitrion> {
  ResultadoLugar? resultado;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () async {
              final r = await Navigator.of(context).push<ResultadoLugar>(
                MaterialPageRoute(
                  builder: (_) => ElegirLugarScreen(
                    esOrigen: widget.esOrigen,
                    cerca: const LatLng(10.4, -75.5),
                    origenTexto: 'Mi ubicación',
                    destinoTexto: 'Destino actual',
                  ),
                ),
              );
              setState(() => resultado = r);
            },
            child: const Text('abrir'),
          ),
          if (resultado?.lugar != null)
            Text('ELEGIDO ${resultado!.lugar!.nombre}'),
          if (resultado?.fijarEnMapa ?? false) const Text('FIJAR'),
          if (resultado?.miUbicacion ?? false) const Text('MI UBICACION'),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(iniciarFormatos);

  for (final tam in kTamanos) {
    testWidgets(
      'tu ruta: busca, muestra resultados y devuelve el lugar (${tam.width.toInt()}x${tam.height.toInt()})',
      (t) async {
        usarTamano(t, tam, textScale: 1.3);
        await t.pumpWidget(envolver(const _Anfitrion(esOrigen: false)));
        await t.tap(find.text('abrir'));
        await _ratos(t, 400);

        expect(find.text('Planea tu viaje'), findsOneWidget);
        expect(find.text('Mi ubicación'), findsOneWidget);
        await t.enterText(find.byType(TextField), 'Bocagrande');
        await _ratos(t, 900);
        // No busca mientras se escribe (política de Nominatim): pide tocar Buscar.
        expect(find.text('Centro Comercial Plaza'), findsNothing);
        expect(find.text('Escribe el lugar y toca Buscar.'), findsOneWidget);
        await t.testTextInput.receiveAction(TextInputAction.search);
        await _ratos(t, 900);
        expect(find.text('Centro Comercial Plaza'), findsOneWidget);

        await t.tap(find.text('Centro Comercial Plaza'));
        await _ratos(t, 400);
        expect(find.text('ELEGIDO Centro Comercial Plaza'), findsOneWidget);
      },
    );
  }

  testWidgets('tu ruta: consultas cortas (<3 letras) no llaman al servicio', (
    t,
  ) async {
    usarTamano(t, kTamanos[1]);
    final geo = GeocodingFalso();
    await t.pumpWidget(
      envolver(const _Anfitrion(esOrigen: false), geocoding: geo),
    );
    await t.tap(find.text('abrir'));
    await _ratos(t, 400);
    await t.enterText(find.byType(TextField), 'ab');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await _ratos(t, 1000);
    expect(geo.consultas, isEmpty);
    expect(find.byTooltip('Buscar'), findsNothing);
  });

  testWidgets('tu ruta: escribir no busca; el botón Buscar sí', (t) async {
    usarTamano(t, kTamanos[1]);
    final geo = GeocodingFalso();
    await t.pumpWidget(
      envolver(const _Anfitrion(esOrigen: false), geocoding: geo),
    );
    await t.tap(find.text('abrir'));
    await _ratos(t, 400);
    await t.enterText(find.byType(TextField), 'Unicentro');
    await _ratos(t, 2000);
    expect(geo.consultas, isEmpty);
    await t.tap(find.byTooltip('Buscar'));
    await _ratos(t, 900);
    expect(geo.consultas, ['Unicentro']);
  });

  testWidgets('tu ruta: fijar en el mapa se devuelve como petición', (t) async {
    usarTamano(t, kTamanos[1]);
    await t.pumpWidget(envolver(const _Anfitrion(esOrigen: false)));
    await t.tap(find.text('abrir'));
    await _ratos(t, 400);
    await t.tap(find.text('Fijar en el mapa'));
    await _ratos(t, 400);
    expect(find.text('FIJAR'), findsOneWidget);
  });

  testWidgets('tu ruta: el destino no ofrece usar mi ubicación', (t) async {
    usarTamano(t, kTamanos[1]);
    await t.pumpWidget(envolver(const _Anfitrion(esOrigen: false)));
    await t.tap(find.text('abrir'));
    await _ratos(t, 400);
    expect(find.text('Usar mi ubicación'), findsNothing);
  });

  testWidgets('tu ruta: el origen ofrece usar mi ubicación', (t) async {
    usarTamano(t, kTamanos[1]);
    await t.pumpWidget(envolver(const _Anfitrion(esOrigen: true)));
    await t.tap(find.text('abrir'));
    await _ratos(t, 400);
    expect(find.text('Usar mi ubicación'), findsOneWidget);
    await t.tap(find.text('Usar mi ubicación'));
    await _ratos(t, 400);
    expect(find.text('MI UBICACION'), findsOneWidget);
  });

  testWidgets('confirmar con destino elegido cotiza solo al abrir', (t) async {
    usarTamano(t, kTamanos[1]);
    await t.pumpWidget(
      envolver(
        const SolicitarViajeScreen(
          destinoInicial: Lugar(
            nombre: 'Castillo de San Felipe',
            detalle: 'Cartagena',
            punto: LatLng(10.42, -75.54),
          ),
        ),
      ),
    );
    await _ratos(t, 600);
    expect(find.text('Castillo de San Felipe'), findsOneWidget);
    expect(find.text('Moto NEXA'), findsOneWidget);
    expect(find.textContaining('Pedir NEXA ·'), findsOneWidget);
  });
}
