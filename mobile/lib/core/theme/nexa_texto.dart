import 'package:flutter/material.dart';

/// Estilos de texto `NEXA/*` del Figma del rediseño (Montserrat).
///
/// No llevan color: lo pone el tema (o el widget) para que sirvan en claro y
/// oscuro.
abstract final class NexaTexto {
  static const _f = 'Montserrat';

  static const display = TextStyle(
    fontFamily: _f,
    fontSize: 34,
    height: 1.12,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static const titulo = TextStyle(
    fontFamily: _f,
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const subtitulo = TextStyle(
    fontFamily: _f,
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const cuerpo = TextStyle(
    fontFamily: _f,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w500,
  );
  static const pequeno = TextStyle(
    fontFamily: _f,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  /// Etiquetas en mayúsculas sobre los datos («GANAS», «BUSCA ESTA PLACA»).
  static const etiqueta = TextStyle(
    fontFamily: _f,
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.3,
  );

  /// Cifras grandes (precio, ETA): dígitos de ancho fijo para que no salten.
  static const numero = TextStyle(
    fontFamily: _f,
    fontSize: 40,
    height: 1.05,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const numeroMedio = TextStyle(
    fontFamily: _f,
    fontSize: 24,
    height: 1.1,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const boton = TextStyle(
    fontFamily: _f,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  /// Placa de la moto: grande y espaciada para leerla de lejos.
  static const placa = TextStyle(
    fontFamily: _f,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.4,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Tema de texto de Material con la escala de NEXA.
  static TextTheme tema(ColorScheme s) {
    final base = Typography.material2021().black.apply(
      fontFamily: _f,
      bodyColor: s.onSurface,
      displayColor: s.onSurface,
    );
    return base.copyWith(
      displaySmall: display.copyWith(color: s.onSurface),
      headlineMedium: titulo.copyWith(color: s.onSurface),
      headlineSmall: titulo.copyWith(color: s.onSurface),
      titleLarge: subtitulo.copyWith(color: s.onSurface, fontSize: 20),
      titleMedium: subtitulo.copyWith(color: s.onSurface),
      bodyLarge: cuerpo.copyWith(color: s.onSurface),
      bodyMedium: cuerpo.copyWith(color: s.onSurface, fontSize: 14),
      bodySmall: pequeno.copyWith(color: s.onSurfaceVariant),
      labelLarge: boton.copyWith(color: s.onSurface),
      // Rótulos chicos en texto normal (sin el espaciado de [etiqueta], que
      // es solo para mayúsculas): así los datos del panel de satisfacción se
      // leen igual que el resto de la app.
      labelMedium: pequeno.copyWith(
        color: s.onSurface,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      labelSmall: pequeno.copyWith(
        color: s.onSurfaceVariant,
        fontSize: 12,
        letterSpacing: 0,
      ),
    );
  }
}
