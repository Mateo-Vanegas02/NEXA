import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';
import 'package:nexa_mobile/features/viajes/presentation/widgets/detalle_viaje_screen.dart';

import '../helpers.dart';

final _viaje = Servicio(
  id: 'v1',
  estado: EstadoServicio.finalizado,
  origen: 'Manga',
  destino: 'Torres de La Plazuela',
  distanciaKM: 2.4,
  fechaHora: DateTime(2026, 11, 22, 20),
  fechaAceptacion: DateTime(2026, 11, 22, 20, 1),
  fechaInicio: DateTime(2026, 11, 22, 20, 5),
  fechaFinalizacion: DateTime(2026, 11, 22, 20, 13),
  tarifa: 4400,
  conductor: const Participante(
    nombre: 'Quintero',
    vehiculo: 'Honda R2S azul',
    placa: 'DTE54H',
    calificacion: 4.3,
  ),
  pasajero: const Participante(nombre: 'Juan'),
  calificacionConductor: 5,
  comentariosConductor: 'Muy amable',
  factoresConductor: const ['AMABLE'],
);

void main() {
  for (final escala in [1.0, 2.0]) {
    testWidgets('pasajero: ruta, tiempos, conductor, pago y su nota ($escala)', (
      t,
    ) async {
      usarTamano(t, const Size(360, 640), textScale: escala);
      await t.pumpWidget(envolver(DetalleViajeScreen(servicio: _viaje)));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Detalle del viaje'), findsOneWidget);
      expect(find.text('Torres de La Plazuela'), findsWidgets);
      expect(find.text('Viaje aceptado'), findsOneWidget);
      expect(find.textContaining('8 min de viaje'), findsOneWidget);
      expect(find.text('Quintero'), findsOneWidget);
      expect(find.text('DTE54H'), findsOneWidget);
      await t.scrollUntilVisible(find.text('«Muy amable»'), 200);
      expect(find.text('Tu calificación'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('conductor: su pasajero y sin calificar', (t) async {
    usarTamano(t, const Size(360, 640));
    await t.pumpWidget(
      envolver(DetalleViajeScreen(servicio: _viaje, conductor: true)),
    );
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Tu pasajero'), findsOneWidget);
    expect(find.text('Juan'), findsOneWidget);
    await t.scrollUntilVisible(find.text('No calificaste este viaje.'), 200);
    expect(t.takeException(), isNull);
  });
}
