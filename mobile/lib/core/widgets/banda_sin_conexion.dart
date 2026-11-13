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
              : ColoredBox(
                  color: NexaColors.bg,
                  child: SafeArea(
                  bottom: false,
                  child: Semantics(
                    liveRegion: true,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(
                        Sp.md,
                        Sp.sm,
                        Sp.md,
                        Sp.xs,
                      ),
                      padding: const EdgeInsets.all(Sp.md),
                      decoration: BoxDecoration(
                        color: NexaColors.gold,
                        borderRadius: BorderRadius.circular(Rad.lg),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66000000), blurRadius: 16),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: NexaColors.bg.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(Rad.md),
                            ),
                            child: const Icon(
                              Icons.wifi_off,
                              size: 20,
                              color: NexaColors.bg,
                            ),
                          ),
                          const SizedBox(width: Sp.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.sinConexionBanda,
                                  style: const TextStyle(
                                    color: NexaColors.bg,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  minutos == null
                                      ? l.sinConexionGuardamos
                                      : '${l.sinConexionGuardamos} · '
                                            '${l.sinConexionUltimoDato(minutos)}',
                                  style: const TextStyle(
                                    color: NexaColors.bg,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
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
