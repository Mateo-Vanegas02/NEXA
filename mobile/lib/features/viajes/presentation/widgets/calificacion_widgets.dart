import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/tokens.dart';

/// Piezas de la calificación (diseño P09 y C07), compartidas por pasajero y
/// conductor.

String textoFactor(AppLocalizations l, String codigo) => switch (codigo) {
  'ACEPTACION_LENTA' => l.factor_ACEPTACION_LENTA,
  'LLEGADA_TARDE' => l.factor_LLEGADA_TARDE,
  'DEJO_ANTES_DEL_DESTINO' => l.factor_DEJO_ANTES_DEL_DESTINO,
  'PRECIO' => l.factor_PRECIO,
  'RUTA_LARGA' => l.factor_RUTA_LARGA,
  'CONDUCCION' => l.factor_CONDUCCION,
  'ACEPTACION_RAPIDA' => l.factor_ACEPTACION_RAPIDA,
  'LLEGO_A_TIEMPO' => l.factor_LLEGO_A_TIEMPO,
  'BUEN_PRECIO' => l.factor_BUEN_PRECIO,
  'BUENA_RUTA' => l.factor_BUENA_RUTA,
  'CONDUCCION_SEGURA' => l.factor_CONDUCCION_SEGURA,
  'AMABLE' => l.factor_AMABLE,
  _ => codigo,
};

/// Píldora «Ahora no ×» arriba a la derecha.
class BotonAhoraNo extends StatelessWidget {
  const BotonAhoraNo({required this.onTap, super.key});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextButton.icon(
      onPressed: onTap,
      iconAlignment: IconAlignment.end,
      icon: const Icon(Icons.close, size: 18),
      label: Text(l.ahoraNo),
      style: TextButton.styleFrom(
        minimumSize: const Size(Sizes.touch, Sizes.touch - 8),
        foregroundColor: NexaColors.muted,
        backgroundColor: NexaColors.card,
        side: const BorderSide(color: NexaColors.line),
        shape: const StadiumBorder(),
      ),
    );
  }
}

/// Cinco estrellas grandes (48 dp de área táctil cada una).
class EstrellasGrandes extends StatelessWidget {
  const EstrellasGrandes({
    required this.valor,
    required this.onChanged,
    super.key,
  });
  final int valor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 1; i <= 5; i++)
        IconButton(
          tooltip: '$i',
          constraints: const BoxConstraints(
            minWidth: Sizes.touch + 8,
            minHeight: Sizes.touch + 8,
          ),
          onPressed: () => onChanged(i),
          icon: Icon(
            i <= valor ? Icons.star_rounded : Icons.star_outline_rounded,
            color: i <= valor ? NexaColors.gold : NexaColors.tenue,
            size: 40,
          ),
        ),
    ],
  );
}

class ChipFactor extends StatelessWidget {
  const ChipFactor({
    required this.texto,
    required this.elegido,
    required this.positivo,
    required this.onTap,
    super.key,
  });

  final String texto;
  final bool elegido;
  final bool positivo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = positivo ? NexaColors.cyan : NexaColors.error;
    return Semantics(
      button: true,
      selected: elegido,
      child: Material(
        color: elegido ? color : NexaColors.raised,
        shape: StadiumBorder(
          side: BorderSide(color: elegido ? color : NexaColors.line),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Sp.md,
                vertical: Sp.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (elegido) ...[
                    const Icon(Icons.check, size: 16, color: NexaColors.bg),
                    const SizedBox(width: Sp.xs + 2),
                  ],
                  Flexible(
                    child: Text(
                      texto,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: elegido ? NexaColors.bg : NexaColors.texto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Texto del factor para ambos catálogos.
String textoFactorConductor(AppLocalizations l, String codigo) =>
    switch (codigo) {
      'ESPERA_EN_EL_PUNTO' => l.factor_ESPERA_EN_EL_PUNTO,
      'PUNTO_DIFICIL' => l.factor_PUNTO_DIFICIL,
      'PAGO' => l.factor_PAGO,
      'TRATO' => l.factor_TRATO,
      'LISTO_A_TIEMPO' => l.factor_LISTO_A_TIEMPO,
      'PUNTO_CLARO' => l.factor_PUNTO_CLARO,
      'PAGO_SIN_PROBLEMAS' => l.factor_PAGO_SIN_PROBLEMAS,
      _ => textoFactor(l, codigo),
    };
