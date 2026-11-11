import 'package:flutter/material.dart';

/// Accesos cortos al tema que se adaptan a claro/oscuro (contraste AA).
extension ThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textos => Theme.of(this).textTheme;

  /// Texto secundario.
  Color get muted => colors.onSurface.withValues(alpha: 0.68);

  /// Color de acento legible sobre la superficie actual (cian en oscuro, azul de marca en claro).
  Color get acento => colors.primary;
}
