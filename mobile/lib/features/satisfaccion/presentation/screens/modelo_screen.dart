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
import '../widgets/satisfaccion_widgets.dart';
import 'formato_sat.dart';
import 'programar_sheet.dart';

/// Estado de la red neuronal: métricas, entrenar ahora, programación e historial.
/// Si nunca se ha publicado un modelo y faltan datos, muestra el avance de los datos.
class ModeloScreen extends ConsumerWidget {
  const ModeloScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final modelo = ref.watch(modeloProvider);
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.read(modeloProvider.notifier).refrescar(),
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
                        etiqueta: l.satModeloEyebrow,
                        titulo: l.satModelo,
                        atras: true,
                      ),
                      const SizedBox(height: Sp.md),
                      modelo.when(
                        skipLoadingOnRefresh: true,
                        loading: () => const CargandoSkeleton(),
                        error: (e, _) => EstadoError(
                          mensaje: AppException.from(e).mensaje,
                          onReintentar: () => ref.invalidate(modeloProvider),
                        ),
                        data: (m) => m.version == null && !m.datos.suficientes
                            ? _SinDatos(m: m)
                            : _Contenido(m: m),
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

/// Lanza un entrenamiento y abre la pantalla que lo sigue.
Future<void> _entrenar(BuildContext context, WidgetRef ref) async {
  try {
    final id = await ref.read(modeloProvider.notifier).entrenar();
    if (!context.mounted) return;
    unawaited(context.push('/a/satisfaccion/entrenamiento/$id'));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(AppException.from(e).mensaje)));
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.m});
  final ModeloInfo m;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final activo = m.entrenamientoActivo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Metricas(m: m),
        const SizedBox(height: Sp.md),
        if (activo != null && !activo.estado.esFinal)
          TarjetaSat(
            onTap: () =>
                context.push('/a/satisfaccion/entrenamiento/${activo.id}'),
            semantica: l.satEntrenamientoEnCurso,
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: context.acento,
                  ),
                ),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: Text(
                    l.satEntrenamientoEnCurso,
                    style: context.textos.titleSmall,
                  ),
                ),
                Text(
                  l.satVer,
                  style: context.textos.labelLarge?.copyWith(
                    color: context.acento,
                  ),
                ),
              ],
            ),
          )
        else ...[
          NexaButton(
            label: l.satEntrenarAhora,
            icon: Icons.play_arrow_rounded,
            onPressed: m.datos.suficientes ? () => _entrenar(context, ref) : null,
          ),
          if (!m.datos.suficientes) ...[
            const SizedBox(height: Sp.sm),
            Text(
              l.satEntrenarFaltanDatos,
              textAlign: TextAlign.center,
              style: context.textos.labelSmall?.copyWith(color: context.muted),
            ),
          ],
        ],
        const SizedBox(height: Sp.md),
        _Programado(p: m.programacion),
        if (m.historial.isNotEmpty) ...[
          const SizedBox(height: Sp.md),
          _Historial(registros: m.historial),
        ],
      ],
    );
  }
}

