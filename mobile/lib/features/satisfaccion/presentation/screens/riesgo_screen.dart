import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/satisfaccion.dart';
import '../controllers/satisfaccion_controller.dart';
import '../widgets/pulso_widgets.dart';
import '../widgets/satisfaccion_widgets.dart';
import 'formato_sat.dart';

/// Viajes sin calificar con alta probabilidad de "no", ordenados por probabilidad.
class RiesgoScreen extends ConsumerWidget {
  const RiesgoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final riesgo = ref.watch(riesgoProvider);
    final filtro = ref.watch(filtroRiesgoProvider);
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(riesgoProvider.future),
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
                        titulo: l.satViajesRiesgo,
                        atras: true,
                      ),
                      const SizedBox(height: Sp.sm),
                      Text(
                        l.satRiesgoIntro,
                        style: context.textos.bodySmall?.copyWith(
                          color: context.muted,
                        ),
                      ),
                      const SizedBox(height: Sp.md),
                      riesgo.when(
                        loading: () => const CargandoSkeleton(),
                        error: (e, _) => EstadoError(
                          mensaje: AppException.from(e).mensaje,
                          onReintentar: () => ref.invalidate(riesgoProvider),
                        ),
                        data: (r) => _Lista(r: r, filtro: filtro),
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

class _Lista extends ConsumerWidget {
  const _Lista({required this.r, required this.filtro});
  final Riesgo r;
  final Lado? filtro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final viajes = [
      for (final v in r.viajes)
        if (filtro == null || v.lado == filtro) v,
    ]..sort((a, b) => b.probabilidadNo.compareTo(a.probabilidadNo));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChipsFiltro<Lado?>(
          opciones: [
            (null, l.satConteo(l.satTodos, '${r.cuantos(null)}')),
            (
              Lado.pasajero,
              l.satConteo(l.satPasajero, '${r.cuantos(Lado.pasajero)}'),
            ),
            (
              Lado.conductor,
              l.satConteo(l.satConductor, '${r.cuantos(Lado.conductor)}'),
            ),
          ],
          seleccion: filtro,
          onSeleccion: (v) => ref.read(filtroRiesgoProvider.notifier).elegir(v),
        ),
        const SizedBox(height: Sp.md),
        if (viajes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Sp.xl),
            child: EstadoVacio(
              titulo: l.satSinRiesgo,
              detalle: l.satSinRiesgoDetalle,
              icon: Icons.sentiment_satisfied_alt_outlined,
            ),
          )
        else
          for (final v in viajes) ...[
            _TarjetaViaje(v: v),
            const SizedBox(height: Sp.md),
          ],
        Text(
          l.satUmbral(FormatoSat.probabilidad(r.umbral)),
          textAlign: TextAlign.center,
          style: context.textos.labelSmall?.copyWith(color: context.muted),
        ),
      ],
    );
  }
}

class _TarjetaViaje extends ConsumerWidget {
  const _TarjetaViaje({required this.v});
  final ViajeRiesgo v;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.textos;
    final ahora = ref.watch(relojSatisfaccionProvider)();
    final alto = v.probabilidadNo >= 0.6;
    final colorProb = alto ? colorMalo(context) : colorAviso(context);
    final fecha = v.fecha == null ? '' : Fmt.fechaRelativa(v.fecha!, ahora);
    return TarjetaSat(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.satViajeTitulo(v.id, fecha),
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.satRuta(
                        v.origen,
                        v.destino,
                        FormatoSat.km(v.distanciaKm),
                      ),
                      style: t.bodySmall?.copyWith(color: context.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Sp.sm),
              Column(
                children: [
                  AnilloProbabilidad(
                    valor: v.probabilidadNo,
                    texto: FormatoSat.probabilidad(v.probabilidadNo),
                    color: colorProb,
                  ),
                  const SizedBox(height: Sp.xs),
                  Text(
                    l.satProbNo,
                    style: t.labelSmall?.copyWith(color: context.muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: Sp.sm,
            runSpacing: Sp.sm,
            children: [
              EtiquetaSat(
                texto: v.lado == Lado.pasajero ? l.satPasajero : l.satConductor,
                color: v.lado == Lado.pasajero
                    ? context.acento
                    : colorOk(context),
              ),
              for (final m in v.motivos)
                EtiquetaSat(
                  texto: m.texto,
                  color: m.severidad == Severidad.alta
                      ? colorMalo(context)
                      : colorAviso(context),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
