import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Nombres de las imágenes que el mapa registra al cargar el estilo.
abstract final class ImagenMarcador {
  static const personaCielo = 'nx-persona-cielo';
  static const personaOro = 'nx-persona-oro';
  static const personaGris = 'nx-persona-gris';
  static const hazCielo = 'nx-haz-cielo';
  static const hazOro = 'nx-haz-oro';
  static const marcaHacia = 'nx-marca-hacia';
  static const moto = 'nx-moto';
  static const motoGris = 'nx-moto-gris';
  static const motoPropia = 'nx-moto-propia';
  static const proa = 'nx-proa';
  static const proaGris = 'nx-proa-gris';
  static const recogida = 'nx-recogida';
  static const destino = 'nx-destino';
}

/// Las imágenes se dibujan al doble y se muestran con `iconSize: 0.5`
/// (nítidas en pantallas de alta densidad).
const double kEscalaMarcador = 2;

/// Dibuja todos los marcadores del sistema «Quién es quién» como PNG.
///
/// Forma = rol (personita = persona, motico = vehículo); color = quién
/// (celeste tú, dorado la pasajera vista por el conductor, cian la moto).
/// La forma nunca gira: giran el haz del pasajero y la proa de la moto.
Future<Map<String, Uint8List>> dibujarMarcadores() async => {
  ImagenMarcador.personaCielo: await _png(
    76,
    (c, s) => _persona(c, s, NexaColors.sky),
  ),
  ImagenMarcador.personaOro: await _png(
    76,
    (c, s) => _persona(c, s, NexaColors.gold),
  ),
  ImagenMarcador.personaGris: await _png(
    76,
    (c, s) => _persona(c, s, NexaColors.muted, apagada: true),
  ),
  ImagenMarcador.hazCielo: await _png(220, (c, s) => _haz(c, s, NexaColors.sky)),
  ImagenMarcador.hazOro: await _png(220, (c, s) => _haz(c, s, NexaColors.gold)),
  ImagenMarcador.marcaHacia: await _png(84, _marcaHacia),
  ImagenMarcador.moto: await _png(82, (c, s) => _moto(c, s, diametro: 46)),
  ImagenMarcador.motoPropia: await _png(
    96,
    (c, s) => _moto(c, s, diametro: 54),
  ),
  ImagenMarcador.motoGris: await _png(
    82,
    (c, s) => _moto(c, s, diametro: 46, gris: true),
  ),
  ImagenMarcador.proa: await _png(76, (c, s) => _proa(c, s, NexaColors.cyan)),
  ImagenMarcador.proaGris: await _png(
    76,
    (c, s) => _proa(c, s, NexaColors.muted),
  ),
  ImagenMarcador.recogida: await _png(44, _pinRecogida, alto: 56),
  ImagenMarcador.destino: await _png(34, _destino),
};

Future<Uint8List> _png(
  double lado,
  void Function(Canvas, Size) pintar, {
  double? alto,
}) async {
  final tam = Size(lado, alto ?? lado);
  final grabadora = ui.PictureRecorder();
  final lienzo = Canvas(grabadora)..scale(kEscalaMarcador);
  pintar(lienzo, tam);
  final imagen = await grabadora.endRecording().toImage(
    (tam.width * kEscalaMarcador).ceil(),
    (tam.height * kEscalaMarcador).ceil(),
  );
  final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
  return datos!.buffer.asUint8List();
}

const _sombra = Color(0x8C000000);

/// Personita: halo de precisión, cara de color con aro blanco y el glifo.
void _persona(Canvas c, Size s, Color color, {bool apagada = false}) {
  final centro = s.center(Offset.zero);
  c
    ..drawCircle(centro, 36, Paint()..color = color.withValues(alpha: 0.12))
    ..drawCircle(
      centro,
      36,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: 0.32),
    )
    ..drawCircle(
      centro.translate(0, 3),
      20,
      Paint()
        ..color = _sombra
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    )
    ..drawCircle(centro, 19, Paint()..color = apagada ? NexaColors.muted : NexaColors.texto)
    ..drawCircle(centro, 16, Paint()..color = apagada ? NexaColors.raised : color);
  final tinta = Paint()..color = apagada ? NexaColors.muted : NexaColors.bg;
  // Cabeza y hombros (glifo de 22 × 22 centrado).
  final o = centro.translate(-11, -11);
  c
    ..drawCircle(o.translate(11, 6.7), 3.4, tinta)
    ..drawPath(
      Path()
        ..moveTo(o.dx + 4.2, o.dy + 18.8)
        ..cubicTo(
          o.dx + 4.8,
          o.dy + 14.9,
          o.dx + 7.5,
          o.dy + 12.4,
          o.dx + 11,
          o.dy + 12.4,
        )
        ..cubicTo(
          o.dx + 14.5,
          o.dy + 12.4,
          o.dx + 17.2,
          o.dy + 14.9,
          o.dx + 17.8,
          o.dy + 18.8,
        )
        ..close(),
      tinta,
    );
}

