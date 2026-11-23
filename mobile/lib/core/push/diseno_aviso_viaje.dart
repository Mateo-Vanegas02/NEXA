import 'dart:ui' show Color;

import '../l10n/gen/app_localizations.dart';
import '../theme/tokens.dart';
import 'aviso_push.dart';

/// Cómo se ve la notificación de una etapa del viaje (rediseño 2026): un
/// título con quién y qué pasa, el detalle del conductor y su moto, la etapa
/// como barra y el color de NEXA. Regla pura: se prueba sin Android.
class DisenoAvisoViaje {
  const DisenoAvisoViaje({
    required this.titulo,
    required this.texto,
    required this.color,
    this.lineas = const [],
    this.avance,
    this.buscando = false,
    this.fija = false,
    this.silenciosa = false,
    this.accion,
  });

  final String titulo;

  /// Una línea (la notificación cerrada).
  final String texto;

  /// Lo que se ve al expandirla (además de [texto]).
  final List<String> lineas;
  final Color color;

  /// Etapa del viaje en % (barra); null = sin barra.
  final int? avance;

  /// Barra en movimiento (buscando conductor).
  final bool buscando;

  /// No se puede deslizar mientras dura la búsqueda.
  final bool fija;

  /// Actualiza sin sonar ni vibrar (la búsqueda que se amplía).
  final bool silenciosa;

  /// Texto del botón (null = sin botón).
  final String? accion;
}

/// Diseño de [aviso] para el pasajero o el conductor. Si el servidor no envía
/// los datos (versiones viejas), usa su título y su texto.
DisenoAvisoViaje disenoAvisoViaje(AvisoPush aviso, AppLocalizations l) {
  final e = aviso.extra;
  String? dato(String k) {
    final v = e[k]?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  final nombre = _primerNombre(dato('conductor')) ?? l.avisoConductorGenerico;
  final moto = [
    ?dato('vehiculo'),
    if (dato('placa') case final p?) l.avisoPlaca(p),
  ].join(' · ');
  final nota = dato('calificacion');
  final conductor = [if (moto.isNotEmpty) moto, if (nota != null) '★ $nota'];
  final destino = dato('destino');
  final servidor = [?aviso.cuerpo];

  return switch (aviso.tipo) {
    TipoAviso.solicitudRecibida || TipoAviso.busquedaAmpliada => () {
      final ola = dato('ola');
      final total = dato('olas');
      final radio = dato('radio');
      final texto = ola != null && total != null && radio != null
          ? l.avisoBuscandoOla(ola, total, radio)
          : (aviso.cuerpo ?? l.avisoBuscandoTexto);
      return DisenoAvisoViaje(
        titulo: l.avisoBuscandoTitulo,
        texto: texto,
        lineas: [l.avisoBuscandoTexto, ?destino],
        color: NexaColors.cyan,
        buscando: true,
        fija: true,
        silenciosa: aviso.tipo == TipoAviso.busquedaAmpliada,
        accion: l.avisoVerViaje,
      );
    }(),
    TipoAviso.viajeAceptado => DisenoAvisoViaje(
      titulo: dato('conductor') == null
          ? (aviso.titulo ?? l.avisoAceptadoTitulo(nombre))
          : l.avisoAceptadoTitulo(nombre),
      texto: conductor.isEmpty ? (aviso.cuerpo ?? '') : conductor.join(' · '),
      lineas: [?destino],
      color: NexaColors.cyan,
      avance: 25,
      accion: l.avisoVerViaje,
    ),
    TipoAviso.conductorLlego => DisenoAvisoViaje(
      titulo: dato('conductor') == null
          ? (aviso.titulo ?? l.avisoLlegoTitulo(nombre))
          : l.avisoLlegoTitulo(nombre),
      texto: moto.isEmpty ? (aviso.cuerpo ?? l.avisoLlegoTexto) : moto,
      lineas: [l.avisoLlegoTexto],
      color: NexaColors.gold,
      avance: 50,
      accion: l.avisoVerViaje,
    ),
    TipoAviso.viajeIniciado => DisenoAvisoViaje(
      titulo: destino == null
          ? (aviso.titulo ?? l.avisoIniciadoTexto)
          : l.avisoIniciadoTitulo(destino),
      texto: l.avisoIniciadoTexto,
      lineas: [if (moto.isNotEmpty) moto],
      color: NexaColors.cyan,
      avance: 75,
      silenciosa: true,
      accion: l.avisoVerViaje,
    ),
    TipoAviso.viajeFinalizado => DisenoAvisoViaje(
      titulo: l.avisoFinalizadoTitulo,
      texto: [?dato('total'), l.avisoFinalizadoTexto(nombre)].join(' · '),
      lineas: [?destino],
      color: NexaColors.ok,
      avance: 100,
      accion: l.avisoCalificar,
    ),
    TipoAviso.viajeCancelado || TipoAviso.solicitudVencida => DisenoAvisoViaje(
      titulo: aviso.titulo ?? '',
      texto: aviso.cuerpo ?? '',
      color: NexaColors.error,
    ),
    TipoAviso.sinConductores => DisenoAvisoViaje(
      titulo: aviso.titulo ?? '',
      texto: aviso.cuerpo ?? '',
      lineas: [?destino],
      color: NexaColors.gold,
      accion: l.avisoVerViaje,
    ),
    _ => DisenoAvisoViaje(
      titulo: aviso.titulo ?? '',
      texto: aviso.cuerpo ?? '',
      lineas: servidor.length > 1 ? servidor.sublist(1) : const [],
      color: NexaColors.cyan,
    ),
  };
}

String? _primerNombre(String? nombre) {
  final n = nombre?.trim() ?? '';
  if (n.isEmpty) return null;
  final primero = n.split(RegExp(r'\s+')).first;
  return '${primero[0].toUpperCase()}${primero.substring(1)}';
}
