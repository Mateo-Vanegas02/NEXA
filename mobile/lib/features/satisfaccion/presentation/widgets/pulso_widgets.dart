import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import 'satisfaccion_widgets.dart';

/// Piezas de NEXA Pulso para el panel de satisfacción: el dial de dos
/// anillos, el anillo de probabilidad y el esquema animado de la red.

bool _oscuro(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

Color _pista(BuildContext c) =>
    _oscuro(c) ? NexaColors.line : c.acento.withValues(alpha: 0.14);

/// Dial de dos anillos concéntricos (0–100 %): por fuera un lado, por dentro
/// el otro. `null` deja el anillo vacío (sin calificaciones en el período).
class DialDoble extends StatelessWidget {
  const DialDoble({
    required this.exterior,
    required this.interior,
    required this.colorExterior,
    required this.colorInterior,
    required this.child,
    this.diametro = 124,
    super.key,
  });

  final double? exterior;
  final double? interior;
  final Color colorExterior;
  final Color colorInterior;

  /// Contenido del centro (se reduce si no cabe).
  final Widget child;
  final double diametro;

  @override
  Widget build(BuildContext context) {
    final duracion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 900);
    final pista = _pista(context);
    return SizedBox.square(
      dimension: diametro,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (exterior ?? 0) / 100),
        duration: duracion,
        curve: Curves.easeOutCubic,
        builder: (context, fuera, _) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: (interior ?? 0) / 100),
          duration: duracion,
          curve: Curves.easeOutCubic,
          builder: (context, dentro, centro) => CustomPaint(
            painter: _DialPainter(
              exterior: fuera,
              interior: dentro,
              colorExterior: colorExterior,
              colorInterior: colorInterior,
              pista: pista,
            ),
            child: centro,
          ),
          child: Center(
            child: SizedBox(
              width: diametro * 0.5,
              child: FittedBox(fit: BoxFit.scaleDown, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.exterior,
    required this.interior,
    required this.colorExterior,
    required this.colorInterior,
    required this.pista,
  });

  final double exterior;
  final double interior;
  final Color colorExterior;
  final Color colorInterior;
  final Color pista;

  static const double _trazo = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final radio = size.shortestSide / 2 - _trazo / 2 - 2;
    void anillo(double r, double fraccion, Color color) {
      final rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _trazo
          ..color = pista,
      );
      final f = fraccion.clamp(0.0, 1.0);
      if (f <= 0) return;
      final barrido = 2 * math.pi * f;
      canvas
        ..drawArc(
          rect,
          -math.pi / 2,
          barrido,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = _trazo + 4
            ..color = color.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        )
        ..drawArc(
          rect,
          -math.pi / 2,
          barrido,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = _trazo
            ..color = color,
        );
    }

    anillo(radio, exterior, colorExterior);
    anillo(radio - _trazo - 6, interior, colorInterior);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.exterior != exterior ||
      old.interior != interior ||
      old.colorExterior != colorExterior ||
      old.colorInterior != colorInterior ||
      old.pista != pista;
}

/// Anillo pequeño con una probabilidad (0 a 1) y su texto en el centro.
class AnilloProbabilidad extends StatelessWidget {
  const AnilloProbabilidad({
    required this.valor,
    required this.texto,
    required this.color,
    this.diametro = 58,
    super.key,
  });

