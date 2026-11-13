import '../../../../core/theme/tokens.dart';
import '../controllers/session_controller.dart';

import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/widgets/nexa_icono_app.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(sesionProvider.notifier).iniciar());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 0.1),
            radius: 1.1,
            colors: [Color(0xFF06324F), NexaColors.bg],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _RutaPunteada()),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutBack,
                    builder: (_, v, child) => Opacity(
                      opacity: v.clamp(0, 1),
                      child: Transform.scale(scale: 0.7 + 0.3 * v, child: child),
                    ),
                    child: const NexaIconoApp(tamano: 96),
                  ),
                  const SizedBox(height: Sp.xl),
                  Text(
                    'NEXA',
                    style: NexaTexto.display.copyWith(
                      fontSize: 52,
                      letterSpacing: 10,
                    ),
                  ),
                  const SizedBox(height: Sp.sm),
                  Text(
                    l.lema,
                    style: NexaTexto.cuerpo.copyWith(color: NexaColors.muted),
                  ),
                  const Spacer(flex: 4),
                  Text(
                    l.ciudadPais.toUpperCase(),
                    style: NexaTexto.etiqueta.copyWith(color: NexaColors.tenue),
                  ),
                  const SizedBox(height: Sp.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ruta punteada decorativa que cruza la pantalla (diseño A01).
class _RutaPunteada extends CustomPainter {
  const _RutaPunteada();

  @override
  void paint(Canvas canvas, Size size) {
    final ruta = Path()
      ..moveTo(0, size.height * 0.74)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.6,
        size.width * 0.55,
        size.height * 0.62,
        size.width,
        size.height * 0.45,
      );
    final p = Paint()..color = NexaColors.cyan.withValues(alpha: 0.35);
    for (final m in ruta.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 14) {
        final t = m.getTangentForOffset(d);
        if (t != null) canvas.drawCircle(t.position, 1.6, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
