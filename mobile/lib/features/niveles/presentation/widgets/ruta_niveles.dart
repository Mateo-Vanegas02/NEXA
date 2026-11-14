import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/nivel.dart';

/// Los niveles como una ruta (NEXA Pulso): cada parada queda a su distancia
/// real en XP, así que el tramo largo se ve largo. El tramo ya recorrido
/// brilla y la moto se detiene donde va el usuario.
///
/// Solo pinta lo que entrega `GET /api/niveles/me`: los XP de cada nivel, su
/// descuento (pasajero) o comisión (conductor) y el XP actual.
class RutaNiveles extends StatelessWidget {
  const RutaNiveles({
    required this.estado,
    required this.rotuloNivel,
    this.alto = 300,
    super.key,
  });

  final NivelEstado estado;

  /// Texto de una parada: «Nivel 3».
  final String Function(String nivel) rotuloNivel;
  final double alto;

  /// La ruta solo tiene sentido con al menos dos niveles y XP crecientes.
  static bool sePuedeDibujar(NivelEstado e) =>
      e.niveles.length >= 2 && e.niveles.last.xp > e.niveles.first.xp;

  @override
  Widget build(BuildContext context) {
    final niveles = estado.niveles;
    final base = niveles.first.xp;
    final tope = niveles.last.xp;
    double fraccion(int xp) => ((xp - base) / (tope - base)).clamp(0.0, 1.0);
    final hasta = fraccion(estado.xpActual);
    final paradas = [
      for (final n in niveles)
        (
          fraccion: fraccion(n.xp),
          titulo: rotuloNivel(n.nombre),
          detalle: n.descuento != null && n.descuento! > 0
              ? '−${Fmt.pct(n.descuento!)}'
              : n.comision != null
              ? Fmt.pct(n.comision!)
              : '',
          alcanzada: estado.nivel >= n.nivel,
        ),
    ];
    final duracion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 1400);
    return ExcludeSemantics(
      child: SizedBox(
        height: alto,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: hasta),
          duration: duracion,
          curve: Curves.easeInOutCubic,
          builder: (context, v, _) => CustomPaint(
            size: Size.infinite,
            painter: _RutaPainter(avance: v, paradas: paradas),
          ),
        ),
      ),
    );
  }
}

typedef _Parada = ({
  double fraccion,
  String titulo,
  String detalle,
  bool alcanzada,
});

class _RutaPainter extends CustomPainter {
  const _RutaPainter({required this.avance, required this.paradas});

  final double avance;
  final List<_Parada> paradas;

  /// La carretera en un cuadro de 320 × 424: sube en cuatro curvas.
  static Path _carretera(Size s) {
    final kx = s.width / 320;
    final ky = s.height / 424;
    return Path()
      ..moveTo(44 * kx, 372 * ky)
      ..cubicTo(150 * kx, 372 * ky, 268 * kx, 372 * ky, 268 * kx, 318 * ky)
      ..cubicTo(268 * kx, 264 * ky, 52 * kx, 296 * ky, 52 * kx, 240 * ky)
      ..cubicTo(52 * kx, 184 * ky, 268 * kx, 226 * ky, 268 * kx, 170 * ky)
      ..cubicTo(268 * kx, 114 * ky, 72 * kx, 152 * ky, 62 * kx, 100 * ky)
      ..cubicTo(52 * kx, 48 * ky, 120 * kx, 34 * ky, 268 * kx, 34 * ky);
  }

  void _texto(
    Canvas canvas,
    Size size,
    String s,
    Offset arribaCentro,
    TextStyle estilo,
  ) {
    if (s.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(text: s, style: estilo),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final dx = (arribaCentro.dx - tp.width / 2).clamp(
      0.0,
      math.max(0.0, size.width - tp.width),
    );
    // Halo del color del fondo para que se lea encima de la carretera.
    final halo = TextPainter(
      text: TextSpan(
        text: s,
        style: estilo.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeJoin = StrokeJoin.round
            ..color = NexaColors.card,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final donde = Offset(dx, arribaCentro.dy);
    halo.paint(canvas, donde);
    tp.paint(canvas, donde);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final carretera = _carretera(size);
    final medida = carretera.computeMetrics().first;
    final largo = medida.length;
    Offset punto(double f) =>
        medida.getTangentForOffset(largo * f.clamp(0.0, 1.0))?.position ??
        Offset.zero;

    canvas.drawPath(
      carretera,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 22
        ..color = const Color(0xFF0B2A43),
    );
    final raya = Paint()..color = NexaColors.line;
    for (var d = 0.0; d < largo; d += 14) {
      final t = medida.getTangentForOffset(d);
      if (t != null) canvas.drawCircle(t.position, 1.2, raya);
    }
    if (avance > 0) {
      final hecho = medida.extractPath(0, largo * avance);
      canvas
        ..drawPath(
          hecho,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 14
            ..color = NexaColors.cyan.withValues(alpha: 0.22)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        )
        ..drawPath(
          hecho,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 6
            ..color = NexaColors.cyan,
        );
    }

    final titulo = NexaTexto.pequeno.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: NexaColors.texto,
    );
    final detalle = NexaTexto.pequeno.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: NexaColors.muted,
    );
    for (final p in paradas) {
      final c = punto(p.fraccion);
      // Se enciende cuando la moto pasa por ella.
      final encendida = p.alcanzada && avance >= p.fraccion - 0.001;
      canvas
        ..drawCircle(
          c,
          9,
          Paint()..color = encendida ? NexaColors.navy : NexaColors.bg,
        )
        ..drawCircle(
          c,
          9,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = encendida ? NexaColors.cyan : NexaColors.tenue,
        );
      _texto(canvas, size, p.titulo, c + const Offset(0, 14), titulo);
      _texto(canvas, size, p.detalle, c + const Offset(0, 29), detalle);
    }

    final moto = punto(avance);
    canvas
      ..drawCircle(
        moto,
        15,
        Paint()
          ..color = NexaColors.cyan.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      )
      ..drawCircle(moto, 7, Paint()..color = NexaColors.texto)
      ..drawCircle(moto, 4.5, Paint()..color = NexaColors.cyan);
  }

  @override
  bool shouldRepaint(_RutaPainter old) =>
      old.avance != avance || old.paradas != paradas;
}
