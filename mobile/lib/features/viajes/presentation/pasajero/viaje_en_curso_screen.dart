import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/acciones_externas.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/mapa/polyline.dart';
import '../../../../core/widgets/mapa_nexa.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_popup.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/estimado_tarifa.dart';
import '../../domain/servicio.dart';
import '../controllers/viaje_pasajero_controller.dart';
import '../widgets/conductor_card.dart';
import '../widgets/pasos_viaje.dart';

/// Seguimiento del viaje sobre el mapa. Con la solicitud abierta: búsqueda de
/// conductor y extra voluntario. Con el viaje aceptado o en curso: minutos de
/// llegada en grande, conductor, acciones, destino y precio, y asistencia (SOS).
class ViajeEnCursoScreen extends ConsumerWidget {
  const ViajeEnCursoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // Al terminar pasamos a calificar; si se cancela, volvemos al inicio.
    ref.listen(viajePasajeroProvider, (anterior, actual) {
      final s = actual.value;
      if (s == null) return;
      if (s.estado == EstadoServicio.finalizado) {
        context.pushReplacement('/p/calificar');
      }
    });
    final viaje = ref.watch(viajePasajeroProvider);
    return Scaffold(
      body: viaje.when(
        loading: () => const SafeArea(child: CargandoSkeleton()),
        error: (e, _) => SafeArea(
          child: EstadoError(
            mensaje: AppException.from(e).mensaje,
            onReintentar: () => ref.invalidate(viajePasajeroProvider),
          ),
        ),
        data: (s) => s == null
            ? SafeArea(
                child: EstadoVacio(
                  titulo: l.vacioHistorial,
                  icon: Icons.two_wheeler,
                ),
              )
            : _Seguimiento(servicio: s),
      ),
    );
  }
}

class _Seguimiento extends ConsumerWidget {
  const _Seguimiento({required this.servicio});
  final Servicio servicio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = servicio;
    final origen = s.ubicacionOrigen == null
        ? kCentroPorDefecto
        : LatLng(s.ubicacionOrigen!.latitud, s.ubicacionOrigen!.longitud);
    final destino = s.ubicacionDestino == null
        ? null
        : LatLng(s.ubicacionDestino!.latitud, s.ubicacionDestino!.longitud);
    // Posición, distancia y ETA reales del conductor (los calcula el servidor).
    final pos = ref.watch(posicionConductorProvider);
    final total = s.duracionEstimadaMin > 0
        ? s.duracionEstimadaMin.ceil()
        : minutosEstimados(s.distanciaKM);
    final restantes = !s.estado.activo
        ? 0
        : pos != null && pos.etaMinutos > 0
        ? pos.etaMinutos
        : total;
    final llegada = DateFormat(
      'h:mm a',
      'es_CO',
    ).format(DateTime.now().add(Duration(minutes: restantes)));
    final titulo = switch (s.estado) {
      EstadoServicio.solicitado => l.buscandoConductor,
      EstadoServicio.aceptado => l.conductorEnCamino,
      EstadoServicio.cancelado => l.viajeCancelado,
      _ => l.viajeEnCursoTitulo,
    };
    final enMarcha =
        s.estado == EstadoServicio.aceptado ||
        s.estado == EstadoServicio.enCurso;
    return Stack(
      children: [
        Positioned.fill(
          child: MapaNexa(
            centro: origen,
            origen: origen,
            destino: destino,
            ruta: rutaDe(s.rutaGeometria),
            conductor: pos == null ? null : LatLng(pos.latitud, pos.longitud),
            pasajero: s.estado == EstadoServicio.aceptado
                ? ref.watch(miUbicacionViajeProvider)
                : null,
            orientable: true,
            // Debajo del botón SOS.
            brujulaArriba: enMarcha ? Sp.md + Sizes.boton + Sp.sm : Sp.md,
          ),
        ),
        if (enMarcha)
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(Sp.md),
              child: Align(alignment: Alignment.topRight, child: _BotonSos()),
            ),
          ),
        NexaHojaArrastrable(
          inicial: s.estado == EstadoServicio.solicitado ? 0.6 : 0.55,
          minimo: 0.3,
          children: [
            if (s.estado == EstadoServicio.solicitado) ...[
              Text(
                titulo,
                style: context.textos.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Sp.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(Rad.pill),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  color: NexaColors.cyan,
                  backgroundColor: NexaColors.raised,
                  semanticsLabel: l.buscandoConductor,
                ),
              ),
              const SizedBox(height: Sp.lg + 2),
              _ExtraVoluntario(servicio: s),
              const SizedBox(height: Sp.md),
              _DestinoPrecio(servicio: s),
              const SizedBox(height: Sp.sm),
              const _BotonCancelar(),
            ] else if (s.estado == EstadoServicio.cancelado) ...[
              Text(
                titulo,
                style: context.textos.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Sp.lg),
              _DestinoPrecio(servicio: s),
              const SizedBox(height: Sp.lg),
              NexaButton(
                label: l.continuar,
                onPressed: () {
                  ref.read(viajePasajeroProvider.notifier).cerrar();
                  context.go('/p/inicio');
                },
              ),
            ] else ...[
              _Llegada(
                titulo: titulo,
                minutos: restantes,
                llegada: llegada,
                estado: s.estado,
              ),
              const SizedBox(height: Sp.md),
              PasosViaje(estado: s.estado),
              if (s.conductor != null) ...[
                const SizedBox(height: Sp.lg),
                ConductorCard(conductor: s.conductor!),
              ],
              const SizedBox(height: Sp.lg),
              _Acciones(servicio: s),
              const SizedBox(height: Sp.lg),
              _DestinoPrecio(servicio: s),
              if (s.estado == EstadoServicio.aceptado) ...[
                const SizedBox(height: Sp.sm),
                const _BotonCancelar(),
              ],
            ],
          ],
        ),
      ],
    );
  }
}

