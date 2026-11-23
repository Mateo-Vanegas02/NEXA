import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/nexa_texto.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/mapa_nexa.dart';
import '../../../core/widgets/nexa_widgets.dart';
import 'flujo_permisos.dart';

/// Muestra [child] (el mapa) solo cuando se conoce la ubicación real del
/// teléfono. Mientras tanto no se dibuja el centro por defecto de la ciudad:
/// «Ubicándote…» y, si no llega, cómo activarla (se reintenta sola cada 5 s
/// y al volver a la app). Con [omitir] (p. ej. hay un viaje con su propia
/// posición) muestra el mapa siempre.
class ConUbicacion extends ConsumerStatefulWidget {
  const ConUbicacion({required this.child, this.omitir = false, super.key});

  final Widget child;
  final bool omitir;

  /// La ubicación sirve para el mapa: no es el centro por defecto.
  static bool esReal(LatLng? p) => p != null && p != kCentroPorDefecto;

  @override
  ConsumerState<ConUbicacion> createState() => _ConUbicacionState();
}

class _ConUbicacionState extends ConsumerState<ConUbicacion> {
  Timer? _reintento;
  late final AppLifecycleListener _ciclo = AppLifecycleListener(
    onResume: () {
      if (!_conocida) ref.invalidate(ubicacionProvider);
    },
  );

  bool get _conocida => ConUbicacion.esReal(ref.read(ubicacionProvider).value);

  @override
  void initState() {
    super.initState();
    _ciclo; // escucha el regreso a la app desde los ajustes del GPS
  }

  @override
  void dispose() {
    _reintento?.cancel();
    _ciclo.dispose();
    super.dispose();
  }

  void _programarReintento(bool hace) {
    if (!hace) {
      _reintento?.cancel();
      _reintento = null;
      return;
    }
    _reintento ??= Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) ref.invalidate(ubicacionProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ub = ref.watch(ubicacionProvider);
    final real = ConUbicacion.esReal(ub.value);
    final buscando = !real && ub.isLoading;
    _programarReintento(!widget.omitir && !real && !buscando);
    if (widget.omitir || real) return widget.child;
    return _Ubicandote(
      buscando: buscando,
      onActivar: () async {
        if (await asegurarUbicacion(context, ref) && mounted) {
          ref.invalidate(ubicacionProvider);
        }
      },
    );
  }
}

class _Ubicandote extends StatefulWidget {
  const _Ubicandote({required this.buscando, required this.onActivar});
  final bool buscando;
  final VoidCallback onActivar;

  @override
  State<_Ubicandote> createState() => _UbicandoteState();
}

class _UbicandoteState extends State<_Ubicandote>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ondas = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final quieto = MediaQuery.disableAnimationsOf(context);
    if (quieto) {
      _ondas
        ..stop()
        ..value = 0.6;
    } else if (!_ondas.isAnimating) {
      unawaited(_ondas.repeat());
    }
  }

  @override
  void dispose() {
    _ondas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = widget.buscando ? NexaColors.cyan : NexaColors.gold;
    return ColoredBox(
      color: NexaColors.bg,
      child: Align(
        // En la mitad de arriba: la hoja inferior tapa el resto.
        alignment: const Alignment(0, -0.45),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.xl),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 120,
                  child: CustomPaint(
                    painter: _Ondas(_ondas, color),
                    child: Center(
                      child: Icon(
                        widget.buscando
                            ? Icons.my_location
                            : Icons.location_disabled,
                        color: color,
                        size: 34,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Sp.md),
                Text(
                  widget.buscando ? l.ubicandoTitulo : l.sinUbicacionTitulo,
                  textAlign: TextAlign.center,
                  style: NexaTexto.titulo.copyWith(color: NexaColors.texto),
                ),
                const SizedBox(height: Sp.xs),
                Text(
                  widget.buscando ? l.ubicandoTexto : l.sinUbicacionTexto,
                  textAlign: TextAlign.center,
                  style: NexaTexto.cuerpo.copyWith(color: NexaColors.muted),
                ),
                if (!widget.buscando) ...[
                  const SizedBox(height: Sp.lg),
                  NexaButton(
                    label: l.activarUbicacion,
                    onPressed: widget.onActivar,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tres ondas que salen del centro, como el radar del pedido.
class _Ondas extends CustomPainter {
  _Ondas(this.t, this.color) : super(repaint: t);
  final Animation<double> t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maximo = size.shortestSide / 2;
    for (var i = 0; i < 3; i++) {
      final f = (t.value + i / 3) % 1;
      canvas.drawCircle(
        c,
        18 + f * (maximo - 18),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: (1 - f) * 0.6),
      );
    }
    canvas.drawCircle(
      c,
      26 + 2 * math.sin(t.value * 2 * math.pi),
      Paint()..color = color.withValues(alpha: 0.14),
    );
  }

  @override
  bool shouldRepaint(_Ondas old) => old.color != color;
}
