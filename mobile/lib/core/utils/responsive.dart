import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Breakpoints: compacto < 360, normal, tablet >= 600 (diseño base 390x844).
enum Breakpoint { compacto, normal, tablet }

Breakpoint breakpointDe(double ancho) {
  if (ancho < 360) return Breakpoint.compacto;
  if (ancho >= 600) return Breakpoint.tablet;
  return Breakpoint.normal;
}

extension ResponsiveContext on BuildContext {
  Breakpoint get breakpoint => breakpointDe(MediaQuery.sizeOf(this).width);
  bool get esTablet => breakpoint == Breakpoint.tablet;

  /// Margen horizontal de pantalla según el tamaño.
  double get gutter => switch (breakpoint) {
    Breakpoint.compacto => Sp.md,
    Breakpoint.normal => Sp.lg,
    Breakpoint.tablet => Sp.xl,
  };
}

/// Contenedor que limita el ancho del contenido en tablets y centra.
class ContenidoCentrado extends StatelessWidget {
  const ContenidoCentrado({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: Sizes.maxContentWidth),
      child: child,
    ),
  );
}
