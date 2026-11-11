import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../controllers/viaje_pasajero_controller.dart';
import '../widgets/viaje_tile.dart';

class HistorialPasajeroScreen extends ConsumerWidget {
  const HistorialPasajeroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final historial = ref.watch(historialPasajeroProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.historial)),
      body: SafeArea(
        child: historial.when(
          loading: () => const CargandoSkeleton(),
          error: (e, _) => EstadoError(
            mensaje: AppException.from(e).mensaje,
            onReintentar: () => ref.invalidate(historialPasajeroProvider),
          ),
          data: (lista) => lista.isEmpty
              ? EstadoVacio(
                  titulo: l.vacioHistorial,
                  detalle: l.vacioHistorialDetalle,
                  icon: Icons.history,
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(historialPasajeroProvider.future),
                  child: ListView.separated(
                    padding: EdgeInsets.all(context.gutter),
                    itemCount: lista.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Sp.sm),
                    itemBuilder: (_, i) =>
                        ContenidoCentrado(child: ViajeTile(servicio: lista[i])),
                  ),
                ),
        ),
      ),
    );
  }
}
