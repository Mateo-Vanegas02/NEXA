import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/features/viajes/domain/agrupar_viajes.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';

void main() {
  final viajes = [
    Servicio(
      id: 'a',
      estado: EstadoServicio.finalizado,
      fechaFinalizacion: DateTime(2026, 11, 22, 20, 6, 30),
    ),
    Servicio(
      id: 'b',
      estado: EstadoServicio.finalizado,
      fechaFinalizacion: DateTime(2026, 11, 21, 18, 2),
    ),
  ];

  test('el ingreso trae el id del viaje', () {
    final i = Ingreso(fecha: '2026-11-21', servicioId: 'b');
    expect(servicioDeIngreso(i, viajes)?.id, 'b');
    expect(
      servicioDeIngreso(const Ingreso(fecha: 'x', servicioId: 'z'), viajes),
      isNull,
    );
  });

  test('sin id (servidor viejo) se busca por la hora en que terminó', () {
    const i = Ingreso(fecha: '2026-11-22', hora: '2026-11-22T20:06:12.512');
    expect(servicioDeIngreso(i, viajes)?.id, 'a');
    const lejos = Ingreso(fecha: '2026-11-22', hora: '2026-11-22T21:00:00');
    expect(servicioDeIngreso(lejos, viajes), isNull);
  });

  test('las calificaciones y factores llegan del servidor', () {
    final s = Servicio.fromJson({
      'id': 'x',
      'estado': 'FINALIZADO',
      'calificacionConductor': 4.0,
      'comentariosConductor': 'Muy amable',
      'factoresConductor': ['AMABLE'],
      'factoresPasajero': null,
      'fechaAceptacion': '2026-11-22T20:00:00',
    });
    expect(s.calificacionConductor, 4);
    expect(s.factoresConductor, ['AMABLE']);
    expect(s.factoresPasajero, isEmpty);
    expect(s.fechaAceptacion, DateTime(2026, 11, 22, 20));
  });
}
