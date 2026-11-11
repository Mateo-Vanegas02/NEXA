import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/servicio.dart';

/// Conductor del viaje: avatar, nombre, calificación, nivel, moto y placa.
/// Los datos de reputación/vehículo son opcionales.
class ConductorCard extends StatelessWidget {
  const ConductorCard({required this.conductor, super.key});

  final Participante conductor;

  String get _iniciales {
    final p = conductor.nombre.trim().split(RegExp(r'\s+'));
    if (p.isEmpty || p.first.isEmpty) return '?';
    return (p.first[0] + (p.length > 1 ? p[1][0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.textos;
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [NexaColors.cyan, NexaColors.sky],
            ),
            boxShadow: NexaShadows.glow,
          ),
          alignment: Alignment.center,
          child: Text(
            _iniciales,
            style: const TextStyle(
              color: NexaColors.bg,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),
        const SizedBox(width: Sp.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conductor.nombre,
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (conductor.calificacion != null || conductor.viajes != null)
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (conductor.calificacion != null) ...[
                      const Icon(Icons.star, size: 16, color: NexaColors.gold),
                      const SizedBox(width: Sp.xs),
                      Text(
                        conductor.calificacion!
                            .toStringAsFixed(1)
                            .replaceAll('.', ','),
                        style: t.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (conductor.viajes != null)
                      Text(
                        ' · ${l.viajesCantidadCorto(conductor.viajes!)}',
                        style: t.bodySmall?.copyWith(color: context.muted),
                      ),
                  ],
                ),
              if (conductor.vehiculo != null)
                Text(
                  conductor.vehiculo!,
                  style: t.bodySmall?.copyWith(color: context.muted),
                  maxLines: 2,
                ),
            ],
          ),
        ),
        if (conductor.placa != null) ...[
          const SizedBox(width: Sp.sm),
          Semantics(
            label: '${l.placa} ${conductor.placa}',
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.md,
                  vertical: Sp.sm - 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                    bottom: BorderSide(color: Color(0xFFCDD7DF), width: 3),
                  ),
                ),
                child: Text(
                  conductor.placa!,
                  textScaler: TextScaler.noScaling,
                  style: const TextStyle(
                    color: NexaColors.bg,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
