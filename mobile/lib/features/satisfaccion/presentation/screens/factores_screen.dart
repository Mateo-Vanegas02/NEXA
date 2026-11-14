import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/satisfaccion.dart';
import '../controllers/satisfaccion_controller.dart';
import '../widgets/satisfaccion_widgets.dart';
import 'formato_sat.dart';

/// Qué pesa más en la satisfacción de cada lado y cómo cambia por tramos.
class FactoresScreen extends ConsumerWidget {
  const FactoresScreen({super.key});

  /// Cuántos factores se muestran en "Qué pesa más".
  static const maxFactores = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lado = ref.watch(ladoFactoresProvider);
    final factores = ref.watch(factoresProvider);
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(factoresProvider.future),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                context.gutter,
                Sp.sm,
                context.gutter,
                Sp.xl,
              ),
              children: [
                ContenidoCentrado(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EncabezadoSat(
                        etiqueta: l.satTitulo,
                        titulo: l.satFactores,
                        atras: true,
                      ),
                      const SizedBox(height: Sp.md),
                      SelectorSegmentado<Lado>(
                        opciones: [
                          (Lado.pasajero, l.satPasajero),
                          (Lado.conductor, l.satConductor),
                        ],
                        seleccion: lado,
                        onSeleccion: (v) =>
                            ref.read(ladoFactoresProvider.notifier).elegir(v),
                      ),
                      const SizedBox(height: Sp.md),
                      factores.when(
                        loading: () => const CargandoSkeleton(),
                        error: (e, _) => EstadoError(
                          mensaje: AppException.from(e).mensaje,
                          onReintentar: () => ref.invalidate(factoresProvider),
                        ),
                        data: (f) => _Contenido(f: f),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.f});
  final Factores f;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.textos;
    final top = f.importancia.take(FactoresScreen.maxFactores).toList();
    final mayor = top.isEmpty ? 1.0 : top.first.pesoPct;
    final elegida = ref.watch(curvaSeleccionadaProvider);
    final i = elegida < f.curvas.length ? elegida : 0;
    final curva = f.curvas.isEmpty ? null : f.curvas[i];
    final titulo = t.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    final sub = t.bodySmall?.copyWith(color: context.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (f.sinModelo) ...[
          AvisoSat(
            tipo: TipoAviso.aviso,
            negrita: l.satSinModeloTitulo,
            texto: l.satSinModeloFactores,
          ),
          const SizedBox(height: Sp.md),
        ],
        TarjetaSat(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.satQuePesaMas, style: titulo),
              const SizedBox(height: 2),
              Text(l.satQuePesaMasDetalle, style: sub),
              const SizedBox(height: Sp.md),
              for (final (n, fac) in top.indexed) ...[
                if (n > 0) const SizedBox(height: Sp.xs),
                _FilaFactor(
                  puesto: n + 1,
                  factor: fac,
                  // La barra más larga es la del factor de mayor peso.
                  fraccion: fac.pesoPct / (mayor * 1.14),
                  color: n < 3 ? context.acento : NexaColors.sky,
                  // Los factores con curva se pueden tocar para verla abajo.
                  curva: f.curvas.indexWhere((c) => c.variable == fac.variable),
                  elegida: i,
                ),
              ],
              if (f.otrosCantidad > 0) ...[
                const SizedBox(height: Sp.md),
                Text(
                  l.satOtrosFactores(
                    '${f.otrosCantidad}',
                    FormatoSat.pct(f.otrosPesoMaximoPct),
                  ),
                  style: t.labelSmall?.copyWith(color: context.muted),
                ),
              ],
            ],
          ),
        ),
        if (curva != null) ...[
          const SizedBox(height: Sp.md),
          TarjetaSat(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.satComoCambia, style: titulo),
                const SizedBox(height: 2),
                Text(
                  f.lado == Lado.pasajero
                      ? l.satPorTramoPasajero
                      : l.satPorTramoConductor,
                  style: sub,
                ),
                const SizedBox(height: Sp.md),
                ChipsFiltro<int>(
                  opciones: [
                    for (final (n, c) in f.curvas.indexed) (n, c.etiqueta),
                  ],
                  seleccion: i,
                  onSeleccion: (n) =>
                      ref.read(curvaSeleccionadaProvider.notifier).elegir(n),
                ),
                const SizedBox(height: Sp.lg),
                GraficaTramos(
                  semantica: [
                    curva.etiqueta,
                    for (final tr in curva.tramos)
                      '${tr.etiqueta}: ${FormatoSat.pct(tr.satisfechosPct)}',
                  ].join('. '),
                  tramos: [
                    for (final tr in curva.tramos)
                      (tr.etiqueta, tr.satisfechosPct),
                  ],
                ),
                if (curva.hallazgo != null) ...[
                  const SizedBox(height: Sp.md),
                  AvisoSat(texto: curva.hallazgo!),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Un factor de «Qué pesa más»: puesto, barra y, si tiene curva por tramos,
/// se puede tocar para verla (queda resaltado mientras es la elegida).
class _FilaFactor extends ConsumerWidget {
  const _FilaFactor({
    required this.puesto,
    required this.factor,
    required this.fraccion,
    required this.color,
    required this.curva,
    required this.elegida,
  });

  final int puesto;
  final FactorImportancia factor;
  final double fraccion;
  final Color color;

  /// Posición de su curva en la lista de curvas, o -1 si no tiene.
  final int curva;

  /// Curva que se está mostrando abajo.
  final int elegida;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activa = curva >= 0 && curva == elegida;
    final radio = BorderRadius.circular(Rad.md);
    final fila = Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Text(
              '$puesto',
              style: context.textos.labelSmall?.copyWith(
                color: activa ? context.acento : context.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: FilaBarra(
              etiqueta: factor.etiqueta,
              valor: FormatoSat.pct(factor.pesoPct),
              fraccion: fraccion,
              color: color,
            ),
          ),
        ],
      ),
    );
    return Material(
      color: activa ? context.acento.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: radio,
      child: InkWell(
        borderRadius: radio,
        onTap: curva < 0
            ? null
            : () => ref.read(curvaSeleccionadaProvider.notifier).elegir(curva),
        child: fila,
      ),
    );
  }
}
