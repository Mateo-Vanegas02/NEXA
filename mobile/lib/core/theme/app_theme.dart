import 'package:flutter/material.dart';

import 'nexa_texto.dart';
import 'tokens.dart';

abstract final class AppTheme {
  /// Tipografía de marca, declarada en `pubspec.yaml`.
  static const String fuente = 'Montserrat';

  static ThemeData get dark => _build(
    ColorScheme.fromSeed(
      seedColor: NexaColors.cyan,
      brightness: Brightness.dark,
    ).copyWith(
      primary: NexaColors.cyan,
      onPrimary: NexaColors.bg,
      secondary: NexaColors.sky,
      surface: NexaColors.surface,
      onSurface: NexaColors.texto,
      onSurfaceVariant: NexaColors.muted,
      surfaceContainerHighest: NexaColors.raised,
      surfaceContainer: NexaColors.card,
      outline: NexaColors.line,
      error: NexaColors.error,
    ),
    NexaColors.bg,
  );

  static ThemeData get light => _build(
    ColorScheme.fromSeed(seedColor: NexaColors.cyan).copyWith(
      primary: NexaColors.lightPrimary,
      onPrimary: Colors.white,
      secondary: NexaColors.cyan,
      surface: NexaColors.lightSurface,
      onSurface: NexaColors.lightText,
      outline: const Color(0xFFB7CBD8),
      error: NexaColors.lightError,
    ),
    NexaColors.lightBg,
  );

  static ThemeData _build(ColorScheme scheme, Color background) {
    final radius = BorderRadius.circular(Rad.lg);
    final oscuro = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      fontFamily: fuente,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: NexaTexto.tema(scheme),
      cardTheme: CardThemeData(
        color: oscuro ? NexaColors.card : scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rad.lg),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(Sizes.boton),
          shape: const StadiumBorder(),
          textStyle: NexaTexto.boton,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(Sizes.boton),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outline, width: 1.5),
          textStyle: NexaTexto.boton,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: oscuro ? NexaColors.card : scheme.surface,
        border: OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: oscuro
                ? scheme.outline
                : scheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sp.lg,
          vertical: Sp.md,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(Sizes.touch),
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: scheme.onPrimary,
          side: BorderSide(
            color: oscuro
                ? scheme.outline
                : scheme.outline.withValues(alpha: 0.5),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: oscuro ? NexaColors.card : scheme.surface,
        indicatorColor: scheme.primary,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith(
          (estados) => IconThemeData(
            color: estados.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurface.withValues(alpha: 0.68),
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (estados) => TextStyle(
            fontSize: 12,
            fontWeight: estados.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
