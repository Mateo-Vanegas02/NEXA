import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../controllers/session_controller.dart';

/// Bienvenida (NEXA Pulso): cuatro promesas y una sola línea de neón que se
/// transforma al deslizar: ruta con su precio, escudo con los documentos,
/// radar del viaje en vivo y escalera de niveles. Abajo, siempre, las dos
/// salidas (crear cuenta / ya tengo cuenta). También es `/inicio`.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _page = PageController();

  /// Recorre la línea una vez al entrar y cada vez que cambia la página.
  late final AnimationController _corredor = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  int _i = 0;
  bool _arrancada = false;
  bool _sinAnimar = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sinAnimar = MediaQuery.disableAnimationsOf(context);
    if (_arrancada) return;
    _arrancada = true;
    _recorrer();
  }

  void _recorrer() {
    if (_sinAnimar) {
      _corredor.value = 1;
    } else {
      _corredor.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _page.dispose();
    _corredor.dispose();
    super.dispose();
  }

  Future<void> _ir(String ruta) async {
    await ref.read(sesionProvider.notifier).completarOnboarding();
    if (mounted) context.go(ruta);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final paginas = [
      (l.onb1Titulo, l.onb1Texto),
      (l.onb2Titulo, l.onb2Texto),
      (l.onb3Titulo, l.onb3Texto),
      (l.onb4Titulo, l.onb4Texto),
    ];
    final margen = context.gutter + Sp.xs;
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          child: ContenidoCentrado(
            child: LayoutBuilder(
              builder: (context, c) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: math.min(c.maxHeight * 0.46, 380),
                    child: ExcludeSemantics(
                      child: _Arte(pagina: _page, corredor: _corredor),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _page,
                      itemCount: paginas.length,
                      onPageChanged: (i) {
                        setState(() => _i = i);
                        _recorrer();
                      },
                      itemBuilder: (_, i) {
                        final (titulo, texto) = paginas[i];
                        return SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            margen,
                            Sp.md,
                            margen,
                            Sp.sm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.onbPaso(i + 1, paginas.length),
                                style: NexaTexto.etiqueta.copyWith(
                                  color: NexaColors.cyan,
                                ),
                              ),
                              const SizedBox(height: Sp.sm),
                              Text(
                                titulo,
                                style: NexaTexto.display.copyWith(fontSize: 30),
                              ),
                              const SizedBox(height: Sp.md),
                              Text(
                                texto,
                                style: NexaTexto.cuerpo.copyWith(
                                  color: NexaColors.muted,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: margen),
                    child: Semantics(
                      label: l.onbPaginaSemantica(_i + 1, paginas.length),
                      child: Row(
                        children: [
                          for (var i = 0; i < paginas.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: Sp.xs + 2),
                              width: i == _i ? 26 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == _i
                                    ? NexaColors.cyan
                                    : NexaColors.line,
                                borderRadius: BorderRadius.circular(Rad.pill),
                                boxShadow: i == _i ? NexaShadows.glow : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.gutter,
                      Sp.xl,
                      context.gutter,
                      Sp.md,
                    ),
                    child: Column(
                      children: [
                        NexaButton(
                          label: l.crearCuenta,
                          onPressed: () => _ir('/registro'),
                        ),
                        const SizedBox(height: Sp.sm),
                        NexaButton(
                          label: l.yaTengoCuenta,
                          variant: NexaButtonVariant.fantasma,
                          onPressed: () => _ir('/login'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Puntos con que se dibuja la línea en cada forma (todas tienen los mismos
/// para poder pasar de una a otra punto por punto).
const int _puntos = 120;

/// Reparte [_puntos] puntos a distancias iguales sobre la poligonal [p].
List<Offset> _repartir(List<Offset> p) {
  final acumulado = <double>[0];
  for (var i = 1; i < p.length; i++) {
    acumulado.add(acumulado.last + (p[i] - p[i - 1]).distance);
  }
  final total = acumulado.last;
  final salida = <Offset>[];
  var k = 1;
  for (var i = 0; i < _puntos; i++) {
    final d = total * i / (_puntos - 1);
    while (k < p.length - 1 && acumulado[k] < d) {
      k++;
    }
    final tramo = acumulado[k] - acumulado[k - 1];
    final u = tramo == 0 ? 0.0 : (d - acumulado[k - 1]) / tramo;
    salida.add(Offset.lerp(p[k - 1], p[k], u)!);
  }
  return salida;
}

/// Las cuatro formas, en un cuadro de lado 1: ruta, escudo, radar y escalera.
final List<List<Offset>> _formas = [
  _repartir(const [
    Offset(0.16, 0.86),
    Offset(0.16, 0.62),
    Offset(0.46, 0.62),
    Offset(0.46, 0.38),
    Offset(0.76, 0.38),
    Offset(0.76, 0.18),
  ]),
  _repartir(const [
    Offset(0.5, 0.1),
    Offset(0.78, 0.2),
    Offset(0.78, 0.46),
    Offset(0.74, 0.58),
    Offset(0.66, 0.7),
    Offset(0.58, 0.8),
    Offset(0.5, 0.86),
    Offset(0.42, 0.8),
    Offset(0.34, 0.7),
    Offset(0.26, 0.58),
    Offset(0.22, 0.46),
    Offset(0.22, 0.2),
    Offset(0.5, 0.1),
  ]),
  _repartir([
    for (var i = 0; i <= 160; i++)
      Offset(
        0.5 +
            math.cos(i / 160 * 6 * math.pi - math.pi / 2) *
                (0.03 + i / 160 * 0.37),
        0.5 +
            math.sin(i / 160 * 6 * math.pi - math.pi / 2) *
                (0.03 + i / 160 * 0.37),
      ),
  ]),
  _repartir(const [
    Offset(0.14, 0.84),
    Offset(0.28, 0.84),
    Offset(0.28, 0.7),
    Offset(0.42, 0.7),
    Offset(0.42, 0.56),
    Offset(0.56, 0.56),
    Offset(0.56, 0.42),
    Offset(0.7, 0.42),
    Offset(0.7, 0.28),
    Offset(0.86, 0.28),
  ]),
];

/// Qué tan cerca está la posición [pagina] de la página [i]: 1 encima, 0 a
/// una página o más de distancia.
double _cerca(double pagina, int i) => (1 - (pagina - i).abs()).clamp(0.0, 1.0);

/// La línea y lo que se apoya en ella (precio, documentos, moto, descuentos).
class _Arte extends StatelessWidget {
  const _Arte({required this.pagina, required this.corredor});

  final PageController pagina;
  final Animation<double> corredor;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return MediaQuery.withNoTextScaling(
      child: LayoutBuilder(
        builder: (context, c) {
          final lado = math.min(c.maxWidth, c.maxHeight);
          final origen = Offset(
            (c.maxWidth - lado) / 2,
            (c.maxHeight - lado) / 2,
          );
          return AnimatedBuilder(
            animation: Listenable.merge([pagina, corredor]),
            builder: (context, _) {
              final p =
                  pagina.hasClients && pagina.position.hasContentDimensions
                  ? (pagina.page ?? 0.0)
                  : 0.0;
              final v = corredor.value;

              /// Coloca [child] centrado en (x, y) del cuadro; solo se ve
              /// cuando la página [i] está al frente.
              Widget? en(int i, double x, double y, Widget child) {
                final visible = (_cerca(p, i) * 2 - 1).clamp(0.0, 1.0);
                if (visible <= 0) return null;
                return Positioned(
                  left: origen.dx + x * lado,
                  top: origen.dy + y * lado,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: Opacity(opacity: visible, child: child),
                  ),
                );
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LineaPainter(pagina: p, corredor: v),
                    ),
                  ),
                  ..._sinNulos([
                    en(
                      0,
                      0.69,
                      0.62,
                      _Chip(
                        titulo: l.onbArtePrecio,
                        detalle: l.onbArtePrecioDetalle,
                      ),
                    ),
                    en(0, 0.27, 0.86, _Rotulo(l.onbArteTu)),
                    en(0, 0.76, 0.08, _Rotulo(l.destino)),
                    en(
                      1,
                      0.5,
                      0.42,
                      _Documentos(
                        ancho: lado * 0.42,
                        avance: v,
                        nombres: [
                          l.onbDocLicencia,
                          l.onbDocSoat,
                          l.onbDocTecno,
                          l.onbDocTarjeta,
                        ],
                      ),
                    ),
                    en(2, 0.5, 0.5, const _Moto()),
                    en(2, 0.8, 0.15, _Chip(titulo: l.onbArteEnVivo)),
                    en(
                      3,
                      0.21,
                      0.91,
                      _Rotulo(l.nivelActual('1'), color: NexaColors.muted),
                    ),
                    for (var n = 2; n <= 5; n++)
                      en(
                        3,
                        0.21 + (n - 1) * 0.14 + (n == 5 ? 0.01 : 0),
                        0.78 - (n - 1) * 0.14,
                        _Rotulo(
                          l.onbArteDescuento(n),
                          color: n == 5 ? NexaColors.gold : NexaColors.texto,
                        ),
                      ),
                    en(
                      3,
                      0.78,
                      0.11,
                      const Icon(
                        Icons.star_rounded,
                        size: 26,
                        color: NexaColors.gold,
                      ),
                    ),
                  ]),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

List<Widget> _sinNulos(List<Widget?> lista) => lista.nonNulls.toList();

class _LineaPainter extends CustomPainter {
  const _LineaPainter({required this.pagina, required this.corredor});

  /// Posición del `PageView` (0 a 3, con decimales mientras se desliza).
  final double pagina;

  /// Avance del punto que recorre la línea (0 a 1).
  final double corredor;

  @override
  void paint(Canvas canvas, Size size) {
    final lado = math.min(size.width, size.height);
    final origen = Offset((size.width - lado) / 2, (size.height - lado) / 2);
    final desde = pagina.floor().clamp(0, _formas.length - 1);
    final hasta = math.min(desde + 1, _formas.length - 1);
    final fr = (pagina - desde).clamp(0.0, 1.0);
    final a = _formas[desde];
    final b = _formas[hasta];
    // Cada punto sale un poco después del anterior: la línea se «redibuja».
    final pts = <Offset>[
      for (var i = 0; i < _puntos; i++)
        origen +
            Offset.lerp(
                  a[i],
                  b[i],
                  Curves.easeInOut.transform(
                    (fr * 1.6 - i / _puntos * 0.6).clamp(0.0, 1.0),
                  ),
                )! *
                lado,
    ];
    final linea = Path()..addPolygon(pts, false);
    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(
        linea,
        trazo
          ..strokeWidth = 16
          ..color = NexaColors.cyan.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawPath(
        linea,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 4.5
          ..color = NexaColors.cyan,
      );

    if (corredor > 0 && corredor < 1) {
      final k = (corredor * (_puntos - 1)).round();
      final cola = Path()
        ..addPolygon(pts.sublist(math.max(0, k - 16), k + 1), false);
      canvas
        ..drawPath(
          cola,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = 3
            ..color = NexaColors.texto.withValues(alpha: 0.9),
        )
        ..drawCircle(
          pts[k],
          18,
          Paint()
            ..color = NexaColors.cyan.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        )
        ..drawCircle(pts[k], 4.5, Paint()..color = NexaColors.texto);
    }

    // Origen (punto) y destino (cuadro): el radar no tiene origen visible y
    // el escudo, que es cerrado, no tiene destino.
    final inicio = 1 - _cerca(pagina, 2);
    if (inicio > 0.02) {
      canvas
        ..drawCircle(
          pts.first,
          7,
          Paint()..color = NexaColors.bg.withValues(alpha: inicio),
        )
        ..drawCircle(
          pts.first,
          7,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5
            ..color = NexaColors.sky.withValues(alpha: inicio),
        );
    }
    final fin = 1 - _cerca(pagina, 1);
    if (fin > 0.02) {
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: pts.last, width: 16, height: 16),
            const Radius.circular(5),
          ),
          Paint()..color = NexaColors.cyan.withValues(alpha: fin),
        )
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: pts.last, width: 6, height: 6),
            const Radius.circular(2),
          ),
          Paint()..color = NexaColors.bg.withValues(alpha: fin),
        );
    }
  }

  @override
  bool shouldRepaint(_LineaPainter old) =>
      old.pagina != pagina || old.corredor != corredor;
}

/// Tarjeta pequeña de cristal sobre la línea.
class _Chip extends StatelessWidget {
  const _Chip({required this.titulo, this.detalle});

  final String titulo;
  final String? detalle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
    decoration: BoxDecoration(
      color: NexaColors.glass,
      borderRadius: BorderRadius.circular(Rad.md),
      border: Border.all(color: NexaColors.cyan.withValues(alpha: 0.35)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: NexaTexto.cuerpo.copyWith(
            fontWeight: FontWeight.w700,
            color: NexaColors.texto,
            height: 1.15,
          ),
        ),
        if (detalle != null)
          Text(
            detalle!,
            style: NexaTexto.pequeno.copyWith(
              fontSize: 11,
              color: NexaColors.muted,
            ),
          ),
      ],
    ),
  );
}

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto, {this.color = NexaColors.sky});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    texto,
    style: NexaTexto.pequeno.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: color,
    ),
  );
}

/// Los cuatro documentos del conductor, que se van marcando uno por uno.
class _Documentos extends StatelessWidget {
  const _Documentos({
    required this.ancho,
    required this.avance,
    required this.nombres,
  });

  final double ancho;
  final double avance;
  final List<String> nombres;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: ancho,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < nombres.length; i++)
          Opacity(
            opacity: ((avance - 0.15 - i * 0.16) / 0.2).clamp(0.0, 1.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: Sp.xs + 2),
              padding: const EdgeInsets.symmetric(
                horizontal: Sp.sm,
                vertical: Sp.xs + 1,
              ),
              decoration: BoxDecoration(
                color: NexaColors.raised.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(Rad.sm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      nombres[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NexaTexto.pequeno.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: NexaColors.texto,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: NexaColors.ok,
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _Moto extends StatelessWidget {
  const _Moto();

  @override
  Widget build(BuildContext context) => Container(
    width: 54,
    height: 54,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: NexaColors.cyan,
      border: Border.all(color: NexaColors.texto, width: 3),
      boxShadow: NexaShadows.glow,
    ),
    child: const Icon(Icons.two_wheeler, color: NexaColors.bg, size: 28),
  );
}