class _Metricas extends StatelessWidget {
  const _Metricas({required this.m});
  final ModeloInfo m;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.textos;
    final cabecera = t.labelSmall?.copyWith(
      color: context.muted,
      fontWeight: FontWeight.w600,
    );
    final celda = t.bodySmall;
    TableRow fila(String lado, MetricaLado x) => TableRow(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: bordeSuave(context))),
      ),
      children: [
        _Celda(Text(lado, style: celda)),
        _Celda(Text(FormatoSat.metrica(x.redPrAuc), style: celda), fin: true),
        _Celda(
          Text(FormatoSat.metrica(x.regresionPrAuc), style: celda),
          fin: true,
        ),
        _Celda(
          Text(
            x.supera ? l.satSupera : l.satNoSupera,
            style: celda?.copyWith(
              fontWeight: FontWeight.w600,
              color: x.supera ? colorOk(context) : colorAviso(context),
            ),
          ),
          fin: true,
        ),
      ],
    );
    final fecha = m.entrenadoEn == null
        ? ''
        : FormatoSat.fechaHora(m.entrenadoEn!.toLocal());
    return TarjetaSat(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.satVersionTitulo('${m.version ?? 0}'),
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.xs),
          Text(
            l.satEntrenadoInfo(fecha, '${m.viajes}', '${m.variables}'),
            style: t.bodySmall?.copyWith(color: context.muted),
          ),
          const SizedBox(height: Sp.sm),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.3),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.3),
            },
            children: [
              TableRow(
                children: [
                  const SizedBox.shrink(),
                  _Celda(Text(l.satRed, style: cabecera), fin: true),
                  _Celda(Text(l.satRegresion, style: cabecera), fin: true),
                  _Celda(Text(l.satResultado, style: cabecera), fin: true),
                ],
              ),
              fila(l.satPasajero, m.pasajero),
              fila(l.satConductor, m.conductor),
            ],
          ),
          const SizedBox(height: Sp.sm),
          Text(
            l.satMetricaNota,
            style: t.labelSmall?.copyWith(color: context.muted),
          ),
        ],
      ),
    );
  }
}

class _Celda extends StatelessWidget {
  const _Celda(this.child, {this.fin = false});
  final Widget child;
  final bool fin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Sp.sm),
    child: Align(
      alignment: fin ? Alignment.centerRight : Alignment.centerLeft,
      child: child,
    ),
  );
}

class _Programado extends ConsumerWidget {
  const _Programado({required this.p});
  final Programacion p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.textos;
    final proxima = p.proxima == null
        ? null
        : FormatoSat.fechaHoraCorta(p.proxima!.toLocal());
    return TarjetaSat(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 20, color: context.acento),
              const SizedBox(width: Sp.sm),
              Expanded(
                child: Text(
                  l.satProgramado,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Switch(
                value: p.activa,
                onChanged: (v) => _guardar(context, ref, p.copyWith(activa: v)),
              ),
            ],
          ),
          const SizedBox(height: Sp.sm),
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Rad.md),
              side: BorderSide(color: bordeSuave(context)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(Rad.md),
              onTap: () => mostrarProgramar(context, p),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.md,
                  vertical: Sp.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        FormatoSat.programacion(l, p),
                        style: t.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: p.activa ? null : context.muted,
                        ),
                      ),
                    ),
                    Text(
                      l.satCambiar,
                      style: t.labelLarge?.copyWith(color: context.acento),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Sp.sm),
          Text(
            !p.activa || proxima == null
                ? l.satSinProgramar
                : p.soloConDatosNuevos
                ? l.satProximaDatosNuevos(proxima, '${p.minimoViajesNuevos}')
                : l.satProxima(proxima),
            style: t.bodySmall?.copyWith(color: context.muted),
          ),
        ],
      ),
    );
  }
}

Future<void> _guardar(
  BuildContext context,
  WidgetRef ref,
  Programacion p,
) async {
  try {
    await ref.read(modeloProvider.notifier).guardarProgramacion(p);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(AppException.from(e).mensaje)));
  }
}

/// Texto y color de cada estado del historial.
(String, Color) estadoEntrenamiento(
  BuildContext context,
  RegistroEntrenamiento r,
) {
  final l = AppLocalizations.of(context);
  return switch (r.estado) {
    EstadoEntrenamiento.publicado => (
      l.satEstPublicado,
      colorOk(context),
    ),
    EstadoEntrenamiento.guardadoSinPublicar => (
      l.satEstSinPublicar,
      colorAviso(context),
    ),
    EstadoEntrenamiento.sinDatosNuevos => (
      l.satEstSinDatosNuevos,
      context.acento,
    ),
    EstadoEntrenamiento.faltanDatos => (
      l.satEstFaltanDatos,
      colorMalo(context),
    ),
    EstadoEntrenamiento.fallido => (l.satEstFallido, colorMalo(context)),
    EstadoEntrenamiento.cancelado => (l.satEstCancelado, context.muted),
    _ => (l.satEstEnCurso, context.acento),
  };
}

