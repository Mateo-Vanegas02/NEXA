import 'servicio.dart';

/// Tramos del historial (diseño P10): hoy, esta semana (desde el lunes) y
/// antes. Sin fecha va a «antes».
enum TramoFecha { hoy, semana, antes }

TramoFecha tramoDe(DateTime? fecha, DateTime ahora) {
  if (fecha == null) return TramoFecha.antes;
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final dia = DateTime(fecha.year, fecha.month, fecha.day);
  if (dia == hoy) return TramoFecha.hoy;
  final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));
  if (!dia.isBefore(lunes) && dia.isBefore(hoy)) return TramoFecha.semana;
  return TramoFecha.antes;
}

/// Agrupa en orden (hoy, semana, antes) conservando el orden de la lista.
Map<TramoFecha, List<Servicio>> agruparPorTramo(
  List<Servicio> viajes,
  DateTime ahora,
) {
  final grupos = <TramoFecha, List<Servicio>>{
    for (final t in TramoFecha.values) t: [],
  };
  for (final s in viajes) {
    grupos[tramoDe(s.fechaHora, ahora)]!.add(s);
  }
  grupos.removeWhere((_, v) => v.isEmpty);
  return grupos;
}

/// Destinos recientes distintos para el inicio del pasajero (rediseño 2026):
/// en el orden del historial, sin viajes activos y sin repetir destino (por
/// coordenadas a ~100 m, o por nombre si no las hay).
List<Servicio> destinosRecientes(List<Servicio> viajes, {int maximo = 3}) {
  final vistos = <String>{};
  final recientes = <Servicio>[];
  for (final s in viajes) {
    if (s.estado.activo) continue;
    final d = s.ubicacionDestino;
    final clave = d == null
        ? s.destino.trim().toLowerCase()
        : '${d.latitud.toStringAsFixed(3)},${d.longitud.toStringAsFixed(3)}';
    if (clave.isEmpty || !vistos.add(clave)) continue;
    recientes.add(s);
    if (recientes.length == maximo) break;
  }
  return recientes;
}
