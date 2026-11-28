import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/mapa/reglas_marcadores.dart';
import '../../../../core/mapa/reglas_ruta.dart';
import '../../../../core/rumbo/orientacion_mapa.dart';
import '../../../../core/utils/acciones_externas.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/mi_posicion.dart';
import '../../../../core/mapa/polyline.dart';
import '../../../../core/widgets/mapa_nexa.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_popup.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/servicio.dart';
import '../controllers/viaje_pasajero_controller.dart';
import '../widgets/conductor_card.dart';
import '../widgets/hoja_sos.dart';
import '../widgets/piezas_viaje.dart';
import '../widgets/radar_olas.dart';

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
    final moto = pos == null ? null : LatLng(pos.latitud, pos.longitud);
    // Su propio punto sale del GPS apenas llega (cada 2 s mientras la moto
    // viene); si no hay dato reciente, el último que se envió al servidor.
    final enVivo = ref.watch(posicionEnVivoProvider).value;
    final yoVivo =
        enVivo != null &&
            DateTime.now().difference(enVivo.en) < const Duration(seconds: 8)
        ? enVivo.punto
        : null;
    final yo = s.estado == EstadoServicio.aceptado
        ? (yoVivo ?? ref.watch(miUbicacionViajeProvider))
        : null;
    // Al iniciar el viaje todavía puede estar en memoria la posición de recogida.
    final seguimiento = pos?.fase == s.estado.codigo ? pos : null;
    final restantes = seguimiento?.etaMinutos;
    final kmRestantes = seguimiento?.distanciaRestanteKm;
    final llegada = restantes == null
        ? null
        : DateFormat(
            'H:mm',
            'es_CO',
          ).format(DateTime.now().add(Duration(minutes: restantes)));
    final enElPunto =
        s.estado == EstadoServicio.aceptado && s.fechaLlegada != null;
    final nombre = (s.conductor?.nombre ?? l.tuConductor).split(' ').first;
    // El conductor tomó otra calle y eligió una ruta nueva (rediseño 2026).
    ref.listen(rutaCambiadaProvider, (antes, ahora) {
      if (ahora <= (antes ?? 0)) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l.rutaCambiadaTitulo(nombre)} · ${l.rutaCambiadaTexto}',
          ),
        ),
      );
    });
    final anteriorGeo = ref.watch(rutaAnteriorProvider);
    final rutaAnterior = anteriorGeo == null
        ? null
        : decodificarPolyline(anteriorGeo);
    // La cámara sigue a la moto con lo que importa en cada fase: viniendo por
    // ti, tú y la moto; en viaje, la moto y el destino.
    final List<LatLng>? encuadre = moto == null
        ? null
        : switch (s.estado) {
            EstadoServicio.aceptado => [moto, yo ?? origen],
            EstadoServicio.enCurso => [moto, ?destino],
            _ => null,
          };
    final fases = [
      l.faseAceptado,
      l.faseEnCamino,
      l.faseEnElPunto,
      l.faseEnViaje,
    ];
    final fase = switch (s.estado) {
      EstadoServicio.enCurso || EstadoServicio.finalizado => 3,
      EstadoServicio.aceptado when enElPunto => 2,
      _ => 1,
    };

    // Dónde queda la moto según hacia dónde apunta el teléfono (diseño M02).
    final rumbo = ref.watch(orientacionMapaProvider.select((o) => o.rumbo));
    String? lado;
    if (yo != null && moto != null && rumbo != null && !enElPunto) {
      lado = switch (ReglasMarcadores.ladoRelativo(
        rumboTelefono: rumbo,
        haciaObjetivo: ReglasMarcadores.rumboEntre(yo, moto),
      )) {
        LadoRelativo.deFrente => l.ladoDeFrente,
        LadoRelativo.derecha => l.ladoDerecha,
        LadoRelativo.izquierda => l.ladoIzquierda,
        LadoRelativo.detras => l.ladoDetras,
      };
    }

    // Ola del despacho (la calcula el servidor; P04 y E03).
    final despacho = s.estado == EstadoServicio.solicitado
        ? ref.watch(ofertaActivaProvider)?.despacho
        : null;
    final topeExtra = ref.watch(ofertaActivaProvider)?.topeExtra;
    final kmFmt = NumberFormat('0.#', 'es_CO');
    // La ola a escala real alrededor de la recogida (propuesta «Estela»): el
    // radio lo decide el servidor; la app solo lo dibuja y lo encuadra.
    final ola = despacho?.radioKm == null || s.ubicacionOrigen == null
        ? null
        : (
            centro: origen,
            metros: despacho!.radioKm! * 1000,
            activa: !despacho.ultima,
          );
    final buscando = s.estado == EstadoServicio.solicitado;
    final Widget? arriba = switch (s.estado) {
      EstadoServicio.solicitado when despacho != null => Align(
        alignment: Alignment.topCenter,
        child: PildoraEstado(
          icono: Icons.waves,
          color: despacho.ultima ? NexaColors.muted : NexaColors.cyan,
          texto: despacho.radioKm == null
              ? l.olaDe(despacho.ola, despacho.totalOlas)
              : l.olaDeRadio(
                  despacho.ola,
                  despacho.totalOlas,
                  kmFmt.format(despacho.radioKm),
                ),
        ),
      ),
      EstadoServicio.aceptado when enElPunto => Align(
        alignment: Alignment.topCenter,
        child: PildoraEstado(texto: l.estaEnTuPunto(nombre)),
      ),
      EstadoServicio.aceptado => TarjetaFlotante(
        icono: Icons.timer_outlined,
        titulo: restantes == null
            ? l.llegadaPendiente
            : l.llegaEnMin(restantes),
        detalle: lado ?? l.vaHaciaTuPunto(nombre),
        colorDetalle: lado == null ? null : NexaColors.cyan,
      ),
      // En viaje, lo importante arriba: hora de llegada, minutos, km que
      // faltan y una barra con lo recorrido (rediseño 2026; todo del servidor).
      EstadoServicio.enCurso when restantes != null && llegada != null =>
        TarjetaLlegada(
          destino: s.destino,
          hora: llegada,
          minutos: restantes,
          kmRestantes: kmRestantes,
          avance: s.distanciaKM > 0 && kmRestantes != null
              ? (1 - kmRestantes / s.distanciaKM).clamp(0.0, 1.0)
              : null,
        ),
      EstadoServicio.enCurso => TarjetaFlotante(
        icono: Icons.route,
        titulo: l.llegasA(s.destino),
        detalle: l.llegadaPendiente,
      ),
      _ => null,
    };

    return Stack(
      children: [
        Positioned.fill(
          child: MapaNexa(
            centro: origen,
            origen: origen,
            destino: destino,
            ruta: rutaDe(s.rutaGeometria),
            conductor: moto,
            pasajero: yo,
            orientable: true,
            progreso: s.estado == EstadoServicio.enCurso,
            rutaAnterior: s.estado == EstadoServicio.enCurso
                ? rutaAnterior
                : null,
            tiempoEnRuta:
                s.estado == EstadoServicio.enCurso && restantes != null
                ? l.minutosValor(restantes)
                : null,
            etiquetaDestino: s.estado == EstadoServicio.enCurso
                ? [s.destino, ?llegada].join(' · ')
                : null,
            // Buscando: la cámara muestra la ola completa sobre la hoja.
            encuadre: ola == null
                ? encuadre
                : ReglasRuta.circulo(ola.centro, ola.metros, lados: 8),
            ola: ola,
            margenInferior:
                MediaQuery.sizeOf(context).height * (buscando ? 0.46 : 0.48),
          ),
        ),
        if (arriba != null)
          SafeArea(
            child: Padding(
              // A la derecha queda la brújula.
              padding: const EdgeInsets.fromLTRB(
                Sp.lg,
                Sp.md,
                Sizes.touch + Sp.md + Sp.sm,
                0,
              ),
              child: Align(alignment: Alignment.topLeft, child: arriba),
            ),
          ),
        // Buscando, la hoja deja ver la ola en el mapa (antes ocupaba el 62 %).
        NexaHojaArrastrable(
          inicial: buscando ? 0.44 : 0.46,
          minimo: 0.3,
          children: [
            if (s.estado == EstadoServicio.solicitado) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          despacho?.ultima ?? false
                              ? l.nadieAcepto
                              : l.buscandoTuConductor,
                          style: NexaTexto.titulo,
                        ),
                        const SizedBox(height: Sp.sm),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            despacho == null
                                ? l.buscandoTexto
                                : despacho.ultima
                                ? l.nadieAceptoTexto(
                                    despacho.conductoresAvisados,
                                    kmFmt.format(despacho.radioKm ?? 0),
                                  )
                                : l.avisamosA(despacho.conductoresAvisados),
                            style: NexaTexto.cuerpo.copyWith(
                              color: NexaColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Radar de olas: un aro por ola, hasta la que va.
                  if (despacho != null) ...[
                    const SizedBox(width: Sp.md),
                    RadarOlas(
                      ola: despacho.ola,
                      total: despacho.totalOlas,
                      buscando: !despacho.ultima,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: Sp.lg),
              if (despacho != null)
                _BarraOlas(ola: despacho.ola, total: despacho.totalOlas)
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(Rad.pill),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    color: NexaColors.cyan,
                    backgroundColor: NexaColors.line,
                    semanticsLabel: l.buscandoConductor,
                  ),
                ),
              const SizedBox(height: Sp.xl),
              _ExtraVoluntario(servicio: s, tope: topeExtra),
              const SizedBox(height: Sp.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.totalConExtra,
                      style: NexaTexto.cuerpo.copyWith(color: NexaColors.muted),
                    ),
                  ),
                  Text(
                    Fmt.cop(s.tarifa + s.extraVoluntario),
                    style: NexaTexto.numeroMedio.copyWith(fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: Sp.lg),
              _BotonCancelar(
                solicitud: true,
                sinCargo: despacho?.ultima ?? false,
              ),
            ] else if (s.estado == EstadoServicio.cancelado) ...[
              Text(l.viajeCancelado, style: NexaTexto.titulo),
              const SizedBox(height: Sp.lg),
              _Pago(servicio: s),
              const SizedBox(height: Sp.lg),
              NexaButton(
                label: l.continuar,
                onPressed: () {
                  ref.read(viajePasajeroProvider.notifier).cerrar();
                  context.go('/p/inicio');
                },
              ),
            ] else ...[
              FasesViaje(etiquetas: fases, actual: fase),
              const SizedBox(height: Sp.xl),
              if (enElPunto) ...[
                _EsperaSinCosto(desde: s.fechaLlegada!),
                const SizedBox(height: Sp.md),
                if (s.conductor?.placa != null)
                  _BuscaPlaca(conductor: s.conductor!),
                const SizedBox(height: Sp.lg),
                _Acciones(servicio: s),
              ] else if (s.estado == EstadoServicio.enCurso) ...[
                if (s.distanciaKM > 0 && kmRestantes != null) ...[
                  _Avance(
                    destino: s.destino,
                    totalKm: s.distanciaKM,
                    restanteKm: kmRestantes,
                  ),
                  const SizedBox(height: Sp.lg),
                ],
                if (s.conductor != null) ConductorCard(conductor: s.conductor!),
                const SizedBox(height: Sp.lg),
                _AccionesEnViaje(servicio: s),
              ] else ...[
                if (s.conductor != null) ConductorCard(conductor: s.conductor!),
                const SizedBox(height: Sp.lg),
                _Acciones(servicio: s),
                const SizedBox(height: Sp.lg),
                _Pago(servicio: s),
                const SizedBox(height: Sp.sm),
                const _BotonCancelar(solicitud: false),
              ],
            ],
          ],
        ),
      ],
    );
  }
}

