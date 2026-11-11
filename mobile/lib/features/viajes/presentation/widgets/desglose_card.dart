import '../../../../core/theme/theme_x.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/nexa_widgets.dart';

import 'package:flutter/material.dart';

/// Tarjeta de desglose: filas (etiqueta, monto) y total.
class DesgloseCard extends StatelessWidget {
  const DesgloseCard({
    required this.titulo,
    required this.filas,
    required this.total,
    this.km,
    this.nota,
    super.key,
  });

  final String titulo;
  final List<(String, double)> filas;
  final double total;
  final double? km;
  final String? nota;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    Widget fila(String a, String b, {TextStyle? style}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.xs),
      child: Row(
        children: [
          Expanded(child: Text(a, style: style)),
          const SizedBox(width: Sp.sm),
          Text(b, style: style),
        ],
      ),
    );
    return NexaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: t.titleSmall),
          if (km != null) fila(l.distancia, '${km!.toStringAsFixed(1)} km'),
          for (final f in filas) fila(f.$1, Fmt.cop(f.$2)),
          const Divider(),
          fila(l.total, Fmt.cop(total), style: t.titleMedium),
          if (nota != null)
            Text(nota!, style: t.bodySmall?.copyWith(color: context.muted)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ viaje activo
