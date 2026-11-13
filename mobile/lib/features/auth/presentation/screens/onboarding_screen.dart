import 'dart:math' as math;

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../controllers/session_controller.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Bienvenida (diseño A02): ilustración del radar con la ruta arriba, mensaje
/// grande y las dos salidas (crear cuenta / ya tengo cuenta). Se puede
/// deslizar entre tres mensajes.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _i = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _ir(String ruta) async {
    await ref.read(sesionProvider.notifier).completarOnboarding();
    if (mounted) context.go(ruta);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final paginas = [
      (const _Radar(), l.onb1Titulo, l.onb1Texto),
      (const _Insignia(Icons.bolt_rounded), l.onb2Titulo, l.onb2Texto),
      (const _Insignia(Icons.verified_user_outlined), l.onb3Titulo, l.onb3Texto),
    ];
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          child: ContenidoCentrado(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _page,
                    itemCount: paginas.length,
                    onPageChanged: (i) => setState(() => _i = i),
                    itemBuilder: (_, i) {
                      final (arte, titulo, texto) = paginas[i];
                      return LayoutBuilder(
                        builder: (context, c) => SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: math.min(c.maxHeight * 0.58, 420),
                                child: ExcludeSemantics(child: arte),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.gutter + Sp.xs,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(titulo, style: NexaTexto.display),
                                    const SizedBox(height: Sp.md),
                                    Text(
                                      texto,
                                      style: NexaTexto.cuerpo.copyWith(
                                        color: NexaColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.gutter + Sp.xs,
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < paginas.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: Sp.xs + 2),
                          width: i == _i ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _i ? NexaColors.cyan : NexaColors.tenue,
                            borderRadius: BorderRadius.circular(Rad.pill),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.gutter,
                    Sp.xl,
                    context.gutter,
                    Sp.md,
                  ),
                  child: Column(
                    children: [
                      NexaButton(
                        label: l.crearCuenta,
                        onPressed: () => _ir('/registro'),
                      ),
                      const SizedBox(height: Sp.sm),
                      NexaButton(
                        label: l.yaTengoCuenta,
                        variant: NexaButtonVariant.fantasma,
                        onPressed: () => _ir('/login'),
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

/// Radar con la ruta de la moto (A02): ondas concéntricas, la ruta cian del
/// punto al destino, la moto a mitad de camino y dos etiquetas.
class _Radar extends StatelessWidget {
  const _Radar();

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(child: CustomPaint(painter: _RadarPainter())),
      const Align(
        alignment: Alignment(-0.05, 0.02),
        child: _Moto(),
      ),
      Align(
        alignment: const Alignment(-0.45, -0.52),
        child: _Etiqueta(icono: Icons.bolt_rounded, texto: '+7 XP por viaje'),
      ),
      Align(
        alignment: const Alignment(0.55, 0.1),
        child: _Etiqueta(icono: Icons.timer_outlined, texto: 'Llega en 3 min'),
      ),
    ],
  );
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.5, size.height * 0.52);
    final onda = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final (r, a) in [(0.95, 0.10), (0.7, 0.16), (0.46, 0.22), (0.24, 0.3)]) {
      onda.color = NexaColors.cyan.withValues(alpha: a);
      canvas.drawCircle(c, size.height * 0.5 * r, onda);
    }
    final inicio = Offset(size.width * 0.12, size.height * 0.88);
    final fin = Offset(size.width * 0.75, size.height * 0.24);
    final ruta = Path()
      ..moveTo(inicio.dx, inicio.dy)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.55,
        size.width * 0.38,
        size.height * 0.55,
        size.width * 0.5,
        size.height * 0.5,
      )
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.44,
        size.width * 0.7,
        size.height * 0.38,
        fin.dx,
        fin.dy,
      );
    canvas
      ..drawPath(
        ruta,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..color = NexaColors.cyan.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawPath(
        ruta,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = NexaColors.cyan,
      )
      // Origen: punto con halo.
      ..drawCircle(inicio, 16, Paint()..color = NexaColors.cyan.withValues(alpha: 0.2))
      ..drawCircle(inicio, 8, Paint()..color = NexaColors.texto)
      ..drawCircle(inicio, 5, Paint()..color = NexaColors.navy);
    // Destino: cuadro blanco.
    final destino = RRect.fromRectAndRadius(
      Rect.fromCenter(center: fin, width: 34, height: 34),
      const Radius.circular(9),
    );
    canvas
      ..drawRRect(destino, Paint()..color = NexaColors.texto)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: fin, width: 11, height: 11),
          const Radius.circular(2),
        ),
        Paint()..color = NexaColors.bg,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Moto extends StatelessWidget {
  const _Moto();

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: NexaColors.cyan,
      border: Border.all(color: NexaColors.texto, width: 3),
      boxShadow: NexaShadows.glow,
    ),
    child: const Icon(Icons.two_wheeler, color: NexaColors.bg, size: 26),
  );
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.icono, required this.texto});
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
    decoration: BoxDecoration(
      color: NexaColors.card,
      borderRadius: BorderRadius.circular(Rad.md),
      border: Border.all(color: NexaColors.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 16, color: NexaColors.gold),
        const SizedBox(width: Sp.sm),
        Text(
          texto,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

/// Arte de las páginas 2 y 3: insignia con ondas.
class _Insignia extends StatelessWidget {
  const _Insignia(this.icono);
  final IconData icono;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      const Positioned.fill(child: CustomPaint(painter: _OndasPainter())),
      Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF29D3FF), NexaColors.navy],
          ),
          boxShadow: NexaShadows.glow,
        ),
        child: Icon(icono, size: 56, color: NexaColors.bg),
      ),
    ],
  );
}

class _OndasPainter extends CustomPainter {
  const _OndasPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final (r, a) in [(0.95, 0.1), (0.7, 0.16), (0.46, 0.24)]) {
      p.color = NexaColors.cyan.withValues(alpha: a);
      canvas.drawCircle(c, size.height * 0.5 * r, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
