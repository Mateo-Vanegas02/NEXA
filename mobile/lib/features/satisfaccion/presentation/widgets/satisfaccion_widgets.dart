import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';

/// Piezas del panel de satisfacción (Figma `mKq1Yb7s7nBW9TmAf2O2wn`).

bool _oscuro(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

/// Fondo de tarjeta del rediseño (#03192E en oscuro, superficie en claro).
Color fondoTarjeta(BuildContext c) =>
    _oscuro(c) ? NexaColors.card : c.colors.surface;

/// Borde fino de las tarjetas.
Color bordeSuave(BuildContext c) => c.acento.withValues(alpha: 0.18);

/// Colores semánticos del panel. En claro se usan los de contraste AA.
Color colorOk(BuildContext c) => _oscuro(c) ? NexaColors.ok : NexaColors.okFg;
Color colorMalo(BuildContext c) =>
    _oscuro(c) ? NexaColors.error : NexaColors.badFg;
Color colorAviso(BuildContext c) =>
    _oscuro(c) ? NexaColors.gold : const Color(0xFF8A5A00);

/// Color de una barra o porcentaje según qué tan satisfechos están (verde/cian,
/// amarillo o rojo). Solo pinta; los cortes no son reglas de negocio.
Color colorSatisfaccion(BuildContext c, double pct) => pct >= 85
    ? c.acento
    : pct >= 70
    ? colorAviso(c)
    : colorMalo(c);

class TarjetaSat extends StatelessWidget {
  const TarjetaSat({
    required this.child,
    this.padding = const EdgeInsets.all(Sp.lg - 2),
    this.onTap,
    this.semantica,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semantica;

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(Rad.lg);
    final tarjeta = Material(
      color: fondoTarjeta(context),
      borderRadius: radio,
      child: InkWell(
        borderRadius: radio,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radio,
            border: Border.all(color: bordeSuave(context)),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
    if (semantica == null) return tarjeta;
    return Semantics(
      button: onTap != null,
      label: semantica,
      excludeSemantics: true,
      child: tarjeta,
    );
  }
}

/// Encabezado de pantalla: etiqueta en mayúsculas + título grande, con botón
/// atrás opcional y una acción a la derecha.
class EncabezadoSat extends StatelessWidget {
  const EncabezadoSat({
    required this.etiqueta,
    required this.titulo,
    this.atras = false,
    this.accion,
    super.key,
  });

  final String etiqueta;
  final String titulo;
  final bool atras;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final t = context.textos;
    return Padding(
      padding: const EdgeInsets.only(top: Sp.xs, bottom: Sp.xs),
      child: Row(
        children: [
          if (atras) ...[
            BotonRedondo(
              icono: Icons.chevron_left,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: Sp.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta.toUpperCase(),
                  style: t.labelSmall?.copyWith(
                    color: context.acento,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                Semantics(
                  header: true,
                  child: Text(
                    titulo,
                    style: t.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ?accion,
        ],
      ),
    );
  }
}

class BotonRedondo extends StatelessWidget {
  const BotonRedondo({
    required this.icono,
    required this.tooltip,
    required this.onPressed,
    this.color,
    super.key,
  });

  final IconData icono;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: fondoTarjeta(context),
      shape: CircleBorder(side: BorderSide(color: bordeSuave(context))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: Sizes.touch,
          child: Icon(icono, color: color),
        ),
      ),
    ),
  );
}

/// Fila de chips de filtro de una sola selección.
class ChipsFiltro<T> extends StatelessWidget {
  const ChipsFiltro({
    required this.opciones,
    required this.seleccion,
    required this.onSeleccion,
    super.key,
  });

  final List<(T, String)> opciones;
  final T seleccion;
  final ValueChanged<T> onSeleccion;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Sp.sm,
    runSpacing: Sp.sm,
    children: [
      for (final (valor, texto) in opciones)
        ChoiceChip(
          label: Text(texto),
          selected: valor == seleccion,
          showCheckmark: false,
          onSelected: (_) => onSeleccion(valor),
          shape: const StadiumBorder(),
          side: BorderSide(
            color: valor == seleccion ? context.acento : bordeSuave(context),
          ),
          backgroundColor: fondoTarjeta(context),
          selectedColor: context.acento,
          labelStyle: context.textos.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valor == seleccion
                ? context.colors.onPrimary
                : context.colors.onSurface,
          ),
        ),
    ],
  );
}

/// Selector de dos o tres opciones en forma de píldora (Pasajero | Conductor).
class SelectorSegmentado<T> extends StatelessWidget {
  const SelectorSegmentado({
    required this.opciones,
    required this.seleccion,
    required this.onSeleccion,
    super.key,
  });

  final List<(T, String)> opciones;
  final T seleccion;
  final ValueChanged<T> onSeleccion;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Sp.xs),
    decoration: BoxDecoration(
      color: fondoTarjeta(context),
      borderRadius: BorderRadius.circular(Rad.pill),
      border: Border.all(color: bordeSuave(context)),
    ),
    child: Row(
      children: [
        for (final (valor, texto) in opciones)
          Expanded(
            child: Semantics(
              selected: valor == seleccion,
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(Rad.pill),
                onTap: () => onSeleccion(valor),
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  constraints: const BoxConstraints(minHeight: 40),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: Sp.sm),
                  decoration: BoxDecoration(
                    color: valor == seleccion
                        ? (_oscuro(context)
                              ? NexaColors.raised
                              : context.acento.withValues(alpha: 0.12))
                        : null,
                    borderRadius: BorderRadius.circular(Rad.pill),
                    border: valor == seleccion
                        ? Border.all(
                            color: context.acento.withValues(alpha: 0.45),
                          )
                        : null,
                  ),
                  child: Text(
                    texto,
                    textAlign: TextAlign.center,
                    style: context.textos.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: valor == seleccion ? null : context.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

enum TipoAviso { aviso, info }

/// Aviso con icono (sin modelo, consejos, notas).
class AvisoSat extends StatelessWidget {
  const AvisoSat({
    required this.texto,
    this.tipo = TipoAviso.info,
    this.negrita,
    this.icono,
    super.key,
  });

  final String texto;
  final TipoAviso tipo;

  /// Texto en negrita al inicio (p. ej. "Sin modelo todavía.").
  final String? negrita;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final color = tipo == TipoAviso.aviso
        ? colorAviso(context)
        : context.acento;
    final t = context.textos.bodySmall?.copyWith(
      color: tipo == TipoAviso.aviso ? color : null,
      height: 1.4,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: tipo == TipoAviso.aviso ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(Rad.lg - 4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icono ??
                (tipo == TipoAviso.aviso
                    ? Icons.info_outline
                    : Icons.lightbulb_outline),
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (negrita != null)
                    TextSpan(
                      text: '$negrita ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  TextSpan(text: texto),
                ],
              ),
              style: t,
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta en píldora (lado del viaje, motivo, estado del entrenamiento).
class EtiquetaSat extends StatelessWidget {
  const EtiquetaSat({required this.texto, required this.color, super.key});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Sp.xs),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(Rad.pill),
    ),
    child: Text(
      texto,
      style: context.textos.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Etiqueta y valor con una barra de avance (importancia de factores, datos).
class FilaBarra extends StatelessWidget {
  const FilaBarra({
    required this.etiqueta,
    required this.valor,
    required this.fraccion,
    this.color,
    super.key,
  });

  final String etiqueta;
  final String valor;

  /// Largo de la barra, de 0 a 1.
  final double fraccion;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.textos.bodySmall;
    return Semantics(
      label: '$etiqueta: $valor',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(etiqueta, style: t)),
              const SizedBox(width: Sp.sm),
              Text(valor, style: t?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(Rad.pill),
            child: LinearProgressIndicator(
              value: fraccion.clamp(0.0, 1.0),
              minHeight: 8,
              color: color ?? context.acento,
              backgroundColor: _oscuro(context)
                  ? NexaColors.raised
                  : context.acento.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Punto de color + texto, para leyendas.
class Leyenda extends StatelessWidget {
  const Leyenda({required this.texto, required this.color, super.key});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(texto, style: context.textos.labelSmall),
    ],
  );
}

/// Serie de una línea de la gráfica de tendencia. Un `null` es un tramo sin
/// datos: la línea lo cruza punteada en vez de cortarse.
class SerieLinea {
  const SerieLinea({required this.valores, required this.color, this.notas});

  final List<double?> valores;
  final Color color;

  /// Notas detrás de cada valor (`null` = no se sabe).
  final List<int?>? notas;

  int? notasEn(int i) {
    final n = notas;
    return n == null || i >= n.length ? null : n[i];
  }
}

/// Gráfica de líneas de satisfacción (0–100 %). Escala vertical de [minimo] a
/// 100 con tres guías. Cada valor lleva su punto; los que tienen menos de
/// [minimoNotas] notas se dibujan huecos (dato débil). Al tocarla o arrastrar
/// sobre ella se marca un tramo y arriba aparece el valor y las notas.
class GraficaTendencia extends StatefulWidget {
  const GraficaTendencia({
    required this.series,
    required this.etiquetasX,
    required this.semantica,
    this.etiquetasLectura,
    this.minimo = 60,
    this.alto = 120,
    this.minimoNotas,
    this.formato,
    this.textoNotas,
    super.key,
  });

  final List<SerieLinea> series;

  /// Etiqueta corta de cada tramo bajo el eje (si son muchas, se ralean).
  final List<String> etiquetasX;

  /// Etiqueta larga del tramo marcado; por defecto, la del eje.
  final List<String>? etiquetasLectura;
  final String semantica;
  final double minimo;
  final double alto;

  /// Por debajo de estas notas el punto es hueco. `null` = todos llenos.
  final int? minimoNotas;

  /// Cómo se escribe un valor en la lectura (por defecto, `86 %`).
  final String Function(double valor)? formato;

  /// Cómo se escribe el número de notas en la lectura (`12 notas`).
  final String Function(int notas)? textoNotas;

  @override
  State<GraficaTendencia> createState() => _GraficaTendenciaState();
}

/// Margen horizontal y vertical del trazado, compartido por el pintor y las
/// etiquetas para que cada etiqueta quede bajo su punto.
const double _margenGrafica = 8;

double _xTramo(int i, int n, double ancho) => n <= 1
    ? ancho / 2
    : _margenGrafica + (ancho - 2 * _margenGrafica) * i / (n - 1);

/// Índices del eje que llevan etiqueta: todos hasta 7; si son más, uno de
/// cada pocos contando desde el último (el más reciente siempre se ve).
Set<int> _etiquetasVisibles(int n) {
  if (n <= 7) return {for (var i = 0; i < n; i++) i};
  final paso = (n / 6).ceil();
  return {for (var i = n - 1; i >= 0; i -= paso) i};
}

class _GraficaTendenciaState extends State<GraficaTendencia> {
  int? _sel;

  int get _n =>
      widget.series.fold<int>(0, (m, s) => math.max(m, s.valores.length));

  void _elegir(double dx, double ancho) {
    final n = _n;
    if (n == 0) return;
    final util = ancho - 2 * _margenGrafica;
    final i = n == 1 || util <= 0
        ? 0
        : ((dx - _margenGrafica) / util * (n - 1)).round().clamp(0, n - 1);
    if (i != _sel) setState(() => _sel = i);
  }

  @override
  void didUpdateWidget(GraficaTendencia old) {
    super.didUpdateWidget(old);
    if (_sel != null && _sel! >= _n) _sel = null;
  }

  @override
  Widget build(BuildContext context) {
    final estilo = context.textos.labelSmall?.copyWith(color: context.muted);
    final minimo = widget.minimo;
    final alto = widget.alto;
    final guias = [100.0, (100 + minimo) / 2, minimo];
    final sel = _sel;
    final n = _n;
    String valor(SerieLinea s, int i) {
      final v = i < s.valores.length ? s.valores[i] : null;
      if (v == null) return '–';
      final texto = widget.formato?.call(v) ?? '${v.toStringAsFixed(0)} %';
      final notas = s.notasEn(i);
      final enNotas = widget.textoNotas;
      return notas == null || enNotas == null
          ? texto
          : '$texto · ${enNotas(notas)}';
    }

    final lectura = widget.etiquetasLectura ?? widget.etiquetasX;
    final visibles = _etiquetasVisibles(widget.etiquetasX.length);
    return Semantics(
      label: widget.semantica,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sel != null) ...[
            Wrap(
              spacing: Sp.md,
              runSpacing: Sp.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (sel < lectura.length)
                  Text(
                    lectura[sel],
                    style: context.textos.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                for (final s in widget.series)
                  Leyenda(texto: valor(s, sel), color: s.color),
              ],
            ),
            const SizedBox(height: Sp.sm),
          ],
          SizedBox(
            height: alto,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Stack(
                    children: [
                      for (final g in guias)
                        Positioned(
                          left: 0,
                          top: (alto - 12) * (100 - g) / (100 - minimo),
                          child: Text(g.toStringAsFixed(0), style: estilo),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) => _elegir(d.localPosition.dx, c.maxWidth),
                      onHorizontalDragStart: (d) =>
                          _elegir(d.localPosition.dx, c.maxWidth),
                      onHorizontalDragUpdate: (d) =>
                          _elegir(d.localPosition.dx, c.maxWidth),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _LineasPainter(
                          series: widget.series,
                          minimo: minimo,
                          guias: guias,
                          minimoNotas: widget.minimoNotas,
                          colorGuia: context.acento.withValues(alpha: 0.12),
                          seleccion: sel,
                          colorMarca: context.colors.onSurface,
                          fondo: fondoTarjeta(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: LayoutBuilder(
              builder: (context, c) {
                const ancho = 52.0;
                final tope = math.max(0.0, c.maxWidth - ancho);
                return SizedBox(
                  height: 16,
                  child: Stack(
                    children: [
                      for (final (i, e) in widget.etiquetasX.indexed)
                        if (visibles.contains(i))
                          Positioned(
                            left: (_xTramo(i, n, c.maxWidth) - ancho / 2).clamp(
                              0.0,
                              tope,
                            ),
                            width: ancho,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(e, style: estilo),
                            ),
                          ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LineasPainter extends CustomPainter {
  _LineasPainter({
    required this.series,
    required this.minimo,
    required this.guias,
    required this.colorGuia,
    required this.colorMarca,
    required this.fondo,
    this.minimoNotas,
    this.seleccion,
  });

  final List<SerieLinea> series;
  final double minimo;
  final List<double> guias;
  final Color colorGuia;
  final Color colorMarca;
  final Color fondo;
  final int? minimoNotas;
  final int? seleccion;

  bool _debil(SerieLinea s, int i) {
    final tope = minimoNotas;
    final notas = s.notasEn(i);
    return tope != null && notas != null && notas < tope;
  }

  void _punteada(Canvas canvas, Offset a, Offset b, Paint p) {
    const trazo = 4.0;
    const hueco = 4.0;
    final largo = (b - a).distance;
    if (largo == 0) return;
    final dir = (b - a) / largo;
    for (var t = 0.0; t < largo; t += trazo + hueco) {
      canvas.drawLine(a + dir * t, a + dir * math.min(t + trazo, largo), p);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    const margen = _margenGrafica;
    final altoUtil = size.height - 12;
    final total = series.fold<int>(0, (m, s) => math.max(m, s.valores.length));
    double y(double v) =>
        margen +
        (altoUtil - margen) * (100 - v.clamp(minimo, 100)) / (100 - minimo);
    double xDe(int i, int n) => _xTramo(i, n, size.width);

    final guia = Paint()
      ..color = colorGuia
      ..strokeWidth = 1;
    for (final g in guias) {
      canvas.drawLine(Offset(0, y(g)), Offset(size.width, y(g)), guia);
    }
    for (final (indice, s) in series.indexed) {
      final n = s.valores.length;
      if (n == 0) continue;
      Offset punto(int i) => Offset(xDe(i, n), y(s.valores[i]!));
      final linea = Paint()
        ..color = s.color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final puente = Paint()
        ..color = s.color.withValues(alpha: 0.55)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      final conDatos = [
        for (var i = 0; i < n; i++)
          if (s.valores[i] != null) i,
      ];
      // Tramos seguidos con datos: línea continua; separados por tramos sin
      // notas: puente punteado, para que se lea la dirección sin inventar
      // los valores que faltan.
      final path = Path();
      for (var k = 0; k < conDatos.length; k++) {
        final i = conDatos[k];
        if (k == 0 || conDatos[k - 1] != i - 1) {
          path.moveTo(punto(i).dx, punto(i).dy);
        } else {
          path.lineTo(punto(i).dx, punto(i).dy);
        }
        if (k > 0 && conDatos[k - 1] != i - 1) {
          _punteada(canvas, punto(conDatos[k - 1]), punto(i), puente);
        }
      }
      // Relleno suave bajo la primera serie, solo si no tiene huecos.
      if (indice == 0 && n > 1 && conDatos.length == n) {
        final area = Path.from(path)
          ..lineTo(xDe(n - 1, n), altoUtil + 4)
          ..lineTo(xDe(0, n), altoUtil + 4)
          ..close();
        final zona = Rect.fromLTWH(0, 0, size.width, altoUtil + 4);
        canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                s.color.withValues(alpha: 0.22),
                s.color.withValues(alpha: 0),
              ],
            ).createShader(zona),
        );
      }
      canvas.drawPath(path, linea);
      // Un punto por valor: lleno si tiene notas suficientes, hueco si no.
      final ultimo = conDatos.isEmpty ? -1 : conDatos.last;
      for (final i in conDatos) {
        final p = punto(i);
        final radio = i == ultimo && seleccion == null ? 5.0 : 3.5;
        if (_debil(s, i)) {
          canvas
            ..drawCircle(p, radio, Paint()..color = fondo)
            ..drawCircle(
              p,
              radio,
              Paint()
                ..color = s.color
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.5,
            );
        } else {
          canvas.drawCircle(p, radio, Paint()..color = s.color);
        }
      }
    }

    // Tramo marcado: línea vertical y un punto por serie.
    final sel = seleccion;
    if (sel != null && total > 0) {
      final xs = xDe(sel, total);
      canvas.drawLine(
        Offset(xs, 0),
        Offset(xs, altoUtil + 4),
        Paint()
          ..color = colorMarca.withValues(alpha: 0.4)
          ..strokeWidth = 1,
      );
      for (final s in series) {
        final v = sel < s.valores.length ? s.valores[sel] : null;
        if (v == null) continue;
        final p = Offset(xDe(sel, s.valores.length), y(v));
        canvas
          ..drawCircle(p, 7, Paint()..color = fondo)
          ..drawCircle(
            p,
            5,
            _debil(s, sel)
                ? (Paint()
                    ..color = s.color
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 2)
                : (Paint()..color = s.color),
          );
      }
    }
  }

  @override
  bool shouldRepaint(_LineasPainter old) =>
      old.series != series ||
      old.minimo != minimo ||
      old.minimoNotas != minimoNotas ||
      old.colorGuia != colorGuia ||
      old.seleccion != seleccion ||
      old.colorMarca != colorMarca ||
      old.fondo != fondo;
}

/// Barras verticales por tramo (0–100 %), con el valor arriba y el tramo abajo.
class GraficaTramos extends StatelessWidget {
  const GraficaTramos({
    required this.tramos,
    required this.semantica,
    this.alto = 110,
    super.key,
  });

  /// (etiqueta, porcentaje).
  final List<(String, double)> tramos;
  final String semantica;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final t = context.textos;
    final maximo = tramos.fold<double>(1, (m, e) => math.max(m, e.$2));
    return Semantics(
      label: semantica,
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (etiqueta, pct) in tramos)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Sp.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1)} %',
                      style: t.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: math.max(6, alto * pct / maximo),
                      decoration: BoxDecoration(
                        color: colorSatisfaccion(context, pct),
                        borderRadius: BorderRadius.circular(Rad.sm),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      etiqueta,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: t.labelSmall?.copyWith(color: context.muted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Anillo de progreso grande (pantalla "Entrenando").
class AnilloAvance extends StatelessWidget {
  const AnilloAvance({
    required this.fraccion,
    required this.child,
    this.diametro = 140,
    super.key,
  });

  final double fraccion;
  final Widget child;
  final double diametro;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: diametro,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.square(
          dimension: diametro,
          child: CircularProgressIndicator(
            value: fraccion.clamp(0.0, 1.0),
            strokeWidth: 12,
            strokeCap: StrokeCap.round,
            color: context.acento,
            backgroundColor: _oscuro(context)
                ? NexaColors.raised
                : context.acento.withValues(alpha: 0.12),
          ),
        ),
        child,
      ],
    ),
  );
}
