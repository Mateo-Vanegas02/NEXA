import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/rumbo/orientacion_mapa.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/mapa/polyline.dart';
import '../../../../core/mapa/reglas_marcadores.dart';
import '../../../../core/widgets/mapa_nexa.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../../../core/utils/mi_posicion.dart';
import '../../../niveles/presentation/widgets/nivel_banner.dart';
import '../../domain/opcion_ruta.dart';
import '../../domain/zonas_documentos.dart';
import '../../domain/servicio.dart';
import '../../../../core/sin_conexion/reglas_sin_conexion.dart';
import '../controllers/avisos_push_controller.dart';
import '../controllers/sin_conexion_controller.dart';
import '../controllers/viaje_conductor_controller.dart';
import '../widgets/cuenta_bloqueada.dart';
import '../widgets/navegacion_conductor.dart';
import '../controllers/zonas_documentos_controller.dart';
import '../widgets/panel_turno.dart';
import '../widgets/solicitud_entrante.dart';
import '../widgets/rutas_desvio.dart';
import '../widgets/solicitud_card.dart';
import '../widgets/viaje_activo_card.dart';
import '../../../permisos/presentation/con_ubicacion.dart';
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
    // Al tomar un viaje, el mapa pasa solo a navegación (rediseño 2026: el
    // conductor no tiene que tocar «Navegar»); puede salir cuando quiera.
    ref.listen(conductorProvider.select((e) => e.value?.activo?.id), (
      antes,
      ahora,
    ) {
      if (ahora != null && ahora != antes) {
        ref
            .read(orientacionMapaProvider.notifier)
            .cambiarModo(ModoOrientacion.navegacion);
      }
    });
    // Un paso hecho sin señal que el servidor ya no aceptó: gana el servidor.
    ref.listen(sinConexionProvider.select((e) => e.rechazo), (_, rechazo) {
      if (rechazo == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rechazo), duration: const Duration(seconds: 8)),
      );
      ref.read(sinConexionProvider.notifier).descartarRechazo();
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
    final vistas = ref.watch(solicitudesVistasProvider);
    final entrante = activo == null && estado.terminado == null
        ? estado.solicitudes.where((s) => !vistas.contains(s.id)).firstOrNull
        : null;
    // Su propia moto sale del GPS del teléfono apenas llega cada dato (1 por
    // segundo en viaje), sin esperar al servidor. Quieto, el GPS no manda
    // datos nuevos: se conserva el último para que la moto no desaparezca.
    final enVivo = ref.watch(posicionEnVivoProvider).value;
    final moto = ReglasMarcadores.motoPropia(
      activo: estado.enLinea || activo != null,
      gps: enVivo?.punto,
      gpsEn: enVivo?.en,
      servidor: pos == null ? null : LatLng(pos.latitud, pos.longitud),
      ahora: DateTime.now(),
    );
    // Zoom de navegación según la velocidad: solo con un dato reciente (con
    // uno viejo la cámara quedaría alejada aunque la moto esté detenida).
    final velocidadKmh =
        enVivo?.velocidad != null &&
            DateTime.now().difference(enVivo!.en) <
                ReglasMarcadores.gpsFrescoPor
        ? enVivo.velocidad! * 3.6
        : null;
    // Rutas: las que ofrece el servidor al desviarse (la sugerida resaltada),
    // la elegida o la del viaje.
    final opciones = estado.desvio == EstadoDesvio.opciones
        ? estado.rutasOfrecidas
        : const <OpcionRuta>[];
    final rutaVigente = estado.rutaVigente;
    final rutaMapa = opciones.isNotEmpty
        ? rutaDe(opciones.first.geometria)
        : (rutaVigente ?? rutaDe(activo?.rutaGeometria));
    final conRutaRecogida =
        estado.fase == FaseConductor.aRecoger && rutaVigente != null;
    // Modo navegación: solo en línea o con un viaje (lo enciende el conductor).
    final puedeNavegar = estado.enLinea || activo != null;
    final modoMapa = ref.watch(orientacionMapaProvider.select((o) => o.modo));
    final navegando = puedeNavegar && modoMapa == ModoOrientacion.navegacion;
    if (!puedeNavegar && modoMapa == ModoOrientacion.navegacion) {
      // Se desconectó o terminó el viaje: vuelve el norte arriba.
      Future.microtask(
        () => ref
            .read(orientacionMapaProvider.notifier)
            .cambiarModo(ModoOrientacion.norte),
      );
    }
    return Stack(
      children: [
        // Sin viaje ni moto en vivo, el mapa espera la ubicación real (nada de
        // abrir en el centro de la ciudad y saltar después).
        Positioned.fill(
          child: ConUbicacion(
            omitir: moto != null || activo != null,
            child: MapaNexa(
            centro: moto ?? recogida,
            // Sin viaje no hay recogida: solo su moto (antes salía un pin viejo).
            origen: activo == null ? null : recogida,
            destino: destino,
            ruta: rutaMapa,
            alternativas: [
              for (final o in opciones.skip(1)) rutaDe(o.geometria),
            ],
            progreso: rutaVigente != null && opciones.isEmpty,
            // Fuera de línea su moto queda donde dice el GPS del teléfono, para
            // ubicarse apenas entra (antes solo aparecía al conectarse).
            conductor:
                moto ??
                (activo == null && centro != kCentroPorDefecto ? centro : null),
            motoPropia: true,
            velocidadKmh: velocidadKmh,
            pasajero: estado.pasajero == null
                ? null
                : LatLng(estado.pasajero!.latitud, estado.pasajero!.longitud),
            pasajeroPropio: false,
            pasajeroSinSenal:
                estado.pasajero != null &&
                ReglasMarcadores.sinSenal(estado.pasajero!.haceSegundos),
            orientable: true,
            navegacion: navegando,
            // En línea y sin viaje: dónde se está pidiendo más (rediseño 2026).
            zonas: estado.enLinea && activo == null
                ? [
                    for (final z
                        in ref.watch(zonasDemandaProvider).value ??
                            const <ZonaDemanda>[])
                      (LatLng(z.latitud, z.longitud), z.intensidad),
                  ]
                : const [],
          ),
          ),
        ),
        if (puedeNavegar)
          SafeArea(
            child: Padding(
              // Debajo de la brújula y del botón de capas del mapa.
              padding: const EdgeInsets.only(
                top: Sp.md + (Sizes.touch + 4 + Sp.sm) * 2,
                right: Sp.md,
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _BotonNavegar(activo: navegando),
                    if (activo != null &&
                        estado.fase != FaseConductor.enElPunto) ...[
                      const SizedBox(height: Sp.sm),
                      _BotonRutas(onTap: ctrl.pedirRutas),
                    ],
                  ],
                ),
              ),
            ),
          ),
        if (activo != null && estado.desvio != EstadoDesvio.ninguno)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Sp.md,
                Sp.md,
                Sizes.touch + Sp.md + Sp.sm,
                0,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: TarjetaDesvio(estado: estado),
              ),
            ),
          )
        else if (navegando &&
            activo != null &&
            moto != null &&
            (estado.fase ?? FaseConductor.aRecoger) != FaseConductor.enElPunto)
          SafeArea(
            child: Padding(
              // A la derecha quedan la brújula y «Navegar».
              padding: const EdgeInsets.fromLTRB(
                Sp.md,
                Sp.md,
                Sizes.touch + Sp.md + Sp.sm,
                0,
              ),
              child: NavegacionConductor(
                fase: estado.fase ?? FaseConductor.aRecoger,
                moto: moto,
                ruta: rutaVigente ?? rutaDe(activo.rutaGeometria),
                conRutaRecogida: conRutaRecogida,
                pasos: estado.pasosVigentes,
                recogida: recogida,
                destino: activo.destino,
                pasajero: activo.pasajero?.nombre ?? '',
                restanteKm: pos?.distanciaRestanteKm,
              ),
            ),
          )
        else
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Sp.md),
              child: Align(
                alignment: Alignment.topLeft,
                // Solo muestra el estado: conectarse es deslizar en la hoja y
                // desconectarse, «Desconectarme» (una sola forma de cada uno).
                child: _EstadoFlotante(enLinea: estado.enLinea),
              ),
            ),
          ),
        if (activo != null &&
            estado.fase != FaseConductor.enElPunto &&
            estado.desvio == EstadoDesvio.ninguno)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: Sp.md),
              child: VelocimetroGps(
                movimiento: ref.read(rastreadorProvider).movimiento,
              ),
            ),
          ),
        // Con un viaje, la hoja deja ver el mapa (en el video del conductor la
        // hoja tapaba la recogida); el resumen final sí ocupa más.
        NexaHojaArrastrable(
          inicial: estado.terminado != null
              ? 0.62
              : (activo != null ? 0.36 : 0.5),
          minimo: activo != null ? 0.2 : 0.3,
          children: [
            // Sin viaje (rediseño 2026): fuera de línea, deslizar para
            // conectarse y lo ganado; en línea, lo ganado hoy y el GPS.
            if (!enViaje) ...[
              if (estado.enLinea)
                PanelEnLinea(onDesconectar: ctrl.alternarLinea)
              else
                PanelFueraDeLinea(
                  onConectar: () async {
                    if (!await prepararConexion(context, ref)) return;
                    await ctrl.alternarLinea();
                  },
                ),
              const SizedBox(height: Sp.lg),
            ],
            const NivelBanner(rutaNiveles: '/c/niveles', irEnLugar: true),
            const SizedBox(height: Sp.md),
            if (estado.pasajeroCancelo && estado.terminado == null) ...[
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
            if (estado.copiaDe != null && estado.activo != null) ...[
              NexaCard(
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off),
                    const SizedBox(width: Sp.md),
                    Expanded(child: Text(l.copiaDelViaje)),
                  ],
                ),
              ),
              const SizedBox(height: Sp.md),
            ],
            if (estado.terminado != null &&
                ref
                    .watch(sinConexionProvider)
                    .tienePendiente(
                      estado.terminado!.id,
                      TipoPendiente.finalizar,
                    )) ...[
              NexaCard(
                child: Row(
                  children: [
                    const Icon(Icons.cloud_upload_outlined),
                    const SizedBox(width: Sp.md),
                    Expanded(child: Text(l.finalPendienteTexto)),
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
                for (final s in estado.solicitudes)
                  if (s.id != entrante?.id) ...[
                    SolicitudCard(servicio: s),
                    const SizedBox(height: Sp.sm),
                  ],
            ],
          ],
        ),
        // Una solicitud nueva ocupa la pantalla (rediseño 2026) hasta que la
        // acepta o la manda a la lista con «Ver en el mapa».
        if (entrante != null)
          SolicitudEntrante(
            servicio: entrante,
            pendientes: [for (final s in estado.solicitudes) s.id],
          ),
      ],
    );
  }
}

