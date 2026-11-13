import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Piezas del rediseño oscuro (ver `docs/mockups-nexa-dark.html`).

/// Fondo con halos de color (cian arriba a la derecha, azul abajo a la izquierda).
/// En tema claro no pinta nada.
class FondoNexa extends StatelessWidget {
  const FondoNexa({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.dark) return child;
    // expand: el fondo cubre toda la pantalla aunque el contenido sea corto.
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1, -1),
                radius: 1.1,
                colors: [
                  NexaColors.cyan.withValues(alpha: 0.2),
                  NexaColors.cyan.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-1, 1),
                radius: 0.9,
                colors: [
                  NexaColors.navy.withValues(alpha: 0.45),
                  NexaColors.navy.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Chip de cristal para flotar sobre el mapa; [destacado] lo rellena de cian.
class NexaChipCristal extends StatelessWidget {
  const NexaChipCristal({
    required this.texto,
    this.icono,
    this.destacado = false,
    super.key,
  });

  final String texto;
  final IconData? icono;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final color = destacado ? NexaColors.bg : NexaColors.cyan;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Rad.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: destacado ? NexaColors.cyan : NexaColors.glass,
            borderRadius: BorderRadius.circular(Rad.pill),
            border: Border.all(color: NexaColors.cyan.withValues(alpha: 0.45)),
            boxShadow: destacado ? NexaShadows.glow : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.md,
              vertical: Sp.sm - 1,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icono != null) ...[
                  Icon(icono, size: 14, color: color),
                  const SizedBox(width: Sp.xs + 2),
                ],
                Flexible(
                  child: Text(
                    texto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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

/// Avatar con un anillo de neón que muestra el avance de nivel (0 a 1).
class NexaAvatarAnillo extends StatelessWidget {
  const NexaAvatarAnillo({
    required this.iniciales,
    required this.progreso,
    this.diametro = 56,
    this.foto,
    super.key,
  });

  final String iniciales;

  /// Avance hacia el siguiente nivel, de 0 a 1.
  final double progreso;
  final double diametro;
  final ImageProvider? foto;

  @override
  Widget build(BuildContext context) {
    final avance = progreso.clamp(0.0, 1.0);
    return Semantics(
      excludeSemantics: true,
      label: 'Avance de nivel ${(avance * 100).round()} %',
      child: SizedBox(
        width: diametro,
        height: diametro,
        child: CustomPaint(
          painter: _AnilloPainter(avance),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: ClipOval(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [NexaColors.cyan, NexaColors.sky],
                  ),
                  image: foto == null
                      ? null
                      : DecorationImage(image: foto!, fit: BoxFit.cover),
                ),
                child: foto != null
                    ? null
                    : Center(
                        child: Text(
                          iniciales,
                          style: TextStyle(
                            color: NexaColors.bg,
                            fontWeight: FontWeight.w700,
                            fontSize: diametro * 0.28,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnilloPainter extends CustomPainter {
  const _AnilloPainter(
    this.progreso, {
    this.trazo = 3,
    this.color = NexaColors.cyan,
  });
  final double progreso;
  final double trazo;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(trazo / 2);
    final pista = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = trazo
      ..color = color.withValues(alpha: 0.18);
    canvas.drawArc(rect, 0, 2 * math.pi, false, pista);
    if (progreso <= 0) return;
    final barrido = 2 * math.pi * progreso;
    final brillo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = trazo + 3
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final arco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = trazo
      ..color = color;
    canvas
      ..drawArc(rect, -math.pi / 2, barrido, false, brillo)
      ..drawArc(rect, -math.pi / 2, barrido, false, arco);
  }

  @override
  bool shouldRepaint(_AnilloPainter old) =>
      old.progreso != progreso || old.trazo != trazo || old.color != color;
}

/// Anillo de neón con avance de 0 a 1 que rodea cualquier contenido
/// (foto de perfil, número de nivel…).
class NexaAnilloProgreso extends StatelessWidget {
  const NexaAnilloProgreso({
    required this.progreso,
    required this.child,
    this.diametro = 112,
    this.trazo = 4,
    this.relleno = 7,
    this.etiquetaSemantica,
    this.color = NexaColors.cyan,
    super.key,
  });

  final Color color;
  final double progreso;
  final Widget child;
  final double diametro;
  final double trazo;

  /// Espacio entre el anillo y el contenido.
  final double relleno;

  /// Si se indica, el anillo se anuncia con esta etiqueta a lectores de pantalla.
  final String? etiquetaSemantica;

  @override
  Widget build(BuildContext context) {
    final anillo = SizedBox(
      width: diametro,
      height: diametro,
      child: CustomPaint(
        painter: _AnilloPainter(
          progreso.clamp(0.0, 1.0),
          trazo: trazo,
          color: color,
        ),
        child: Padding(padding: EdgeInsets.all(trazo + relleno), child: child),
      ),
    );
    if (etiquetaSemantica == null) return anillo;
    return Semantics(label: etiquetaSemantica, child: anillo);
  }
}

/// Hoja inferior con asa, para apoyar sobre el mapa (p. ej. dentro de un `Stack`).
class NexaHojaInferior extends StatelessWidget {
  const NexaHojaInferior({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(Sp.xl, Sp.sm, Sp.xl, Sp.xl),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: _decoracionHoja,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _AsaHoja(),
            const SizedBox(height: Sp.lg - 2),
            child,
          ],
        ),
      ),
    ),
  );
}

const BoxDecoration _decoracionHoja = BoxDecoration(
  color: NexaColors.card,
  borderRadius: BorderRadius.vertical(top: Radius.circular(Rad.sheet)),
  border: Border(top: BorderSide(color: NexaColors.line)),
  boxShadow: [
    BoxShadow(color: Color(0x99000000), blurRadius: 40, offset: Offset(0, -12)),
  ],
);

class _AsaHoja extends StatelessWidget {
  const _AsaHoja();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: NexaColors.tenue,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}

/// Hoja inferior que se arrastra sobre el mapa. Todo el contenido se construye
/// de una vez (no es una lista perezosa), así que cabe en pantallas pequeñas
/// desplazándose dentro de la hoja.
class NexaHojaArrastrable extends StatelessWidget {
  const NexaHojaArrastrable({
    required this.children,
    this.inicial = 0.55,
    this.minimo = 0.3,
    this.maximo = 0.92,
    this.controller,
    super.key,
  });

  final List<Widget> children;
  final double inicial;
  final double minimo;
  final double maximo;
  final DraggableScrollableController? controller;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    controller: controller,
    initialChildSize: inicial,
    minChildSize: minimo,
    maxChildSize: maximo,
    builder: (context, scroll) => DecoratedBox(
      decoration: _decoracionHoja,
      child: SingleChildScrollView(
        controller: scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        // Con la barra de pestañas flotando encima, el final de la hoja queda
        // por encima de ella (el Scaffold la suma al padding inferior).
        padding: EdgeInsets.fromLTRB(
          Sp.xl,
          Sp.sm,
          Sp.xl,
          Sp.xl + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _AsaHoja(),
            const SizedBox(height: Sp.lg - 2),
            ...children,
          ],
        ),
      ),
    ),
  );
}

/// Control de «desliza para confirmar» para acciones delicadas.
///
/// Para lectores de pantalla se expone como un botón que confirma con un toque.
class NexaDeslizar extends StatefulWidget {
  const NexaDeslizar({
    required this.texto,
    required this.onConfirmado,
    super.key,
  });

  final String texto;

  /// Si es `null` el control queda deshabilitado.
  final VoidCallback? onConfirmado;

  @override
  State<NexaDeslizar> createState() => _NexaDeslizarState();
}

class _NexaDeslizarState extends State<NexaDeslizar>
    with SingleTickerProviderStateMixin {
  static const double _asa = 52;
  static const double _alto = 64;
  static const double _margen = 6;
  static const double _umbral = 0.85;

  late final AnimationController _vuelta = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  )..addListener(() => setState(() => _x = _desde * (1 - _vuelta.value)));

  double _x = 0;
  double _desde = 0;

  @override
  void dispose() {
    _vuelta.dispose();
    super.dispose();
  }

  void _soltar() {
    if (_x >= _umbral) widget.onConfirmado?.call();
    _desde = _x;
    _vuelta.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final activo = widget.onConfirmado != null;
    return Semantics(
      button: true,
      enabled: activo,
      label: widget.texto,
      onTap: activo ? widget.onConfirmado : null,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) {
            final recorrido = math.max(1.0, box.maxWidth - _asa - 2 * _margen);
            return Opacity(
              opacity: activo ? 1 : 0.5,
              child: Container(
                height: _alto,
                decoration: BoxDecoration(
                  color: NexaColors.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Rad.pill),
                  border: Border.all(
                    color: NexaColors.cyan.withValues(alpha: 0.45),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(left: _asa),
                        child: Text(
                          widget.texto,
                          style: const TextStyle(
                            color: NexaColors.cyan,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: _margen + _x * recorrido,
                      child: GestureDetector(
                        onHorizontalDragUpdate: activo
                            ? (d) => setState(() {
                                _x = (_x + d.delta.dx / recorrido).clamp(
                                  0.0,
                                  1.0,
                                );
                              })
                            : null,
                        onHorizontalDragEnd: activo ? (_) => _soltar() : null,
                        child: Container(
                          width: _asa,
                          height: _asa,
                          decoration: const BoxDecoration(
                            color: NexaColors.cyan,
                            shape: BoxShape.circle,
                            boxShadow: NexaShadows.glow,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: NexaColors.bg,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Elemento de la barra de navegación flotante.
class NexaItemBarra {
  const NexaItemBarra({required this.icono, required this.etiqueta});
  final IconData icono;
  final String etiqueta;
}

/// Barra de pestañas flotante del rediseño (componente «Barra de pestañas»
/// del Figma): cada opción con icono y etiqueta; la activa en cian sobre una
/// píldora oscura.
class NexaBarraFlotante extends StatelessWidget {
  const NexaBarraFlotante({
    required this.items,
    required this.indice,
    required this.onSeleccion,
    super.key,
  });

  final List<NexaItemBarra> items;
  final int indice;
  final ValueChanged<int> onSeleccion;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(Rad.sheet),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        height: 68,
        padding: const EdgeInsets.all(Sp.sm - 2),
        decoration: BoxDecoration(
          color: NexaColors.card.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(Rad.sheet),
          border: Border.all(color: NexaColors.line),
          boxShadow: const [
            BoxShadow(color: Color(0x80000000), blurRadius: 24),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _Opcion(
                  item: items[i],
                  activo: i == indice,
                  onTap: () => onSeleccion(i),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.item,
    required this.activo,
    required this.onTap,
  });

  final NexaItemBarra item;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = activo ? NexaColors.cyan : NexaColors.muted;
    return Semantics(
      button: true,
      selected: activo,
      label: item.etiqueta,
      child: InkWell(
        borderRadius: BorderRadius.circular(Rad.lg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: activo ? NexaColors.raised : Colors.transparent,
            borderRadius: BorderRadius.circular(Rad.lg),
          ),
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icono, size: 22, color: color),
                const SizedBox(height: 3),
                Text(
                  item.etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.3,
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
