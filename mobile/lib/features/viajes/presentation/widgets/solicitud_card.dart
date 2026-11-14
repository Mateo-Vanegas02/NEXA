import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../domain/servicio.dart';
import '../controllers/viaje_conductor_controller.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Solicitud entrante: lo que cobra el conductor en grande, la ruta en dos líneas
/// y «Aceptar» como acción principal.
class SolicitudCard extends ConsumerStatefulWidget {
  const SolicitudCard({super.key, required this.servicio});
  final Servicio servicio;

  @override
  ConsumerState<SolicitudCard> createState() => _SolicitudCardState();
}

class _SolicitudCardState extends ConsumerState<SolicitudCard>
    with SingleTickerProviderStateMixin {
  /// Segundos que la solicitud pide atención (los mismos del aviso push).
  static const int _ventana = 45;

  bool _aceptando = false;

  /// Cuenta regresiva de la ventana de atención: corre una vez. Al acabar la
  /// solicitud sigue disponible (el servidor no la vence por conductor), solo
  /// deja de resaltarse.
  late final AnimationController _reloj = AnimationController(
    vsync: this,
    duration: const Duration(seconds: _ventana),
  )..forward();

  @override
  void dispose() {
    _reloj.dispose();
    super.dispose();
  }

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
    final servicio = widget.servicio;
    final ctrl = ref.read(conductorProvider.notifier);
    final extra = servicio.extraVoluntario;
    final total = servicio.tarifa + extra;
    final porKm = servicio.distanciaKM > 0
        ? Fmt.cop(servicio.tarifa / servicio.distanciaKM)
        : null;
    final km = NumberFormat('0.0', 'es_CO').format(servicio.distanciaKM);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NexaColors.card,
        borderRadius: BorderRadius.circular(Rad.lg + 4),
        border: Border.all(color: NexaColors.cyan.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: NexaColors.cyan.withValues(alpha: 0.16),
            blurRadius: 28,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.nuevaSolicitud.toUpperCase(),
              textAlign: TextAlign.center,
              style: NexaTexto.etiqueta.copyWith(color: NexaColors.cyan),
            ),
            const SizedBox(height: Sp.md),
            // Anillo de 45 s con lo que gana en el centro. «Ganas $X» lo
            // calcula el servidor según el nivel del conductor; sin ese dato
            // se muestra lo que cobra en efectivo.
            Center(
              child: AnimatedBuilder(
                animation: _reloj,
                builder: (context, centro) {
                  final queda = 1 - _reloj.value;
                  final segundos = (queda * _ventana).ceil();
                  return NexaAnilloProgreso(
                    progreso: queda,
                    diametro: 164,
                    trazo: 7,
                    relleno: 10,
                    color: queda <= 0
                        ? NexaColors.tenue
                        : queda < 0.27
                        ? NexaColors.gold
                        : NexaColors.cyan,
                    etiquetaSemantica: queda <= 0
                        ? l.solicitudSigue
                        : l.solicitudSegundos(segundos),
                    child: Center(
                      child: SizedBox(
                        width: 118,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              centro!,
                              Text(
                                queda <= 0
                                    ? l.solicitudSigue
                                    : l.solicitudSegundos(segundos),
                                style: NexaTexto.pequeno.copyWith(
                                  color: NexaColors.sky,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      servicio.gananciaEstimada != null
                          ? l.ganasMonto(Fmt.cop(servicio.gananciaEstimada!))
                          : '${l.cobraAlPasajero} ${Fmt.cop(total)}',
                      style: NexaTexto.titulo,
                    ),
                    Text(
                      [
                        if (porKm != null) l.porKm(porKm),
                        l.efectivo.toLowerCase(),
                      ].join(' · '),
                      style: NexaTexto.pequeno.copyWith(
                        color: NexaColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Sp.md),
            Wrap(
              spacing: Sp.sm,
              runSpacing: Sp.sm,
              children: [
                if (extra > 0)
                  _Etiqueta(
                    icono: Icons.bolt_rounded,
                    texto: '+${Fmt.cop(extra)} ${l.extra}',
                    color: NexaColors.gold,
                  ),
                if (servicio.nivelPasajero > 0)
                  _Etiqueta(
                    texto: l.nivelActual('${servicio.nivelPasajero}'),
                    color: NexaColors.cyan,
                  ),
                _Etiqueta(texto: '$km km', color: NexaColors.ok),
              ],
            ),
            const SizedBox(height: Sp.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: NexaColors.bg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(Rad.lg),
                border: Border.all(color: NexaColors.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Sp.md),
                child: Column(
                  children: [
                    _Punto(
                      icono: Icons.my_location,
                      texto: servicio.origen,
                      detalle: servicio.pasajero?.nombre,
                    ),
                    const SizedBox(height: Sp.md),
                    _Punto(
                      icono: Icons.place_outlined,
                      texto: servicio.destino,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Sp.lg),
            // Aceptar se desliza: en la moto un toque accidental es fácil.
            NexaDeslizar(
              texto: l.deslizaAceptar,
              onConfirmado: _aceptando ? null : _aceptar,
            ),
            const SizedBox(height: Sp.xs),
            TextButton(
              onPressed: _aceptando ? null : () => ctrl.rechazar(servicio),
              child: Text(l.ahoraNo),
            ),
          ],
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.color, this.icono});
  final String texto;
  final Color color;
  final IconData? icono;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(Rad.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icono != null) ...[
          Icon(icono, size: 14, color: color),
          const SizedBox(width: Sp.xs),
        ],
        Flexible(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Punto extends StatelessWidget {
  const _Punto({required this.icono, required this.texto, this.detalle});
  final IconData icono;
  final String texto;
  final String? detalle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: NexaColors.raised,
          borderRadius: BorderRadius.circular(Rad.sm + 2),
        ),
        child: Icon(icono, size: 18, color: NexaColors.cyan),
      ),
      const SizedBox(width: Sp.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              texto,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: NexaTexto.cuerpo.copyWith(fontWeight: FontWeight.w600),
            ),
            if (detalle != null)
              Text(
                detalle!,
                style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
              ),
          ],
        ),
      ),
    ],
  );
}
