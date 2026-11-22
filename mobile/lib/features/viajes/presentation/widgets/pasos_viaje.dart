import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/servicio.dart';

/// Línea de progreso: Solicitado → Aceptado → En curso → Finalizado.
class PasosViaje extends StatelessWidget {
  const PasosViaje({required this.estado, super.key});

  final EstadoServicio estado;

  int get _actual => switch (estado) {
    EstadoServicio.solicitado => 0,
    EstadoServicio.aceptado => 1,
    EstadoServicio.enCurso => 2,
    EstadoServicio.finalizado || EstadoServicio.cancelado => 3,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final etiquetas = [
      l.paso_solicitado,
      l.paso_aceptado,
      l.paso_en_curso,
      l.paso_finalizado,
    ];
    return Semantics(
      container: true,
      label: '${l.viajeEnCursoTitulo}: ${etiquetas[_actual]}',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < etiquetas.length; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    _Punto(hecho: i < _actual, activo: i == _actual),
                    const SizedBox(height: Sp.xs),
                    Text(
                      etiquetas[i],
                      textAlign: TextAlign.center,
                      style: context.textos.labelSmall?.copyWith(
                        letterSpacing: 0.8,
                        fontWeight: i == _actual ? FontWeight.w700 : null,
                        color: i <= _actual ? null : context.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({required this.hecho, required this.activo});
  final bool hecho;
  final bool activo;

  @override
  Widget build(BuildContext context) {
    final color = hecho || activo ? NexaColors.cyan : context.colors.outline;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hecho ? NexaColors.cyan : context.colors.surface,
        border: Border.all(color: color, width: activo ? 5 : 2),
        boxShadow: activo ? NexaShadows.glow : null,
      ),
      child: hecho
          ? const Icon(Icons.check, size: 14, color: NexaColors.bg)
          : null,
    );
  }
}
