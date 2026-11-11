import '../../../../core/theme/theme_x.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/nivel.dart';

import 'package:flutter/material.dart';

/// Un escalón de la escalera de niveles: nodo sobre una línea vertical, con el
/// nivel, su XP, el descuento o la comisión y los beneficios que desbloquea.
class NivelTile extends StatelessWidget {
  const NivelTile({
    super.key,
    required this.info,
    required this.actual,
    required this.esConductor,
    this.ultimo = false,
  });
  final NivelInfo info;
  final int actual;
  final bool esConductor;

  /// El último escalón no dibuja la línea hacia abajo.
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    final alcanzado = actual >= info.nivel;
    final esActual = actual == info.nivel;
    final porcentaje = esConductor && info.comision != null
        ? Fmt.pct(info.comision!)
        : !esConductor && (info.descuento ?? 0) > 0
        ? Fmt.pct(info.descuento!)
        : null;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                _Nodo(alcanzado: alcanzado, esActual: esActual),
                if (!ultimo)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        color: NexaColors.cyan.withValues(
                          alpha: alcanzado ? 0.6 : 0.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: ultimo ? 0 : Sp.lg),
              child: Opacity(
                opacity: alcanzado ? 1 : 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${l.nivelActual(info.nombre)} · ${info.xp} XP',
                            style: t.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (porcentaje != null)
                          Text(
                            porcentaje,
                            style: t.titleSmall?.copyWith(
                              color: alcanzado
                                  ? NexaColors.cyan
                                  : context.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    if (esActual)
                      Text(
                        l.estasAqui,
                        style: t.bodySmall?.copyWith(
                          color: NexaColors.cyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    for (final b in info.beneficios) ...[
                      const SizedBox(height: Sp.sm),
                      Text(
                        b.titulo,
                        style: t.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (b.descripcion.isNotEmpty)
                        Text(
                          b.descripcion,
                          style: t.bodySmall?.copyWith(color: context.muted),
                        ),
                      if (!alcanzado)
                        Text(
                          l.beneficioBloqueado(b.nivelRequerido),
                          style: t.bodySmall,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Nodo extends StatelessWidget {
  const _Nodo({required this.alcanzado, required this.esActual});
  final bool alcanzado;
  final bool esActual;

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: alcanzado ? NexaColors.cyan : NexaColors.raised,
      boxShadow: esActual ? NexaShadows.glow : null,
    ),
    child: Icon(
      esActual
          ? Icons.two_wheeler
          : alcanzado
          ? Icons.check
          : Icons.lock_outline,
      size: 16,
      color: alcanzado ? NexaColors.bg : context.muted,
    ),
  );
}
