import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/mapa_nexa.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../../satisfaccion/presentation/widgets/satisfaccion_widgets.dart';
import '../../domain/admin.dart';
import '../controllers/admin_controller.dart';

/// Inicio del admin (rediseño 2026): la operación en vivo. Cifras del día,
/// la flota en el mapa y las alertas; todo del servidor, se refresca solo.
class OperacionScreen extends ConsumerWidget {
  const OperacionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final op = ref.watch(operacionProvider);
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          bottom: false,
          child: op.when(
            loading: () => const CargandoSkeleton(),
            error: (e, _) => EstadoError(
              mensaje: AppException.from(e).mensaje,
              onReintentar: () => ref.invalidate(operacionProvider),
            ),
            data: (o) => RefreshIndicator(
              onRefresh: () => ref.read(operacionProvider.notifier).refrescar(),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  context.gutter,
                  0,
                  context.gutter,
                  120 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  ContenidoCentrado(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EncabezadoSat(
                          etiqueta: l.adminOperacionEtiqueta,
                          titulo: l.adminOperacionTitulo,
                        ),
                        const SizedBox(height: Sp.md),
                        _Cifras(o: o),
                        const SizedBox(height: Sp.md),
                        _Flota(o: o),
                        const SizedBox(height: Sp.lg),
                        Text(
                          l.adminAlertas.toUpperCase(),
                          style: NexaTexto.etiqueta.copyWith(
                            color: NexaColors.tenue,
                          ),
                        ),
                        const SizedBox(height: Sp.sm),
                        if (o.alertas.isEmpty)
                          TarjetaSat(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: NexaColors.ok,
                                ),
                                const SizedBox(width: Sp.md),
                                Expanded(child: Text(l.adminSinAlertas)),
                              ],
                            ),
                          )
                        else
                          for (final a in o.alertas) ...[
                            _Alerta(alerta: a),
                            const SizedBox(height: Sp.sm),
                          ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cifras extends StatelessWidget {
  const _Cifras({required this.o});
  final OperacionAdmin o;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tarjetas = [
      _Cifra(
        icono: Icons.two_wheeler,
        color: NexaColors.cyan,
        valor: '${o.viajesHoy}',
        titulo: l.adminViajesHoy,
        detalle: l.adminFinalizadosCancelados(
          o.finalizadosHoy,
          o.canceladosHoy,
        ),
      ),
      _Cifra(
        icono: Icons.route,
        color: NexaColors.ok,
        valor: '${o.enCurso}',
        titulo: l.adminEnCurso,
        detalle: l.adminYendoAbiertas(o.yendoARecoger, o.solicitudesAbiertas),
      ),
      _Cifra(
        icono: Icons.wifi_tethering,
        color: NexaColors.cyan,
        valor: '${o.conductoresEnLinea}',
        titulo: l.adminEnLinea,
        detalle: l.adminLibres(o.conductoresDisponibles),
      ),
      _Cifra(
        icono: Icons.how_to_reg_outlined,
        color: o.conductoresPendientes > 0 ? NexaColors.gold : NexaColors.muted,
        valor: '${o.conductoresPendientes}',
        titulo: l.adminPorAprobar,
        detalle: l.adminVerConductores,
        onTap: () => context.go('/a/conductores'),
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final columnas = c.maxWidth > 560 ? 4 : 2;
        final ancho = (c.maxWidth - Sp.md * (columnas - 1)) / columnas;
        return Wrap(
          spacing: Sp.md,
          runSpacing: Sp.md,
          children: [
            for (final t in tarjetas) SizedBox(width: ancho, child: t),
          ],
        );
      },
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.icono,
    required this.color,
    required this.valor,
    required this.titulo,
    required this.detalle,
    this.onTap,
  });

  final IconData icono;
  final Color color;
  final String valor;
  final String titulo;
  final String detalle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => TarjetaSat(
    onTap: onTap,
    semantica: '$titulo: $valor. $detalle',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 18, color: color),
            const SizedBox(width: Sp.xs),
            Expanded(
              child: Text(
                titulo,
                style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: Sp.xs),
        Text(valor, style: NexaTexto.numero.copyWith(fontSize: 30)),
        Text(detalle, style: NexaTexto.pequeno.copyWith(color: color)),
      ],
    ),
  );
}

/// La flota en el mapa: cian = libre, gris = en un viaje.
class _Flota extends ConsumerWidget {
  const _Flota({required this.o});
  final OperacionAdmin o;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final puntos = [
      for (final p in o.flota) (LatLng(p.latitud, p.longitud), p.disponible),
    ];
    // Centro: el promedio de la flota o, sin motos, la ciudad por defecto.
    final centro = puntos.isEmpty
        ? kCentroPorDefecto
        : LatLng(
            puntos.map((p) => p.$1.latitude).reduce((a, b) => a + b) /
                puntos.length,
            puntos.map((p) => p.$1.longitude).reduce((a, b) => a + b) /
                puntos.length,
          );
    return TarjetaSat(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.lg, Sp.sm),
            child: Row(
              children: [
                Expanded(child: Text(l.adminFlota, style: NexaTexto.subtitulo)),
                _Leyenda(color: NexaColors.cyan, texto: l.adminLibre),
                const SizedBox(width: Sp.md),
                _Leyenda(color: NexaColors.muted, texto: l.adminEnViaje),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(Rad.lg),
            ),
            child: SizedBox(
              height: 240,
              child: ExcludeSemantics(
                child: MapaNexa(
                  centro: centro,
                  zoom: 12.5,
                  flota: puntos,
                  encuadre: puntos.length >= 2
                      ? [for (final p in puntos) p.$1]
                      : null,
                  margenInferior: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.color, required this.texto});
  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: Sp.xs),
      Text(texto, style: NexaTexto.pequeno.copyWith(color: NexaColors.muted)),
    ],
  );
}

class _Alerta extends StatelessWidget {
  const _Alerta({required this.alerta});
  final AlertaAdmin alerta;

  @override
  Widget build(BuildContext context) {
    final (icono, color) = switch (alerta.tipo) {
      TipoAlerta.solicitudSinConductor => (
        Icons.hourglass_bottom,
        NexaColors.error,
      ),
      TipoAlerta.conductoresPorAprobar => (
        Icons.how_to_reg_outlined,
        NexaColors.gold,
      ),
      TipoAlerta.documentoVencido => (
        Icons.event_busy_outlined,
        NexaColors.error,
      ),
      TipoAlerta.otra => (Icons.info_outline, NexaColors.cyan),
    };
    return TarjetaSat(
      onTap: alerta.tipo == TipoAlerta.conductoresPorAprobar
          ? () => context.go('/a/conductores')
          : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Rad.md),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: Sp.md),
          Expanded(child: Text(alerta.texto, style: NexaTexto.cuerpo)),
          if (alerta.tipo == TipoAlerta.conductoresPorAprobar)
            const Icon(Icons.chevron_right, color: NexaColors.muted),
        ],
      ),
    );
  }
}
