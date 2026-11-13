import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_diseno.dart';

import 'package:flutter/material.dart';

import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/widgets/nexa_icono_app.dart';

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
    this.pie,
  });
  final String titulo;
  final String? subtitulo;
  final List<Widget> children;
  final int? paso;
  final int? pasos;
  final VoidCallback? onAtras;

  /// Va pegado abajo (p. ej. «¿No tienes cuenta? Crear cuenta»).
  final Widget? pie;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final porPasos = paso != null && pasos != null;
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(context.gutter),
                sliver: SliverFillRemaining(
                  hasScrollBody: false,
                  child: ContenidoCentrado(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (onAtras != null || porPasos)
                          Row(
                            children: [
                              if (onAtras != null)
                                NexaBotonAtras(
                                  onPressed: onAtras!,
                                  tooltip: l.volver,
                                ),
                              if (porPasos)
                                Expanded(
                                  child: Text(
                                    l.pasoDe(paso!, pasos!),
                                    textAlign: TextAlign.end,
                                    style: NexaTexto.pequeno.copyWith(
                                      color: context.muted,
                                    ),
                                  ),
                                )
                              else
                                const Spacer(),
                            ],
                          ),
                        const SizedBox(height: Sp.xl),
                        if (porPasos) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(Rad.pill),
                            child: LinearProgressIndicator(
                              value: paso! / pasos!,
                              minHeight: 4,
                              color: NexaColors.cyan,
                              backgroundColor: NexaColors.line,
                            ),
                          ),
                          const SizedBox(height: Sp.xl),
                        ] else ...[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: NexaIconoApp(tamano: 52),
                          ),
                          const SizedBox(height: Sp.xl),
                        ],
                        Text(titulo, style: NexaTexto.titulo),
                        if (subtitulo != null) ...[
                          const SizedBox(height: Sp.sm),
                          Text(
                            subtitulo!,
                            style: NexaTexto.cuerpo.copyWith(
                              color: context.muted,
                            ),
                          ),
                        ],
                        const SizedBox(height: Sp.xl),
                        ...children,
                        if (pie != null) ...[
                          const Spacer(),
                          const SizedBox(height: Sp.xl),
                          pie!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
