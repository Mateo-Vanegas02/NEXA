import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/mapa_nexa.dart';
import '../../../../core/widgets/nexa_logo.dart';
import '../../../../core/widgets/nexa_widgets.dart';

/// Portada pública (rediseño 2026): el mapa real de Cartagena de fondo y un
/// solo llamado por camino: pedir el primer viaje o conducir con NEXA. Es lo
/// primero que ve quien ya pasó la bienvenida y no tiene sesión.
class PortadaScreen extends StatelessWidget {
  const PortadaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: NexaColors.bg,
      body: Stack(
        children: [
          // Fondo decorativo: sin toques ni lector de pantalla. Si el mapa no
          // carga (sin red), queda el fondo azul noche de la pantalla.
          const Positioned.fill(
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: MapaNexa(centro: kCentroPorDefecto, zoom: 13.5),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.35, 0.62],
                    colors: [
                      NexaColors.bg.withValues(alpha: 0.4),
                      NexaColors.bg.withValues(alpha: 0.6),
                      NexaColors.bg,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  context.gutter,
                  Sp.xl,
                  context.gutter,
                  Sp.lg,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: c.maxHeight - Sp.xl - Sp.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: NexaLogo(tamano: 40, brillo: true),
                      ),
                      const SizedBox(height: Sp.xxl),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              l.portadaTitulo,
                              style: NexaTexto.display.copyWith(
                                color: NexaColors.texto,
                              ),
                            ),
                          ),
                          const SizedBox(height: Sp.sm),
                          Text(
                            l.portadaTexto,
                            style: NexaTexto.cuerpo.copyWith(
                              color: NexaColors.muted,
                            ),
                          ),
                          const SizedBox(height: Sp.xl),
                          NexaButton(
                            label: l.portadaPedir,
                            onPressed: () => context.go('/registro'),
                          ),
                          const SizedBox(height: Sp.sm),
                          NexaButton(
                            label: l.portadaConducir,
                            variant: NexaButtonVariant.fantasma,
                            onPressed: () => context.go('/registro/conductor'),
                          ),
                          const SizedBox(height: Sp.sm),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text(l.yaTengoCuenta),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
