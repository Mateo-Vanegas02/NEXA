import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../../niveles/presentation/controllers/niveles_controller.dart';
import '../../domain/factores_calificacion.dart';
import '../../domain/servicio.dart';
import '../controllers/viaje_pasajero_controller.dart';
import '../widgets/calificacion_widgets.dart';
import '../widgets/piezas_viaje.dart';

/// Cierre del viaje en dos pasos (diseño P08 y P09): «¡Llegaste!» con lo que
/// se pagó y el XP ganado; después, la calificación opcional con estrellas,
/// factores («¿Qué estuvo bien?» / «¿Qué falló?») y comentario.
class CalificacionScreen extends ConsumerStatefulWidget {
  const CalificacionScreen({super.key});

  @override
  ConsumerState<CalificacionScreen> createState() => _CalificacionScreenState();
}

class _CalificacionScreenState extends ConsumerState<CalificacionScreen> {
  static const _maxComentario = 250;
  final _comentario = TextEditingController();
  final Set<String> _factores = {};
  double _estrellas = 5;
  bool _calificando = false;
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
    try {
      await ref
          .read(viajePasajeroProvider.notifier)
          .calificar(
            _estrellas,
            _comentario.text.trim(),
            factores: FactoresCalificacion.validos(_estrellas, _factores),
          );
      messenger.showSnackBar(SnackBar(content: Text(l.gracias)));
      router.go('/p/inicio');
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppException.from(e).mensaje)),
      );
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(viajePasajeroProvider).value;
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
                    child: _calificando
                        ? _calificacion(context, l, s)
                        : _Llegaste(
                            servicio: s,
                            onCalificar: () =>
                                setState(() => _calificando = true),
                            onAhoraNo: _salir,
                          ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _calificacion(BuildContext context, AppLocalizations l, Servicio s) {
    final nombre = (s.conductor?.nombre ?? l.tuConductor).split(' ').first;
    final n = _estrellas.round();
    final textoNota = switch (n) {
      1 => l.calif1,
      2 => l.calif2,
      3 => l.calif3,
      4 => l.calif4,
      _ => l.calif5,
    };
    final bien = FactoresCalificacion.satisfecho(_estrellas);
    final colorNota = bien ? NexaColors.cyan : NexaColors.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: BotonAhoraNo(onTap: _enviando ? null : _salir),
        ),
        const SizedBox(height: Sp.lg),
        Center(child: AvatarIniciales(nombre: s.conductor?.nombre ?? '?')),
        const SizedBox(height: Sp.lg),
        Text(
          l.comoTeFueCon(nombre),
          textAlign: TextAlign.center,
          style: NexaTexto.titulo,
        ),
        const SizedBox(height: Sp.xs),
        Text(
          l.calificarOpcional,
          textAlign: TextAlign.center,
          style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
        ),
        const SizedBox(height: Sp.lg),
        EstrellasGrandes(
          valor: n,
          onChanged: (v) => setState(() => _estrellas = v.toDouble()),
        ),
        const SizedBox(height: Sp.sm),
        Semantics(
          liveRegion: true,
          child: Text(
            textoNota,
            textAlign: TextAlign.center,
            style: NexaTexto.subtitulo.copyWith(color: colorNota),
          ),
        ),
        const SizedBox(height: Sp.lg),
        NexaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    bien ? l.queEstuvoBien : l.queFallo,
                    style: NexaTexto.subtitulo.copyWith(fontSize: 16),
                  ),
                  Text(
                    l.puedesMarcarVarios,
                    style: NexaTexto.pequeno.copyWith(color: NexaColors.tenue),
                  ),
                ],
              ),
              const SizedBox(height: Sp.md),
              Wrap(
                spacing: Sp.sm,
                runSpacing: Sp.sm,
                children: [
                  for (final f in FactoresCalificacion.paraNota(_estrellas))
                    ChipFactor(
                      texto: textoFactor(l, f.codigo),
                      elegido: _factores.contains(f.codigo),
                      positivo: f.positivo,
                      onTap: () => setState(
                        () => _factores.contains(f.codigo)
                            ? _factores.remove(f.codigo)
                            : _factores.add(f.codigo),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Sp.md),
        TextField(
          controller: _comentario,
          maxLength: _maxComentario,
          maxLines: 4,
          minLines: 2,
          decoration: InputDecoration(hintText: l.comentarioOpcional),
        ),
        const SizedBox(height: Sp.md),
        NexaButton(
          label: l.enviarCalificacion,
          cargando: _enviando,
          onPressed: _enviar,
        ),
      ],
    );
  }
}

/// «¡Llegaste!» (P08): lo que se pagó y el XP del viaje.
class _Llegaste extends ConsumerWidget {
  const _Llegaste({
    required this.servicio,
    required this.onCalificar,
    required this.onAhoraNo,
  });

