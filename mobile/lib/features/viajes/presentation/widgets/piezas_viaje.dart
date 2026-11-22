import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';

/// Piezas del flujo del viaje (Figma P04–P07 y C02–C06).

/// Tarjeta que flota arriba del mapa: icono cian + título + detalle
/// («Llega en 4 min · Carlos va hacia tu punto de recogida»).
class TarjetaFlotante extends StatelessWidget {
  const TarjetaFlotante({
    required this.icono,
    required this.titulo,
    this.detalle,
    this.colorDetalle,
    super.key,
  });

  final IconData icono;
  final String titulo;
  final String? detalle;

  /// Para resaltar el detalle (p. ej. «Viene por tu derecha» en cian).
  final Color? colorDetalle;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    container: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: NexaColors.glass,
        borderRadius: BorderRadius.circular(Rad.lg),
        border: Border.all(color: NexaColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.md, Sp.md, Sp.lg, Sp.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: NexaColors.cyan,
                borderRadius: BorderRadius.circular(Rad.md),
              ),
              child: Icon(icono, color: NexaColors.bg, size: 24),
            ),
            const SizedBox(width: Sp.md),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    style: NexaTexto.subtitulo.copyWith(
                      color: NexaColors.texto,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (detalle != null)
                    Text(
                      detalle!,
                      style: NexaTexto.pequeno.copyWith(
                        color: colorDetalle ?? NexaColors.muted,
                        fontWeight: colorDetalle == null
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Píldora con punto de color sobre el mapa («Carlos está en tu punto»).
class PildoraEstado extends StatelessWidget {
  const PildoraEstado({
    required this.texto,
    this.color = NexaColors.ok,
    this.icono,
    super.key,
  });

  final String texto;
  final Color color;

  /// En vez del punto (p. ej. las ondas de «Ola 2 de 4»).
  final IconData? icono;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: NexaColors.glass,
        borderRadius: BorderRadius.circular(Rad.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: NexaShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono != null)
              Icon(icono, size: 16, color: color)
            else
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            const SizedBox(width: Sp.sm),
            Flexible(
              child: Text(
                texto,
                style: TextStyle(
                  color: icono == null ? color : NexaColors.texto,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Barra de fases del viaje: cuatro tramos con su etiqueta; los anteriores y
/// el actual en cian, la actual en negrilla.
class FasesViaje extends StatelessWidget {
  const FasesViaje({required this.etiquetas, required this.actual, super.key});

  final List<String> etiquetas;

  /// Índice de la fase en curso (0 a etiquetas.length − 1).
  final int actual;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: etiquetas[actual.clamp(0, etiquetas.length - 1)],
    child: ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < etiquetas.length; i++) ...[
            if (i > 0) const SizedBox(width: Sp.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= actual ? NexaColors.cyan : NexaColors.line,
                      borderRadius: BorderRadius.circular(Rad.pill),
                    ),
                  ),
                  const SizedBox(height: Sp.sm),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      etiquetas[i].toUpperCase(),
                      maxLines: 1,
                      style: NexaTexto.etiqueta.copyWith(
                        fontSize: 10,
                        letterSpacing: 0.8,
                        color: i == actual
                            ? NexaColors.cyan
                            : i < actual
                            ? NexaColors.muted
                            : NexaColors.tenue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Tarjeta de arriba durante el viaje (rediseño 2026): a qué hora llegas, en
/// grande; los minutos y los km que faltan; y una barra con lo recorrido. Los
/// datos son los del servidor (ETA y distancia restante).
class TarjetaLlegada extends StatelessWidget {
  const TarjetaLlegada({
    required this.destino,
    required this.hora,
    required this.minutos,
    this.kmRestantes,
    this.avance,
    super.key,
  });

  final String destino;
  final String hora;
  final int minutos;
  final double? kmRestantes;

  /// Fracción recorrida (0..1); null = sin barra.
  final double? avance;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final km = kmRestantes == null
        ? null
        : NumberFormat('0.0', 'es_CO').format(kmRestantes);
    final a = avance;
    return Semantics(
      liveRegion: true,
      container: true,
      label: [
        l.llegasAHora(destino, hora),
        l.minutosValor(minutos),
        if (km != null) l.kmRestantes(km),
      ].join('. '),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.lg, Sp.md),
          decoration: BoxDecoration(
            color: NexaColors.glass,
            borderRadius: BorderRadius.circular(Rad.lg),
            border: Border.all(color: NexaColors.line),
            boxShadow: NexaShadows.flotante,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.llegasA(destino),
                style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
              ),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: Sp.md,
                runSpacing: Sp.xs,
                children: [
                  Text(
                    hora,
                    style: NexaTexto.numero.copyWith(fontSize: 30, height: 1.1),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l.minutosValor(minutos),
                        style: NexaTexto.numeroMedio.copyWith(fontSize: 18),
                      ),
                      if (km != null)
                        Text(
                          l.kmRestantes(km),
                          style: NexaTexto.pequeno.copyWith(
                            color: NexaColors.muted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (a != null) ...[
                const SizedBox(height: Sp.md),
                LayoutBuilder(
                  builder: (context, c) => SizedBox(
                    height: 18,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: NexaColors.line,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Container(
                          width: c.maxWidth * a,
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [NexaColors.cyan, NexaColors.azul],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Positioned(
                          left: (c.maxWidth * a - 9).clamp(0, c.maxWidth - 18),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: NexaColors.texto,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: NexaColors.cyan.withValues(alpha: 0.4),
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Placa amarilla de la moto (dato principal al recoger).
class PlacaMoto extends StatelessWidget {
  const PlacaMoto({required this.placa, this.grande = false, super.key});

  final String placa;
  final bool grande;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Placa $placa',
    child: ExcludeSemantics(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: grande ? Sp.lg : Sp.md - 2,
          vertical: grande ? Sp.sm : Sp.xs + 1,
        ),
        decoration: BoxDecoration(
          color: NexaColors.gold,
          borderRadius: BorderRadius.circular(grande ? Rad.md : Rad.sm),
          boxShadow: grande
              ? [
                  BoxShadow(
                    color: NexaColors.gold.withValues(alpha: 0.3),
                    blurRadius: 18,
                  ),
                ]
              : null,
        ),
        child: Text(
          placa,
          textScaler: TextScaler.noScaling,
          style: (grande ? NexaTexto.placa : NexaTexto.boton).copyWith(
            color: NexaColors.bg,
            fontSize: grande ? 28 : 14,
            letterSpacing: grande ? 2.4 : 1.2,
          ),
        ),
      ),
    ),
  );
}

/// Avatar con iniciales (cian para el conductor, dorado para la pasajera).
class AvatarIniciales extends StatelessWidget {
  const AvatarIniciales({
    required this.nombre,
    this.dorado = false,
    this.diametro = 52,
    super.key,
  });

  final String nombre;
  final bool dorado;
  final double diametro;

  static String iniciales(String nombre) {
    final p = nombre.trim().split(RegExp(r'\s+'));
    if (p.isEmpty || p.first.isEmpty) return '?';
    return (p.first[0] + (p.length > 1 ? p[1][0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Container(
    width: diametro,
    height: diametro,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dorado
            ? const [Color(0xFFFFD98A), Color(0xFFB7862F)]
            : const [Color(0xFF29C4F0), NexaColors.navy],
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      iniciales(nombre),
      style: TextStyle(
        color: dorado ? NexaColors.bg : NexaColors.texto,
        fontWeight: FontWeight.w700,
        fontSize: diametro * 0.32,
      ),
    ),
  );
}

/// Acción en cuadro redondeado con su etiqueta debajo (Llamar, Mensaje,
/// Compartir, SOS).
class AccionCuadro extends StatelessWidget {
  const AccionCuadro({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
    this.peligro = false,
    this.tooltip,
    super.key,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
  final bool peligro;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final color = peligro ? NexaColors.error : NexaColors.cyan;
    final boton = Semantics(
      button: true,
      label: etiqueta,
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(Rad.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Sp.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: peligro ? NexaColors.errorSuave : NexaColors.raised,
                    borderRadius: BorderRadius.circular(Rad.md),
                  ),
                  child: Icon(icono, color: color, size: 24),
                ),
                const SizedBox(height: Sp.sm),
                Text(
                  etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NexaTexto.pequeno.copyWith(
                    color: peligro ? NexaColors.error : NexaColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? boton : Tooltip(message: tooltip, child: boton);
  }
}

/// Botón ancho con icono, oscuro (o rojo de peligro): «Compartir viaje», «SOS»,
/// «Llamar», «Abrir en Maps».
class BotonIcono extends StatelessWidget {
  const BotonIcono({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
    this.peligro = false,
    this.tooltip,
    super.key,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
  final bool peligro;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final color = peligro ? NexaColors.error : NexaColors.texto;
    final boton = TextButton.icon(
      onPressed: onTap,
      icon: Icon(icono, size: 18, color: peligro ? color : NexaColors.cyan),
      label: Text(etiqueta, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(Sizes.touch),
        foregroundColor: color,
        backgroundColor: peligro ? NexaColors.errorSuave : NexaColors.raised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rad.md),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(horizontal: Sp.md),
      ),
    );
    return tooltip == null ? boton : Tooltip(message: tooltip, child: boton);
  }
}

/// Cronómetro circular (espera en el punto, solicitud nueva).
class CronoCircular extends StatelessWidget {
  const CronoCircular({
    required this.texto,
    required this.avance,
    this.color = NexaColors.cyan,
    this.diametro = 68,
    super.key,
  });

  final String texto;

  /// Parte del arco dibujada, de 0 a 1.
  final double avance;
  final Color color;
  final double diametro;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: diametro,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: CircularProgressIndicator(
            value: avance.clamp(0.0, 1.0),
            strokeWidth: 4,
            color: color,
            backgroundColor: NexaColors.line,
            strokeCap: StrokeCap.round,
          ),
        ),
        Text(
          texto,
          style: NexaTexto.subtitulo.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}
