import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/servicio.dart';

import 'package:flutter/material.dart';

class CuentaBloqueada extends StatelessWidget {
  const CuentaBloqueada({super.key, required this.aprobacion});
  final EstadoAprobacion aprobacion;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.gutter),
      child: ContenidoCentrado(
        child: Column(
          children: [
            const SizedBox(height: Sp.xxl),
            const Icon(Icons.lock_clock, size: 72, color: NexaColors.gold),
            const SizedBox(height: Sp.lg),
            Text(
              l.pendienteTitulo,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Sp.md),
            Text(
              aprobacion == EstadoAprobacion.rechazado
                  ? l.rechazadoTexto
                  : l.pendienteTexto,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
