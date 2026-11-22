import 'servicio.dart';

/// Período de la pantalla de ganancias (rediseño 2026).
enum PeriodoGanancias {
  hoy(1),
  semana(7),
  treinta(30);

  const PeriodoGanancias(this.dias);

  /// Días que abarca, contando hoy (también se piden así al saldo).
  final int dias;
}

/// Agrupa lo que el servidor ya calculó (`GET /conductor/ingresos`): suma por
/// día y por hora. No recalcula ganancias ni comisiones.
abstract final class ResumenGanancias {
  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime? fechaDe(Ingreso i) => DateTime.tryParse(i.fecha);

  /// Los ingresos de los últimos [p.dias] días, hoy incluido.
  static List<Ingreso> delPeriodo(
    List<Ingreso> lista,
    PeriodoGanancias p,
    DateTime ahora,
  ) {
    final hoy = _dia(ahora);
    final desde = hoy.subtract(Duration(days: p.dias - 1));
    return [
      for (final i in lista)
        if (fechaDe(i) case final f?
            when !_dia(f).isBefore(desde) && !_dia(f).isAfter(hoy))
          i,
    ];
  }

  static double total(List<Ingreso> lista) =>
      lista.fold(0, (a, i) => a + i.monto);

  /// Suma por día, del más viejo a hoy ([dias] posiciones).
  static List<double> porDia(List<Ingreso> lista, int dias, DateTime ahora) {
    final hoy = _dia(ahora);
    final r = List<double>.filled(dias, 0);
    for (final i in lista) {
      final f = fechaDe(i);
      if (f == null) continue;
      final atras = hoy.difference(_dia(f)).inDays;
      if (atras >= 0 && atras < dias) r[dias - 1 - atras] += i.monto;
    }
    return r;
  }

  /// Suma por hora del día de [ahora] (0..23); vacío si el servidor no envía
  /// la hora de los viajes.
  static List<double> porHora(List<Ingreso> lista, DateTime ahora) {
    final hoy = _dia(ahora);
    final r = List<double>.filled(24, 0);
    var alguna = false;
    for (final i in lista) {
      final h = DateTime.tryParse(i.hora ?? '');
      if (h == null || _dia(h) != hoy) continue;
      r[h.hour] += i.monto;
      alguna = true;
    }
    return alguna ? r : const [];
  }

  /// Desde la primera hora con viajes hasta la hora actual (lo que se dibuja).
  static ({int desde, List<double> montos}) horasConActividad(
    List<double> porHora,
    DateTime ahora,
  ) {
    if (porHora.isEmpty) return (desde: 0, montos: const []);
    final primera = porHora.indexWhere((m) => m > 0);
    final ultima = ahora.hour;
    if (primera < 0 || primera > ultima) {
      return (desde: 0, montos: const []);
    }
    return (desde: primera, montos: porHora.sublist(primera, ultima + 1));
  }
}
