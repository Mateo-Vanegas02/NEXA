import '../../../../core/theme/theme_x.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final t = Theme.of(context).textTheme;
    final s = widget.servicio;
    final fase = widget.fase ?? FaseConductor.aRecoger;
    final pos = widget.posicion;
    final acciones = ref.read(accionesExternasProvider);
    final titulo = switch (fase) {
      FaseConductor.aRecoger => l.yendoAPasajero,
      FaseConductor.enElPunto => l.esperandoPasajero,
      FaseConductor.enViaje => l.enViaje,
    };
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Fases(fase: fase),
        if (pendiente) ...[
          const SizedBox(height: Sp.md),
          _AvisoPendiente(texto: l.pendienteDeEnviar),
        ],
        const SizedBox(height: Sp.lg),
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [NexaColors.cyan, NexaColors.sky],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _iniciales(nombre),
                style: const TextStyle(
                  color: NexaColors.bg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: t.bodySmall?.copyWith(
                      color: context.acento,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    nombre,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _Redondo(
              icono: Icons.phone_outlined,
              tooltip: l.llamar,
              onTap: () => _contactar(acciones.llamar),
            ),
            const SizedBox(width: Sp.sm),
            _Redondo(
              icono: Icons.chat_bubble_outline,
              tooltip: l.mensaje,
              onTap: () => _contactar(acciones.enviarSms),
            ),
          ],
        ),
        const SizedBox(height: Sp.md),
        Text('${s.origen} → ${s.destino}', style: t.bodyMedium),
        if (pos != null && pos.etaMinutos > 0)
          Text(
            '${l.minutosValor(pos.etaMinutos)}  ·  $km',
            style: t.labelLarge?.copyWith(color: context.muted),
          ),
        if (fase == FaseConductor.aRecoger && widget.pasajero != null)
          Text(
            '${l.distanciaPasajero}: ${widget.pasajero!.distanciaRecogidaMetros} m',
            style: t.bodySmall?.copyWith(color: context.muted),
          ),
        const SizedBox(height: Sp.md),
        // Un solo monto: lo que cobra en efectivo (el servidor ya suma el
        // cargo anterior del pasajero, sin mostrarlo por separado).
        DecoratedBox(
          decoration: BoxDecoration(
            color: NexaColors.card,
            borderRadius: BorderRadius.circular(Rad.lg),
            border: Border.all(color: NexaColors.cyan.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: NexaColors.cyan.withValues(alpha: 0.18),
                blurRadius: 24,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.lg,
              vertical: Sp.md,
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
                        Fmt.cop(s.tarifa + s.extraVoluntario),
                        style: t.headlineSmall?.copyWith(
                          color: NexaColors.cyan,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_cargando)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Sp.lg),
        NexaDeslizar(texto: boton, onConfirmado: _cargando ? null : _avanzar),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(Sizes.touch),
            foregroundColor: context.colors.error,
          ),
          onPressed: _cancelar,
          child: Text(l.cancelarViaje),
        ),
      ],
    );
  }

  static String _iniciales(String nombre) {
    final p = nombre.trim().split(RegExp(r'\s+'));
    if (p.isEmpty || p.first.isEmpty) return '?';
    return (p.first[0] + (p.length > 1 ? p[1][0] : '')).toUpperCase();
  }
}

/// Tres pasos del viaje del conductor: a recoger, en el punto, en viaje.
class _Fases extends StatelessWidget {
  const _Fases({required this.fase});
  final FaseConductor fase;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final etiquetas = [l.faseARecoger, l.faseEnPunto, l.faseEnViaje];
    final actual = fase.index;
    return Semantics(
      container: true,
      label: etiquetas[actual],
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < etiquetas.length; i++)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < actual
                            ? NexaColors.cyan
                            : context.colors.surface,
                        border: Border.all(
                          color: i <= actual
                              ? NexaColors.cyan
                              : context.colors.outline,
                          width: i == actual ? 5 : 2,
                        ),
                        boxShadow: i == actual ? NexaShadows.glow : null,
                      ),
                      child: i < actual
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: NexaColors.bg,
                            )
                          : null,
                    ),
                    const SizedBox(height: Sp.xs),
                    Text(
                      etiquetas[i],
                      textAlign: TextAlign.center,
                      style: context.textos.labelSmall?.copyWith(
                        fontWeight: i == actual ? FontWeight.w700 : null,
                        color: i <= actual ? null : context.muted,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Redondo extends StatelessWidget {
  const _Redondo({
    required this.icono,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    icon: Icon(icono, color: context.acento),
    style: IconButton.styleFrom(
      minimumSize: const Size.square(Sizes.touch),
      backgroundColor: NexaColors.raised,
      side: BorderSide(color: NexaColors.cyan.withValues(alpha: 0.25)),
    ),
  );
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
    final t = Theme.of(context).textTheme;
    final cobrar =
        desglose?.cobrarAlPasajero ??
        (servicio.tarifa + servicio.extraVoluntario);
    return NexaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: NexaColors.ok),
              const SizedBox(width: Sp.sm),
              Text(l.viajeTerminado, style: t.titleMedium),
            ],
          ),
          const SizedBox(height: Sp.md),
          Text(l.cobraAlPasajero, style: t.labelMedium),
          Text(Fmt.cop(cobrar), style: t.headlineMedium),
          if (servicio.finalizadoAntesDelDestino)
            Padding(
              padding: const EdgeInsets.only(top: Sp.xs),
              child: Text(
                l.finalizarAntesTexto,
                style: t.bodySmall?.copyWith(color: context.muted),
              ),
            ),
          if (desglose != null && desglose!.gananciaConductor > 0) ...[
            const SizedBox(height: Sp.sm),
            Text(
              '${l.gananciaPeriodo}: ${Fmt.cop(desglose!.gananciaConductor)}',
              style: t.bodyMedium,
            ),
          ],
          const SizedBox(height: Sp.md),
          NexaButton(label: l.listo, onPressed: onCerrar),
        ],
      ),
    );
  }
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
