import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/opcion_ruta.dart';
import '../controllers/viaje_conductor_controller.dart';

/// Lo que ve el conductor al salirse de la ruta (rediseño 2026): primero
/// «Buscando rutas…», luego hasta tres rutas desde donde va (la sugerida
/// primero, con su tiempo y distancia) o el aviso de que no hay rutas nuevas.
/// Si no elige, a los [TarjetaDesvio.segundosParaElegir] s sigue la sugerida.
class TarjetaDesvio extends ConsumerWidget {
  const TarjetaDesvio({required this.estado, super.key});

  final ConductorState estado;

  static const segundosParaElegir = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(conductorProvider.notifier);
    return switch (estado.desvio) {
      EstadoDesvio.ninguno => const SizedBox.shrink(),
      EstadoDesvio.buscando => const _Buscando(),
      EstadoDesvio.sinOpciones => _SinOpciones(onCerrar: ctrl.descartarRutas),
      EstadoDesvio.opciones => _Opciones(
        // Una lista nueva reinicia la cuenta.
        key: ValueKey(estado.rutasOfrecidas.map((o) => o.geometria).join()),
        opciones: estado.rutasOfrecidas,
        onElegir: ctrl.elegirRuta,
        onCerrar: ctrl.descartarRutas,
      ),
    };
  }
}

BoxDecoration _caja(Color borde) => BoxDecoration(
  color: NexaColors.glass,
  borderRadius: BorderRadius.circular(Rad.lg),
  border: Border.all(color: borde),
  boxShadow: NexaShadows.flotante,
);

class _Buscando extends StatelessWidget {
  const _Buscando();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      label: '${l.rutaFueraTitulo}. ${l.rutaBuscando}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(Sp.md),
          decoration: _caja(NexaColors.gold.withValues(alpha: 0.6)),
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: NexaColors.gold,
                ),
              ),
              const SizedBox(width: Sp.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.rutaFueraTitulo, style: NexaTexto.subtitulo),
                    Text(
                      l.rutaBuscando,
                      style: NexaTexto.pequeno.copyWith(
                        color: NexaColors.muted,
                      ),
                    ),
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

/// No hay rutas nuevas (o el servidor aún no las calcula): se avisa y se
/// cierra solo a los 8 s.
class _SinOpciones extends StatefulWidget {
  const _SinOpciones({required this.onCerrar});
  final VoidCallback onCerrar;

  @override
  State<_SinOpciones> createState() => _SinOpcionesState();
}

class _SinOpcionesState extends State<_SinOpciones> {
  Timer? _cierre;

  @override
  void initState() {
    super.initState();
    _cierre = Timer(const Duration(seconds: 8), widget.onCerrar);
  }

  @override
  void dispose() {
    _cierre?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(Sp.md, Sp.md, Sp.xs, Sp.md),
        decoration: _caja(NexaColors.gold.withValues(alpha: 0.6)),
        child: Row(
          children: [
            const Icon(Icons.alt_route, color: NexaColors.gold),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.rutaFueraTitulo, style: NexaTexto.subtitulo),
                  Text(
                    l.rutaSinOpciones,
                    style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l.cerrar,
              onPressed: widget.onCerrar,
              icon: const Icon(Icons.close, color: NexaColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Opciones extends StatefulWidget {
  const _Opciones({
    required this.opciones,
    required this.onElegir,
    required this.onCerrar,
    super.key,
  });

  final List<OpcionRuta> opciones;
  final Future<void> Function(int indice) onElegir;
  final VoidCallback onCerrar;

  @override
  State<_Opciones> createState() => _OpcionesState();
}

class _OpcionesState extends State<_Opciones> {
  int _quedan = TarjetaDesvio.segundosParaElegir;
  Timer? _cuenta;

  @override
  void initState() {
    super.initState();
    _cuenta = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_quedan <= 1) {
        t.cancel();
        unawaited(widget.onElegir(widget.opciones.first.indice));
        return;
      }
      setState(() => _quedan--);
    });
  }

  @override
  void dispose() {
    _cuenta?.cancel();
    super.dispose();
  }

  void _elegir(int indice) {
    _cuenta?.cancel();
    unawaited(widget.onElegir(indice));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final km = NumberFormat('0.0', 'es_CO');
    return Container(
      padding: const EdgeInsets.all(Sp.md),
      decoration: _caja(NexaColors.cyan.withValues(alpha: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.alt_route, color: NexaColors.cyan),
              const SizedBox(width: Sp.sm),
              Expanded(child: Text(l.rutasTitulo, style: NexaTexto.subtitulo)),
              IconButton(
                tooltip: l.cerrar,
                onPressed: () {
                  _cuenta?.cancel();
                  widget.onCerrar();
                },
                icon: const Icon(Icons.close, color: NexaColors.muted),
              ),
            ],
          ),
          const SizedBox(height: Sp.xs),
          for (final (i, o) in widget.opciones.indexed) ...[
            if (i > 0) const SizedBox(height: Sp.sm),
            _FilaRuta(
              opcion: o,
              sugerida: i == 0,
              detalle: l.rutaDetalle(
                o.duracionMin.round(),
                km.format(o.distanciaKm),
              ),
              etiqueta: switch (o.etiqueta) {
                EtiquetaRuta.rapida => l.rutaRapida,
                EtiquetaRuta.corta => l.rutaCorta,
                EtiquetaRuta.alternativa => l.rutaAlternativa,
              },
              onTap: () => _elegir(o.indice),
            ),
          ],
          const SizedBox(height: Sp.md),
          Semantics(
            button: true,
            child: FilledButton(
              onPressed: () => _elegir(widget.opciones.first.indice),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(Sizes.touch),
                backgroundColor: NexaColors.cyan,
                foregroundColor: NexaColors.bg,
              ),
              child: Text(
                l.rutaSeguirSugerida(_quedan),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaRuta extends StatelessWidget {
  const _FilaRuta({
    required this.opcion,
    required this.sugerida,
    required this.detalle,
    required this.etiqueta,
    required this.onTap,
  });

  final OpcionRuta opcion;
  final bool sugerida;
  final String detalle;
  final String etiqueta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: '$etiqueta. $detalle${sugerida ? '. ${l.rutaSugerida}' : ''}',
      child: ExcludeSemantics(
        child: Material(
          color: sugerida ? NexaColors.cyanSuave : NexaColors.raised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Rad.md),
            side: BorderSide(
              color: sugerida ? NexaColors.cyan : NexaColors.line,
              width: sugerida ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(Rad.md),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Sizes.touch),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.md,
                  vertical: Sp.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 30,
                      decoration: BoxDecoration(
                        color: sugerida
                            ? NexaColors.cyan
                            : NexaColors.rutaAlterna,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(detalle, style: NexaTexto.subtitulo),
                          Text(
                            etiqueta,
                            style: NexaTexto.pequeno.copyWith(
                              color: NexaColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (sugerida)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Sp.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: NexaColors.okSuave,
                          borderRadius: BorderRadius.circular(Rad.pill),
                        ),
                        child: Text(
                          l.rutaSugerida,
                          style: NexaTexto.pequeno.copyWith(
                            color: NexaColors.ok,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
