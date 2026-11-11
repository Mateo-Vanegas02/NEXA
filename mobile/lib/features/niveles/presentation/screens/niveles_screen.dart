import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/nivel.dart';
import '../controllers/niveles_controller.dart';
import '../widgets/conductor_info_card.dart';
import '../widgets/nivel_tile.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NivelesScreen extends ConsumerWidget {
  const NivelesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final nivel = ref.watch(nivelProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.nivelesTitulo)),
      body: FondoNexa(
        child: SafeArea(
          child: nivel.when(
            loading: () => const CargandoSkeleton(),
            error: (e, _) => EstadoError(
              mensaje: AppException.from(e).mensaje,
              onReintentar: () => ref.invalidate(nivelProvider),
            ),
            data: (n) => RefreshIndicator(
              onRefresh: () => ref.read(nivelProvider.notifier).refrescar(),
              child: ListView(
                padding: EdgeInsets.all(context.gutter),
                children: [ContenidoCentrado(child: _Contenido(n: n))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Número de nivel dentro de un anillo con el avance hacia el siguiente, y los
/// XP que faltan.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.n});
  final NivelEstado n;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.textos;
    final progreso = n.esNivelMaximo ? 1.0 : n.progreso.clamp(0.0, 1.0);
    final meta = n.xpSiguienteNivel;
    return Column(
      children: [
        NexaAnilloProgreso(
          progreso: progreso,
          diametro: 136,
          trazo: 9,
          relleno: 4,
          etiquetaSemantica: l.barraNivelSemantica(
            n.nombre,
            (progreso * 100).round(),
          ),
          child: ExcludeSemantics(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${n.nivel}',
                    textScaler: TextScaler.noScaling,
                    style: t.displayMedium?.copyWith(
                      color: NexaColors.cyan,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  Text(
                    l.statNivel.toUpperCase(),
                    textScaler: TextScaler.noScaling,
                    style: t.labelSmall?.copyWith(
                      color: context.muted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: Sp.md),
        Text(
          meta == null ? '${n.xpActual} XP' : l.xpProgreso(n.xpActual, meta),
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: Sp.xs),
        Text(
          n.esNivelMaximo
              ? l.nivelMaximo
              : l.faltanXp(n.xpFaltante, n.nombreSiguiente ?? ''),
          textAlign: TextAlign.center,
          style: t.bodySmall?.copyWith(color: context.muted),
        ),
      ],
    );
  }
}

/// Lo que el nivel actual del pasajero le da hoy: descuento y prioridad de recogida.
class _VentajasPasajero extends StatelessWidget {
  const _VentajasPasajero({required this.n});
  final NivelEstado n;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final sinVentajas = n.descuento <= 0 && n.prioridadSegundos <= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.ventajasActuales,
            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Sp.sm),
          if (sinVentajas)
            NexaCard(child: Text(l.sinVentajas))
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (n.descuento > 0)
                  Expanded(
                    child: _Ventaja(
                      icono: Icons.percent,
                      valor: Fmt.pct(n.descuento),
                      etiqueta: l.descuentoViajes,
                      color: NexaColors.cyan,
                    ),
                  ),
                if (n.descuento > 0 && n.prioridadSegundos > 0)
                  const SizedBox(width: Sp.md),
                if (n.prioridadSegundos > 0)
                  Expanded(
                    child: _Ventaja(
                      icono: Icons.bolt_outlined,
                      valor: '${n.prioridadSegundos} s',
                      etiqueta: l.prioridadRecogida,
                      color: NexaColors.ok,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Ventaja extends StatelessWidget {
  const _Ventaja({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    required this.color,
  });
  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: NexaColors.card,
      borderRadius: BorderRadius.circular(Rad.lg),
      border: Border.all(color: NexaColors.cyan.withValues(alpha: 0.18)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(Sp.lg - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Rad.md),
            ),
            child: Icon(icono, size: 18, color: color),
          ),
          const SizedBox(height: Sp.sm),
          Text(
            valor,
            style: context.textos.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            etiqueta,
            style: context.textos.bodySmall?.copyWith(color: context.muted),
          ),
        ],
      ),
    ),
  );
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.n});
  final NivelEstado n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final esConductor = n.rol.toLowerCase() == 'conductor';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Resumen(n: n),
        const SizedBox(height: Sp.xl),
        if (esConductor && n.conductor != null) ...[
          ConductorInfoCard(info: n.conductor!),
          const SizedBox(height: Sp.lg),
        ],
        if (!esConductor) _VentajasPasajero(n: n),
        Text(
          l.beneficios.toUpperCase(),
          style: t.labelSmall?.copyWith(
            color: context.muted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: Sp.md),
        for (var i = 0; i < n.niveles.length; i++)
          NivelTile(
            info: n.niveles[i],
            actual: n.nivel,
            esConductor: esConductor,
            ultimo: i == n.niveles.length - 1,
          ),
        if (!esConductor) ...[
          const SizedBox(height: Sp.xl),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: context.muted),
              const SizedBox(width: Sp.sm),
              Expanded(
                child: Text(
                  l.inactividadNota,
                  style: t.bodySmall?.copyWith(color: context.muted),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
