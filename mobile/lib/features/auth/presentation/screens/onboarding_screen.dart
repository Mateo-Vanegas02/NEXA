import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../controllers/session_controller.dart';

import 'package:flutter/material.dart';

import '../../../../core/widgets/nexa_logo.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Widget _icono(IconData i) => Container(
  width: 132,
  height: 132,
  decoration: BoxDecoration(
    color: NexaColors.cyan.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(Rad.sheet),
    border: Border.all(color: NexaColors.cyan.withValues(alpha: 0.45)),
    boxShadow: NexaShadows.glow,
  ),
  child: Icon(i, size: 60, color: NexaColors.cyan),
);

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

  Future<void> _terminar() async {
    await ref.read(sesionProvider.notifier).completarOnboarding();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final paginas = [
      (const NexaLogo(tamano: 132, brillo: true), l.onb1Titulo, l.onb1Texto),
      (_icono(Icons.military_tech), l.onb2Titulo, l.onb2Texto),
      (_icono(Icons.verified_user), l.onb3Titulo, l.onb3Texto),
    ];
    final ultima = _i == paginas.length - 1;
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          child: ContenidoCentrado(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _terminar,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(Sizes.touch, Sizes.touch),
                    ),
                    child: Text(l.omitir),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _page,
                    itemCount: paginas.length,
                    onPageChanged: (i) => setState(() => _i = i),
                    itemBuilder: (_, i) {
                      final (icono, titulo, texto) = paginas[i];
                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.gutter + Sp.sm,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: Sp.xl),
                            icono,
                            const SizedBox(height: Sp.xl),
                            Text(
                              titulo,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: Sp.md),
                            Text(
                              texto,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < paginas.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(Sp.xs),
                        width: i == _i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _i ? NexaColors.cyan : NexaColors.line,
                          borderRadius: BorderRadius.circular(Rad.pill),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.all(context.gutter),
                  child: NexaButton(
                    label: ultima ? l.empezar : l.continuar,
                    onPressed: ultima
                        ? _terminar
                        : () => _page.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
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
