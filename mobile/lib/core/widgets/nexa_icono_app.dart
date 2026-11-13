import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Icono de la app del rediseño (A01/A03): cuadro redondeado en degradado
/// cian → azul con la flecha de NEXA.
class NexaIconoApp extends StatelessWidget {
  const NexaIconoApp({this.tamano = 56, this.brillo = true, super.key});

  final double tamano;
  final bool brillo;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'NEXA',
    image: true,
    child: Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tamano * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF29D3FF), Color(0xFF0091C2), NexaColors.navy],
        ),
        boxShadow: brillo
            ? [
                BoxShadow(
                  color: NexaColors.cyan.withValues(alpha: 0.35),
                  blurRadius: tamano * 0.5,
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.near_me_outlined,
        size: tamano * 0.5,
        color: NexaColors.bg,
      ),
    ),
  );
}

/// Botón «atrás» del rediseño: cuadro redondeado con borde.
class NexaBotonAtras extends StatelessWidget {
  const NexaBotonAtras({required this.onPressed, this.tooltip, super.key});

  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: onPressed,
    icon: const Icon(Icons.chevron_left, size: 26),
    style: IconButton.styleFrom(
      fixedSize: const Size.square(Sizes.touch - 4),
      backgroundColor: NexaColors.card,
      foregroundColor: NexaColors.texto,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.md),
        side: const BorderSide(color: NexaColors.line),
      ),
    ),
  );
}
