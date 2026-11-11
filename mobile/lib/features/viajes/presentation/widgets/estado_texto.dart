import '../../../../core/l10n/gen/app_localizations.dart';
import '../../domain/servicio.dart';

String estadoTexto(AppLocalizations l, EstadoServicio e) => switch (e) {
  EstadoServicio.solicitado => l.estado_SOLICITADO,
  EstadoServicio.aceptado => l.estado_ACEPTADO,
  EstadoServicio.enCurso => l.estado_EN_CURSO,
  EstadoServicio.finalizado => l.estado_FINALIZADO,
  EstadoServicio.cancelado => l.estado_CANCELADO,
};

// ------------------------------------------------------------------ inicio
