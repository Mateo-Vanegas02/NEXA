import '../../../../core/theme/theme_x.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/nivel.dart';

import 'package:flutter/material.dart';

class ConductorInfoCard extends StatelessWidget {
  const ConductorInfoCard({super.key, required this.info});
  final ConductorInfo info;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return NexaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.comisionActual, style: t.labelMedium),
          Text(Fmt.pct(info.comisionActual), style: t.headlineSmall),
          if (info.comisionSiguiente != null) ...[
            const SizedBox(height: Sp.sm),
            Text(
              '${l.comisionSiguiente}: ${Fmt.pct(info.comisionSiguiente!)}',
              style: t.bodyMedium,
            ),
          ],
          const SizedBox(height: Sp.lg),
          Text(l.requisitosCalidad, style: t.titleSmall),
          for (final r in info.requisitosSiguiente)
            Padding(
              padding: const EdgeInsets.only(top: Sp.sm),
              child: Row(
                children: [
                  Icon(
                    r.cumplido
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: r.cumplido ? NexaColors.ok : context.muted,
                    size: 20,
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(child: Text(r.texto)),
                ],
              ),
            ),
          if (info.bloqueadoPorCalidad) ...[
            const SizedBox(height: Sp.md),
            Text(
              l.bloqueadoCalidad,
              style: t.bodySmall?.copyWith(color: NexaColors.gold),
            ),
          ],
        ],
      ),
    );
  }
}
