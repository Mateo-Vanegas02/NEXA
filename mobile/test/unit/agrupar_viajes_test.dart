import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/features/viajes/domain/agrupar_viajes.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';

void main() {
  // Viernes 13 de noviembre de 2026 (la semana empieza el lunes 9).
  final ahora = DateTime(2026, 11, 13, 18);

  test('hoy, esta semana (desde el lunes) y antes', () {
    expect(tramoDe(DateTime(2026, 11, 13, 7), ahora), TramoFecha.hoy);
    expect(tramoDe(DateTime(2026, 11, 10, 22), ahora), TramoFecha.semana);
    expect(tramoDe(DateTime(2026, 11, 9, 6), ahora), TramoFecha.semana);
    expect(tramoDe(DateTime(2026, 11, 8, 23), ahora), TramoFecha.antes);
    expect(tramoDe(null, ahora), TramoFecha.antes);
  });

  test('agrupa sin grupos vacíos y conserva el orden', () {
    Servicio s(String id, DateTime f) =>
        Servicio(id: id, estado: EstadoServicio.finalizado, fechaHora: f);
    final g = agruparPorTramo([
      s('a', DateTime(2026, 11, 13, 9)),
      s('b', DateTime(2026, 11, 1)),
      s('c', DateTime(2026, 11, 13, 8)),
    ], ahora);
    expect(g.keys, [TramoFecha.hoy, TramoFecha.antes]);
    expect(g[TramoFecha.hoy]!.map((e) => e.id), ['a', 'c']);
  });
}
