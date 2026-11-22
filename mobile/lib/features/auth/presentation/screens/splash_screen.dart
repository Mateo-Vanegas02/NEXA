import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/nexa_logo.dart';
import '../controllers/session_controller.dart';

/// Carátula (rediseño 2026): la N de NEXA es una ruta. Sale de un punto que
/// late, recorre la letra con el degradado cian → azul y llega a un pin de
/// destino; es la idea que se repite en toda la app. Luego entra el nombre
/// inclinado y abajo queda la firma «una app de NEXA» mientras se restaura la
/// sesión.
///
/// La animación corre una sola vez (2,4 s) y se queda en el cuadro final; con
/// «reducir animaciones» se muestra ese cuadro desde el principio.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final Animation<double> _lema = _tramo(0.76, 0.92);
  late final Animation<double> _firma = _tramo(0.8, 1);
  late final Animation<double> _barra = _tramo(0.72, 1, Curves.easeInOut);
  late final List<Animation<double>> _letras = [
    for (var i = 0; i < 4; i++) _tramo(0.6 + i * 0.045, 0.78 + i * 0.045),
  ];
  bool _arrancada = false;

  Animation<double> _tramo(
    double desde,
    double hasta, [
    Curve curva = Curves.easeOutCubic,
  ]) => CurvedAnimation(
    parent: _c,
    curve: Interval(desde, hasta, curve: curva),
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(sesionProvider.notifier).iniciar());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arrancada) return;
    _arrancada = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      // Tamaño fijo a toda la pantalla: sin esto la columna se encoge al
      // ancho de su hijo más ancho y el fondo no cubre.
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.35),
            radius: 1.1,
            colors: [Color(0xFF06324F), NexaColors.bg],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Sp.xl),
            child: Column(
              children: [
                const Spacer(flex: 3),
                Flexible(
                  flex: 10,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          label: 'NEXA',
                          image: true,
                          child: ExcludeSemantics(
                            child: CustomPaint(
                              size: _RutaN.tamano,
                              painter: _RutaN(_c),
                            ),
                          ),
                        ),
                        const SizedBox(height: Sp.xl),
                        Semantics(
                          label: l.appNombre,
                          child: ExcludeSemantics(
                            child: _Nombre(letras: _letras),
                          ),
                        ),
                        const SizedBox(height: Sp.sm),
                        FadeTransition(
                          opacity: _lema,
                          child: Text(
                            l.lema,
                            style: NexaTexto.cuerpo.copyWith(
                              color: NexaColors.muted,
                            ),
                          ),
                        ),
                        const SizedBox(height: Sp.xxl),
                        FadeTransition(
                          opacity: _lema,
                          child: ExcludeSemantics(
                            child: _BarraCarga(avance: _barra),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: _firma,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _Firma(deQuien: l.splashFirma, lugar: l.ciudadPais),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «NEXA» inclinado, como va la moto: cada letra entra desde la izquierda.
class _Nombre extends StatelessWidget {
  const _Nombre({required this.letras});

  final List<Animation<double>> letras;

  static final Tween<Offset> _entrada = Tween(
    begin: const Offset(-0.7, 0),
    end: Offset.zero,
  );

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (r) => const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, NexaColors.cyan],
      stops: [0.2, 1],
    ).createShader(r),
    child: Transform(
      alignment: Alignment.center,
      transform: Matrix4.skewX(-0.2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 4; i++)
            FadeTransition(
              opacity: letras[i],
              child: SlideTransition(
                position: _entrada.animate(letras[i]),
                child: Text(
                  'NEXA'[i],
                  textScaler: TextScaler.noScaling,
                  style: NexaTexto.display.copyWith(
                    fontSize: 56,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Barra de carga: una moto que recorre su ruta.
class _BarraCarga extends StatelessWidget {
  const _BarraCarga({required this.avance});

  final Animation<double> avance;

  static const double _ancho = 172;
  static const double _moto = 22;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _ancho,
    height: 28,
    child: AnimatedBuilder(
      animation: avance,
      builder: (_, _) {
        final v = avance.value.clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: NexaColors.line,
                  borderRadius: BorderRadius.circular(Rad.pill),
                ),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              width: _ancho * v,
              height: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: NexaColors.cyan,
                  borderRadius: BorderRadius.circular(Rad.pill),
                  boxShadow: NexaShadows.glow,
                ),
              ),
            ),
            Positioned(
              left: (_ancho - _moto) * v,
              top: 0,
              child: const Icon(
                Icons.two_wheeler,
                size: _moto,
                color: NexaColors.cyan,
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// Firma de la marca al pie: «una app de NEXA».
class _Firma extends StatelessWidget {
  const _Firma({required this.deQuien, required this.lugar});

  final String deQuien;
  final String lugar;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(deQuien, style: NexaTexto.pequeno.copyWith(color: NexaColors.tenue)),
      const SizedBox(height: Sp.xs + 2),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NexaLogo(tamano: 28),
          const SizedBox(width: Sp.sm),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.skewX(-0.2),
            child: Text(
              'NEXA',
              style: NexaTexto.subtitulo.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: NexaColors.texto,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: Sp.xs + 2),
      Text(
        lugar.toUpperCase(),
        style: NexaTexto.etiqueta.copyWith(color: NexaColors.tenue),
      ),
    ],
  );
}

/// La N como ruta, según el avance `t` de 0 a 1 (todo sale de `t`):
/// punto de salida que late (0–0,12) → la línea recorre la N (0,08–0,6) con
/// una cabeza blanca → el pin de destino cae en la punta (0,58–0,74) → un aro
/// se abre desde el pin (0,7–1).
class _RutaN extends CustomPainter {
  _RutaN(this.animacion) : super(repaint: animacion);

  final Animation<double> animacion;

  static const Size tamano = Size(150, 176);
  static const double _grosor = 15;

  /// Vértices de la N (abajo izq. → arriba izq. → abajo der. → arriba der.),
  /// con margen para el pin y el brillo.
  static const _a = Offset(22, 158);
  static const _b = Offset(22, 46);
  static const _c = Offset(128, 158);
  static const _d = Offset(128, 46);

  static double _tramo(double t, double desde, double hasta, [Curve? curva]) {
    final u = ((t - desde) / (hasta - desde)).clamp(0.0, 1.0);
    return (curva ?? Curves.linear).transform(u);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = animacion.value;
    final ruta = Path()
      ..moveTo(_a.dx, _a.dy)
      ..lineTo(_b.dx, _b.dy)
      ..lineTo(_c.dx, _c.dy)
      ..lineTo(_d.dx, _d.dy);
    final metrica = ruta.computeMetrics().first;
    final avance = _tramo(t, 0.08, 0.6, Curves.easeInOutCubic);

    // La ruta completa, tenue: se ve hacia dónde va.
    canvas.drawPath(
      ruta,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _grosor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = NexaColors.line.withValues(alpha: 0.7),
    );

    if (avance > 0) {
      final hecho = metrica.extractPath(0, metrica.length * avance);
      final zona = Offset.zero & size;
      const degradado = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [NexaColors.cyan, NexaColors.azul],
      );
      // Brillo debajo y la línea encima.
      canvas
        ..drawPath(
          hecho,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = _grosor + 10
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
            ..color = NexaColors.cyan.withValues(alpha: 0.45),
        )
        ..drawPath(
          hecho,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = _grosor
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..shader = degradado.createShader(zona),
        );
      // Cabeza de la ruta mientras avanza.
      if (avance < 1) {
        final cabeza = metrica
            .getTangentForOffset(metrica.length * avance)
            ?.position;
        if (cabeza != null) {
          canvas
            ..drawCircle(
              cabeza,
              _grosor * 0.9,
              Paint()..color = NexaColors.cyan.withValues(alpha: 0.35),
            )
            ..drawCircle(cabeza, _grosor * 0.42, Paint()..color = Colors.white);
        }
      }
    }

    // Punto de salida: late al principio y queda como origen.
    final pulso = t < 0.12 ? math.sin(t / 0.12 * math.pi) : 0.0;
    canvas
      ..drawCircle(
        _a,
        _grosor * (0.9 + 0.7 * pulso),
        Paint()..color = NexaColors.cyan.withValues(alpha: 0.25 + 0.2 * pulso),
      )
      ..drawCircle(_a, _grosor * 0.55, Paint()..color = Colors.white)
      ..drawCircle(_a, _grosor * 0.28, Paint()..color = NexaColors.cyan);

    // Aro que se abre desde el destino.
    final aro = _tramo(t, 0.7, 1);
    if (aro > 0 && aro < 1) {
      canvas.drawCircle(
        _d,
        14 + aro * 34,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = NexaColors.cyan.withValues(alpha: (1 - aro) * 0.5),
      );
    }

    // Pin de destino con la punta en el final de la N.
    final pin = _tramo(t, 0.58, 0.74, Curves.easeOutBack);
    if (pin > 0) {
      canvas
        ..save()
        ..translate(_d.dx, _d.dy)
        ..scale(pin);
      const r = 13.0;
      const alto = 34.0;
      final gota = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-r * 1.05, -alto * 0.55, -r, -alto + r)
        ..arcToPoint(
          const Offset(r, -alto + r),
          radius: const Radius.circular(r),
        )
        ..quadraticBezierTo(r * 1.05, -alto * 0.55, 0, 0)
        ..close();
      canvas
        ..drawShadow(gota, NexaColors.cyan, 6, false)
        ..drawPath(gota, Paint()..color = Colors.white)
        ..drawCircle(
          const Offset(0, -alto + r),
          r * 0.45,
          Paint()..color = NexaColors.azul,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_RutaN old) => old.animacion != animacion;
}
