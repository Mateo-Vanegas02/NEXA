import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Logo oficial de NEXA (el mismo icono de la web: `static/icon/NEXA_ICO.ico`),
/// recortado en círculo para que se vea limpio sobre cualquier fondo.
class NexaLogo extends StatelessWidget {
  const NexaLogo({this.tamano = 48, this.brillo = false, super.key});

  final double tamano;

  /// Aro y resplandor cian (pantallas de acceso).
  final bool brillo;

  static const String asset = 'assets/images/nexa_logo.png';

  @override
  Widget build(BuildContext context) => Center(
    widthFactor: 1,
    heightFactor: 1,
    child: Semantics(
      label: 'NEXA',
      image: true,
      child: ExcludeSemantics(
        child: Container(
          width: tamano,
          height: tamano,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: brillo
                ? Border.all(
                    color: NexaColors.cyan.withValues(alpha: 0.45),
                    width: 2,
                  )
                : null,
            boxShadow: brillo ? NexaShadows.glow : null,
          ),
          child: ClipOval(
            child: Image.asset(
              asset,
              width: tamano,
              height: tamano,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    ),
  );
}
