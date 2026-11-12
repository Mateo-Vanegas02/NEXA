import 'package:flutter/material.dart';

import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/nexa_diseno.dart';
import '../../../core/widgets/nexa_widgets.dart';

/// Un motivo con icono, título y detalle («para qué sirve este permiso»).
class Motivo {
  const Motivo(this.icono, this.titulo, this.detalle);
  final IconData icono;
  final String titulo;
  final String detalle;
}

/// Plantilla común de las pantallas de permisos: ilustración, título, texto,
/// motivos o contenido propio y los botones abajo (siempre visibles).
class PlantillaPermiso extends StatelessWidget {
  const PlantillaPermiso({
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.primario,
    required this.onPrimario,
    this.motivos = const [],
    this.contenido,
    this.secundario,
    this.onSecundario,
    this.cargando = false,
    this.colorIcono,
    this.onAtras,
    super.key,
  });

  final IconData icono;
  final Color? colorIcono;
  final String titulo;
  final String texto;
  final List<Motivo> motivos;
  final Widget? contenido;
  final String primario;
  final VoidCallback? onPrimario;
  final String? secundario;
  final VoidCallback? onSecundario;
  final bool cargando;

  /// Flecha de atrás; por omisión cierra la pantalla respondiendo `false`.
  final VoidCallback? onAtras;

  @override
  Widget build(BuildContext context) {
    final color = colorIcono ?? context.acento;
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Sizes.maxContentWidth,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(Sp.sm),
                      child: BackButton(
                        onPressed: cargando
                            ? null
                            : onAtras ??
                                  () => Navigator.of(context).maybePop(false),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: Sp.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: _IconoGrande(icono: icono, color: color),
                          ),
                          const SizedBox(height: Sp.xl),
                          Semantics(
                            header: true,
                            child: Text(
                              titulo,
                              style: context.textos.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: Sp.sm),
                          Text(
                            texto,
                            style: context.textos.bodyLarge?.copyWith(
                              color: context.muted,
                            ),
                          ),
                          const SizedBox(height: Sp.lg),
                          for (final m in motivos) _FilaMotivo(motivo: m),
                          ?contenido,
                          const SizedBox(height: Sp.lg),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Sp.xl,
                      Sp.sm,
                      Sp.xl,
                      Sp.lg,
                    ),
                    child: Column(
                      children: [
                        NexaButton(
                          label: primario,
                          onPressed: onPrimario,
                          cargando: cargando,
                        ),
                        if (secundario != null) ...[
                          const SizedBox(height: Sp.xs),
                          SizedBox(
                            width: double.infinity,
                            height: Sizes.touch,
                            child: TextButton(
                              onPressed: cargando ? null : onSecundario,
                              child: Text(secundario!),
                            ),
                          ),
                        ],
                      ],
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

class _IconoGrande extends StatelessWidget {
  const _IconoGrande({required this.icono, required this.color});
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Rad.lg),
            color: color.withValues(alpha: 0.18),
          ),
          child: Icon(icono, size: 38, color: color),
        ),
      ),
    );
  }
}

class _FilaMotivo extends StatelessWidget {
  const _FilaMotivo({required this.motivo});
  final Motivo motivo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Rad.md),
              color: context.acento.withValues(alpha: 0.14),
            ),
            child: Icon(motivo.icono, size: 20, color: context.acento),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  motivo.titulo,
                  style: context.textos.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  motivo.detalle,
                  style: context.textos.bodySmall?.copyWith(
                    color: context.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista numerada de pasos (guía de batería, ajustes del teléfono).
class PasosNumerados extends StatelessWidget {
  const PasosNumerados({required this.pasos, this.titulo, super.key});
  final List<String> pasos;
  final String? titulo;

  @override
  Widget build(BuildContext context) {
    return NexaCard(
      padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titulo != null)
            Padding(
              padding: const EdgeInsets.only(top: Sp.sm, bottom: Sp.xs),
              child: Text(
                titulo!.toUpperCase(),
                style: context.textos.labelSmall?.copyWith(
                  color: context.muted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          for (var i = 0; i < pasos.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.sm),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: context.acento.withValues(alpha: 0.16),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: context.acento,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: Sp.md),
                  Expanded(child: Text(pasos[i])),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
