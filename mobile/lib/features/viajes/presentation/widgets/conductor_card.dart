import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/servicio.dart';
import 'piezas_viaje.dart';

/// Conductor del viaje (diseño P05): avatar, nombre, «★ 4,9 · Nivel 4 ·
/// 1.284 viajes», la moto y la placa amarilla. Los datos de reputación y
/// vehículo son opcionales (los completa el servidor al aceptar).
class ConductorCard extends StatelessWidget {
  const ConductorCard({required this.conductor, super.key});

  final Participante conductor;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final partes = <String>[
      if (conductor.calificacion != null)
        conductor.calificacion!.toStringAsFixed(1).replaceAll('.', ','),
      if (conductor.nivel != null) '${l.nivelPalabra} ${conductor.nivel}',
      if (conductor.viajes != null) l.viajesCantidadCorto(conductor.viajes!),
    ];
    return Row(
      children: [
        AvatarIniciales(nombre: conductor.nombre),
        const SizedBox(width: Sp.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conductor.nombre,
                style: NexaTexto.subtitulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (partes.isNotEmpty)
                Row(
                  children: [
                    if (conductor.calificacion != null) ...[
                      const Icon(Icons.star, size: 14, color: NexaColors.gold),
                      const SizedBox(width: Sp.xs),
                    ],
                    Flexible(
                      child: Text(
                        partes.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: NexaTexto.pequeno.copyWith(
                          color: NexaColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              if (conductor.vehiculo != null)
                Text(
                  conductor.vehiculo!,
                  style: NexaTexto.pequeno.copyWith(color: NexaColors.tenue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (conductor.placa != null) ...[
          const SizedBox(width: Sp.sm),
          PlacaMoto(placa: conductor.placa!),
        ],
      ],
    );
  }
}