  final Servicio servicio;
  final VoidCallback onCalificar;
  final VoidCallback onAhoraNo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = servicio;
    final fin = s.fechaFinalizacion ?? DateTime.now();
    final hora = DateFormat('H:mm', 'es_CO').format(fin);
    final km = NumberFormat('0.0', 'es_CO').format(s.distanciaKM);
    final desglose = ref.watch(desglosePasajeroProvider(s.id)).value;
    final nivel = ref.watch(nivelProvider).value;
    final nombre = (s.conductor?.nombre ?? l.tuConductor).split(' ').first;
    final total = desglose?.totalAPagar ?? (s.tarifa + s.extraVoluntario);
    final metodo = switch (s.metodoPago) {
      'tarjeta' => l.metodoTarjeta,
      'billetera' => l.metodoBilletera,
      _ => l.enEfectivo,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Sp.xl),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: NexaColors.ok,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: NexaColors.ok.withValues(alpha: 0.35),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, color: NexaColors.bg, size: 48),
          ),
        ),
        const SizedBox(height: Sp.lg),
        Text(l.llegaste, textAlign: TextAlign.center, style: NexaTexto.display),
        const SizedBox(height: Sp.xs),
        Text(
          '${s.destino} · $hora · $km km',
          textAlign: TextAlign.center,
          style: NexaTexto.cuerpo.copyWith(color: NexaColors.muted),
        ),
        const SizedBox(height: Sp.xl),
        NexaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (desglose != null) ...[
                _Fila(texto: l.tarifaBase, valor: Fmt.cop(desglose.tarifa)),
                if (desglose.descuentoNivel > 0)
                  _Fila(
                    texto: nivel == null
                        ? l.descuentoNivel
                        : l.descuentoNivelN(nivel.nivel),
                    valor: '−${Fmt.cop(desglose.descuentoNivel)}',
                    color: NexaColors.gold,
                  ),
                if (desglose.recargoEspera > 0)
                  _Fila(
                    texto: l.recargoEspera,
                    valor: '+${Fmt.cop(desglose.recargoEspera)}',
                  ),
                if (desglose.extraVoluntario > 0)
                  _Fila(
                    texto: l.extraPara(nombre),
                    valor: '+${Fmt.cop(desglose.extraVoluntario)}',
                  ),
                if (desglose.deudaAnterior > 0)
                  _Fila(
                    texto: l.deudaAnterior,
                    valor: '+${Fmt.cop(desglose.deudaAnterior)}',
                  ),
                const Divider(height: Sp.xl),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.totalPagado, style: NexaTexto.subtitulo),
                        Text(
                          metodo,
                          style: NexaTexto.pequeno.copyWith(
                            color: NexaColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(Fmt.cop(total), style: NexaTexto.numeroMedio),
                ],
              ),
            ],
          ),
        ),
        if (s.xpGanadoPasajero > 0) ...[
          const SizedBox(height: Sp.md),
          _XpGanado(xp: s.xpGanadoPasajero),
        ],
        const SizedBox(height: Sp.xxl),
        NexaButton(label: l.calificarA(nombre), onPressed: onCalificar),
        const SizedBox(height: Sp.sm),
        NexaButton(
          label: l.ahoraNo,
          variant: NexaButtonVariant.fantasma,
          onPressed: onAhoraNo,
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.texto, required this.valor, this.color});
  final String texto;
  final String valor;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Sp.xs + 2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            texto,
            style: NexaTexto.cuerpo.copyWith(color: NexaColors.muted),
          ),
        ),
        Text(
          valor,
          style: NexaTexto.cuerpo.copyWith(
            fontWeight: FontWeight.w700,
            color: color ?? NexaColors.texto,
          ),
        ),
      ],
    ),
  );
}

/// «Ganaste 7 XP» con la barra hacia el siguiente nivel (P08).
class _XpGanado extends ConsumerWidget {
  const _XpGanado({required this.xp});
  final int xp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final nivel = ref.watch(nivelProvider).value;
    return Container(
      padding: const EdgeInsets.all(Sp.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Rad.lg),
        border: Border.all(color: NexaColors.gold.withValues(alpha: 0.35)),
        gradient: const LinearGradient(
          colors: [Color(0xFF2B2410), NexaColors.card],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: NexaColors.goldSuave,
              borderRadius: BorderRadius.circular(Rad.md),
            ),
            alignment: Alignment.center,
            child: Text(
              '+$xp',
              style: NexaTexto.subtitulo.copyWith(color: NexaColors.gold),
            ),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.xpGanado(xp), style: NexaTexto.subtitulo.copyWith(fontSize: 16)),
                if (nivel != null) ...[
                  const SizedBox(height: Sp.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Rad.pill),
                    child: LinearProgressIndicator(
                      value: nivel.progreso,
                      minHeight: 6,
                      color: NexaColors.gold,
                      backgroundColor: NexaColors.line,
                    ),
                  ),
                  const SizedBox(height: Sp.xs),
                  Text(
                    l.nivelFaltan(nivel.nivel, nivel.xpFaltante, nivel.nivel + 1),
                    style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
