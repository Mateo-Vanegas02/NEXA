import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/servicio.dart';
import 'estado_chip.dart';

/// Fila de viaje: "Origen → Destino", fecha · distancia, precio y estado.
class ViajeTile extends StatelessWidget {
  const ViajeTile({required this.servicio, this.onTap, super.key});

  final Servicio servicio;
  final VoidCallback? onTap;

  String _subtitulo() {
    final partes = <String>[];
    final f = servicio.fechaHora;
    if (f != null) partes.add(Fmt.fechaRelativa(f, DateTime.now()));
    if (servicio.distanciaKM > 0) {
      partes.add(
        '${NumberFormat('0.0', 'es_CO').format(servicio.distanciaKM)} km',
      );
    }
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.textos;
    final titulo = servicio.origen.isEmpty
        ? servicio.destino
        : '${servicio.origen} → ${servicio.destino}';
    return NexaCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Sp.sm),
            decoration: BoxDecoration(
              color: NexaColors.cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(Rad.sm),
            ),
            child: Icon(Icons.swap_calls, color: context.acento),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _subtitulo(),
                  style: t.bodySmall?.copyWith(color: context.muted),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: Sp.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Fmt.cop(servicio.tarifa),
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: Sp.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: EstadoChip(estado: servicio.estado),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