  final double valor;
  final String texto;
  final Color color;
  final double diametro;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: diametro,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.square(
          dimension: diametro - 6,
          child: CircularProgressIndicator(
            value: valor.clamp(0.0, 1.0),
            strokeWidth: 5,
            strokeCap: StrokeCap.round,
            color: color,
            backgroundColor: _pista(context),
          ),
        ),
        SizedBox(
          width: diametro * 0.6,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              texto,
              style: context.textos.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Esquema animado de la red de satisfacción: las variables del viaje entran
/// por la izquierda, pasan por las dos capas comunes y salen por una rama para
/// cada lado. Con [entrenando], además viajan señales doradas hacia atrás.
///
/// Las neuronas de cada capa son las de `ml/nexa_ml/modelo.py` ([capas]); el
/// número de variables lo entrega el servidor. Es un esquema: dibuja unas
/// pocas neuronas por capa y no muestra datos de ningún viaje.
class RedNeuronal extends StatefulWidget {
  const RedNeuronal({
    required this.variables,
    required this.etiquetaVariables,
    required this.etiquetaPasajero,
    required this.etiquetaConductor,
    required this.semantica,
    this.entrenando = false,
    this.alto = 176,
    super.key,
  });

  /// Neuronas de las capas ocultas: comunes 1 y 2, y cada rama.
  static const List<int> capas = [32, 16, 8];

  final int variables;
  final String etiquetaVariables;
  final String etiquetaPasajero;
  final String etiquetaConductor;
  final String semantica;
  final bool entrenando;
  final double alto;

  @override
  State<RedNeuronal> createState() => _RedNeuronalState();
}

class _RedNeuronalState extends State<RedNeuronal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c
        ..stop()
        ..value = 0.37;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rotulo = context.textos.labelSmall?.copyWith(
      color: context.muted,
      fontSize: 10,
      letterSpacing: 0,
    );
    return Semantics(
      label: widget.semantica,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: widget.alto,
          child: CustomPaint(
            size: Size.infinite,
            painter: _RedPainter(
              reloj: _c,
              entrenando: widget.entrenando,
              colorPasajero: context.acento,
              colorConductor: colorOk(context),
              colorNodo: context.acento,
              fondoNodo: fondoTarjeta(context),
              rotulo: rotulo ?? const TextStyle(fontSize: 10),
              rotulos: [
                widget.etiquetaVariables,
                '${RedNeuronal.capas[0]}',
                '${RedNeuronal.capas[1]}',
                '${RedNeuronal.capas[2]} + ${RedNeuronal.capas[2]}',
              ],
              salidas: [widget.etiquetaPasajero, widget.etiquetaConductor],
            ),
          ),
        ),
      ),
    );
  }
}

/// Recorrido de una señal: una neurona por capa, de la entrada a la salida.
typedef _Senal = ({List<int> ruta, double fase});

/// Neuronas que se dibujan por capa (entradas, común 1, común 2, ramas, salidas).
const List<int> _dibujadas = [9, 8, 6, 6, 2];

List<_Senal> _senales(int cuantas, int semilla) {
  final azar = math.Random(semilla);
  final salida = <_Senal>[];
  for (var i = 0; i < cuantas; i++) {
    final rama = azar.nextInt(6);
    final ruta = <int>[
      azar.nextInt(_dibujadas[0]),
      azar.nextInt(_dibujadas[1]),
      azar.nextInt(_dibujadas[2]),
      rama,
      // Las tres primeras neuronas de la rama van al pasajero.
      rama < 3 ? 0 : 1,
    ];
    salida.add((ruta: ruta, fase: azar.nextDouble()));
  }
  return salida;
}

final List<_Senal> _ida = _senales(26, 7);
final List<_Senal> _vuelta = _senales(16, 19);

class _RedPainter extends CustomPainter {
  _RedPainter({
    required this.reloj,
    required this.entrenando,
    required this.colorPasajero,
    required this.colorConductor,
    required this.colorNodo,
    required this.fondoNodo,
    required this.rotulo,
    required this.rotulos,
    required this.salidas,
  }) : super(repaint: reloj);

  final Animation<double> reloj;
  final bool entrenando;
  final Color colorPasajero;
  final Color colorConductor;
  final Color colorNodo;
  final Color fondoNodo;
  final TextStyle rotulo;
  final List<String> rotulos;
  final List<String> salidas;

  static const List<double> _x = [0.07, 0.31, 0.54, 0.75, 0.93];
  static const List<double> _ramas = [0.08, 0.22, 0.36, 0.64, 0.78, 0.92];
  static const List<double> _ySalidas = [0.22, 0.78];

