import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/servicio.dart';
import 'estado_texto.dart';

/// Etiqueta de color del estado de un viaje (verde finalizado, rojo cancelado).
class EstadoChip extends StatelessWidget {
  const EstadoChip({required this.estado, super.key});

  final EstadoServicio estado;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (bg, fg) = switch (estado) {
      EstadoServicio.finalizado => (NexaColors.okBg, NexaColors.okFg),
      EstadoServicio.cancelado => (NexaColors.badBg, NexaColors.badFg),
      _ => (NexaColors.cyan.withValues(alpha: 0.18), NexaColors.brand),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Rad.pill),
      ),
      child: Text(
        estadoTexto(l, estado),
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
