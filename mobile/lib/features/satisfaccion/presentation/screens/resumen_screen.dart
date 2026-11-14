import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/satisfaccion.dart';
import '../controllers/satisfaccion_controller.dart';
import '../widgets/pulso_widgets.dart';
import '../widgets/satisfaccion_widgets.dart';
import 'formato_sat.dart';

/// Inicio del panel: satisfacción de pasajeros y conductores, tendencia y accesos.
class ResumenScreen extends ConsumerWidget {
  const ResumenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final resumen = ref.watch(resumenProvider);
    final periodo = ref.watch(periodoProvider);
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(resumenProvider.future),
            child: ListView(
              // Espacio al final para la barra flotante.
              padding: EdgeInsets.fromLTRB(
                context.gutter,
                Sp.sm,
                context.gutter,
                120,
              ),
              children: [
                ContenidoCentrado(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EncabezadoSat(
                        etiqueta: l.satEyebrow,
                        titulo: l.satTitulo,
                        accion: BotonRedondo(
                          icono: Icons.memory_outlined,
                          tooltip: l.satVerModelo,
                          color: context.acento,
                          onPressed: () =>
                              context.push('/a/satisfaccion/modelo'),
                        ),
                      ),
                      const SizedBox(height: Sp.md),
                      ChipsFiltro<TipoPeriodo>(
                        opciones: [
                          (TipoPeriodo.dias7, l.satPeriodo7),
                          (TipoPeriodo.dias30, l.satPeriodo30),
                          (TipoPeriodo.dias90, l.satPeriodo90),
                          (
                            TipoPeriodo.rango,
                            periodo.tipo == TipoPeriodo.rango
                                ? FormatoSat.rango(periodo.desde, periodo.hasta)
                                : l.satPeriodoRango,
                          ),
                        ],
                        seleccion: periodo.tipo,
                        onSeleccion: (t) {
                          if (t == TipoPeriodo.rango) {
                            unawaited(_elegirRango(context, ref));
                          } else {
                            ref.read(periodoProvider.notifier).elegir(t);
                          }
                        },
                      ),
                      const SizedBox(height: Sp.md),
                      resumen.when(
                        skipLoadingOnRefresh: true,
                        loading: () => const CargandoSkeleton(),
                        error: (e, _) => EstadoError(
                          mensaje: AppException.from(e).mensaje,
                          onReintentar: () => ref.invalidate(resumenProvider),
                        ),
                        data: (r) =>
                            _Contenido(r: r),
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

  Future<void> _elegirRango(BuildContext context, WidgetRef ref) async {
    final hoy = ref.read(relojSatisfaccionProvider)();
    final actual = ref.read(periodoProvider);
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(hoy.year, hoy.month, hoy.day),
      initialDateRange: DateTimeRange(start: actual.desde, end: actual.hasta),
    );
    if (r != null) ref.read(periodoProvider.notifier).rango(r.start, r.end);
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.r});
  final Resumen r;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (r.sinModelo) ...[
          AvisoSat(
            tipo: TipoAviso.aviso,
            negrita: l.satSinModeloTitulo,
            texto: l.satSinModeloTexto,
          ),
          const SizedBox(height: Sp.md),
        ],
        _Pulso(r: r),
        const SizedBox(height: Sp.md),
        _Tendencia(serie: r.serie),
        const SizedBox(height: Sp.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Acceso(
                  titulo: l.satViajesRiesgo,
                  detalle: l.satViajesRiesgoDetalle,
                  insignia: Text(
                    '${r.riesgoTotal}',
                    style: context.textos.labelLarge?.copyWith(
                      color: colorMalo(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  color: colorMalo(context),
                  ruta: '/a/satisfaccion/riesgo',
                ),
              ),
              const SizedBox(width: Sp.sm),
              Expanded(
                child: _Acceso(
                  titulo: l.satFactores,
                  detalle: r.factorPrincipal == null
                      ? l.satQuePesaMas
                      : l.satLoQueMasPesa(r.factorPrincipal!),
                  insignia: Icon(Icons.sort, size: 18, color: context.acento),
                  color: context.acento,
                  ruta: '/a/satisfaccion/factores',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.titulo,
    required this.datos,
    required this.color,
  });

  final String titulo;
  final ResumenLado datos;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.textos;
    final pct = datos.satisfechosPct;
    final variacion = datos.variacionPts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3, right: Sp.sm),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            Expanded(
              child: Text(
                titulo,
                style: t.labelSmall?.copyWith(
                  color: context.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          pct == null ? '–' : FormatoSat.pct(pct),
          style: t.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (pct == null)
          Text(
            l.satSinCalificaciones,
            style: t.labelSmall?.copyWith(color: context.muted),
          )
        else if (variacion != null)
          Text(
            '${variacion >= 0 ? '▲' : '▼'} '
            '${l.satVariacion(FormatoSat.numero(variacion.abs()))}',
            style: t.labelSmall?.copyWith(
              color: variacion >= 0 ? colorOk(context) : colorMalo(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        Text(
          l.satCalifica(FormatoSat.pct(datos.tasaRespuestaPct)),
          style: t.labelSmall?.copyWith(color: context.muted),
        ),
      ],
    );
  }
}

/// El pulso del período: dial de dos anillos (pasajeros por fuera, conductores
/// por dentro) con el total de calificaciones en el centro, y al lado cada
/// porcentaje con su variación y cuántos califican.
class _Pulso extends StatelessWidget {
  const _Pulso({required this.r});
  final Resumen r;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.textos;
    final ok = colorOk(context);
    final notas = r.pasajero.calificaciones + r.conductor.calificaciones;
    return TarjetaSat(
      padding: const EdgeInsets.all(Sp.md),
      child: Row(
        children: [
          ExcludeSemantics(
            child: DialDoble(
              exterior: r.pasajero.satisfechosPct,
              interior: r.conductor.satisfechosPct,
              colorExterior: context.acento,
              colorInterior: ok,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$notas',
                    style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    l.satNotas,
                    style: t.labelSmall?.copyWith(color: context.muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Indicador(
                  titulo: l.satPasajerosSatisfechos,
                  datos: r.pasajero,
                  color: context.acento,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Sp.sm),
                  child: Divider(height: 1, color: bordeSuave(context)),
                ),
                _Indicador(
                  titulo: l.satConductoresSatisfechos,
                  datos: r.conductor,
                  color: ok,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tendencia extends StatelessWidget {
  const _Tendencia({required this.serie});
  final SerieSatisfaccion serie;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ok = colorOk(context);
    final puntos = serie.puntos;
    final minimo = FormatoSat.minimoEscala([
      for (final p in puntos) ...[p.pasajeroPct, p.conductorPct],
    ]);
    final tope = serie.minimoNotas;
    bool debil(int? n) => tope != null && n != null && n < tope;
    final hayDebiles = puntos.any(
      (p) =>
          (p.pasajeroPct != null && debil(p.pasajeroNotas)) ||
          (p.conductorPct != null && debil(p.conductorNotas)),
    );
    final aviso = context.textos.bodySmall?.copyWith(color: context.muted);
    return TarjetaSat(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: Sp.xs,
            spacing: Sp.md,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: l.satTendencia,
                      style: context.textos.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: '  ${FormatoSat.porAgrupacion(l, serie.agrupacion)}',
                      style: context.textos.labelSmall?.copyWith(
                        color: context.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: Sp.md,
                children: [
                  Leyenda(texto: l.satPasajero, color: context.acento),
                  Leyenda(texto: l.satConductor, color: ok),
                ],
              ),
            ],
          ),
          const SizedBox(height: Sp.md),
          if (serie.tramosConDatos == 0)
            Text(l.satSinCalificaciones, style: context.textos.bodySmall)
          else ...[
            GraficaTendencia(
              minimo: minimo,
              minimoNotas: tope,
              formato: FormatoSat.pct,
              textoNotas: (n) => FormatoSat.notas(l, n),
              semantica: FormatoSat.semanticaSerie(l, serie),
              etiquetasX: [
                for (final p in puntos)
                  FormatoSat.etiquetaEje(p, serie.agrupacion),
              ],
              etiquetasLectura: [
                for (final p in puntos)
                  FormatoSat.etiquetaLectura(p, serie.agrupacion),
              ],
              series: [
                SerieLinea(
                  valores: [for (final p in puntos) p.pasajeroPct],
                  notas: [for (final p in puntos) p.pasajeroNotas],
                  color: context.acento,
                ),
                SerieLinea(
                  valores: [for (final p in puntos) p.conductorPct],
                  notas: [for (final p in puntos) p.conductorNotas],
                  color: ok,
                ),
              ],
            ),
            if (serie.tramosConDatos < 2) ...[
              const SizedBox(height: Sp.sm),
              Text(
                l.satPocosTramos(FormatoSat.tramos(l, serie.agrupacion)),
                style: aviso,
              ),
            ] else if (hayDebiles) ...[
              const SizedBox(height: Sp.sm),
              Text(l.satPuntoDebil('${tope ?? 0}'), style: aviso),
            ],
          ],
        ],
      ),
    );
  }
}

class _Acceso extends StatelessWidget {
  const _Acceso({
    required this.titulo,
    required this.detalle,
    required this.insignia,
    required this.color,
    required this.ruta,
  });

  final String titulo;
  final String detalle;
  final Widget insignia;
  final Color color;
  final String ruta;

  @override
  Widget build(BuildContext context) => TarjetaSat(
    padding: const EdgeInsets.all(Sp.md),
    semantica: '$titulo. $detalle',
    onTap: () => context.push(ruta),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: insignia,
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: context.muted),
          ],
        ),
        const SizedBox(height: Sp.sm),
        Text(
          titulo,
          style: context.textos.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          detalle,
          style: context.textos.labelSmall?.copyWith(color: context.muted),
        ),
      ],
    ),
  );
}
