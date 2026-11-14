import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/nexa_logo.dart';
import '../controllers/session_controller.dart';

/// Carátula (NEXA Pulso): un latido, la calle que se acelera y el faro de la
/// moto que se enciende con el logo adentro. El nombre entra inclinado y abajo
/// queda la firma «una app de NEXA» mientras se restaura la sesión.
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
  late final Animation<double> _logo = _tramo(0.5, 0.74, Curves.easeOutBack);
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
                        // La calle y el destello se pintan desde el centro
                        // del faro y se salen de su caja a propósito.
                        CustomPaint(
                          painter: _CallePainter(_c),
                          child: ScaleTransition(
                            scale: _logo,
                            child: const _Faro(),
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

/// El faro: disco blanco con brillo y, adentro, la moto del logo de NEXA
/// (el recorte deja fuera el nombre que trae la imagen: va más grande abajo).
class _Faro extends StatelessWidget {
  const _Faro();

  static const double _d = 132;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'NEXA',
    image: true,
    child: ExcludeSemantics(
      child: Container(
        width: _d,
        height: _d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: NexaColors.cyan.withValues(alpha: 0.18),
              spreadRadius: 6,
            ),
            BoxShadow(
              color: NexaColors.cyan.withValues(alpha: 0.55),
              blurRadius: 70,
              spreadRadius: 10,
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            children: [
              Positioned(
                left: -_d * 0.231,
                top: -_d * 0.0735,
                width: _d * 1.439,
                height: _d * 1.439,
                child: Image.asset(
                  NexaLogo.asset,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _d * 0.2,
                child: ColoredBox(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    ),
  );
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

/// Un trazo de la calle: sale del centro en [angulo] y avanza hacia afuera.
typedef _Trazo = ({double angulo, double radio, double largo, double paso});

final List<_Trazo> _trazos = () {
  final azar = math.Random(5);
  return [
    for (var i = 0; i < 96; i++)
      (
        angulo: azar.nextDouble() * 2 * math.pi,
        radio: azar.nextDouble() * 340,
        largo: 18 + azar.nextDouble() * 70,
        paso: 0.5 + azar.nextDouble(),
      ),
  ];
}();

/// Lo que pasa detrás del faro, según el avance `t` de 0 a 1:
/// latido (0–0,24) → calle que se acelera (0,2–0,85) → destello (0,5–0,72) →
/// aros que se abren (0,56–1). Todo sale de `t`, sin estado entre cuadros.
class _CallePainter extends CustomPainter {
  _CallePainter(this.animacion) : super(repaint: animacion);

  final Animation<double> animacion;

  static const double _alcance = 520;

  /// Empuje de la calle: sube en 0,2–0,5 y se apaga hacia 0,85.
  static double _empuje(double t) {
    if (t <= 0.2 || t >= 0.85) return 0;
    if (t < 0.5) {
      final u = (t - 0.2) / 0.3;
      return u * u;
    }
    return 1 - (t - 0.5) / 0.35;
  }

  /// Camino recorrido por los trazos hasta `t` (la integral del empuje).
  static double _recorrido(double t) {
    if (t <= 0.2) return 0;
    if (t < 0.5) {
      final u = (t - 0.2) / 0.3;
      return 0.1 * u * u * u;
    }
    final v = ((t - 0.5) / 0.35).clamp(0.0, 1.0);
    return 0.1 + 0.35 * (v - v * v / 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = animacion.value;
    final c = size.center(Offset.zero);

    if (t < 0.24) {
      final pulso = math.sin(t / 0.24 * 2 * math.pi).abs();
      canvas
        ..drawCircle(
          c,
          14 + 12 * pulso,
          Paint()..color = NexaColors.cyan.withValues(alpha: 0.28 * pulso),
        )
        ..drawCircle(c, 5 + 4 * pulso, Paint()..color = NexaColors.texto);
    }

    final empuje = _empuje(t);
    if (empuje > 0.01) {
      final avance = _recorrido(t) * 2280;
      final trazo = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (final z in _trazos) {
        final r0 = (z.radio + avance * z.paso) % _alcance;
        final r1 = r0 + z.largo * (0.25 + empuje) * (r0 / 190);
        final dir = Offset(math.cos(z.angulo), math.sin(z.angulo));
        trazo
          ..strokeWidth = 1 + r0 / 240
          ..color = NexaColors.sky.withValues(
            alpha: (empuje * 0.6 * math.min(1, r0 / 130)).clamp(0.0, 1.0),
          );
        canvas.drawLine(c + dir * r0, c + dir * r1, trazo);
      }
    }

    if (t > 0.5 && t < 0.72) {
      final f = 1 - (t - 0.5) / 0.22;
      final zona = Rect.fromCircle(center: c, radius: 440);
      canvas.drawRect(
        zona,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: f),
              NexaColors.cyan.withValues(alpha: f * 0.65),
              NexaColors.cyan.withValues(alpha: 0),
            ],
            stops: const [0, 0.3, 1],
          ).createShader(zona),
      );
    }

    if (t > 0.56 && t < 1) {
      final aro = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      for (var i = 0; i < 2; i++) {
        final u = (t - 0.56) / 0.44 - i * 0.35;
        if (u <= 0 || u >= 1) continue;
        aro.color = NexaColors.cyan.withValues(alpha: (1 - u) * 0.32);
        canvas.drawCircle(c, 72 + u * 130, aro);
      }
    }
  }

  @override
  bool shouldRepaint(_CallePainter old) => old.animacion != animacion;
}
