import 'dart:async';

import '../../../../core/theme/nexa_texto.dart';
import 'piezas_viaje.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/mapa/maniobra.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/acciones_externas.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_popup.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/servicio.dart';
import '../controllers/sin_conexion_controller.dart';
import '../controllers/viaje_conductor_controller.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A cuántos km del destino se considera que el conductor "llegó" para avisar
/// antes de finalizar. Solo es un aviso: el servidor decide cuánto se cobra.
const double kAvisoFinalizarKm = 0.15;

/// Viaje activo del conductor, por fases: ir a recoger → "Llegué" → esperar al
/// pasajero e iniciar → en viaje → finalizar. Distancia y ETA vienen del servidor.
/// Las acciones que avanzan el viaje se confirman deslizando. El mapa lo dibuja
/// el panel que contiene esta tarjeta.
class ViajeActivoCard extends ConsumerStatefulWidget {
  const ViajeActivoCard({
    super.key,
    required this.servicio,
    this.fase,
    this.posicion,
    this.pasajero,
  });

  final Servicio servicio;
  final FaseConductor? fase;
  final PosicionViaje? posicion;
  final PosicionPasajero? pasajero;

  @override
  ConsumerState<ViajeActivoCard> createState() => _ViajeActivoCardState();
}

class _ViajeActivoCardState extends ConsumerState<ViajeActivoCard> {
  bool _cargando = false;

