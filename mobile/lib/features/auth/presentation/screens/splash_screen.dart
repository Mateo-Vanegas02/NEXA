import '../../../../core/theme/tokens.dart';
import '../controllers/session_controller.dart';

import 'package:flutter/material.dart';

import '../../../../core/widgets/nexa_logo.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                builder: (_, v, child) => Opacity(
                  opacity: v.clamp(0, 1),
                  child: Transform.scale(scale: 0.7 + 0.3 * v, child: child),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: NexaColors.cyan.withValues(alpha: 0.45),
                        blurRadius: 60,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: const NexaLogo(tamano: 132),
                ),
              ),
              const SizedBox(height: Sp.xl),
              const SizedBox(
                width: 140,
                child: LinearProgressIndicator(minHeight: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
