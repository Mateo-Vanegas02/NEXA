import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/acciones_externas.dart';
import '../../../../core/widgets/nexa_diseno.dart';

/// Hoja de SOS (NEXA Pulso): la llamada a emergencias se confirma manteniendo
/// presionado el botón hasta que el anillo se cierra; soltar antes la cancela.
/// Devuelve `true` si el anillo se completó.
Future<bool> mostrarHojaSos(BuildContext context) async {
  final confirmo = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: NexaColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Rad.sheet)),
    ),
    builder: (_) => const _HojaSos(),
  );
  return confirmo ?? false;
}

class _HojaSos extends StatefulWidget {
  const _HojaSos();

  @override
  State<_HojaSos> createState() => _HojaSosState();
}

class _HojaSosState extends State<_HojaSos>
    with SingleTickerProviderStateMixin {
  late final AnimationController _carga = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
    reverseDuration: const Duration(milliseconds: 250),
  )..addStatusListener(_alCambiar);

  bool _presionado = false;

  void _alCambiar(AnimationStatus estado) {
    if (estado == AnimationStatus.completed) _confirmar();
  }

  void _confirmar() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop(true);
  }

  void _presionar() {
    HapticFeedback.selectionClick();
    setState(() => _presionado = true);
    _carga.forward();
  }

  void _soltar() {
    if (!_presionado) return;
    setState(() => _presionado = false);
    if (_carga.status != AnimationStatus.completed) _carga.reverse();
  }

  @override
  void dispose() {
    _carga.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.sosTitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: NexaColors.texto,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: Sp.xs),
            Text(
              l.sosTexto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: NexaColors.muted, fontSize: 14),
            ),
            const SizedBox(height: Sp.lg),
            // Con lector de pantalla, un toque basta: mantener presionado no
            // es un gesto accesible.
            Semantics(
              button: true,
              label: l.sosLlamarSemantica(kLineaEmergencias),
              onTap: _confirmar,
              excludeSemantics: true,
              child: GestureDetector(
                onTapDown: (_) => _presionar(),
                onTapUp: (_) => _soltar(),
                onTapCancel: _soltar,
                child: AnimatedBuilder(
                  animation: _carga,
                  builder: (context, child) => NexaAnilloProgreso(
                    progreso: _carga.value,
                    diametro: 152,
                    trazo: 6,
                    relleno: 8,
                    color: NexaColors.error,
                    child: child!,
                  ),
                  child: AnimatedScale(
                    scale: _presionado ? 0.94 : 1,
                    duration: const Duration(milliseconds: 120),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: NexaColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_in_talk,
                              color: NexaColors.bg,
                              size: 32,
                            ),
                            Text(
                              kLineaEmergencias,
                              style: TextStyle(
                                color: NexaColors.bg,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Sp.md),
            Text(
              _presionado ? l.sosSuelta : l.sosManten,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: NexaColors.texto,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Sp.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.cancelar),
            ),
          ],
        ),
      ),
    );
  }
}