/// Haz de orientación: abanico de 70° que se desvanece hacia afuera. Apunta
/// hacia arriba; el mapa lo gira con el rumbo del teléfono.
void _haz(Canvas c, Size s, Color color) {
  final centro = s.center(Offset.zero);
  const radio = 100.0;
  const medio = 35 * math.pi / 180;
  final rect = Rect.fromCircle(center: centro, radius: radio);
  c.drawPath(
    Path()
      ..moveTo(centro.dx, centro.dy)
      ..arcTo(rect, -math.pi / 2 - medio, medio * 2, false)
      ..close(),
    Paint()
      ..shader = ui.Gradient.radial(
        centro,
        radio,
        [color.withValues(alpha: 0.7), color.withValues(alpha: 0)],
        [0.12, 1],
      ),
  );
}

/// Marca en el aro de la personita que señala hacia dónde está la moto.
void _marcaHacia(Canvas c, Size s) {
  final centro = s.center(Offset.zero);
  final aro = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = NexaColors.cyan.withValues(alpha: 0.3);
  const radio = 33.0;
  // Aro punteado.
  for (var a = 0.0; a < 2 * math.pi; a += 0.24) {
    c.drawArc(
      Rect.fromCircle(center: centro, radius: radio),
      a,
      0.09,
      false,
      aro,
    );
  }
  c.drawPath(
    Path()
      ..moveTo(centro.dx, centro.dy - radio - 8)
      ..lineTo(centro.dx + 7, centro.dy - radio + 4)
      ..lineTo(centro.dx - 7, centro.dy - radio + 4)
      ..close(),
    Paint()..color = NexaColors.cyan,
  );
}

/// Motico: brillo cian, disco con aro blanco y la moto siempre derecha.
void _moto(Canvas c, Size s, {required double diametro, bool gris = false}) {
  final centro = s.center(Offset.zero);
  final r = diametro / 2;
  if (!gris) {
    c.drawCircle(
      centro,
      r + 14,
      Paint()
        ..shader = ui.Gradient.radial(centro, r + 14, [
          NexaColors.cyan.withValues(alpha: 0.38),
          NexaColors.cyan.withValues(alpha: 0),
        ]),
    );
  }
  c
    ..drawCircle(
      centro.translate(0, 4),
      r + 1,
      Paint()
        ..color = _sombra
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    )
    ..drawCircle(
      centro,
      r,
      Paint()..color = gris ? NexaColors.muted : NexaColors.texto,
    )
    ..drawCircle(
      centro,
      r - 3,
      Paint()..color = gris ? NexaColors.raised : NexaColors.cyan,
    );
  final glifo = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(Icons.two_wheeler.codePoint),
      style: TextStyle(
        fontSize: diametro * 0.58,
        fontFamily: Icons.two_wheeler.fontFamily,
        package: Icons.two_wheeler.fontPackage,
        color: gris ? NexaColors.muted : NexaColors.bg,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  glifo.paint(c, centro - Offset(glifo.width / 2, glifo.height / 2));
}

/// Proa: punta en el aro de la moto que gira con su rumbo.
void _proa(Canvas c, Size s, Color color) {
  final cx = s.width / 2;
  c.drawPath(
    Path()
      ..moveTo(cx, 2)
      ..lineTo(cx + 9, 15)
      ..quadraticBezierTo(cx, 11, cx - 9, 15)
      ..close(),
    Paint()..color = color,
  );
  c.drawPath(
    Path()
      ..moveTo(cx, 2)
      ..lineTo(cx + 9, 15)
      ..quadraticBezierTo(cx, 11, cx - 9, 15)
      ..close(),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..color = NexaColors.texto,
  );
}

/// Pin de recogida cian (el ancla va abajo: `iconAnchor: bottom`).
void _pinRecogida(Canvas c, Size s) {
  final cx = s.width / 2;
  final gota = Path()
    ..moveTo(cx, s.height - 3)
    ..cubicTo(cx, s.height - 3, cx - 18, 32, cx - 18, 21)
    ..arcToPoint(Offset(cx + 18, 21), radius: const Radius.circular(18))
    ..cubicTo(cx + 18, 32, cx, s.height - 3, cx, s.height - 3)
    ..close();
  c
    ..drawPath(
      gota.shift(const Offset(0, 2)),
      Paint()
        ..color = _sombra
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    )
    ..drawPath(gota, Paint()..color = NexaColors.cyan)
    ..drawPath(
      gota,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = NexaColors.texto,
    )
    ..drawCircle(Offset(cx, 21), 6, Paint()..color = NexaColors.bg);
}

/// Destino: cuadro blanco (nunca se confunde con la recogida).
void _destino(Canvas c, Size s) {
  final centro = s.center(Offset.zero);
  final cuadro = RRect.fromRectAndRadius(
    Rect.fromCenter(center: centro, width: 26, height: 26),
    const Radius.circular(7),
  );
  c
    ..drawRRect(
      cuadro.shift(const Offset(0, 3)),
      Paint()
        ..color = _sombra
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    )
    ..drawRRect(cuadro, Paint()..color = NexaColors.texto)
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: centro, width: 9, height: 9),
        const Radius.circular(2),
      ),
      Paint()..color = NexaColors.bg,
    );
}
