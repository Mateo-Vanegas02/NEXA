import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';

/// Un método de pago del pedido (rediseño 2026). Hoy solo el efectivo está
/// disponible; la tarjeta y la billetera quedan a la vista como «Próximamente»
/// hasta que el servidor tenga la pasarela de pago.
class MetodoPago {
  const MetodoPago(this.codigo, this.icono, {this.disponible = false});

  /// Lo que se envía al servidor (`metodoPago`).
  final String codigo;
  final IconData icono;
  final bool disponible;

  static const efectivo = MetodoPago(
    'efectivo',
    Icons.payments_rounded,
    disponible: true,
  );
  static const tarjeta = MetodoPago('tarjeta', Icons.credit_card_rounded);
  static const billetera = MetodoPago(
    'billetera',
    Icons.account_balance_wallet_rounded,
  );

  static const todos = [efectivo, tarjeta, billetera];

  static MetodoPago de(String codigo) =>
      todos.firstWhere((m) => m.codigo == codigo, orElse: () => efectivo);

  String nombre(AppLocalizations l) => switch (codigo) {
    'tarjeta' => l.metodoTarjeta,
    'billetera' => l.metodoBilletera,
    _ => l.efectivo,
  };

  String detalle(AppLocalizations l) => switch (codigo) {
    'tarjeta' => l.pagoTarjetaDetalle,
    'billetera' => l.pagoBilleteraDetalle,
    _ => l.pagoEfectivoDetalle,
  };
}

/// Abre la hoja para elegir cómo pagar; devuelve el código elegido.
Future<String?> elegirMetodoPago(BuildContext context, String actual) =>
    showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: NexaColors.surface,
      builder: (_) => _HojaMetodos(actual: actual),
    );

class _HojaMetodos extends StatelessWidget {
  const _HojaMetodos({required this.actual});
  final String actual;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(
                l.pagoTitulo,
                style: NexaTexto.titulo.copyWith(color: NexaColors.texto),
              ),
            ),
            const SizedBox(height: Sp.md),
            for (final m in MetodoPago.todos) ...[
              TarjetaMetodoPago(
                metodo: m,
                elegido: m.codigo == actual,
                onTap: m.disponible
                    ? () => Navigator.of(context).pop(m.codigo)
                    : null,
              ),
              const SizedBox(height: Sp.sm),
            ],
            const SizedBox(height: Sp.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: NexaColors.tenue,
                ),
                const SizedBox(width: Sp.sm),
                Expanded(
                  child: Text(
                    l.pagoNota,
                    style: NexaTexto.pequeno.copyWith(color: NexaColors.tenue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de un método: icono en su color, nombre, para qué sirve y si está
/// elegido; los que aún no existen salen atenuados con «Próximamente».
class TarjetaMetodoPago extends StatelessWidget {
  const TarjetaMetodoPago({
    required this.metodo,
    required this.elegido,
    this.onTap,
    super.key,
  });

  final MetodoPago metodo;
  final bool elegido;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final activo = metodo.disponible;
    final acento = activo ? NexaColors.cyan : NexaColors.tenue;
    return Opacity(
      opacity: activo ? 1 : 0.6,
      child: Material(
        color: elegido ? NexaColors.cyanSuave : NexaColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rad.lg),
          side: BorderSide(
            color: elegido ? NexaColors.cyan : NexaColors.line,
            width: elegido ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Rad.lg),
          child: Semantics(
            selected: elegido,
            enabled: activo,
            child: Padding(
              padding: const EdgeInsets.all(Sp.md),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: acento.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(Rad.md),
                    ),
                    child: Icon(metodo.icono, color: acento, size: 24),
                  ),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: Sp.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              metodo.nombre(l),
                              style: NexaTexto.subtitulo.copyWith(
                                color: NexaColors.texto,
                              ),
                            ),
                            if (!activo)
                              DecoratedBox(
                                decoration: const ShapeDecoration(
                                  color: NexaColors.goldSuave,
                                  shape: StadiumBorder(),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Sp.sm,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    l.pagoProximamente,
                                    style: NexaTexto.pequeno.copyWith(
                                      color: NexaColors.gold,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          metodo.detalle(l),
                          style: NexaTexto.pequeno.copyWith(
                            color: NexaColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (elegido) ...[
                    const SizedBox(width: Sp.sm),
                    Icon(
                      Icons.check_circle_rounded,
                      color: NexaColors.cyan,
                      semanticLabel: l.pagoElegido,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
