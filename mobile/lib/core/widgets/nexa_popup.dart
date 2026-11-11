import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'nexa_logo.dart';

/// Tono del popup: define el color y el icono de la insignia.
enum NexaPopupTipo {
  info(Icons.info_outline, NexaColors.cyan),
  exito(Icons.check, NexaColors.ok),
  alerta(Icons.priority_high, NexaColors.gold),
  peligro(Icons.close, NexaColors.error);

  const NexaPopupTipo(this.icono, this.color);
  final IconData icono;
  final Color color;
}

/// Acción de un popup. La primera es la principal (relleno cian).
class NexaPopupAccion<T> {
  const NexaPopupAccion({required this.etiqueta, this.valor, this.peligro});

  final String etiqueta;

  /// Valor que devuelve `mostrarNexaPopup` al pulsarla.
  final T? valor;

  /// Pinta el botón en rojo (acciones destructivas).
  final bool? peligro;
}

/// Muestra el popup de marca de NEXA: tarjeta oscura con logo, fondo difuminado
/// y animación de entrada (escala con rebote + fade + deslizamiento, logo con
/// halo pulsante y contenido escalonado). Respeta "reducir animaciones".
Future<T?> mostrarNexaPopup<T>(
  BuildContext context, {
  required String titulo,
  String? mensaje,
  NexaPopupTipo tipo = NexaPopupTipo.info,
  List<NexaPopupAccion<T>> acciones = const [],
  Widget? hero,
  bool descartable = true,
}) {
  final reducir = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: descartable,
    barrierLabel: titulo,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: reducir
        ? Duration.zero
        : const Duration(milliseconds: 420),
    pageBuilder: (ctx, _, _) => _NexaPopup<T>(
      titulo: titulo,
      mensaje: mensaje,
      tipo: tipo,
      acciones: acciones,
      hero: hero,
      reducirMovimiento: reducir,
    ),
    transitionBuilder: (ctx, anim, _, child) {
      if (reducir) return child;
      final entrada = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 6 * anim.value,
                sigmaY: 6 * anim.value,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(entrada),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.82, end: 1).animate(entrada),
                child: child,
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _NexaPopup<T> extends StatefulWidget {
  const _NexaPopup({
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.acciones,
    required this.hero,
    required this.reducirMovimiento,
  });

  final String titulo;
  final String? mensaje;
  final NexaPopupTipo tipo;
  final List<NexaPopupAccion<T>> acciones;
  final Widget? hero;
  final bool reducirMovimiento;

  @override
  State<_NexaPopup<T>> createState() => _NexaPopupState<T>();
}

class _NexaPopupState<T> extends State<_NexaPopup<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.reducirMovimiento) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Aparición escalonada: sube 12 px y aparece dentro del tramo [a, b].
  Widget _escalonado(double a, double b, Widget child) {
    final anim = CurvedAnimation(
      parent: _c,
      curve: Interval(a, b, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // El popup conserva siempre el estilo oscuro de NEXA.
    final tema = AppTheme.dark;
    final t = tema.textTheme;
    final color = widget.tipo.color;
    return Theme(
      data: tema,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Sp.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Semantics(
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                label: widget.titulo,
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Rad.lg + 4),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF05243F), NexaColors.bg],
                      ),
                      border: Border.all(
                        color: NexaColors.cyan.withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NexaColors.cyan.withValues(alpha: 0.22),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                        const BoxShadow(
                          color: Colors.black87,
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      Sp.xl,
                      Sp.xl,
                      Sp.xl,
                      Sp.lg,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _escalonado(
                            0,
                            0.45,
                            Center(
                              child: _Hero(
                                tipo: widget.tipo,
                                animar: !widget.reducirMovimiento,
                                hero: widget.hero,
                              ),
                            ),
                          ),
                          const SizedBox(height: Sp.lg),
                          _escalonado(
                            0.2,
                            0.65,
                            Text(
                              widget.titulo,
                              textAlign: TextAlign.center,
                              style: t.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (widget.mensaje != null) ...[
                            const SizedBox(height: Sp.sm),
                            _escalonado(
                              0.3,
                              0.75,
                              Text(
                                widget.mensaje!,
                                textAlign: TextAlign.center,
                                style: t.bodyMedium?.copyWith(
                                  color: NexaColors.muted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                          if (widget.acciones.isNotEmpty) ...[
                            const SizedBox(height: Sp.xl),
                            _escalonado(
                              0.45,
                              1,
                              Column(
                                children: [
                                  for (
                                    var i = 0;
                                    i < widget.acciones.length;
                                    i++
                                  ) ...[
                                    if (i > 0) const SizedBox(height: Sp.sm),
                                    _Boton<T>(
                                      accion: widget.acciones[i],
                                      principal: i == 0,
                                      color: color,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Boton<T> extends StatelessWidget {
  const _Boton({
    required this.accion,
    required this.principal,
    required this.color,
  });

  final NexaPopupAccion<T> accion;
  final bool principal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Rad.md),
    );
    const minimo = Size.fromHeight(Sizes.touch);
    final peligro = accion.peligro ?? false;
    void cerrar() => Navigator.of(context).pop(accion.valor);
    if (principal) {
      return FilledButton(
        onPressed: cerrar,
        style: FilledButton.styleFrom(
          minimumSize: minimo,
          shape: shape,
          backgroundColor: peligro ? NexaColors.error : NexaColors.cyan,
          foregroundColor: NexaColors.bg,
        ),
        child: Text(
          accion.etiqueta,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }
    return TextButton(
      onPressed: cerrar,
      style: TextButton.styleFrom(
        minimumSize: minimo,
        shape: shape,
        foregroundColor: peligro ? NexaColors.error : NexaColors.muted,
      ),
      child: Text(accion.etiqueta),
    );
  }
}

/// Logo con halo pulsante e insignia del tipo (o un [hero] propio).
class _Hero extends StatefulWidget {
  const _Hero({required this.tipo, required this.animar, this.hero});

  final NexaPopupTipo tipo;
  final bool animar;
  final Widget? hero;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animar) _pulso.repeat();
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.tipo.color;
    const tam = 88.0;
    return SizedBox(
      width: tam + 40,
      height: tam + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulso,
            builder: (_, _) {
              final v = widget.animar ? _pulso.value : 0.0;
              return Container(
                width: tam + 40 * v,
                height: tam + 40 * v,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.5 * (1 - v)),
                    width: 2,
                  ),
                ),
              );
            },
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: widget.animar ? 0 : 1, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: widget.hero ?? const NexaLogo(tamano: tam),
          ),
          if (widget.hero == null)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: NexaColors.bg, width: 3),
                ),
                child: Icon(widget.tipo.icono, size: 16, color: NexaColors.bg),
              ),
            ),
        ],
      ),
    );
  }
}
