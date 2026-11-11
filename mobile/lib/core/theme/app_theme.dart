import 'package:flutter/material.dart';

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
      onSurface: Colors.white,
      surfaceContainerHighest: NexaColors.raised,
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
      textTheme: Typography.material2021().black.apply(
        fontFamily: fuente,
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: oscuro ? NexaColors.card : scheme.surface,
        border: OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
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
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
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