/// «En línea» con su interruptor, flotando sobre el mapa (diseño C01).
class _EstadoFlotante extends StatelessWidget {
  const _EstadoFlotante({required this.enLinea});
  final bool enLinea;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = enLinea ? NexaColors.ok : NexaColors.muted;
    return Semantics(
      liveRegion: true,
      label: enLinea ? l.enLinea : l.fueraDeLinea,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: NexaColors.glass,
            shape: StadiumBorder(
              side: BorderSide(color: color.withValues(alpha: 0.5)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.lg,
              vertical: Sp.sm + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: enLinea ? NexaShadows.glow : null,
                  ),
                ),
                const SizedBox(width: Sp.sm),
                Flexible(
                  child: Text(
                    enLinea ? l.enLinea : l.fueraDeLinea,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Enciende o apaga el modo navegación: el mapa sigue a la moto y gira con su
/// avance (GPS en marcha; brújula detenido).
class _BotonNavegar extends ConsumerWidget {
  const _BotonNavegar({required this.activo});
  final bool activo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      toggled: activo,
      child: Material(
        color: activo ? NexaColors.cyan : NexaColors.glass,
        borderRadius: BorderRadius.circular(Rad.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(Rad.pill),
          onTap: () => ref
              .read(orientacionMapaProvider.notifier)
              .cambiarModo(
                activo ? ModoOrientacion.norte : ModoOrientacion.navegacion,
              ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.touch),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.lg),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    activo ? Icons.close : Icons.navigation,
                    color: activo ? NexaColors.bg : NexaColors.texto,
                    size: 20,
                  ),
                  const SizedBox(width: Sp.sm),
                  Text(
                    activo ? l.navegacionSalir : l.navegacionActivar,
                    style: TextStyle(
                      color: activo ? NexaColors.bg : NexaColors.texto,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pide rutas desde donde va (también salen solas al desviarse).
class _BotonRutas extends StatelessWidget {
  const _BotonRutas({required this.onTap});
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      child: Material(
        color: NexaColors.glass,
        shape: const StadiumBorder(side: BorderSide(color: NexaColors.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.touch),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.lg),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.alt_route,
                    color: NexaColors.texto,
                    size: 20,
                  ),
                  const SizedBox(width: Sp.sm),
                  Text(
                    l.rutasBoton,
                    style: const TextStyle(
                      color: NexaColors.texto,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
