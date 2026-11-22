import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../mapa/polyline.dart';
import '../theme/tokens.dart';

/// Miniatura de una ruta (rediseño 2026): el trazado del servidor dibujado
/// sobre un fondo de mapa, sin teselas ni red. Con [corte] (0..1, la fracción
/// recorrida) lo recorrido va en cian y lo que faltó, punteado.
class MiniRuta extends StatelessWidget {
  const MiniRuta({
    required this.geometria,
    this.corte,
    this.puntos,
    this.radio = Rad.md,
    super.key,
  });

  /// Polyline codificada (precisión 5), como la envía el servidor.
  final String? geometria;

  /// Puntos ya decodificados (si no hay geometría).
  final List<LatLng>? puntos;
  final double? corte;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final ruta = puntos ?? decodificarPolyline(geometria);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radio),
        child: CustomPaint(
          painter: _MiniRutaPainter(ruta, corte),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _MiniRutaPainter extends CustomPainter {
  _MiniRutaPainter(this.ruta, this.corte);
  final List<LatLng> ruta;
  final double? corte;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = NexaColors.mapaOscuroFondo,
    );
    // Calles sugeridas: una trama diagonal tenue.
    final calle = Paint()
      ..color = NexaColors.mapaOscuroCalle
      ..strokeWidth = 1;
    final paso = math.max(14.0, size.shortestSide / 5);
    for (var x = -size.height; x < size.width; x += paso) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height * 0.6, 0),
        calle,
      );
    }
    for (var y = paso / 2; y < size.height; y += paso) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - paso / 3), calle);
    }
    if (ruta.length < 2) return;

    var minLat = ruta.first.latitude, maxLat = minLat;
    var minLng = ruta.first.longitude, maxLng = minLng;
    for (final p in ruta) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    final cosLat = math.cos((minLat + maxLat) / 2 * math.pi / 180);
    final ancho = math.max((maxLng - minLng) * cosLat, 1e-6);
    final alto = math.max(maxLat - minLat, 1e-6);
    final margen = size.shortestSide * 0.16;
    final escala = math.min(
      (size.width - margen * 2) / ancho,
      (size.height - margen * 2) / alto,
    );
    final dx = (size.width - ancho * escala) / 2;
    final dy = (size.height - alto * escala) / 2;
    Offset a(LatLng p) => Offset(
      dx + (p.longitude - minLng) * cosLat * escala,
      dy + (maxLat - p.latitude) * escala,
    );
    final pts = ruta.map(a).toList();

    // Dónde se corta (por longitud del trazado en pantalla).
    final k = corte?.clamp(0.0, 1.0);
    var hecho = pts;
    var falta = <Offset>[];
    if (k != null && k < 1) {
      var total = 0.0;
      for (var i = 1; i < pts.length; i++) {
        total += (pts[i] - pts[i - 1]).distance;
      }
      var meta = total * k;
      hecho = [pts.first];
      for (var i = 1; i < pts.length; i++) {
        final d = (pts[i] - pts[i - 1]).distance;
        if (meta <= d) {
          final c = Offset.lerp(pts[i - 1], pts[i], d == 0 ? 0 : meta / d)!;
          hecho.add(c);
          falta = [c, ...pts.sublist(i)];
          break;
        }
        meta -= d;
        hecho.add(pts[i]);
      }
    }

    final grosor = math.max(2.5, size.shortestSide / 26);
    Path camino(List<Offset> l) {
      final p = Path()..moveTo(l.first.dx, l.first.dy);
      for (final q in l.skip(1)) {
        p.lineTo(q.dx, q.dy);
      }
      return p;
    }

    if (falta.length >= 2) {
      final punteado = Paint()
        ..color = NexaColors.rutaAlterna
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor * 0.7
        ..strokeCap = StrokeCap.round;
      for (final m in camino(falta).computeMetrics()) {
        for (var d = 0.0; d < m.length; d += grosor * 3) {
          canvas.drawPath(m.extractPath(d, d + grosor * 1.6), punteado);
        }
      }
    }
    canvas.drawPath(
      camino(hecho),
      Paint()
        ..color = NexaColors.rutaBorde
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor + 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      camino(hecho),
      Paint()
        ..shader = ui.Gradient.linear(hecho.first, hecho.last, const [
          NexaColors.cyan,
          NexaColors.azul,
        ])
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final r = grosor * 1.2;
    canvas
      ..drawCircle(pts.first, r + 1.5, Paint()..color = NexaColors.bg)
      ..drawCircle(
        pts.first,
        r,
        Paint()
          ..color = NexaColors.cyan
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: pts.last, width: r * 2, height: r * 2),
          const Radius.circular(2),
        ),
        Paint()..color = NexaColors.texto,
      );
    if (k != null && k < 1 && hecho.isNotEmpty) {
      canvas.drawCircle(hecho.last, r, Paint()..color = NexaColors.gold);
    }
  }

  @override
  bool shouldRepaint(_MiniRutaPainter old) =>
      old.ruta != ruta || old.corte != corte;
}