/// «Espera sin costo»: cuánto lleva el conductor en el punto (solo reloj; el
/// recargo lo decide el servidor).
class _EsperaSinCosto extends StatefulWidget {
  const _EsperaSinCosto({required this.desde});
  final DateTime desde;

  @override
  State<_EsperaSinCosto> createState() => _EsperaSinCostoState();
}

class _EsperaSinCostoState extends State<_EsperaSinCosto> {
  late final Timer _reloj = Timer.periodic(
    const Duration(seconds: 1),
    (_) => setState(() {}),
  );

  @override
  void dispose() {
    _reloj.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final seg = DateTime.now()
        .difference(widget.desde)
        .inSeconds
        .clamp(0, 5999);
    final texto = '${seg ~/ 60}:${(seg % 60).toString().padLeft(2, '0')}';
    return NexaCard(
      child: Row(
        children: [
          CronoCircular(texto: texto, avance: (seg % 60) / 60),
          const SizedBox(width: Sp.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.esperaSinCosto, style: NexaTexto.subtitulo),
                const SizedBox(height: Sp.xs),
                Text(
                  l.esperaSinCostoTexto,
                  style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «Busca esta placa»: la placa grande en dorado para reconocer la moto.
class _BuscaPlaca extends StatelessWidget {
  const _BuscaPlaca({required this.conductor});
  final Participante conductor;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(Sp.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Rad.lg),
        border: Border.all(color: NexaColors.gold.withValues(alpha: 0.35)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B2410), NexaColors.card],
        ),
      ),
      child: Column(
        children: [
          Text(
            l.buscaEstaPlaca.toUpperCase(),
            style: NexaTexto.etiqueta.copyWith(color: NexaColors.gold),
          ),
          const SizedBox(height: Sp.md),
          PlacaMoto(placa: conductor.placa!, grande: true),
          const SizedBox(height: Sp.md),
          Text(
            [?conductor.vehiculo, conductor.nombre].join(' · '),
            textAlign: TextAlign.center,
            style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Avance hacia el destino con el viaje en curso (km del servidor).
class _Avance extends StatelessWidget {
  const _Avance({
    required this.destino,
    required this.totalKm,
    required this.restanteKm,
  });

  final String destino;
  final double totalKm;
  final double restanteKm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final km = NumberFormat('0.0', 'es_CO');
    final recorrido = (totalKm - restanteKm).clamp(0.0, totalKm);
    final hecho = recorrido / totalKm;
    return NexaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  destino,
                  style: NexaTexto.subtitulo.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(hecho * 100).round()} %',
                style: NexaTexto.subtitulo.copyWith(
                  fontSize: 16,
                  color: NexaColors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(Rad.pill),
            child: LinearProgressIndicator(
              value: hecho,
              minHeight: 6,
              color: NexaColors.cyan,
              backgroundColor: NexaColors.line,
            ),
          ),
          const SizedBox(height: Sp.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.kmRecorridos(km.format(recorrido)),
                  style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
                ),
              ),
              const SizedBox(width: Sp.sm),
              Expanded(
                child: Text(
                  l.kmPorRecorrer(km.format(restanteKm)),
                  textAlign: TextAlign.end,
                  style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Forma de pago y total (incluye el extra voluntario, si lo hay).
class _Pago extends StatelessWidget {
  const _Pago({required this.servicio});
  final Servicio servicio;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final extra = servicio.extraVoluntario;
    final metodo = switch (servicio.metodoPago) {
      'tarjeta' => l.metodoTarjeta,
      'billetera' => l.metodoBilletera,
      _ =>
        extra > 0
            ? l.pagasEnEfectivoExtra('+${Fmt.cop(extra)}')
            : l.pagasEnEfectivo,
    };
    return NexaCard(
      padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
      child: Row(
        children: [
          const Icon(
            Icons.payments_outlined,
            color: NexaColors.muted,
            size: 20,
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Text(
              metodo,
              style: NexaTexto.pequeno.copyWith(color: NexaColors.texto),
            ),
          ),
          const SizedBox(width: Sp.sm),
          Text(
            Fmt.cop(servicio.tarifa + extra),
            style: NexaTexto.subtitulo.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/// Opciones de extra voluntario mientras se busca conductor. El tope por viaje lo
/// pone el servidor (responde 409 si se pasa); aquí solo se muestra lo ofrecido.
class _ExtraVoluntario extends ConsumerStatefulWidget {
  const _ExtraVoluntario({required this.servicio, this.tope});
  final Servicio servicio;

  /// Tope del extra por viaje (lo dice el servidor).
  final double? tope;

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
    return NexaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.llegarMasRapido,
                  style: NexaTexto.subtitulo.copyWith(fontSize: 16),
                ),
              ),
              if (widget.tope != null)
                Text(
                  l.topeExtra(Fmt.cop(widget.tope!)),
                  style: NexaTexto.pequeno.copyWith(color: NexaColors.tenue),
                ),
            ],
          ),
          const SizedBox(height: Sp.xs),
          Text(
            l.llegarMasRapidoTexto,
            style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
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
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: NexaColors.texto,
                  ),
                  backgroundColor: NexaColors.raised,
                  side: const BorderSide(color: NexaColors.line),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Sp.sm,
                    vertical: Sp.sm,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _pedirSos(BuildContext context, WidgetRef ref) async {
  final acciones = ref.read(accionesExternasProvider);
  if (await mostrarHojaSos(context)) {
    await acciones.llamar(kLineaEmergencias);
  }
}

void _compartir(BuildContext context, WidgetRef ref, Servicio s) {
  final l = AppLocalizations.of(context);
  ref
      .read(accionesExternasProvider)
      .compartir(
        l.compartirTexto(s.destino, s.conductor?.nombre ?? l.tuConductor),
      );
}

/// Llamar, Mensaje, Compartir y SOS (diseño P05/P06).
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
          child: AccionCuadro(
            icono: Icons.phone_outlined,
            etiqueta: l.llamar,
            onTap: () => _conTelefono(context, acciones.llamar),
          ),
        ),
        Expanded(
          child: AccionCuadro(
            icono: Icons.chat_bubble_outline,
            etiqueta: l.mensaje,
            onTap: () => _conTelefono(context, acciones.enviarSms),
          ),
        ),
        Expanded(
          child: AccionCuadro(
            icono: Icons.ios_share,
            etiqueta: l.compartir,
            onTap: () => _compartir(context, ref, servicio),
          ),
        ),
        Expanded(
          child: AccionCuadro(
            icono: Icons.shield_outlined,
            etiqueta: l.sos,
            tooltip: l.asistenciaRuta,
            peligro: true,
            onTap: () => _pedirSos(context, ref),
          ),
        ),
      ],
    );
  }
}

/// En viaje: compartir el viaje y SOS (diseño P07).
class _AccionesEnViaje extends ConsumerWidget {
  const _AccionesEnViaje({required this.servicio});
  final Servicio servicio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: BotonIcono(
            icono: Icons.ios_share,
            etiqueta: l.compartirViaje,
            onTap: () => _compartir(context, ref, servicio),
          ),
        ),
        const SizedBox(width: Sp.md),
        Expanded(
          child: BotonIcono(
            icono: Icons.shield_outlined,
            etiqueta: l.sos,
            tooltip: l.asistenciaRuta,
            peligro: true,
            onTap: () => _pedirSos(context, ref),
          ),
        ),
      ],
    );
  }
}

/// Cancelar: con la solicitud abierta es un botón rojo («Cancelar
/// solicitud»); con el conductor en camino, un texto discreto. Siempre pide
/// confirmación.
class _BotonCancelar extends ConsumerWidget {
  const _BotonCancelar({required this.solicitud, this.sinCargo = false});
  final bool solicitud;

  /// Última ola sin conductor (E03): cancelar no cobra nada.
  final bool sinCargo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    Future<void> cancelar() async {
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
    }

    return NexaButton(
      label: !solicitud
          ? l.cancelarViaje
          : sinCargo
          ? l.cancelarSinCargo
          : l.cancelarSolicitud,
      variant: solicitud
          ? NexaButtonVariant.peligro
          : NexaButtonVariant.fantasma,
      onPressed: cancelar,
    );
  }
}

/// Avance del despacho: un tramo por ola, encendidos hasta la actual.
class _BarraOlas extends StatelessWidget {
  const _BarraOlas({required this.ola, required this.total});
  final int ola;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).olaDe(ola, total),
    child: Row(
      children: [
        for (var i = 1; i <= total; i++) ...[
          if (i > 1) const SizedBox(width: Sp.sm),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= ola ? NexaColors.cyan : NexaColors.line,
                borderRadius: BorderRadius.circular(Rad.pill),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
