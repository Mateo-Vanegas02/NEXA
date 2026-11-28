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
///
/// En la lista lleva su anillo de 45 s. A pantalla completa
/// ([SolicitudEntrante]) la cuenta regresiva va en el borde de la pantalla: se
/// pasa en [reloj] y la tarjeta queda compacta para dejar ver el mapa.
class SolicitudCard extends ConsumerStatefulWidget {
  const SolicitudCard({
    super.key,
    required this.servicio,
    this.reloj,
    this.onVerEnMapa,
  });
  final Servicio servicio;

  /// Avance de la ventana de atención (0 → 1) que lleva quien la muestra a
  /// pantalla completa. Con él la tarjeta no dibuja el anillo.
  final Animation<double>? reloj;

  /// «Ver en el mapa» junto a «Ahora no» (solo a pantalla completa).
  final VoidCallback? onVerEnMapa;

  /// Tiempo que la solicitud pide atención (el mismo del aviso push).
  static const ventana = Duration(seconds: 45);

  /// Color de la cuenta regresiva: cian, dorado en el último cuarto y apagado
  /// al terminar (la solicitud sigue disponible).
  static Color colorCuenta(double queda) {
    if (queda <= 0) return NexaColors.tenue;
    return queda < 0.27 ? NexaColors.gold : NexaColors.cyan;
  }

  @override
  ConsumerState<SolicitudCard> createState() => _SolicitudCardState();
}

class _SolicitudCardState extends ConsumerState<SolicitudCard>
    with SingleTickerProviderStateMixin {
  static final int _ventana = SolicitudCard.ventana.inSeconds;

  bool _aceptando = false;

  /// Cuenta regresiva propia (en la lista): corre una vez. Al acabar la
  /// solicitud sigue disponible (el servidor no la vence por conductor), solo
  /// deja de resaltarse.
  AnimationController? _propio;

  Animation<double> get _reloj => widget.reloj ?? _propio!;

  @override
  void initState() {
    super.initState();
    _crearRelojSiFalta();
  }

  @override
  void didUpdateWidget(SolicitudCard anterior) {
    super.didUpdateWidget(anterior);
    _crearRelojSiFalta();
  }

  void _crearRelojSiFalta() {
    if (widget.reloj != null || _propio != null) return;
    _propio = AnimationController(
      vsync: this,
      duration: SolicitudCard.ventana,
    )..forward();
  }

  @override
  void dispose() {
    _propio?.dispose();
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
    final decoracion = BoxDecoration(
      color: NexaColors.card,
      borderRadius: BorderRadius.circular(Rad.lg + 4),
      border: Border.all(color: NexaColors.cyan.withValues(alpha: 0.6)),
      boxShadow: [
        BoxShadow(
          color: NexaColors.cyan.withValues(alpha: 0.16),
          blurRadius: 28,
        ),
      ],
    );
    if (widget.reloj != null) {
      return DecoratedBox(
        decoration: decoracion,
        child: Padding(
          padding: const EdgeInsets.all(Sp.lg),
          child: _compacta(l, ctrl, total: total, porKm: porKm, km: km),
        ),
      );
    }
    return DecoratedBox(
      decoration: decoracion,
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
                    color: SolicitudCard.colorCuenta(queda),
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

  /// A pantalla completa: sin anillo (la cuenta va en el borde de la
  /// pantalla), la recogida y el destino en dos líneas y las acciones
  /// secundarias juntas, para que la tarjeta deje ver el mapa.
  Widget _compacta(
    AppLocalizations l,
    ConductorController ctrl, {
    required double total,
    required String? porKm,
    required String km,
  }) {
    final servicio = widget.servicio;
    final extra = servicio.extraVoluntario;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.nuevaSolicitud.toUpperCase(),
                style: NexaTexto.etiqueta.copyWith(color: NexaColors.cyan),
              ),
            ),
            const SizedBox(width: Sp.sm),
            Flexible(
              child: AnimatedBuilder(
                animation: _reloj,
                builder: (context, _) => _Segundos(queda: 1 - _reloj.value),
              ),
            ),
          ],
        ),
        const SizedBox(height: Sp.sm),
        // «Ganas $X» lo calcula el servidor según el nivel del conductor; sin
        // ese dato se muestra lo que cobra en efectivo.
        Text(
          servicio.gananciaEstimada != null
              ? l.ganasMonto(Fmt.cop(servicio.gananciaEstimada!))
              : '${l.cobraAlPasajero} ${Fmt.cop(total)}',
          style: NexaTexto.display,
        ),
        Text(
          [
            if (porKm != null) l.porKm(porKm),
            l.efectivo.toLowerCase(),
          ].join(' · '),
          style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
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
            borderRadius: BorderRadius.circular(Rad.md),
            border: Border.all(color: NexaColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.md,
              vertical: Sp.sm + 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Linea(
                  icono: Icons.my_location,
                  texto: servicio.origen,
                  detalle: servicio.pasajero?.nombre,
                ),
                const SizedBox(height: Sp.sm),
                _Linea(icono: Icons.place_outlined, texto: servicio.destino),
              ],
            ),
          ),
        ),
        const SizedBox(height: Sp.md),
        // Aceptar se desliza: en la moto un toque accidental es fácil.
        NexaDeslizar(
          texto: l.deslizaAceptar,
          onConfirmado: _aceptando ? null : _aceptar,
        ),
        const SizedBox(height: Sp.xs),
        Row(
          children: [
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, Sizes.touch),
                ),
                onPressed: _aceptando ? null : () => ctrl.rechazar(servicio),
                child: Text(
                  l.ahoraNo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (widget.onVerEnMapa != null)
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, Sizes.touch),
                    foregroundColor: NexaColors.muted,
                  ),
                  onPressed: _aceptando ? null : widget.onVerEnMapa,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(
                    l.solicitudVerEnMapa,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Segundos que quedan, en una píldora del color de la cuenta regresiva.
class _Segundos extends StatelessWidget {
  const _Segundos({required this.queda});
  final double queda;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = SolicitudCard.colorCuenta(queda);
    final segundos = (queda * SolicitudCard.ventana.inSeconds).ceil();
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Sp.md,
          vertical: Sp.xs + 2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(Rad.pill),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 14, color: color),
            const SizedBox(width: Sp.xs),
            Flexible(
              child: Text(
                queda <= 0 ? l.solicitudSigue : l.solicitudSegundos(segundos),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NexaTexto.pequeno.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una línea de la ruta en la tarjeta compacta: ícono, lugar y, si hay, quién.
class _Linea extends StatelessWidget {
  const _Linea({required this.icono, required this.texto, this.detalle});
  final IconData icono;
  final String texto;
  final String? detalle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Icon(icono, size: 16, color: NexaColors.cyan),
      ),
      const SizedBox(width: Sp.sm),
      Expanded(
        child: Text.rich(
          TextSpan(
            text: texto,
            style: NexaTexto.cuerpo.copyWith(fontWeight: FontWeight.w600),
            children: [
              if (detalle != null)
                TextSpan(
                  text: ' · $detalle',
                  style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
                ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
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
