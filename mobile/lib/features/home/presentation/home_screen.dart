import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/nexa_logo.dart';

/// Pantalla de inicio pública (landing): hero con llamadas a la acción y servicios.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _menu(BuildContext context) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.login),
              title: Text(l.iniciarSesion),
              minTileHeight: Sizes.touch,
              onTap: () {
                Navigator.of(ctx).pop();
                context.go('/login');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt),
              title: Text(l.registrate),
              minTileHeight: Sizes.touch,
              onTap: () {
                Navigator.of(ctx).pop();
                context.go('/registro');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final servicios = [
      (Icons.two_wheeler, l.svcReservaTitulo, l.svcReservaTexto),
      (Icons.location_on_outlined, l.svcRastreoTitulo, l.svcRastreoTexto),
      (Icons.star_outline, l.svcCalifTitulo, l.svcCalifTexto),
      (Icons.payments_outlined, l.svcPagosTitulo, l.svcPagosTexto),
    ];
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.gutter),
          child: ContenidoCentrado(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: NexaLogo(),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(Sizes.touch, Sizes.touch),
                      ),
                      child: Text(l.iniciarSesion),
                    ),
                    IconButton(
                      tooltip: l.abrirMenu,
                      onPressed: () => _menu(context),
                      icon: const Icon(Icons.menu),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(Sizes.touch, Sizes.touch),
                        side: BorderSide(color: context.colors.outline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.lg),
                const _Hero(),
                const SizedBox(height: Sp.xl),
                Text(l.servicios, style: context.textos.headlineSmall),
                Text(
                  l.serviciosSub,
                  style: context.textos.bodyMedium?.copyWith(
                    color: context.muted,
                  ),
                ),
                const SizedBox(height: Sp.md),
                _Servicios(items: servicios),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Sp.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Rad.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NexaColors.brand, Color(0xFF07405F)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.md,
              vertical: Sp.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(Rad.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    l.homeBadge,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Sp.lg),
          Text(
            l.homeHero,
            style: context.textos.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: Sp.sm),
          Text(
            l.homeSubtitulo,
            style: context.textos.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: Sp.xl),
          FilledButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.arrow_forward),
            iconAlignment: IconAlignment.end,
            label: Text(l.solicitaAhora),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(Sizes.touch),
              backgroundColor: NexaColors.cyan,
              foregroundColor: NexaColors.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Rad.md),
              ),
            ),
          ),
          const SizedBox(height: Sp.sm),
          OutlinedButton(
            onPressed: () => context.go('/registro'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(Sizes.touch),
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Rad.md),
              ),
            ),
            child: Text(l.registrate),
          ),
        ],
      ),
    );
  }
}

class _Servicios extends StatelessWidget {
  const _Servicios({required this.items});
  final List<(IconData, String, String)> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columnas = c.maxWidth >= 520 ? 4 : 2;
      final filas = <Widget>[];
      for (var i = 0; i < items.length; i += columnas) {
        final fin = (i + columnas).clamp(0, items.length);
        filas.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = i; j < fin; j++) ...[
                  if (j > i) const SizedBox(width: Sp.md),
                  Expanded(child: _ServicioCard(item: items[j])),
                ],
              ],
            ),
          ),
        );
        if (fin < items.length) filas.add(const SizedBox(height: Sp.md));
      }
      return Column(children: filas);
    },
  );
}

class _ServicioCard extends StatelessWidget {
  const _ServicioCard({required this.item});
  final (IconData, String, String) item;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Sp.lg),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(Rad.md),
      border: Border.all(color: context.colors.outline.withValues(alpha: 0.4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(Sp.sm),
          decoration: BoxDecoration(
            color: NexaColors.cyan.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(Rad.sm),
          ),
          child: Icon(item.$1, color: context.acento),
        ),
        const SizedBox(height: Sp.md),
        Text(
          item.$2,
          style: context.textos.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: Sp.xs),
        Text(
          item.$3,
          style: context.textos.bodySmall?.copyWith(color: context.muted),
        ),
      ],
    ),
  );
}
