import '../../../../core/theme/theme_x.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/nivel.dart';

import 'package:flutter/material.dart';

/// Barra de nivel/XP: insignia, nombre del nivel, progreso y XP faltante.
class LevelProgressBar extends StatelessWidget {
  const LevelProgressBar({required this.estado, this.onTap, super.key});

  final NivelEstado estado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final color =
        kColoresNivel[(estado.nivel - 1).clamp(0, kColoresNivel.length - 1)];
    final progreso = estado.esNivelMaximo
        ? 1.0
        : estado.progreso.clamp(0.0, 1.0);
    final pct = (progreso * 100).round();
    final meta = estado.xpSiguienteNivel;

    return Semantics(
      container: true,
      label: l.barraNivelSemantica(estado.nombre, pct),
      value: meta == null ? l.nivelMaximo : l.xpProgreso(estado.xpActual, meta),
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(Rad.lg),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Rad.lg),
                border: Border.all(color: color.withValues(alpha: 0.4)),
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(NexaColors.card, color, 0.16)!,
                    NexaColors.card,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(Sp.lg),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(Rad.md),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${estado.nivel}',
                      style: t.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                estado.descuento > 0
                                    ? l.nivelDescuento(
                                        estado.nombre,
                                        (estado.descuento * 100).round(),
                                      )
                                    : l.nivelActual(estado.nombre),
                                style: t.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: Sp.sm),
                            Flexible(
                              child: Text(
                                meta == null
                                    ? '${estado.xpActual} XP'
                                    : l.xpProgreso(estado.xpActual, meta),
                                style: t.bodySmall,
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Sp.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(Rad.pill),
                          child: LinearProgressIndicator(
                            value: progreso,
                            minHeight: 6,
                            color: color,
                            backgroundColor: NexaColors.line,
                          ),
                        ),
                        const SizedBox(height: Sp.xs + 2),
                        Text(
                          estado.esNivelMaximo
                              ? l.nivelMaximo
                              : l.faltanXp(
                                  estado.xpFaltante,
                                  estado.nombreSiguiente ?? '',
                                ),
                          style: t.bodySmall?.copyWith(color: context.muted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: Sp.sm),
                    Icon(Icons.chevron_right, color: context.muted),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