  void _texto(Canvas canvas, String s, Offset centro, {bool derecha = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: rotulo),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final dx = derecha ? centro.dx - tp.width : centro.dx - tp.width / 2;
    tp.paint(canvas, Offset(math.max(0, dx), centro.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = reloj.value;
    final alto = size.height - 22;
    final nodos = <List<Offset>>[
      for (var capa = 0; capa < _dibujadas.length; capa++)
        [
          for (var k = 0; k < _dibujadas[capa]; k++)
            Offset(
              size.width * _x[capa],
              switch (capa) {
                3 => alto * _ramas[k],
                4 => alto * _ySalidas[k],
                _ => 10 + (alto - 20) * k / (_dibujadas[capa] - 1),
              },
            ),
        ],
    ];

    // Conexiones: todas entre capas comunes; cada rama solo con su salida.
    final lineas = Path();
    for (var capa = 0; capa < 3; capa++) {
      for (final a in nodos[capa]) {
        for (final b in nodos[capa + 1]) {
          lineas
            ..moveTo(a.dx, a.dy)
            ..lineTo(b.dx, b.dy);
        }
      }
    }
    for (var k = 0; k < 6; k++) {
      final a = nodos[3][k];
      final b = nodos[4][k < 3 ? 0 : 1];
      lineas
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
    }
    canvas.drawPath(
      lineas,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = colorNodo.withValues(alpha: 0.09),
    );

    // Señales: cada una recorre su ruta; al llegar enciende la neurona.
    final brillo = <List<double>>[
      for (final n in _dibujadas) List<double>.filled(n, 0),
    ];
    void senal(_Senal s, {required bool atras, required Color color}) {
      final ciclo = (t * (atras ? 4 : 3) + s.fase) % 1;
      final avance = (atras ? 1 - ciclo : ciclo) * 4;
      final tramo = math.min(3, avance.floor());
      final u = avance - tramo;
      final a = nodos[tramo][s.ruta[tramo]];
      final b = nodos[tramo + 1][s.ruta[tramo + 1]];
      final p = Offset.lerp(a, b, u)!;
      final cola = Offset.lerp(a, b, (u + (atras ? 0.14 : -0.14)).clamp(0.0, 1.0))!;
      canvas
        ..drawLine(
          p,
          cola,
          Paint()
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round
            ..color = color.withValues(alpha: 0.5),
        )
        ..drawCircle(p, 2.3, Paint()..color = color);
      final llega = atras ? tramo : tramo + 1;
      final cerca = atras ? 1 - u : u;
      final i = s.ruta[llega];
      brillo[llega][i] = math.max(brillo[llega][i], cerca * cerca);
    }

    for (final s in _ida) {
      senal(s, atras: false, color: NexaColors.sky);
    }
    if (entrenando) {
      for (final s in _vuelta) {
        senal(s, atras: true, color: NexaColors.gold);
      }
    }

    for (var capa = 0; capa < nodos.length; capa++) {
      for (var k = 0; k < nodos[capa].length; k++) {
        final p = nodos[capa][k];
        final salida = capa == 4;
        final color = salida
            ? (k == 0 ? colorPasajero : colorConductor)
            : colorNodo;
        final b = brillo[capa][k];
        final r = salida ? 7.0 : 3.6;
        if (b > 0.02 || salida) {
          canvas.drawCircle(
            p,
            r + 4 + b * 5,
            Paint()..color = color.withValues(alpha: salida ? 0.22 : 0.3 * b),
          );
        }
        canvas
          ..drawCircle(p, r, Paint()..color = salida ? color : fondoNodo)
          ..drawCircle(
            p,
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = color.withValues(alpha: salida ? 1.0 : 0.45 + 0.55 * b),
          );
      }
    }

    for (var i = 0; i < rotulos.length; i++) {
      _texto(canvas, rotulos[i], Offset(size.width * _x[i], size.height - 8));
    }
    for (var k = 0; k < 2; k++) {
      _texto(
        canvas,
        salidas[k],
        Offset(size.width - 2, alto * _ySalidas[k] - 17),
        derecha: true,
      );
    }
  }

  @override
  bool shouldRepaint(_RedPainter old) =>
      old.entrenando != entrenando ||
      old.colorPasajero != colorPasajero ||
      old.colorConductor != colorConductor ||
      old.colorNodo != colorNodo ||
      old.fondoNodo != fondoNodo ||
      old.rotulo != rotulo;
}
