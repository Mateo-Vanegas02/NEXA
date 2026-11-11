import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/nexa_diseno.dart';
import '../../../core/widgets/nexa_widgets.dart';
import '../../auth/presentation/controllers/session_controller.dart';
import 'widgets/satisfaccion_widgets.dart';

/// Marco del rol admin: contenido + barra flotante (diseño de Figma).
class AdminShell extends StatelessWidget {
  const AdminShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.lg),
        child: NexaBarraFlotante(
          indice: shell.currentIndex,
          onSeleccion: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          items: [
            NexaItemBarra(icono: Icons.home_outlined, etiqueta: l.navInicio),
            NexaItemBarra(
              icono: Icons.bar_chart_rounded,
              etiqueta: l.satTitulo,
            ),
            NexaItemBarra(
              icono: Icons.groups_outlined,
              etiqueta: l.adminConductores,
            ),
            NexaItemBarra(icono: Icons.person_outline, etiqueta: l.navPerfil),
          ],
        ),
      ),
    );
  }
}

enum SeccionAdmin { inicio, conductores }

/// Secciones del admin que por ahora solo existen en la web.
class AdminProximamenteScreen extends StatelessWidget {
  const AdminProximamenteScreen({required this.seccion, super.key});

  final SeccionAdmin seccion;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.gutter),
            child: Column(
              children: [
                EncabezadoSat(
                  etiqueta: l.adminRol,
                  titulo: switch (seccion) {
                    SeccionAdmin.inicio => l.navInicio,
                    SeccionAdmin.conductores => l.adminConductores,
                  },
                ),
                Expanded(
                  child: EstadoVacio(
                    titulo: l.adminProximamente,
                    detalle: l.adminProximamenteDetalle,
                    icon: Icons.construction_outlined,
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

/// Perfil mínimo del admin: correo y cerrar sesión.
class AdminPerfilScreen extends ConsumerWidget {
  const AdminPerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final sesion = ref.watch(sesionProvider).sesion;
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.gutter,
              0,
              context.gutter,
              120,
            ),
            children: [
              ContenidoCentrado(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EncabezadoSat(etiqueta: l.adminRol, titulo: l.navPerfil),
                    const SizedBox(height: Sp.md),
                    TarjetaSat(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: context.acento.withValues(
                              alpha: 0.16,
                            ),
                            child: Icon(
                              Icons.admin_panel_settings_outlined,
                              color: context.acento,
                            ),
                          ),
                          const SizedBox(width: Sp.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.adminRol,
                                  style: context.textos.titleSmall,
                                ),
                                Text(
                                  sesion?.email ?? '',
                                  style: context.textos.bodySmall?.copyWith(
                                    color: context.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Sp.xl),
                    NexaButton(
                      label: l.cerrarSesion,
                      icon: Icons.logout,
                      variant: NexaButtonVariant.secundario,
                      onPressed: () =>
                          ref.read(sesionProvider.notifier).logout(),
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
