import 'package:flutter/material.dart';

/// Tokens de diseño de NEXA (alineados con `nexa-design.css` de la web).
abstract final class NexaColors {
  static const Color cyan = Color(0xFF00C4FF);
  static const Color navy = Color(0xFF004F78);
  static const Color sky = Color(0xFF5EBDDA);
  static const Color bg = Color(0xFF020A12);
  static const Color surface = Color(0xFF001A33);
  static const Color raised = Color(0xFF07324F);

  /// Tarjetas y hojas inferiores del rediseño (más oscuro que [surface]).
  static const Color card = Color(0xFF03192E);

  /// Vidrio sobre el mapa (72 % de opacidad).
  static const Color glass = Color(0xB8001A33);
  static const Color muted = Color(0xFFA9C1D1);
  static const Color line = Color(0xFF3F7FA3);
  static const Color ok = Color(0xFF6EE7A8);
  static const Color error = Color(0xFFFF8A8A);
  static const Color gold = Color(0xFFFFC857);

  // Tema claro: mismo cian, texto navy para contraste AA.
  static const Color brand = Color(0xFF0B5A82);
  static const Color lightBg = Color(0xFFF2F7FA);
  static const Color okBg = Color(0xFFDDF5E7);
  static const Color okFg = Color(0xFF1B7F46);
  static const Color badBg = Color(0xFFFDE3E3);
  static const Color badFg = Color(0xFFB3261E);
  static const Color sosBg = Color(0xFFFDECEC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF04202F);
  static const Color lightPrimary = brand;
  static const Color lightError = Color(0xFFB3261E);
}

/// Escala de espaciado en múltiplos de 4.
abstract final class Sp {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class Rad {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;

  /// Esquinas superiores de las hojas inferiores.
  static const double sheet = 30;
  static const double pill = 999;
}

abstract final class Sizes {
  /// Área táctil mínima (accesibilidad).
  static const double touch = 48;

  /// Alto de los botones principales del rediseño.
  static const double boton = 56;
  static const double maxContentWidth = 560;
  static const double barHeight = 10;
}

abstract final class NexaShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> glow = [
    BoxShadow(color: Color(0x5900C4FF), blurRadius: 24),
  ];
}

/// Colores de los niveles 1 a 5; del 6 en adelante (el pasajero no tiene techo) se repite el último.
const List<Color> kColoresNivel = [
  Color(0xFF9AA9B5),
  Color(0xFFCD8B4E),
  Color(0xFFC0CCD6),
  NexaColors.gold,
  NexaColors.cyan,
];
