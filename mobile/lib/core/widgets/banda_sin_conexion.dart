import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/gen/app_localizations.dart';
import '../sin_conexion/conexion.dart';
import '../theme/tokens.dart';

/// Banda arriba de toda la app mientras no hay señal con el servidor: «Sin
/// conexión · reintentando» y hace cuánto llegó el último dato (pantalla E02).
class BandaSinConexion extends ConsumerWidget {
  const BandaSinConexion({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final red = ref.watch(conexionProvider);
    final l = AppLocalizations.of(context);
    final ultimo = red.ultimoDato;
    final minutos = ultimo == null
        ? null
        : DateTime.now().difference(ultimo).inMinutes;
    return Column(
      children: [
        AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          child: red.conRed
              ? const SizedBox(width: double.infinity)
              : Material(
                  color: NexaColors.gold,
                  child: SafeArea(
                    bottom: false,
                    child: Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Sp.lg,
                          vertical: Sp.sm,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.wifi_off,
                              size: 18,
                              color: NexaColors.bg,
                            ),
                            const SizedBox(width: Sp.sm),
                            Expanded(
                              child: Text(
                                minutos == null
                                    ? l.sinConexionBanda
                                    : '${l.sinConexionBanda} · '
                                          '${l.sinConexionUltimoDato(minutos)}',
                                style: const TextStyle(
                                  color: NexaColors.bg,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        Expanded(
          child: red.conRed
              ? child
              // La banda ya ocupa la zona de la barra de estado.
              : MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: child,
                ),
        ),
      ],
    );
  }
}
