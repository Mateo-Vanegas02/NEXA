import '../../../../core/theme/theme_x.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../controllers/viaje_conductor_controller.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cuánto efectivo cobró el conductor frente a lo que le corresponde, en los
/// últimos 30 días. Si falla, simplemente no se muestra: no bloquea la pantalla.
class _SaldoCard extends ConsumerWidget {
  const _SaldoCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final saldo = ref.watch(saldoProvider).asData?.value;
    if (saldo == null) return const SizedBox.shrink();
    Widget fila(String a, String b) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.xs),
      child: Row(
        children: [
          Expanded(child: Text(a, style: t.bodyMedium)),
          const SizedBox(width: Sp.sm),
          Text(b, style: t.bodyMedium),
        ],
      ),
    );
    final debe = saldo.saldoConNexa >= 0;
    return NexaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l.saldoConNexa} · ${l.ultimos30Dias}',
            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Sp.xs),
          fila(l.viajesPeriodo, '${saldo.viajes}'),
          fila(l.cobradoEfectivo, Fmt.cop(saldo.cobradoEfectivo)),
          fila(l.gananciaPeriodo, Fmt.cop(saldo.ganado)),
          if (saldo.cargosAFavor > 0)
            fila(l.cargosAFavor, Fmt.cop(saldo.cargosAFavor)),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Text(
                  debe ? l.debesANexa : l.nexaTeDebe,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                Fmt.cop(saldo.saldoConNexa.abs()),
                style: t.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: debe ? NexaColors.gold : NexaColors.ok,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Barras con la ganancia de los últimos viajes; la más alta va en cian.
class _Barras extends StatelessWidget {
  const _Barras({required this.montos});
  final List<double> montos;

  static const double _alto = 72;

  @override
  Widget build(BuildContext context) {
    final mayor = montos.reduce((a, b) => a > b ? a : b);
    final iMayor = montos.indexOf(mayor);
    return SizedBox(
      height: _alto + 8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < montos.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: mayor <= 0
                        ? 4
                        : (montos[i] / mayor * _alto).clamp(4.0, _alto),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                        bottom: Radius.circular(3),
                      ),
                      color: i == iMayor ? null : NexaColors.navy,
                      gradient: i == iMayor
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [NexaColors.cyan, NexaColors.navy],
                            )
                          : null,
                      boxShadow: i == iMayor ? NexaShadows.glow : null,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GananciasScreen extends ConsumerWidget {
  const GananciasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final ingresos = ref.watch(ingresosProvider);
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          bottom: false,
          child: ingresos.when(
            loading: () => const CargandoSkeleton(),
            error: (e, _) => EstadoError(
              mensaje: AppException.from(e).mensaje,
              onReintentar: () => ref.invalidate(ingresosProvider),
            ),
            data: (lista) {
              final total = lista.fold<double>(0, (a, i) => a + i.monto);
              // Los últimos viajes, del más antiguo al más reciente.
              final recientes = lista
                  .take(10)
                  .map((i) => i.monto)
                  .toList()
                  .reversed
                  .toList();
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  context.gutter,
                  Sp.lg,
                  context.gutter,
                  Sp.xl + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  ContenidoCentrado(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.gananciasTitulo,
                          style: NexaTexto.titulo.copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: Sp.lg),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: NexaColors.card,
                            borderRadius: BorderRadius.circular(Rad.lg + 4),
                            border: Border.all(
                              color: NexaColors.cyan.withValues(alpha: 0.45),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: NexaColors.cyan.withValues(alpha: 0.18),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(Sp.lg + 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.gananciaTotal,
                                  style: t.labelMedium?.copyWith(
                                    color: context.muted,
                                  ),
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    Fmt.cop(total),
                                    style: NexaTexto.numero,
                                  ),
                                ),
                                if (recientes.length > 1) ...[
                                  const SizedBox(height: Sp.md),
                                  Text(
                                    l.gananciaPorViaje,
                                    style: t.bodySmall?.copyWith(
                                      color: context.muted,
                                    ),
                                  ),
                                  const SizedBox(height: Sp.sm),
                                  _Barras(montos: recientes),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: Sp.md),
                        const _SaldoCard(),
                        const SizedBox(height: Sp.md),
                        if (lista.isEmpty)
                          SizedBox(
                            height: 200,
                            child: EstadoVacio(
                              titulo: l.vacioHistorial,
                              detalle: l.vacioHistorialDetalle,
                              icon: Icons.payments_outlined,
                            ),
                          )
                        else ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: Sp.xs,
                              top: Sp.sm,
                              bottom: Sp.sm,
                            ),
                            child: Text(
                              l.ultimosViajes.toUpperCase(),
                              style: NexaTexto.etiqueta.copyWith(
                                color: NexaColors.tenue,
                              ),
                            ),
                          ),
                          NexaCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Sp.lg,
                              vertical: Sp.xs,
                            ),
                            child: Column(
                              children: [
                                for (var k = 0; k < lista.length; k++) ...[
                                  if (k > 0)
                                    Divider(
                                      height: 1,
                                      color: context.colors.outline.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  _FilaIngreso(
                                    descripcion: lista[k].descripcion,
                                    fecha: lista[k].fecha,
                                    monto: lista[k].monto,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FilaIngreso extends StatelessWidget {
  const _FilaIngreso({
    required this.descripcion,
    required this.fecha,
    required this.monto,
  });
  final String descripcion;
  final String fecha;
  final double monto;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: NexaColors.cyan.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.place_outlined, size: 18, color: context.acento),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descripcion,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(fecha, style: t.bodySmall?.copyWith(color: context.muted)),
              ],
            ),
          ),
          const SizedBox(width: Sp.sm),
          Text(
            Fmt.cop(monto),
            style: t.titleSmall?.copyWith(
              color: NexaColors.ok,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
