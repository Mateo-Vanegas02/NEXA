import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/features/viajes/data/mock_backend.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';

SolicitudViaje _solicitud() => const SolicitudViaje(
  origen: 'A',
  destino: 'B',
  ubicacionOrigen: Coordenada(latitud: 10.4, longitud: -75.5),
  ubicacionDestino: Coordenada(latitud: 10.42, longitud: -75.52),
);

void main() {
  test('el viaje del pasajero avanza con el tiempo y otorga XP', () {
    var ahora = DateTime(2026);
    final b = MockBackend(reloj: () => ahora);
    final id = b.solicitar(_solicitud()).id;
    expect(b.detallePasajero(id).estado, EstadoServicio.solicitado);
    ahora = ahora.add(const Duration(seconds: 6));
    expect(b.detallePasajero(id).estado, EstadoServicio.aceptado);
    ahora = ahora.add(const Duration(seconds: 6));
    expect(b.detallePasajero(id).estado, EstadoServicio.enCurso);
    ahora = ahora.add(const Duration(seconds: 10));
    final fin = b.detallePasajero(id);
    expect(fin.estado, EstadoServicio.finalizado);
    expect(fin.xpGanadoPasajero, 16, reason: '3,1 km: 10 + 2·km');
    expect(b.xpPasajero, 16);
    // Idempotente: consultar de nuevo no suma otra vez.
    b.detallePasajero(id);
    expect(b.xpPasajero, 16);
  });

  test(
    'pasajero (modelo v2.3): niveles desde 1, descuento y prioridad desde el 2',
    () {
      final b = MockBackend(xpPasajero: 269);
      var n = b.niveles('pasajero');
      expect(n.nivel, 1);
      expect(n.nombre, '1');
      expect(n.descuento, 0);
      expect(n.prioridadSegundos, 0);
      expect(n.xpSiguienteNivel, 270);
      b.xpPasajero = 300;
      n = b.niveles('pasajero');
      expect(n.nivel, 2);
      expect(n.descuento, closeTo(0.02, 1e-9));
      expect(n.prioridadSegundos, 15);
      // El descuento tiene tope de 5 % y el pasajero no tiene nivel máximo.
      b.xpPasajero = 10000;
      n = b.niveles('pasajero');
      expect(n.nivel, greaterThan(5));
      expect(n.descuento, closeTo(0.05, 1e-9));
      expect(n.esNivelMaximo, isFalse);
    },
  );

  test('conductor (modelo v2.3): niveles 1–5 y comisión de 20 % a 15 %', () {
    expect(MockBackend().niveles('conductor').conductor?.comisionActual, 0.20);
    final b = MockBackend(xpConductor: 6400);
    final n = b.niveles('conductor');
    expect(n.nivel, 5);
    expect(n.esNivelMaximo, isTrue);
    expect(n.conductor?.comisionActual, 0.15);
    expect(n.conductor?.comisionSiguiente, isNull);
  });

  test(
    'conductor: flujo completo y ganancia según su comisión (600 XP = nivel 2)',
    () {
      final b = MockBackend(xpConductor: 600);
      final s = b.disponibles().first;
      expect(b.aceptar(s.id).estado, EstadoServicio.aceptado);
      expect(b.enCursoConductor(), hasLength(1));
      b.iniciar(s.id);
      final fin = b.finalizar(s.id);
      expect(fin.xpGanadoConductor, greaterThan(0));
      final d = b.desgloseConductor(s.id);
      expect(
        d.cobrarAlPasajero,
        s.tarifa,
        reason: 'el conductor no ve la comisión',
      );
      expect(d.gananciaConductor, closeTo(s.tarifa * 0.81, 0.01));
      expect(b.ingresos(), hasLength(1));
    },
  );

  test('cancelar pasajero marca CANCELADO', () {
    final b = MockBackend();
    final id = b.solicitar(_solicitud()).id;
    expect(b.cancelarPasajero(id).estado, EstadoServicio.cancelado);
  });
}
