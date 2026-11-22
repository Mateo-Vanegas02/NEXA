import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/servicio.dart';
import 'solicitud_card.dart';

/// Solicitudes que el conductor ya vio a pantalla completa y mandó a la lista.
class SolicitudesVistasNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void ver(String id) => state = {...state, id};
}

final solicitudesVistasProvider =
    NotifierProvider<SolicitudesVistasNotifier, Set<String>>(
      SolicitudesVistasNotifier.new,
    );

/// Solicitud entrante a pantalla completa (rediseño 2026): el mapa se oscurece
/// y queda al centro la tarjeta con su cuenta regresiva, el precio y
/// «Aceptar». «Ver en el mapa» la deja en la lista de la hoja.
class SolicitudEntrante extends ConsumerWidget {
  const SolicitudEntrante({required this.servicio, super.key});
  final Servicio servicio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Positioned.fill(
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: l.solicitudNueva,
        child: ColoredBox(
          color: NexaColors.bg.withValues(alpha: 0.78),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sp.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: NexaColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: Sp.sm),
                          Text(
                            l.solicitudNueva.toUpperCase(),
                            style: NexaTexto.etiqueta.copyWith(
                              color: NexaColors.gold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Sp.md),
                      SolicitudCard(servicio: servicio),
                      const SizedBox(height: Sp.sm),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(Sizes.touch),
                        ),
                        onPressed: () => ref
                            .read(solicitudesVistasProvider.notifier)
                            .ver(servicio.id),
                        icon: const Icon(
                          Icons.map_outlined,
                          color: NexaColors.muted,
                        ),
                        label: Text(
                          l.solicitudVerEnMapa,
                          style: const TextStyle(color: NexaColors.muted),
                        ),
                      ),
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
