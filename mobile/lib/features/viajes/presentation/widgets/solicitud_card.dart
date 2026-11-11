import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/servicio.dart';
import '../controllers/viaje_conductor_controller.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Solicitud entrante: lo que cobra el conductor en grande, la ruta en dos líneas
/// y «Aceptar» como acción principal.
class SolicitudCard extends ConsumerStatefulWidget {
  const SolicitudCard({super.key, required this.servicio});
  final Servicio servicio;

  @override
  ConsumerState<SolicitudCard> createState() => _SolicitudCardState();
}

class _SolicitudCardState extends ConsumerState<SolicitudCard> {
  bool _aceptando = false;

  /// Si otro conductor la tomó (409) o ya no le toca (403), el mensaje del
  /// servidor se muestra y la solicitud sale de la lista.
  Future<void> _aceptar() async {
    final mensajes = ScaffoldMessenger.of(context);
    setState(() => _aceptando = true);
    try {
      await ref.read(conductorProvider.notifier).aceptar(widget.servicio);
    } on Object catch (e) {
      mensajes
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(AppException.from(e).mensaje)));
    } finally {
      if (mounted) setState(() => _aceptando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final servicio = widget.servicio;
    final ctrl = ref.read(conductorProvider.notifier);
    final extra = servicio.extraVoluntario;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NexaColors.card,
        borderRadius: BorderRadius.circular(Rad.lg + 4),
        border: Border.all(color: NexaColors.cyan.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: NexaColors.cyan.withValues(alpha: 0.18),
            blurRadius: 24,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.nuevaSolicitud.toUpperCase(),
                        style: t.labelSmall?.copyWith(
                          color: NexaColors.cyan,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        servicio.pasajero?.nombre ?? '',
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l.nivelActual('${servicio.nivelPasajero}'),
                        style: t.bodySmall?.copyWith(color: context.muted),
                      ),
                    ],
                  ),
                ),
                if (extra > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Sp.md,
                      vertical: Sp.xs + 1,
                    ),
                    decoration: BoxDecoration(
                      color: NexaColors.gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(Rad.pill),
                    ),
                    child: Text(
                      '+${Fmt.cop(extra)}',
                      style: const TextStyle(
                        color: NexaColors.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Sp.md),
            Container(
              padding: const EdgeInsets.all(Sp.lg - 2),
              decoration: BoxDecoration(
                color: NexaColors.cyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Rad.lg),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.cobraAlPasajero,
                          style: t.bodySmall?.copyWith(color: context.muted),
                        ),
                        Text(
                          Fmt.cop(servicio.tarifa + extra),
                          style: t.headlineSmall?.copyWith(
                            color: NexaColors.cyan,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${servicio.distanciaKM.toStringAsFixed(1)} km',
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Sp.md),
            _Punto(esOrigen: true, texto: servicio.origen),
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: SizedBox(
                height: 10,
                child: VerticalDivider(
                  width: 2,
                  thickness: 2,
                  color: NexaColors.cyan.withValues(alpha: 0.45),
                ),
              ),
            ),
            _Punto(esOrigen: false, texto: servicio.destino),
            const SizedBox(height: Sp.lg),
            NexaButton(
              label: l.aceptar,
              cargando: _aceptando,
              onPressed: _aceptar,
            ),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(Sizes.touch),
              ),
              onPressed: _aceptando ? null : () => ctrl.rechazar(servicio),
              child: Text(l.rechazar),
            ),
          ],
        ),
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({required this.esOrigen, required this.texto});
  final bool esOrigen;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (esOrigen)
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
        )
      else
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: NexaColors.cyan,
            borderRadius: BorderRadius.circular(4),
            boxShadow: NexaShadows.glow,
          ),
        ),
      const SizedBox(width: Sp.md),
      Expanded(
        child: Text(
          texto,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textos.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
