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

/// Sigue un entrenamiento (sondeo cada 5 s mientras la pantalla está abierta).
class EntrenandoScreen extends ConsumerStatefulWidget {
  const EntrenandoScreen({required this.id, super.key});

  final String id;

  @override
  ConsumerState<EntrenandoScreen> createState() => _EntrenandoScreenState();
}

class _EntrenandoScreenState extends ConsumerState<EntrenandoScreen> {
  bool _cancelando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(entrenamientoProvider.notifier).seguir(widget.id);
    });
  }

  Future<void> _cancelar() async {
    setState(() => _cancelando = true);
    try {
      await ref.read(entrenamientoProvider.notifier).cancelar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).mensaje)));
      }
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final estado = ref.watch(entrenamientoProvider);
    final e = estado.value;
    final terminado = e?.estado.esFinal ?? false;
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
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
                      titulo: terminado
                          ? l.satEntrenamientoTitulo
                          : l.satEntrenandoTitulo,
                      atras: true,
                    ),
                    const SizedBox(height: Sp.md),
                    if (e == null && estado.hasError)
                      EstadoError(
                        mensaje: AppException.from(estado.error!).mensaje,
                        onReintentar: () =>
                            ref.read(entrenamientoProvider.notifier).sondear(),
                      )
                    else if (e == null)
                      const CargandoSkeleton()
                    else ...[
                      _Avance(e: e),
                      const SizedBox(height: Sp.md),
                      _Pasos(e: e),
                      const SizedBox(height: Sp.md),
                      if (!terminado) ...[
                        AvisoSat(
                          texto: l.satPuedesSalir,
                          icono: Icons.info_outline,
                        ),
                        const SizedBox(height: Sp.md),
                        NexaButton(
                          label: l.satCancelarEntrenamiento,
                          variant: NexaButtonVariant.secundario,
                          cargando: _cancelando,
                          onPressed: _cancelar,
                        ),
                      ] else
                        NexaButton(
                          label: l.satVolverPanel,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avance extends StatelessWidget {
  const _Avance({required this.e});
  final Entrenamiento e;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.textos;
    final (titulo, detalle, color) = switch (e.estado) {
      EstadoEntrenamiento.publicado => (
        l.satFinPublicado,
        null,
        colorOk(context),
      ),
      EstadoEntrenamiento.guardadoSinPublicar => (
        l.satFinSinPublicar,
        l.satFinSinPublicarDetalle,
        colorAviso(context),
      ),
      EstadoEntrenamiento.sinDatosNuevos => (
        l.satFinSinDatosNuevos,
        null,
        colorAviso(context),
      ),
      EstadoEntrenamiento.cancelado => (l.satFinCancelado, null, context.muted),
      EstadoEntrenamiento.fallido || EstadoEntrenamiento.faltanDatos => (
        l.satFinFallido,
        e.mensaje,
        colorMalo(context),
      ),
      EstadoEntrenamiento.enCola => (l.satEnCola, null, context.acento),
      _ => (
        l.satEntrenandoRed,
        e.epoca != null && e.epocas != null
            ? l.satEpoca('${e.epoca}', '${e.epocas}')
            : null,
        context.acento,
      ),
    };
    final fin = e.estado.esFinal;
    return TarjetaSat(
      semantica: '$titulo. ${e.progresoPct} %',
      padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: 22),
      child: Column(
        children: [
          AnilloAvance(
            fraccion: fin && e.estado != EstadoEntrenamiento.publicado
                ? 0
                : e.progresoPct / 100,
            child: fin
                ? Icon(
                    e.estado == EstadoEntrenamiento.publicado
                        ? Icons.check_rounded
                        : Icons.close_rounded,
                    size: 48,
                    color: color,
                  )
                : Text(
                    '${e.progresoPct} %',
                    style: t.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(height: Sp.md),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (detalle != null) ...[
            const SizedBox(height: Sp.xs),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(color: context.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pasos extends StatelessWidget {
  const _Pasos({required this.e});
  final Entrenamiento e;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textos = {
      PasoEntrenamiento.exportar: (l.satPasoExportar, e.detalleExportar),
      PasoEntrenamiento.entrenar: (l.satPasoEntrenar, l.satPasoEntrenarDetalle),
      PasoEntrenamiento.comparar: (l.satPasoComparar, null),
      PasoEntrenamiento.publicar: (l.satPasoPublicar, null),
    };
    return TarjetaSat(
      child: Column(
        children: [
          for (final paso in PasoEntrenamiento.values) ...[
            if (paso.index > 0) const SizedBox(height: Sp.md),
            _Paso(
              numero: paso.index + 1,
              titulo: textos[paso]!.$1,
              detalle: textos[paso]!.$2,
              estado: e.pasos[paso] ?? EstadoPaso.pendiente,
            ),
          ],
        ],
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({
    required this.numero,
    required this.titulo,
    required this.estado,
    this.detalle,
  });

  final int numero;
  final String titulo;
  final String? detalle;
  final EstadoPaso estado;

  @override
  Widget build(BuildContext context) {
    final t = context.textos;
    final pendiente = estado == EstadoPaso.pendiente;
    final circulo = switch (estado) {
      EstadoPaso.hecho => (
        colorOk(context).withValues(alpha: 0.18),
        Icon(Icons.check_rounded, size: 16, color: colorOk(context)),
      ),
      EstadoPaso.enCurso => (
        context.acento,
        Text(
          '$numero',
          style: t.labelMedium?.copyWith(
            color: context.colors.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      EstadoPaso.pendiente => (
        Theme.of(context).brightness == Brightness.dark
            ? NexaColors.raised
            : context.acento.withValues(alpha: 0.12),
        Text(
          '$numero',
          style: t.labelMedium?.copyWith(
            color: context.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    };
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: circulo.$1, shape: BoxShape.circle),
          child: circulo.$2,
        ),
        const SizedBox(width: Sp.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: t.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: pendiente ? context.muted : null,
                ),
              ),
              if (detalle != null && !pendiente)
                Text(
                  detalle!,
                  style: t.labelSmall?.copyWith(color: context.muted),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
