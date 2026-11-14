import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Radar del despacho (NEXA Pulso): un aro por ola, encendidos hasta la ola
/// en la que va la solicitud, y un barrido que gira mientras se busca.
///
/// La ola y el total los entrega el servidor (`despacho` de
/// `GET /pasajero/solicitud-activa`); aquí solo se dibujan. No muestra a los
/// conductores: el servidor no envía sus posiciones al pasajero.
class RadarOlas extends StatefulWidget {
  const RadarOlas({
    required this.ola,
    required this.total,
    this.buscando = true,
    this.diametro = 88,
    super.key,
  });

  /// Ola actual, desde 1.
  final int ola;
  final int total;

  /// `false` en la última ola sin respuesta: el radar se queda quieto.
  final bool buscando;
  final double diametro;

  @override
  State<RadarOlas> createState() => _RadarOlasState();
}

class _RadarOlasState extends State<RadarOlas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  bool _sinAnimar = false;

  void _ajustar() {
    if (widget.buscando && !_sinAnimar) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sinAnimar = MediaQuery.disableAnimationsOf(context);
    _ajustar();
  }

  @override
  void didUpdateWidget(RadarOlas old) {
    super.didUpdateWidget(old);
    _ajustar();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: widget.diametro,
      child: CustomPaint(
        painter: _RadarPainter(
          giro: _c,
          ola: widget.ola,
          total: math.max(1, widget.total),
          buscando: widget.buscando && !_sinAnimar,
          apagado: !widget.buscando,
        ),
      ),
    ),
  );
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.giro,
    required this.ola,
    required this.total,
    required this.buscando,
    required this.apagado,
  }) : super(repaint: giro);

  final Animation<double> giro;
  final int ola;
  final int total;

  /// Con barrido giratorio.
  final bool buscando;

  /// Última ola sin respuesta: en gris.
  final bool apagado;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maximo = size.shortestSide / 2 - 2;
    final color = apagado ? NexaColors.muted : NexaColors.cyan;
    double radio(int i) => maximo * i / total;
    final actual = radio(ola.clamp(1, total));

    canvas.drawCircle(c, actual, Paint()..color = color.withValues(alpha: 0.1));
    if (buscando) {
      final angulo = giro.value * 2 * math.pi;
      final zona = Rect.fromCircle(center: c, radius: actual);
      canvas.drawArc(
        zona,
        angulo - 1,
        1,
        true,
        Paint()
          ..shader = SweepGradient(
            startAngle: 0,
            endAngle: 1,
            colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.45)],
            transform: GradientRotation(angulo - 1),
          ).createShader(zona),
      );
      // Un pulso que sale del punto de recogida hasta la ola actual.
      final u = (giro.value * 2) % 1;
      canvas.drawCircle(
        c,
        actual * u,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = NexaColors.sky.withValues(alpha: (1 - u) * 0.7),
      );
    }
    final aro = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 1; i <= total; i++) {
      aro.color = i <= ola ? color : NexaColors.line;
      canvas.drawCircle(c, radio(i), aro);
    }
    canvas
      ..drawCircle(c, 5, Paint()..color = NexaColors.bg)
      ..drawCircle(c, 3.5, Paint()..color = NexaColors.sky);
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.ola != ola ||
      old.total != total ||
      old.buscando != buscando ||
      old.apagado != apagado;
}
