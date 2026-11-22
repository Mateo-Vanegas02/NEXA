import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/nivel.dart';

/// Comisión y requisitos de calidad del conductor (rediseño 2026): la comisión
/// de hoy frente a la del siguiente nivel, sus tres indicadores y la lista de
/// requisitos con cuántos cumple. Todo viene del servidor.
class ConductorInfoCard extends StatelessWidget {
  const ConductorInfoCard({super.key, required this.info});
  final ConductorInfo info;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cumplidos = info.requisitosSiguiente.where((r) => r.cumplido).length;
    final total = info.requisitosSiguiente.length;
    final siguiente = info.comisionSiguiente;
    return NexaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.comisionActual,
            style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Sp.md,
            runSpacing: Sp.xs,
            children: [
              Text(
                Fmt.pct(info.comisionActual),
                style: NexaTexto.numero.copyWith(fontSize: 34),
              ),
              if (siguiente != null) ...[
                const Icon(Icons.arrow_forward, color: NexaColors.muted),
                Semantics(
                  label: '${l.comisionSiguiente}: ${Fmt.pct(siguiente)}',
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Fmt.pct(siguiente),
                          style: NexaTexto.numero.copyWith(
                            fontSize: 26,
                            color: NexaColors.ok,
                          ),
                        ),
                        Text(
                          l.comisionSiguiente,
                          style: NexaTexto.pequeno.copyWith(
                            color: NexaColors.ok,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Sp.lg),
          Row(
            children: [
              if (info.calificacion != null) ...[
                Expanded(
                  child: _Indicador(
                    titulo: l.indicadorCalificacion,
                    valor: info.calificacion!.toStringAsFixed(1),
                    icono: Icons.star_rounded,
                    color: NexaColors.gold,
                  ),
                ),
                const SizedBox(width: Sp.sm),
              ],
              Expanded(
                child: _Indicador(
                  titulo: l.indicadorAceptacion,
                  valor: Fmt.pct(info.aceptacion),
                  icono: Icons.check_rounded,
                  color: NexaColors.ok,
                ),
              ),
              const SizedBox(width: Sp.sm),
              Expanded(
                child: _Indicador(
                  titulo: l.indicadorCancelacion,
                  valor: Fmt.pct(info.cancelacion),
                  icono: Icons.close_rounded,
                  color: NexaColors.error,
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: Sp.lg),
            Row(
              children: [
                Expanded(
                  child: Text(l.requisitosCalidad, style: NexaTexto.subtitulo),
                ),
                Text(
                  l.requisitosCumplidos(cumplidos, total),
                  style: NexaTexto.pequeno.copyWith(
                    color: cumplidos == total ? NexaColors.ok : NexaColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sp.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: cumplidos / total,
                minHeight: 6,
                backgroundColor: NexaColors.line,
                color: cumplidos == total ? NexaColors.ok : NexaColors.cyan,
              ),
            ),
            for (final r in info.requisitosSiguiente)
              Padding(
                padding: const EdgeInsets.only(top: Sp.md),
                child: Row(
                  children: [
                    Icon(
                      r.cumplido
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: r.cumplido ? NexaColors.ok : NexaColors.muted,
                      size: 20,
                    ),
                    const SizedBox(width: Sp.sm),
                    Expanded(
                      child: Text(
                        r.texto,
                        style: NexaTexto.cuerpo.copyWith(
                          color: r.cumplido
                              ? NexaColors.texto
                              : NexaColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (info.bloqueadoPorCalidad) ...[
            const SizedBox(height: Sp.md),
            Text(
              l.bloqueadoCalidad,
              style: NexaTexto.pequeno.copyWith(color: NexaColors.gold),
            ),
          ],
        ],
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$titulo: $valor',
    child: ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(Sp.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Rad.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 18, color: color),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(valor, style: NexaTexto.numeroMedio),
            ),
            Text(
              titulo,
              maxLines: 2,
              style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
            ),
          ],
        ),
      ),
    ),
  );
}
