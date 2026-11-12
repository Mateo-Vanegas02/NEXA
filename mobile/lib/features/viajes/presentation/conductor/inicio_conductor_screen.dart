import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/mapa_nexa.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../../niveles/presentation/widgets/nivel_banner.dart';
import '../../domain/servicio.dart';
import '../controllers/avisos_push_controller.dart';
import '../controllers/viaje_conductor_controller.dart';
import '../widgets/cuenta_bloqueada.dart';
import '../widgets/solicitud_card.dart';
import '../widgets/viaje_activo_card.dart';
import '../../../permisos/presentation/flujo_permisos.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class InicioConductorScreen extends ConsumerWidget {
  const InicioConductorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(conductorProvider);
    // «Aceptar» desde la notificación no se pudo (otro conductor la tomó…).
    ref.listen(avisosPushProvider, (_, mensaje) {
      if (mensaje == null) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));
      ref.read(avisosPushProvider.notifier).consumirMensaje();
    });
    return RevisionPermisos(
      child: Scaffold(
        body: estado.when(
          loading: () => const SafeArea(child: CargandoSkeleton()),
          error: (e, _) => SafeArea(
            child: EstadoError(
              mensaje: AppException.from(e).mensaje,
              onReintentar: () => ref.invalidate(conductorProvider),
            ),
          ),
          data: (s) => s.aprobacion == EstadoAprobacion.aprobado
              ? _Panel(estado: s)
              : SafeArea(child: CuentaBloqueada(aprobacion: s.aprobacion)),
        ),
      ),
    );
  }
}

/// Panel del conductor: el mapa es la pantalla; arriba flota su estado y abajo
/// una hoja con el botón grande para conectarse y las solicitudes.
class _Panel extends ConsumerWidget {
  const _Panel({required this.estado});
  final ConductorState estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final ctrl = ref.read(conductorProvider.notifier);
    final centro = ref.watch(ubicacionProvider).value ?? kCentroPorDefecto;
    final enViaje = estado.activo != null || estado.terminado != null;
    // Con un viaje activo el mapa muestra la recogida, el destino y al conductor.
    final activo = estado.activo;
    final pos = estado.posicion;
    final recogida = activo?.ubicacionOrigen == null
        ? centro
        : LatLng(
            activo!.ubicacionOrigen!.latitud,
            activo.ubicacionOrigen!.longitud,
          );
    final destino = activo?.ubicacionDestino == null
        ? null
        : LatLng(
            activo!.ubicacionDestino!.latitud,
            activo.ubicacionDestino!.longitud,
          );
    final moto = pos == null ? null : LatLng(pos.latitud, pos.longitud);
    return Stack(
      children: [
        Positioned.fill(
          child: MapaNexa(
            centro: moto ?? recogida,
            origen: recogida,
            destino: destino,
            conductor: moto,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Sp.md),
            child: Align(
              alignment: Alignment.topLeft,
              child: _EstadoFlotante(enLinea: estado.enLinea),
            ),
          ),
        ),
        NexaHojaArrastrable(
          inicial: enViaje ? 0.6 : 0.5,
          minimo: 0.3,
          children: [
            if (!enViaje) ...[
              _BotonConexion(
                enLinea: estado.enLinea,
                onTap: () async {
                  // Antes de conectarse: ubicación y, la primera vez, N03.
                  if (!estado.enLinea &&
                      !await prepararConexion(context, ref)) {
                    return;
                  }
                  await ctrl.alternarLinea();
                },
              ),
              const SizedBox(height: Sp.md),
              Text(
                estado.enLinea ? l.buscandoSolicitudes : l.estasFueraDeLinea,
                textAlign: TextAlign.center,
                style: context.textos.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (estado.enLinea)
                Text(
                  l.estasEnLinea,
                  textAlign: TextAlign.center,
                  style: context.textos.bodySmall?.copyWith(
                    color: context.muted,
                  ),
                ),
              const SizedBox(height: Sp.lg),
            ],
            const NivelBanner(rutaNiveles: '/c/niveles', irEnLugar: true),
            const SizedBox(height: Sp.md),
            if (estado.pasajeroCancelo) ...[
              NexaCard(
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: Sp.md),
                    Expanded(child: Text(l.pasajeroCancelo)),
                    TextButton(
                      onPressed: ctrl.descartarAvisoCancelacion,
                      child: Text(l.listo),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.md),
            ],
            if (estado.terminado != null)
              ResumenViajeCard(
                servicio: estado.terminado!,
                desglose: estado.desgloseTerminado,
                onCerrar: ctrl.cerrarResumen,
              )
            else if (estado.activo != null)
              ViajeActivoCard(
                servicio: estado.activo!,
                fase: estado.fase,
                posicion: estado.posicion,
                pasajero: estado.pasajero,
              )
            else ...[
              Text(
                l.solicitudesEntrantes,
                style: context.textos.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Sp.sm),
              if (!estado.enLinea || estado.solicitudes.isEmpty)
                SizedBox(
                  height: 160,
                  child: EstadoVacio(
                    titulo: l.sinSolicitudes,
                    icon: Icons.notifications_none,
                  ),
                )
              else
                for (final s in estado.solicitudes) ...[
                  SolicitudCard(servicio: s),
                  const SizedBox(height: Sp.sm),
                ],
            ],
          ],
        ),
      ],
    );
  }
}

/// «En línea» / «Fuera de línea» flotando sobre el mapa.
class _EstadoFlotante extends StatelessWidget {
  const _EstadoFlotante({required this.enLinea});
  final bool enLinea;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NexaColors.glass,
        borderRadius: BorderRadius.circular(Rad.pill),
        border: Border.all(color: NexaColors.cyan.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Sp.lg - 2,
          vertical: Sp.sm + 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enLinea ? NexaColors.ok : context.muted,
                boxShadow: enLinea
                    ? [
                        BoxShadow(
                          color: NexaColors.ok.withValues(alpha: 0.8),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: Sp.sm),
            Flexible(
              child: Text(
                enLinea ? l.enLinea : l.fueraDeLinea,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textos.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón grande para conectarse o desconectarse.
class _BotonConexion extends StatelessWidget {
  const _BotonConexion({required this.enLinea, required this.onTap});
  final bool enLinea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Semantics(
        button: true,
        toggled: enLinea,
        label: enLinea ? l.desconectarme : l.conectarme,
        child: ExcludeSemantics(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enLinea ? NexaColors.cyan : NexaColors.raised,
                border: Border.all(
                  color: NexaColors.cyan.withValues(alpha: enLinea ? 0 : 0.45),
                  width: 2,
                ),
                boxShadow: enLinea
                    ? [
                        BoxShadow(
                          color: NexaColors.cyan.withValues(alpha: 0.2),
                          blurRadius: 0,
                          spreadRadius: 8,
                        ),
                        ...NexaShadows.glow,
                      ]
                    : null,
              ),
              child: Icon(
                Icons.power_settings_new,
                size: 38,
                color: enLinea ? NexaColors.bg : NexaColors.cyan,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
