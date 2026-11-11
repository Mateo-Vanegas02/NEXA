import 'package:intl/intl.dart';

abstract final class Fmt {
  static final NumberFormat _cop = NumberFormat.currency(
    locale: 'es_CO',
    symbol: r'$',
    decimalDigits: 0,
    customPattern: '¤#,##0',
  );

  /// Pesos colombianos: `$12.500`.
  static String cop(num v) => _cop.format(v);

  static String fecha(DateTime d) =>
      DateFormat('d MMM, h:mm a', 'es_CO').format(d);

  /// "Ayer · 6:40 p. m." / "Hoy · ..." / "Lun · ..." / fecha corta.
  static String fechaRelativa(DateTime d, DateTime ahora) {
    final hora = DateFormat('h:mm a', 'es_CO').format(d);
    final dias = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
    ).difference(DateTime(d.year, d.month, d.day)).inDays;
    final dia = switch (dias) {
      0 => 'Hoy',
      1 => 'Ayer',
      < 7 => toBeginningOfSentenceCase(
        DateFormat('EEE', 'es_CO').format(d).replaceAll('.', ''),
      ),
      _ => DateFormat('d MMM', 'es_CO').format(d),
    };
    return '$dia, $hora';
  }

  static String pct(double v) {
    final p = v * 100;
    return '${p.toStringAsFixed(p % 1 == 0 ? 0 : 1)} %';
  }
}
