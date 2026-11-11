import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/estimado_tarifa.dart';
import '../../domain/servicio.dart';
import '../controllers/viaje_pasajero_controller.dart';
import '../widgets/desglose_card.dart';
import '../widgets/estrellas.dart';

/// Cierre del viaje: resumen, calificación con estrellas, etiquetas, comentario
/// y el XP ganado.
class CalificacionScreen extends ConsumerStatefulWidget {
  const CalificacionScreen({super.key});

  @override
  ConsumerState<CalificacionScreen> createState() => _CalificacionScreenState();
}

class _CalificacionScreenState extends ConsumerState<CalificacionScreen> {
  static const _maxComentario = 250;
  final _comentario = TextEditingController();
  final Set<String> _etiquetas = {};
  double _estrellas = 4;
  bool _enviando = false;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  void _salir() {
    ref.read(viajePasajeroProvider.notifier).cerrar();
    context.go('/p/inicio');
  }

  Future<void> _enviar() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _enviando = true);
    // El backend solo recibe `comentarios`: las etiquetas se anteponen.
    final texto = [
      if (_etiquetas.isNotEmpty) '[${_etiquetas.join(', ')}]',
      _comentario.text.trim(),
    ].where((e) => e.isNotEmpty).join(' ');
    try {
      await ref
          .read(viajePasajeroProvider.notifier)
          .calificar(_estrellas, texto);
      messenger.showSnackBar(SnackBar(content: Text(l.gracias)));
      router.go('/p/inicio');
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppException.from(e).mensaje)),
      );
      if (mounted) setState(() => _enviando = false);
    }
  }

  String _textoCalificacion(AppLocalizations l) {
    final n = _estrellas.round();
    final texto = switch (n) {
      1 => l.calif1,
      2 => l.calif2,
      3 => l.calif3,
      4 => l.calif4,
      _ => l.calif5,
    };
    return l.califDe5(texto, n);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(viajePasajeroProvider).value;
    final etiquetas = {
      'segura': l.etiquetaSegura,
      'puntual': l.etiquetaPuntual,
      'amable': l.etiquetaAmable,
      'moto': l.etiquetaMoto,
      'casco': l.etiquetaCasco,
    };
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          child: s == null
              ? EstadoVacio(titulo: l.vacioHistorial, icon: Icons.two_wheeler)
              : SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.all(context.gutter),
                  child: ContenidoCentrado(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: l.cerrar,
                            onPressed: _enviando ? null : _salir,
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              minimumSize: const Size.square(Sizes.touch),
                              side: BorderSide(
                                color: context.colors.outline.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        _Resumen(servicio: s),
                        const SizedBox(height: Sp.lg),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: NexaColors.card,
                            borderRadius: BorderRadius.circular(Rad.lg + 4),
                            border: Border.all(
                              color: NexaColors.cyan.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(Sp.lg),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: NexaColors.cyan,
                                      foregroundColor: NexaColors.bg,
                                      child: Text(
                                        _iniciales(s.conductor?.nombre),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: Sp.md),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l.calificaExperiencia,
                                            style: context.textos.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          Text(
                                            l.comoCalificarias(
                                              s.conductor?.nombre ??
                                                  l.tuConductor,
                                            ),
                                            style: context.textos.bodySmall
                                                ?.copyWith(
                                                  color: context.muted,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: Sp.md),
                                Estrellas(
                                  valor: _estrellas,
                                  onChanged: (v) =>
                                      setState(() => _estrellas = v),
                                ),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _textoCalificacion(l),
                                    style: context.textos.titleSmall?.copyWith(
                                      color: context.acento,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: Sp.md),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: Sp.sm,
                                  runSpacing: Sp.sm,
                                  children: [
                                    for (final e in etiquetas.entries)
                                      FilterChip(
                                        label: Text(e.value),
                                        selected: _etiquetas.contains(e.value),
                                        onSelected: (v) => setState(
                                          () => v
                                              ? _etiquetas.add(e.value)
                                              : _etiquetas.remove(e.value),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (s.xpGanadoPasajero > 0) ...[
                          const SizedBox(height: Sp.md),
                          _XpGanado(xp: s.xpGanadoPasajero),
                        ],
                        const SizedBox(height: Sp.md),
                        TextField(
                          controller: _comentario,
                          maxLength: _maxComentario,
                          maxLines: 4,
                          minLines: 3,
                          decoration: InputDecoration(
                            hintText: l.comentarioHint,
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: Sp.md),
                        NexaButton(
                          label: l.enviarCalificacion,
                          cargando: _enviando,
                          onPressed: _enviar,
                        ),
                        const SizedBox(height: Sp.sm),
                        TextButton(
                          onPressed: _enviando ? null : _salir,
                          style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(Sizes.touch),
                          ),
                          child: Text(l.omitirPorAhora),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  static String _iniciales(String? nombre) {
    final p = (nombre ?? '').trim().split(RegExp(r'\s+'));
    if (p.isEmpty || p.first.isEmpty) return '?';
    return (p.first[0] + (p.length > 1 ? p[1][0] : '')).toUpperCase();
  }
}

/// Recompensa del viaje: los XP que ganó el pasajero.
class _XpGanado extends StatelessWidget {
  const _XpGanado({required this.xp});
  final int xp;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NexaColors.card,
        borderRadius: BorderRadius.circular(Rad.lg),
        border: Border.all(color: NexaColors.cyan.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: NexaColors.cyan.withValues(alpha: 0.18),
            blurRadius: 24,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: NexaColors.cyan,
                shape: BoxShape.circle,
                boxShadow: NexaShadows.glow,
              ),
              alignment: Alignment.center,
              child: Text(
                '+$xp',
                style: const TextStyle(
                  color: NexaColors.bg,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Text(
                l.xpGanado(xp),
                style: context.textos.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Resumen extends ConsumerWidget {
  const _Resumen({required this.servicio});
  final Servicio servicio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.textos;
    final inicio = servicio.fechaInicio;
    final fin = servicio.fechaFinalizacion ?? DateTime.now();
    final minutos = inicio != null
        ? fin.difference(inicio).inMinutes.clamp(1, 999)
        : minutosEstimados(servicio.distanciaKM);
    final hora = DateFormat('h:mm a', 'es_CO').format(fin);
    final desglose = ref.watch(desglosePasajeroProvider(servicio.id));
    // Lo que realmente se cobra: el viaje más el cargo anterior, si se cobró con él.
    final total = desglose.value?.totalAPagar ?? servicio.tarifa;
    final metodo = switch (servicio.metodoPago) {
      'tarjeta' => l.metodoTarjeta,
      'billetera' => l.metodoBilletera,
      _ => l.efectivo,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: NexaColors.cyan,
              shape: BoxShape.circle,
              boxShadow: NexaShadows.glow,
            ),
            child: const Icon(Icons.check, color: NexaColors.bg, size: 32),
          ),
        ),
        const SizedBox(height: Sp.md),
        Text(
          l.llegasteDestino,
          textAlign: TextAlign.center,
          style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: Sp.xs),
        Text(
          '${servicio.destino} · $hora',
          textAlign: TextAlign.center,
          style: t.bodySmall?.copyWith(color: context.muted),
        ),
        const SizedBox(height: Sp.xs),
        Text(
          '${l.duracionMin(minutos)} · ${Fmt.cop(total)} · $metodo',
          textAlign: TextAlign.center,
          style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (desglose.value != null)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                l.verDesglose,
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: context.acento),
              ),
              children: [
                DesgloseCard(
                  titulo: l.total,
                  filas: [
                    (l.tarifaBase, desglose.value!.tarifa),
                    if (desglose.value!.descuentoNivel > 0)
                      (l.descuentoNivel, -desglose.value!.descuentoNivel),
                    if (desglose.value!.recargoEspera > 0)
                      (l.recargoEspera, desglose.value!.recargoEspera),
                    if (desglose.value!.extraVoluntario > 0)
                      (l.extraVoluntario, desglose.value!.extraVoluntario),
                    if (desglose.value!.deudaAnterior > 0)
                      (l.deudaAnterior, desglose.value!.deudaAnterior),
                  ],
                  total: desglose.value!.totalAPagar,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
