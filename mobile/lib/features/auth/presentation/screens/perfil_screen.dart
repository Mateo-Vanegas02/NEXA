import 'dart:typed_data';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/selector_imagen.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../../../core/widgets/opciones_foto.dart';
import '../../../niveles/domain/nivel.dart';
import '../../../niveles/presentation/controllers/niveles_controller.dart';
import '../../../viajes/presentation/controllers/viaje_pasajero_controller.dart';
import '../../domain/auth.dart';
import '../controllers/perfil_controller.dart';
import '../controllers/session_controller.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final sesion = ref.watch(sesionProvider).sesion;
    final perfil = ref.watch(perfilProvider).asData?.value;
    final nivel = ref.watch(nivelProvider).asData?.value;
    final esConductor = sesion?.rol == Rol.conductor;
    return Scaffold(
      appBar: AppBar(title: Text(l.perfil)),
      body: FondoNexa(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(context.gutter),
            children: [
              ContenidoCentrado(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: _AvatarPerfil(
                        foto: ref.watch(fotoPerfilProvider).asData?.value,
                        habilitado: perfil != null,
                        tieneFoto: perfil?.tieneFoto ?? false,
                        progreso: nivel?.progreso ?? 0,
                      ),
                    ),
                    const SizedBox(height: Sp.md),
                    Text(
                      (perfil?.nombre.isNotEmpty ?? false)
                          ? perfil!.nombre
                          : sesion?.email ?? '',
                      style: t.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (perfil != null)
                      Text(
                        [
                          perfil.email,
                          if (perfil.telefono != null) perfil.telefono!,
                        ].join(' · '),
                        style: t.bodySmall?.copyWith(color: context.muted),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: Sp.sm),
                    Center(
                      child: Chip(
                        label: Text(
                          esConductor ? l.rolConductor : l.rolPasajero,
                        ),
                      ),
                    ),
                    const SizedBox(height: Sp.lg),
                    _Cifras(esConductor: esConductor, nivel: nivel),
                    const SizedBox(height: Sp.lg),
                    NexaCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Sp.lg,
                        vertical: Sp.xs,
                      ),
                      child: Column(
                        children: [
                          if (perfil != null)
                            _Opcion(
                              icono: Icons.edit_outlined,
                              titulo: l.editarPerfil,
                              detalle: l.editarPerfilSub,
                              onTap: () => showDialog<void>(
                                context: context,
                                builder: (_) => _EditarPerfilDialog(
                                  nombre: perfil.nombre,
                                  telefono: perfil.telefono ?? '',
                                ),
                              ),
                            ),
                          _Opcion(
                            icono: Icons.military_tech_outlined,
                            titulo: l.nivelesTitulo,
                            detalle: nivel == null
                                ? null
                                : esConductor
                                ? l.nivelActual(nivel.nombre)
                                : l.nivelDescuento(
                                    nivel.nombre,
                                    (nivel.descuento * 100).round(),
                                  ),
                            onTap: () => esConductor
                                ? context.go('/c/niveles')
                                : context.go('/p/niveles'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Sp.lg),
                    TextButton.icon(
                      onPressed: () =>
                          ref.read(sesionProvider.notifier).logout(),
                      icon: const Icon(Icons.logout),
                      label: Text(l.cerrarSesion),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(Sizes.touch),
                        foregroundColor: context.colors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tres cifras del perfil: viajes, calificación y nivel. Viajes y calificación
/// solo existen para el pasajero.
class _Cifras extends ConsumerWidget {
  const _Cifras({required this.esConductor, required this.nivel});
  final bool esConductor;
  final NivelEstado? nivel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = esConductor ? null : ref.watch(perfilPasajeroProvider).value;
    final cal = p?.calificacion;
    final cifras = [
      if (p?.viajes != null) ('${p!.viajes}', l.statViajes, false),
      if (cal != null)
        (cal.toStringAsFixed(1).replaceAll('.', ','), l.statCalificacion, true),
      if (nivel != null) (nivel!.nombre, l.statNivel, false),
    ];
    if (cifras.isEmpty) return const SizedBox.shrink();
    return NexaCard(
      padding: const EdgeInsets.symmetric(vertical: Sp.md),
      child: Row(
        children: [
          for (var i = 0; i < cifras.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 32,
                color: context.colors.outline.withValues(alpha: 0.4),
              ),
            Expanded(
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (cifras[i].$3) ...[
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: NexaColors.gold,
                          ),
                          const SizedBox(width: Sp.xs),
                        ],
                        Text(
                          cifras[i].$1,
                          style: context.textos.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: i == cifras.length - 1 && nivel != null
                                ? NexaColors.cyan
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    cifras[i].$2,
                    style: context.textos.bodySmall?.copyWith(
                      color: context.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Fila de la lista del perfil: icono, título, detalle y flecha.
class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.icono,
    required this.titulo,
    required this.onTap,
    this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String? detalle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(Rad.md),
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: NexaColors.cyan.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, size: 18, color: context.acento),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: context.textos.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detalle != null)
                  Text(
                    detalle!,
                    style: context.textos.bodySmall?.copyWith(
                      color: context.muted,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.muted),
        ],
      ),
    ),
  );
}

/// Foto de perfil: al tocarla se puede tomar otra, elegirla de la galería o quitarla.
class _AvatarPerfil extends ConsumerWidget {
  const _AvatarPerfil({
    required this.foto,
    required this.habilitado,
    required this.tieneFoto,
    required this.progreso,
  });

  final Uint8List? foto;
  final bool habilitado;
  final bool tieneFoto;

  /// Avance hacia el siguiente nivel (0 a 1), dibujado como anillo.
  final double progreso;

  Future<void> _cambiar(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final mensajes = ScaffoldMessenger.of(context);
    final opcion = await mostrarOpcionesFoto(context, conQuitar: tieneFoto);
    if (opcion == null) return;
    try {
      final perfil = ref.read(perfilProvider.notifier);
      if (opcion == OpcionFoto.quitar) {
        await perfil.quitarFoto();
        mensajes
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l.fotoQuitada)));
        return;
      }
      final archivo = await ref
          .read(selectorImagenProvider)
          .elegir(
            opcion == OpcionFoto.camara
                ? OrigenImagen.camara
                : OrigenImagen.galeria,
            maxLado: 800,
          );
      if (archivo == null) return;
      await perfil.cambiarFoto(archivo);
      mensajes
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.fotoActualizada)));
    } on Object catch (e) {
      mensajes.showSnackBar(
        SnackBar(content: Text(AppException.from(e).mensaje)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l.cambiarFoto,
      child: InkResponse(
        onTap: habilitado ? () => _cambiar(context, ref) : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            NexaAnilloProgreso(
              progreso: progreso,
              child: CircleAvatar(
                backgroundImage: foto == null ? null : MemoryImage(foto!),
                child: foto == null ? const Icon(Icons.person, size: 40) : null,
              ),
            ),
            if (habilitado)
              const Positioned(
                right: 0,
                bottom: 2,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: NexaColors.cyan,
                  child: Icon(
                    Icons.photo_camera,
                    size: 17,
                    color: NexaColors.bg,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Formulario para cambiar nombre y teléfono (el correo no se edita).
class _EditarPerfilDialog extends ConsumerStatefulWidget {
  const _EditarPerfilDialog({required this.nombre, required this.telefono});

  final String nombre;
  final String telefono;

  @override
  ConsumerState<_EditarPerfilDialog> createState() =>
      _EditarPerfilDialogState();
}

class _EditarPerfilDialogState extends ConsumerState<_EditarPerfilDialog> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.nombre);
  late final _tel = TextEditingController(text: widget.telefono);
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _tel.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await ref
          .read(perfilProvider.notifier)
          .guardar(nombre: _nombre.text.trim(), telefono: _tel.text.trim());
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.perfilActualizado)));
      Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = AppException.from(e).mensaje;
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.editarPerfil),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NexaTextField(
              controller: _nombre,
              label: l.nombreCompleto,
              textInputAction: TextInputAction.next,
              validator: (v) => validarNombre(l, v),
            ),
            const SizedBox(height: Sp.md),
            NexaTextField(
              controller: _tel,
              label: l.telefono,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _guardar(),
              validator: (v) => validarTelefono(l, v),
            ),
            if (_error != null) ...[
              const SizedBox(height: Sp.md),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cargando ? null : () => Navigator.of(context).pop(),
          child: Text(l.cancelar),
        ),
        FilledButton(
          onPressed: _cargando ? null : _guardar,
          child: Text(l.guardar),
        ),
      ],
    );
  }
}