  void _error(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppException.from(e).mensaje)));
  }

  Future<void> _avanzar() async {
    if (_cargando) return;
    final l = AppLocalizations.of(context);
    final fase = widget.fase ?? FaseConductor.aRecoger;
    final lejos =
        fase == FaseConductor.enViaje &&
        (widget.posicion?.distanciaRestanteKm ?? 0) > kAvisoFinalizarKm;
    if (lejos) {
      final seguir = await mostrarNexaPopup<bool>(
        context,
        titulo: l.finalizarAntesTitulo,
        mensaje: l.finalizarAntesTexto,
        tipo: NexaPopupTipo.alerta,
        acciones: [
          NexaPopupAccion(etiqueta: l.finalizarDeTodosModos, valor: true),
          NexaPopupAccion(etiqueta: l.cancelar, valor: false),
        ],
      );
      if (!(seguir ?? false)) return;
    }
    setState(() => _cargando = true);
    try {
      await ref.read(conductorProvider.notifier).avanzar();
    } on Object catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cancelar() async {
    final l = AppLocalizations.of(context);
    final confirmar = await mostrarNexaPopup<bool>(
      context,
      titulo: l.cancelarViajeConductorTitulo,
      mensaje: l.cancelarViajeConductorTexto,
      tipo: NexaPopupTipo.peligro,
      acciones: [
        NexaPopupAccion(etiqueta: l.cancelarViaje, valor: true, peligro: true),
        NexaPopupAccion(etiqueta: l.mantenerViaje, valor: false),
      ],
    );
    if (!(confirmar ?? false)) return;
    try {
      await ref.read(conductorProvider.notifier).cancelarActivo();
    } on Object catch (e) {
      _error(e);
    }
  }

  Future<void> _contactar(Future<bool> Function(String) accion) async {
    final l = AppLocalizations.of(context);
    final tel = widget.servicio.pasajero?.telefono;
    final mensajes = ScaffoldMessenger.of(context);
    final ok = tel != null && await accion(tel);
    if (!ok) mensajes.showSnackBar(SnackBar(content: Text(l.noDisponible)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = widget.servicio;
    final fase = widget.fase ?? FaseConductor.aRecoger;
    final pos = widget.posicion;
    final acciones = ref.read(accionesExternasProvider);
    final boton = switch (fase) {
      FaseConductor.aRecoger => l.llegueAlPunto,
      FaseConductor.enElPunto => l.iniciarViaje,
      FaseConductor.enViaje => l.finalizarViaje,
    };
    final km = pos == null
        ? null
        : '${pos.distanciaRestanteKm.toStringAsFixed(1)} km';
    final nombre = s.pasajero?.nombre ?? '';
    // Un paso hecho sin señal que aún no llega al servidor.
    final pendiente = ref.watch(
      sinConexionProvider.select(
        (e) => e.pendientes.any((a) => a.servicioId == s.id),
      ),
    );
    final detalle = <String>[
      if (s.nivelPasajero > 0) l.pasajeraNivel(s.nivelPasajero),
      if (fase != FaseConductor.enElPunto &&
          pos != null &&
          pos.etaMinutos > 0) ...[
        l.minutosValor(pos.etaMinutos),
        ?km,
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FasesViaje(
          etiquetas: [
            l.faseAceptado,
            l.faseARecoger,
            l.faseEnPunto,
            l.faseEnViaje,
          ],
          actual: fase.index + 1,
        ),
        if (pendiente) ...[
          const SizedBox(height: Sp.md),
          _AvisoPendiente(texto: l.pendienteDeEnviar),
        ],
        const SizedBox(height: Sp.lg),
        if (fase == FaseConductor.enElPunto && s.fechaLlegada != null) ...[
          _Esperando(nombre: nombre, desde: s.fechaLlegada!),
          const SizedBox(height: Sp.lg),
        ],
        Row(
          children: [
            AvatarIniciales(nombre: nombre, dorado: true, diametro: 48),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: NexaTexto.subtitulo.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (detalle.isNotEmpty)
                    Text(
                      detalle.join(' · '),
                      style: NexaTexto.pequeno.copyWith(
                        color: NexaColors.muted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Sp.sm),
            // Un solo monto: lo que cobra en efectivo (el servidor ya suma el
            // cargo anterior del pasajero, sin mostrarlo por separado).
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l.cobra,
                  style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
                ),
                Text(
                  Fmt.cop(s.tarifa + s.extraVoluntario),
                  style: NexaTexto.numeroMedio.copyWith(
                    fontSize: 20,
                    color: NexaColors.ok,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (fase == FaseConductor.aRecoger && widget.pasajero != null) ...[
          const SizedBox(height: Sp.sm),
          Text(
            '${l.distanciaPasajero}: ${widget.pasajero!.distanciaRecogidaMetros} m',
            style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
          ),
        ],
        const SizedBox(height: Sp.lg),
        Row(
          children: [
            Expanded(
              child: BotonIcono(
                icono: Icons.phone_outlined,
                etiqueta: l.llamar,
                tooltip: l.llamar,
                onTap: () => _contactar(acciones.llamar),
              ),
            ),
            const SizedBox(width: Sp.md),
            Expanded(
              child: BotonIcono(
                icono: Icons.chat_bubble_outline,
                etiqueta: l.mensaje,
                tooltip: l.mensaje,
                onTap: () => _contactar(acciones.enviarSms),
              ),
            ),
          ],
        ),
        const SizedBox(height: Sp.lg),
        if (_cargando)
          const Padding(
            padding: EdgeInsets.only(bottom: Sp.sm),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        // Guía de cercanía para «Llegué» (el servidor exige estar a 50 m).
        // Solo orienta: el control nunca se bloquea, porque sin señal la
        // distancia del servidor puede estar vieja.
        if (fase == FaseConductor.aRecoger && pos != null) ...[
          _GuiaLlegada(km: pos.distanciaRestanteKm),
          const SizedBox(height: Sp.sm),
        ],
        NexaDeslizar(texto: boton, onConfirmado: _cargando ? null : _avanzar),
        if (fase == FaseConductor.enViaje)
          Padding(
            padding: const EdgeInsets.only(top: Sp.sm),
            child: Text(
              l.finalizarLejosAviso,
              textAlign: TextAlign.center,
              style: NexaTexto.pequeno.copyWith(color: NexaColors.tenue),
            ),
          )
        else
          NexaButton(
            label: l.cancelarViaje,
            variant: NexaButtonVariant.fantasma,
            onPressed: _cancelar,
          ),
      ],
    );
  }
}

/// «Esperando a Laura»: reloj desde que el conductor marcó «Llegué» (C04).
class _Esperando extends StatefulWidget {
  const _Esperando({required this.nombre, required this.desde});
  final String nombre;
  final DateTime desde;

  @override
  State<_Esperando> createState() => _EsperandoState();
}

class _EsperandoState extends State<_Esperando> {
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
    return NexaCard(
      child: Row(
        children: [
          CronoCircular(
            texto: '${seg ~/ 60}:${(seg % 60).toString().padLeft(2, '0')}',
            avance: (seg % 60) / 60,
            color: NexaColors.gold,
          ),
          const SizedBox(width: Sp.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.esperandoA(widget.nombre.split(' ').first),
                  style: NexaTexto.subtitulo,
                ),
                const SizedBox(height: Sp.xs),
                Text(
                  l.esperaConductorTexto,
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

/// Resumen del viaje que acaba de terminar: cuánto cobrar en efectivo.
class ResumenViajeCard extends StatelessWidget {
  const ResumenViajeCard({
    super.key,
    required this.servicio,
    this.desglose,
    required this.onCerrar,
  });

  final Servicio servicio;
  final DesgloseConductor? desglose;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cobrar =
        desglose?.cobrarAlPasajero ??
        (servicio.tarifa + servicio.extraVoluntario);
    final nombre = (servicio.pasajero?.nombre ?? '').split(' ').first;
    final km = NumberFormat('0.0', 'es_CO').format(servicio.distanciaKM);
    final ganancia = desglose?.gananciaConductor ?? 0;
    final extra = desglose?.extraVoluntario ?? servicio.extraVoluntario;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.viajeTerminado.toUpperCase(),
          textAlign: TextAlign.center,
          style: NexaTexto.etiqueta.copyWith(color: NexaColors.ok),
        ),
        const SizedBox(height: Sp.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.lg,
            vertical: Sp.xl,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Rad.lg),
            border: Border.all(color: NexaColors.ok.withValues(alpha: 0.4)),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B2E2A), Color(0xFF07231F)],
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color: NexaColors.ok,
                  ),
                  const SizedBox(width: Sp.sm),
                  Flexible(
                    child: Text(
                      nombre.isEmpty
                          ? l.cobraAlPasajero
                          : l.cobraAEnEfectivo(nombre),
                      style: NexaTexto.cuerpo.copyWith(
                        color: NexaColors.ok,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sp.sm),
              FittedBox(
                child: Text(
                  Fmt.cop(cobrar),
                  style: NexaTexto.numero.copyWith(fontSize: 52),
                ),
              ),
              const SizedBox(height: Sp.xs),
              Text(
                '${servicio.destino} · $km km',
                textAlign: TextAlign.center,
                style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
              ),
              // Ya terminó: el aviso de «antes de finalizar» confundía; se dice
              // qué pasó y que se cobró solo lo recorrido (rediseño 2026).
              if (servicio.finalizadoAntesDelDestino) ...[
                const SizedBox(height: Sp.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Sp.md,
                    vertical: Sp.sm,
                  ),
                  decoration: BoxDecoration(
                    color: NexaColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Rad.md),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l.finalizadoAntesTitulo,
                        textAlign: TextAlign.center,
                        style: NexaTexto.pequeno.copyWith(
                          color: NexaColors.gold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l.finalizadoAntesCobro,
                        textAlign: TextAlign.center,
                        style: NexaTexto.pequeno.copyWith(
                          color: NexaColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (servicio.xpGanadoConductor > 0) ...[
                const SizedBox(height: Sp.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt, size: 18, color: NexaColors.cyan),
                    const SizedBox(width: Sp.xs),
                    Text(
                      l.xpGanado(servicio.xpGanadoConductor),
                      style: NexaTexto.pequeno.copyWith(
                        color: NexaColors.cyan,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (ganancia > 0) ...[
          const SizedBox(height: Sp.md),
          NexaCard(
            child: Column(
              children: [
                _Linea(
                  texto: l.tuGanancia,
                  valor: Fmt.cop(ganancia),
                  color: NexaColors.ok,
                ),
                if (extra > 0) ...[
                  const SizedBox(height: Sp.sm),
                  _Linea(
                    texto: l.incluyeExtra,
                    valor: '+${Fmt.cop(extra)}',
                    color: NexaColors.gold,
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: Sp.lg),
        NexaButton(
          label: nombre.isEmpty ? l.calificar : l.calificarA(nombre),
          onPressed: () {
            final router = GoRouter.of(context);
            onCerrar();
            router.push('/c/calificar', extra: servicio);
          },
        ),
        const SizedBox(height: Sp.sm),
        NexaButton(
          label: l.ahoraNo,
          variant: NexaButtonVariant.fantasma,
          onPressed: onCerrar,
        ),
      ],
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea({required this.texto, required this.valor, required this.color});
  final String texto;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          texto,
          style: NexaTexto.cuerpo.copyWith(color: NexaColors.muted),
        ),
      ),
      Text(
        valor,
        style: NexaTexto.subtitulo.copyWith(fontSize: 16, color: color),
      ),
    ],
  );
}

/// «Pendiente de enviar»: el paso se hizo sin señal y se registrará con su hora.
class _AvisoPendiente extends StatelessWidget {
  const _AvisoPendiente({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: NexaColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Rad.md),
        border: Border.all(color: NexaColors.gold),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined, color: NexaColors.gold),
          const SizedBox(width: Sp.md),
          Expanded(child: Text(texto)),
        ],
      ),
    ),
  );
}

/// Radio en km dentro del cual el servidor acepta «Llegué».
const double kRadioLlegadaKm = 0.05;

/// Dice si ya se puede marcar «Llegué»: punteada y apagada lejos del punto,
/// verde al entrar en el radio.
class _GuiaLlegada extends StatelessWidget {
  const _GuiaLlegada({required this.km});
  final double km;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cerca = km <= kRadioLlegadaKm;
    final color = cerca ? NexaColors.ok : NexaColors.muted;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
        decoration: BoxDecoration(
          color: cerca ? NexaColors.ok.withValues(alpha: 0.14) : null,
          borderRadius: BorderRadius.circular(Rad.md),
          border: Border.all(
            color: cerca ? NexaColors.ok : NexaColors.line,
            width: cerca ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              cerca ? Icons.check_circle_outline : Icons.near_me_outlined,
              size: 18,
              color: color,
            ),
            const SizedBox(width: Sp.sm),
            Expanded(
              child: Text(
                cerca
                    ? l.llegueEnPunto
                    : l.llegueFaltan(ReglasManiobra.texto(km * 1000)),
                style: NexaTexto.pequeno.copyWith(
                  color: cerca ? NexaColors.ok : NexaColors.muted,
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
