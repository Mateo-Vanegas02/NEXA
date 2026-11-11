import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Selector de 1 a 5 estrellas (áreas táctiles de 48dp).
class Estrellas extends StatelessWidget {
  const Estrellas({required this.valor, required this.onChanged, super.key});

  final double valor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 1; i <= 5; i++)
        IconButton(
          tooltip: '$i',
          constraints: const BoxConstraints(
            minWidth: Sizes.touch,
            minHeight: Sizes.touch,
          ),
          onPressed: () => onChanged(i.toDouble()),
          icon: Icon(
            i <= valor ? Icons.star : Icons.star_border,
            color: NexaColors.gold,
            size: 32,
          ),
        ),
    ],
  );
}
