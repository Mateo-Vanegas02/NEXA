import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_diseno.dart';

import 'package:flutter/material.dart';

import '../../../../core/widgets/nexa_logo.dart';

/// Marco común de login/registro: scroll con teclado abierto, ancho acotado.
///
/// Sin [paso] muestra el logo con brillo y el título centrado (inicio de sesión).
/// Con [paso] y [pasos] muestra "Paso n de total" con una barra de avance y el
/// título alineado a la izquierda (registro). [onAtras] añade el botón de volver.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.children,
    this.paso,
    this.pasos,
    this.onAtras,
  });
  final String titulo;
  final String? subtitulo;
  final List<Widget> children;
  final int? paso;
  final int? pasos;
  final VoidCallback? onAtras;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    final porPasos = paso != null && pasos != null;
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.all(context.gutter),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: c.maxHeight - 2 * context.gutter,
                ),
                child: ContenidoCentrado(
                  child: Column(
                    crossAxisAlignment: porPasos
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.stretch,
                    mainAxisAlignment: porPasos
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      if (onAtras != null || porPasos)
                        Row(
                          children: [
                            if (onAtras != null)
                              IconButton(
                                tooltip: l.volver,
                                onPressed: onAtras,
                                icon: const Icon(Icons.arrow_back),
                                style: IconButton.styleFrom(
                                  minimumSize: const Size.square(Sizes.touch),
                                  side: BorderSide(
                                    color: context.colors.outline.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            if (porPasos)
                              Expanded(
                                child: Text(
                                  l.pasoDe(paso!, pasos!),
                                  textAlign: TextAlign.end,
                                  style: t.labelLarge?.copyWith(
                                    color: context.muted,
                                  ),
                                ),
                              )
                            else
                              const Spacer(),
                          ],
                        ),
                      if (porPasos) ...[
                        const SizedBox(height: Sp.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(Rad.pill),
                          child: LinearProgressIndicator(
                            value: paso! / pasos!,
                            minHeight: 6,
                            color: NexaColors.cyan,
                            backgroundColor: context.colors.outline.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        const SizedBox(height: Sp.xl),
                      ] else ...[
                        const NexaLogo(tamano: 72, brillo: true),
                        const SizedBox(height: Sp.lg),
                      ],
                      Text(
                        titulo,
                        style: t.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: porPasos
                            ? TextAlign.start
                            : TextAlign.center,
                      ),
                      if (subtitulo != null) ...[
                        const SizedBox(height: Sp.xs + 2),
                        Text(
                          subtitulo!,
                          style: t.bodyMedium?.copyWith(color: context.muted),
                          textAlign: porPasos
                              ? TextAlign.start
                              : TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: Sp.xl),
                      if (porPasos)
                        ...children.map(
                          (w) => SizedBox(width: double.infinity, child: w),
                        )
                      else
                        ...children,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
