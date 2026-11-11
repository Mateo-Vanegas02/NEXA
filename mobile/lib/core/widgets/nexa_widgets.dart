import '../theme/theme_x.dart';

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/tokens.dart';

enum NexaButtonVariant { primario, secundario, peligro }

/// Botón de NEXA: alto mínimo 48dp, estado de carga y variantes.
class NexaButton extends StatelessWidget {
  const NexaButton({
    required this.label,
    required this.onPressed,
    this.cargando = false,
    this.variant = NexaButtonVariant.primario,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool cargando;
  final NexaButtonVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !cargando;
    final child = cargando
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: Sp.sm),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );
    const minimo = Size.fromHeight(Sizes.boton);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Rad.pill),
    );
    const texto = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    final callback = enabled ? onPressed : null;
    return switch (variant) {
      NexaButtonVariant.secundario => OutlinedButton(
        onPressed: callback,
        style: OutlinedButton.styleFrom(
          minimumSize: minimo,
          shape: shape,
          textStyle: texto,
        ),
        child: child,
      ),
      NexaButtonVariant.peligro => FilledButton(
        onPressed: callback,
        style: FilledButton.styleFrom(
          minimumSize: minimo,
          shape: shape,
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
          textStyle: texto,
        ),
        child: child,
      ),
      NexaButtonVariant.primario => DecoratedBox(
        // Resplandor cian solo en tema oscuro y con el botón habilitado.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Rad.pill),
          boxShadow: enabled && Theme.of(context).brightness == Brightness.dark
              ? NexaShadows.glow
              : null,
        ),
        child: FilledButton(
          onPressed: callback,
          style: FilledButton.styleFrom(
            minimumSize: minimo,
            shape: shape,
            textStyle: texto,
          ),
          child: child,
        ),
      ),
    };
  }
}

/// Campo de texto con etiqueta, validación y opción de ocultar contraseña.
class NexaTextField extends StatefulWidget {
  const NexaTextField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.obscure = false,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<NexaTextField> createState() => _NexaTextFieldState();
}

class _NexaTextFieldState extends State<NexaTextField> {
  late bool _oculto = widget.obscure;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    validator: widget.validator,
    keyboardType: widget.keyboardType,
    obscureText: _oculto,
    textInputAction: widget.textInputAction,
    onFieldSubmitted: widget.onSubmitted,
    autofillHints: widget.autofillHints,
    decoration: InputDecoration(
      labelText: widget.label,
      suffixIcon: widget.obscure
          ? IconButton(
              tooltip: _oculto ? 'Mostrar' : 'Ocultar',
              constraints: const BoxConstraints(
                minWidth: Sizes.touch,
                minHeight: Sizes.touch,
              ),
              icon: Icon(_oculto ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _oculto = !_oculto),
            )
          : null,
    ),
  );
}

/// Tarjeta con el estilo de superficie de NEXA.
class NexaCard extends StatelessWidget {
  const NexaCard({
    required this.child,
    this.padding = const EdgeInsets.all(Sp.lg),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(Rad.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Rad.md),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Rad.md),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Bloque gris pulsante para estados de carga.
class Skeleton extends StatefulWidget {
  const Skeleton({this.height = 16, this.width, super.key});
  final double height;
  final double? width;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.outline;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: base.withValues(alpha: 0.15 + 0.15 * _c.value),
          borderRadius: BorderRadius.circular(Rad.sm),
        ),
      ),
    );
  }
}

/// Esqueleto de lista/tarjetas mientras carga.
class CargandoSkeleton extends StatelessWidget {
  const CargandoSkeleton({this.filas = 3, super.key});
  final int filas;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Sp.lg),
    child: Column(
      children: [
        for (var i = 0; i < filas; i++) ...[
          const NexaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(height: 18, width: 140),
                SizedBox(height: Sp.sm),
                Skeleton(),
                SizedBox(height: Sp.sm),
                Skeleton(width: 200),
              ],
            ),
          ),
          const SizedBox(height: Sp.md),
        ],
      ],
    ),
  );
}

/// Estado vacío con icono, título y detalle.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    required this.titulo,
    this.detalle,
    this.icon = Icons.inbox_outlined,
    super.key,
  });
  final String titulo;
  final String? detalle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Sp.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: context.muted),
            const SizedBox(height: Sp.md),
            Text(titulo, style: t.titleMedium, textAlign: TextAlign.center),
            if (detalle != null) ...[
              const SizedBox(height: Sp.sm),
              Text(
                detalle!,
                style: t.bodyMedium?.copyWith(color: context.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado de error con botón de reintentar.
class EstadoError extends StatelessWidget {
  const EstadoError({required this.mensaje, this.onReintentar, super.key});
  final String mensaje;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Sp.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: NexaColors.error),
            const SizedBox(height: Sp.md),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: Sp.lg),
              OutlinedButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh),
                label: Text(l.reintentar),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(Sizes.touch, Sizes.touch),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
