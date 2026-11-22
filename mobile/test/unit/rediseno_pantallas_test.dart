import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/utils/resaltar.dart';
import 'package:nexa_mobile/features/viajes/domain/resumen_ganancias.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';

void main() {
  group('tramosResaltados', () {
    test('resalta sin importar mayúsculas ni tildes', () {
      expect(tramosResaltados('Éxito La Castellana', 'castellana'), [
        ('Éxito La ', false),
        ('Castellana', true),
      ]);
      expect(tramosResaltados('Éxito', 'exi'), [('Éxi', true), ('to', false)]);
    });

    test('varias coincidencias y consulta vacía', () {
      expect(tramosResaltados('ana y ana', 'ana'), [
        ('ana', true),
        (' y ', false),
        ('ana', true),
      ]);
      expect(tramosResaltados('Centro', '  '), [('Centro', false)]);
    });
  });

  group('ResumenGanancias', () {
    final ahora = DateTime(2026, 11, 22, 15, 30);
    Ingreso i(String fecha, double monto, {String? hora}) =>
        Ingreso(fecha: fecha, monto: monto, hora: hora);
    final lista = [
      i('2026-11-22', 7000, hora: '2026-11-22T09:10:00'),
      i('2026-11-22', 5000, hora: '2026-11-22T14:50:00'),
      i('2026-11-20', 8000),
      i('2026-11-16', 6000),
      i('2026-10-30', 4000),
    ];

    test('filtra hoy, 7 y 30 días contando hoy', () {
      expect(
        ResumenGanancias.delPeriodo(lista, PeriodoGanancias.hoy, ahora),
        hasLength(2),
      );
      // 16 nov es el séptimo día hacia atrás (16..22).
      expect(
        ResumenGanancias.delPeriodo(lista, PeriodoGanancias.semana, ahora),
        hasLength(4),
      );
      expect(
        ResumenGanancias.total(
          ResumenGanancias.delPeriodo(lista, PeriodoGanancias.treinta, ahora),
        ),
        30000,
      );
    });

    test('suma por día del más viejo a hoy', () {
      final d = ResumenGanancias.porDia(lista, 7, ahora);
      expect(d, [6000, 0, 0, 0, 8000, 0, 12000]);
    });

    test('por hora solo con la hora del servidor, hasta la hora actual', () {
      final h = ResumenGanancias.porHora(lista, ahora);
      expect(h[9], 7000);
      expect(h[14], 5000);
      final a = ResumenGanancias.horasConActividad(h, ahora);
      expect(a.desde, 9);
      expect(a.montos, hasLength(7)); // 9h..15h
      expect(
        ResumenGanancias.porHora([i('2026-11-22', 1000)], ahora),
        isEmpty,
      );
    });
  });
}
