import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../controllers/niveles_controller.dart';
import 'level_progress_bar.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Barra de nivel conectada al estado; al tocarla abre la pantalla de niveles.
class NivelBanner extends ConsumerWidget {
  const NivelBanner({this.rutaNiveles, this.irEnLugar = false, super.key});

  /// `true` = cambia de pestaña con `go`; `false` = abre encima con `push`.
  final bool irEnLugar;

  /// Ruta de la pantalla de niveles; `null` = no navega.
  final String? rutaNiveles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nivel = ref.watch(nivelProvider);
    return nivel.when(
      loading: () => const NexaCard(child: Skeleton(height: 48)),
      error: (e, _) => NexaCard(
        onTap: () => ref.invalidate(nivelProvider),
        child: Row(
          children: [
            const Icon(Icons.refresh),
            const SizedBox(width: Sp.md),
            Expanded(child: Text(AppException.from(e).mensaje)),
          ],
        ),
      ),
      data: (n) => LevelProgressBar(
        estado: n,
        onTap: rutaNiveles == null
            ? null
            : () => irEnLugar
                  ? context.go(rutaNiveles!)
                  : context.push(rutaNiveles!),
      ),
    );
  }
}