/// Minutos de llegada en grande, hora estimada y estado del viaje.
class _Llegada extends StatelessWidget {
  const _Llegada({
    required this.titulo,
    required this.minutos,
    required this.llegada,
    required this.estado,
  });

  final String titulo;
  final int minutos;
  final String llegada;
  final EstadoServicio estado;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.textos;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: t.bodyMedium?.copyWith(
                  color: context.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (minutos > 0)
                Text(
                  l.minutosValor(minutos),
                  style: t.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              Text(
                l.llegadaEstimada(llegada),
                style: t.bodySmall?.copyWith(color: context.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: Sp.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.md,
            vertical: Sp.xs + 2,
          ),
          decoration: BoxDecoration(
            color: NexaColors.ok.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(Rad.pill),
          ),
          child: Text(
            estado == EstadoServicio.aceptado
                ? l.paso_aceptado
                : l.paso_en_curso,
            style: const TextStyle(
              color: NexaColors.ok,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _DestinoPrecio extends StatelessWidget {
  const _DestinoPrecio({required this.servicio});
  final Servicio servicio;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.textos;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NexaColors.card,
        borderRadius: BorderRadius.circular(Rad.lg),
        border: Border.all(color: NexaColors.cyan.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg - 2),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: Sp.md),
              decoration: BoxDecoration(
                color: NexaColors.cyan,
                borderRadius: BorderRadius.circular(4),
                boxShadow: NexaShadows.glow,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.destino,
                    style: t.bodySmall?.copyWith(color: context.muted),
                  ),
                  Text(
                    servicio.destino,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Sp.sm),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Fmt.cop(servicio.tarifa + servicio.extraVoluntario),
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (servicio.extraVoluntario > 0)
                    Text(
                      '${l.extraVoluntario}: ${Fmt.cop(servicio.extraVoluntario)}',
                      style: t.bodySmall?.copyWith(color: context.muted),
                    ),
                  Text(switch (servicio.metodoPago) {
                    'tarjeta' => l.metodoTarjeta,
                    'billetera' => l.metodoBilletera,
                    _ => l.efectivo,
                  }, style: t.bodySmall?.copyWith(color: context.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opciones de extra voluntario mientras se busca conductor. El tope por viaje lo
/// pone el servidor (responde 409 si se pasa); aquí solo se muestra lo ofrecido.
class _ExtraVoluntario extends ConsumerStatefulWidget {
  const _ExtraVoluntario({required this.servicio});
  final Servicio servicio;

  @override
  ConsumerState<_ExtraVoluntario> createState() => _ExtraVoluntarioState();
}

class _ExtraVoluntarioState extends ConsumerState<_ExtraVoluntario> {
  static const _opciones = [500, 1000, 2000];
  bool _enviando = false;

  Future<void> _subir(int incremento) async {
    final mensajes = ScaffoldMessenger.of(context);
    setState(() => _enviando = true);
    try {
      await ref.read(viajePasajeroProvider.notifier).subirExtra(incremento);
    } on Object catch (e) {
      mensajes
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(AppException.from(e).mensaje)));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = widget.servicio;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NexaColors.card,
        borderRadius: BorderRadius.circular(Rad.lg),
        border: Border.all(color: NexaColors.cyan.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.extraTitulo,
              style: context.textos.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: Sp.xs),
            Text(
              l.extraTexto,
              style: context.textos.bodySmall?.copyWith(color: context.muted),
            ),
            const SizedBox(height: Sp.md),
            Wrap(
              spacing: Sp.sm,
              runSpacing: Sp.sm,
              children: [
                for (final v in _opciones)
                  ActionChip(
                    label: Text('+${Fmt.cop(v.toDouble())}'),
                    onPressed: _enviando ? null : () => _subir(v),
                  ),
              ],
            ),
            const SizedBox(height: Sp.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.ofertaAhora,
                    style: context.textos.bodySmall?.copyWith(
                      color: context.muted,
                    ),
                  ),
                ),
                Text(
                  Fmt.cop(s.tarifa + s.extraVoluntario),
                  style: context.textos.titleSmall?.copyWith(
                    color: NexaColors.cyan,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Acciones extends ConsumerWidget {
  const _Acciones({required this.servicio});
  final Servicio servicio;

  Future<void> _conTelefono(
    BuildContext context,
    Future<bool> Function(String) accion,
  ) async {
    final l = AppLocalizations.of(context);
    final tel = servicio.conductor?.telefono;
    final messenger = ScaffoldMessenger.of(context);
    if (tel == null) {
      messenger.showSnackBar(SnackBar(content: Text(l.noDisponible)));
      return;
    }
    final ok = await accion(tel);
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(l.noDisponible)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final acciones = ref.read(accionesExternasProvider);
    return Row(
      children: [
        Expanded(
          child: _Accion(
            icono: Icons.phone_outlined,
            etiqueta: l.llamar,
            onTap: () => _conTelefono(context, acciones.llamar),
          ),
        ),
        Expanded(
          child: _Accion(
            icono: Icons.chat_bubble_outline,
            etiqueta: l.mensaje,
            onTap: () => _conTelefono(context, acciones.enviarSms),
          ),
        ),
        Expanded(
          child: _Accion(
            icono: Icons.share_outlined,
            etiqueta: l.compartir,
            onTap: () => acciones.compartir(
              l.compartirTexto(
                servicio.destino,
                servicio.conductor?.nombre ?? l.tuConductor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Acción redonda con su etiqueta debajo (llamar, mensaje, compartir).
class _Accion extends StatelessWidget {
  const _Accion({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: etiqueta,
    child: ExcludeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(Rad.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.xs,
            vertical: Sp.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: NexaColors.raised,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: NexaColors.cyan.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(icono, color: context.acento),
              ),
              const SizedBox(height: Sp.xs + 2),
              Text(
                etiqueta,
                style: context.textos.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Cancelar el viaje: texto discreto (para evitar toques accidentales) con
/// confirmación.
class _BotonCancelar extends ConsumerWidget {
  const _BotonCancelar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(Sizes.touch),
        foregroundColor: context.colors.error,
      ),
      onPressed: () async {
        final router = GoRouter.of(context);
        final notifier = ref.read(viajePasajeroProvider.notifier);
        final confirmar = await mostrarNexaPopup<bool>(
          context,
          titulo: l.cancelarViajeTitulo,
          mensaje: l.cancelarViajeTexto,
          tipo: NexaPopupTipo.peligro,
          acciones: [
            NexaPopupAccion(
              etiqueta: l.cancelarViaje,
              valor: true,
              peligro: true,
            ),
            NexaPopupAccion(etiqueta: l.mantenerViaje, valor: false),
          ],
        );
        if (confirmar ?? false) {
          await notifier.cancelar();
          router.go('/p/inicio');
        }
      },
      child: Text(l.cancelarViaje),
    );
  }
}

/// Asistencia en ruta: botón flotante sobre el mapa que ofrece llamar a emergencias.
class _BotonSos extends ConsumerWidget {
  const _BotonSos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return IconButton(
      tooltip: l.asistenciaRuta,
      onPressed: () async {
        final llamar = await mostrarNexaPopup<bool>(
          context,
          titulo: l.sosTitulo,
          mensaje: l.sosTexto,
          tipo: NexaPopupTipo.alerta,
          acciones: [
            NexaPopupAccion(
              etiqueta: '${l.llamar} $kLineaEmergencias',
              valor: true,
              peligro: true,
            ),
            NexaPopupAccion(etiqueta: l.cancelar, valor: false),
          ],
        );
        if (llamar ?? false) {
          await ref.read(accionesExternasProvider).llamar(kLineaEmergencias);
        }
      },
      icon: const Icon(Icons.shield_outlined, color: NexaColors.cyan),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(Sizes.touch),
        backgroundColor: NexaColors.glass,
        side: BorderSide(color: NexaColors.cyan.withValues(alpha: 0.45)),
      ),
    );
  }
}
