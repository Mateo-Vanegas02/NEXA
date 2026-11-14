import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../domain/satisfaccion.dart';

/// Formatos de presentación del panel de satisfacción (solo texto: los números
/// los entrega el servidor).
abstract final class FormatoSat {
  static final NumberFormat _numero = NumberFormat('#,##0.#', 'es_CO');

  /// `86 %`, `86,5 %`.
  static String pct(double v) => '${_numero.format(v)} %';

  /// Probabilidad de 0 a 1 como porcentaje entero: `0.71` → `71 %`.
  static String probabilidad(double p) => '${(p * 100).round()} %';

  static String numero(double v) => _numero.format(v);

  static String metrica(double? v) =>
      v == null ? '–' : NumberFormat('0.00', 'es_CO').format(v);

  static String km(double v) => NumberFormat('0.0', 'es_CO').format(v);

  /// `2026-W44` → `S44`.
  static String semana(String iso) {
    final i = iso.indexOf('W');
    return i < 0 ? iso : 'S${int.tryParse(iso.substring(i + 1)) ?? ''}';
  }

  /// `1 nov – 8 nov`.
  static String rango(DateTime desde, DateTime hasta) {
    final f = DateFormat('d MMM', 'es_CO');
    return '${f.format(desde).replaceAll('.', '')}'
        ' – ${f.format(hasta).replaceAll('.', '')}';
  }

  /// `8 nov 2026, 02:14`.
  static String fechaHora(DateTime d) =>
      DateFormat('d MMM y, HH:mm', 'es_CO').format(d).replaceAll('.', '');

  /// `8 nov, 02:14`.
  static String fechaHoraCorta(DateTime d) =>
      DateFormat('d MMM, HH:mm', 'es_CO').format(d).replaceAll('.', '');

  /// Inicio de la escala vertical de la tendencia: múltiplo de 10 por debajo
  /// del menor valor (entre 0 y 60), para que las líneas no se aplasten.
  static double minimoEscala(Iterable<double?> valores) {
    final v = valores.whereType<double>();
    if (v.isEmpty) return 60;
    final menor = v.reduce(math.min);
    return (((menor - 5) / 10).floor() * 10).clamp(0, 60).toDouble();
  }

  static String _fecha(String patron, DateTime d) =>
      DateFormat(patron, 'es_CO').format(d).replaceAll('.', '');

  /// Etiqueta corta del eje: `lun 9`, `S46`, `nov`.
  static String etiquetaEje(PuntoSerie p, Agrupacion a) {
    final d = p.desde;
    if (d == null) return semana(p.clave);
    return switch (a) {
      Agrupacion.dia => _fecha('E d', d),
      Agrupacion.semana => semana(p.clave),
      Agrupacion.mes => _fecha('MMM', d),
    };
  }

  /// Etiqueta del tramo marcado: `lun 9 nov`, `S46 · 9 nov – 14 nov`,
  /// `noviembre 2026`.
  static String etiquetaLectura(PuntoSerie p, Agrupacion a) {
    final d = p.desde;
    final h = p.hasta;
    if (d == null) return semana(p.clave);
    return switch (a) {
      Agrupacion.dia => _fecha('E d MMM', d),
      Agrupacion.semana =>
        h == null ? semana(p.clave) : '${semana(p.clave)} · ${rango(d, h)}',
      Agrupacion.mes => _fecha('MMMM y', d),
    };
  }

  /// `1 nota`, `12 notas`.
  static String notas(AppLocalizations l, int n) =>
      n == 1 ? l.satUnaNota : l.satVariasNotas(numero(n.toDouble()));

  static String porAgrupacion(AppLocalizations l, Agrupacion a) =>
      switch (a) {
        Agrupacion.dia => l.satPorDia,
        Agrupacion.semana => l.satPorSemana,
        Agrupacion.mes => l.satPorMes,
      };

  static String tramos(AppLocalizations l, Agrupacion a) => switch (a) {
    Agrupacion.dia => l.satTramosDias,
    Agrupacion.semana => l.satTramosSemanas,
    Agrupacion.mes => l.satTramosMeses,
  };

  static String semanticaSerie(AppLocalizations l, SerieSatisfaccion s) {
    final ultimo = s.puntos.lastWhere(
      (p) => p.tieneDatos,
      orElse: () => const PuntoSerie(clave: ''),
    );
    String v(double? x, int? n) => x == null
        ? '–'
        : n == null
        ? pct(x)
        : '${pct(x)} (${notas(l, n)})';
    return l.satSemanticaSerie(
      porAgrupacion(l, s.agrupacion).toLowerCase(),
      ultimo.clave.isEmpty ? '–' : etiquetaLectura(ultimo, s.agrupacion),
      v(ultimo.pasajeroPct, ultimo.pasajeroNotas),
      v(ultimo.conductorPct, ultimo.conductorNotas),
    );
  }

  /// Nombre del día en español: `domingo` / `dom`. 1 de enero de 2024 fue lunes.
  static String _dia(DiaSemana d, String patron) => DateFormat(
    patron,
    'es_CO',
  ).format(DateTime(2024, 1, 1 + d.index)).replaceAll('.', '');

  static String _mayuscula(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  /// Resumen legible de la programación: `Domingos · 02:00`,
  /// `Lun, Mié, Vie · 02:00`, `Todos los días · 02:00`, `Cada 6 horas`.
  static String programacion(AppLocalizations l, Programacion p) =>
      switch (p.frecuencia) {
        Frecuencia.diaria => l.satTodosLosDias(p.hora),
        Frecuencia.cadaHoras => l.satCadaHorasValor('${p.cadaHoras ?? 24}'),
        Frecuencia.semanal => '${_dias(p.dias)} · ${p.hora}',
      };

  static String _dias(Set<DiaSemana> dias) {
    final orden = [
      for (final d in DiaSemana.values)
        if (dias.contains(d)) d,
    ];
    if (orden.length == 1) {
      // Plural: "domingos", "sábados"; "lunes"…"viernes" no cambian.
      final dia = _mayuscula(_dia(orden.first, 'EEEE'));
      return dia.endsWith('s') ? dia : '${dia}s';
    }
    return orden.map((d) => _mayuscula(_dia(d, 'EEE'))).join(', ');
  }
}