class _Historial extends StatelessWidget {
  const _Historial({required this.registros});
  final List<RegistroEntrenamiento> registros;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.textos;
    return TarjetaSat(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.satHistorial,
            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          for (final (i, r) in registros.indexed) ...[
            if (i > 0) Divider(height: Sp.lg, color: bordeSuave(context)),
            if (i == 0) const SizedBox(height: Sp.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.fecha == null
                            ? '–'
                            : FormatoSat.fechaHoraCorta(r.fecha!.toLocal()),
                        style: t.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        [
                          r.programado ? l.satProgramadoCorto : l.satManual,
                          if (r.version != null) 'v${r.version}',
                        ].join(' · '),
                        style: t.labelSmall?.copyWith(color: context.muted),
                      ),
                    ],
                  ),
                ),
                Builder(
                  builder: (context) {
                    final (texto, color) = estadoEntrenamiento(context, r);
                    return EtiquetaSat(texto: texto, color: color);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Primera vez, sin modelo publicado y sin datos suficientes (diseño "Datos insuficientes").
class _SinDatos extends StatelessWidget {
  const _SinDatos({required this.m});
  final ModeloInfo m;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.textos;
    final d = m.datos;
    String conteo(int a, int b) => l.satConteoDe('$a', '$b');
    double fr(int a, int b) => b <= 0 ? 0 : a / b;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TarjetaSat(
          padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.xl, Sp.xl, Sp.xl),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorAviso(context).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.show_chart,
                  size: 30,
                  color: colorAviso(context),
                ),
              ),
              const SizedBox(height: Sp.md),
              Text(
                l.satSinDatosTitulo,
                textAlign: TextAlign.center,
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: Sp.sm),
              Text(
                l.satMinimoDatos('${d.minimoCalificaciones}', '${d.minimoNo}'),
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: context.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: Sp.md),
        TarjetaSat(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.satProgresoDatos,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: Sp.md),
              FilaBarra(
                etiqueta: l.satCalifPasajeros,
                valor: conteo(
                  d.pasajero.calificaciones,
                  d.minimoCalificaciones,
                ),
                fraccion: fr(d.pasajero.calificaciones, d.minimoCalificaciones),
              ),
              const SizedBox(height: Sp.md),
              FilaBarra(
                etiqueta: l.satNoPasajeros,
                valor: conteo(d.pasajero.no, d.minimoNo),
                fraccion: fr(d.pasajero.no, d.minimoNo),
              ),
              const SizedBox(height: Sp.md),
              FilaBarra(
                etiqueta: l.satCalifConductores,
                valor: conteo(
                  d.conductor.calificaciones,
                  d.minimoCalificaciones,
                ),
                fraccion: fr(
                  d.conductor.calificaciones,
                  d.minimoCalificaciones,
                ),
                color: colorOk(context),
              ),
              const SizedBox(height: Sp.md),
              FilaBarra(
                etiqueta: l.satNoConductores,
                valor: conteo(d.conductor.no, d.minimoNo),
                fraccion: fr(d.conductor.no, d.minimoNo),
                color: colorOk(context),
              ),
            ],
          ),
        ),
        if (d.conductor.calificaciones < d.pasajero.calificaciones) ...[
          const SizedBox(height: Sp.md),
          AvisoSat(texto: l.satConsejoConductores),
        ],
        const SizedBox(height: Sp.md),
        NexaButton(
          label: l.satEntrenarNoDisponible,
          variant: NexaButtonVariant.secundario,
          onPressed: null,
        ),
        const SizedBox(height: Sp.md),
        _Programado(p: m.programacion),
      ],
    );
  }
}
