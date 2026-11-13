import 'dart:typed_data';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/selector_imagen.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../../../core/widgets/opciones_foto.dart';
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
    final sesion = ref.watch(sesionProvider).sesion;
    final perfil = ref.watch(perfilProvider).asData?.value;
    final nivel = ref.watch(nivelProvider).asData?.value;
    final esConductor = sesion?.rol == Rol.conductor;
    final pasajero = esConductor
        ? null
        : ref.watch(perfilPasajeroProvider).value;
    final nombre = (perfil?.nombre.isNotEmpty ?? false)
        ? perfil!.nombre
        : sesion?.email ?? '';
    final resumen = [
      if (pasajero?.calificacion != null)
        pasajero!.calificacion!.toStringAsFixed(1).replaceAll('.', ','),
      esConductor ? l.rolConductor : l.rolPasajero,
      if (nivel != null) l.nivelActual(nivel.nombre),
    ].join(' · ');
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.gutter,
              Sp.lg,
              context.gutter,
              Sp.xl + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              ContenidoCentrado(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _AvatarPerfil(
                          foto: ref.watch(fotoPerfilProvider).asData?.value,
                          habilitado: perfil != null,
                          tieneFoto: perfil?.tieneFoto ?? false,
                          progreso: nivel?.progreso ?? 0,
                        ),
                        const SizedBox(width: Sp.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: NexaTexto.titulo,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: Sp.xs),
                              Row(
                                children: [
                                  if (pasajero?.calificacion != null) ...[
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: NexaColors.gold,
                                    ),
                                    const SizedBox(width: Sp.xs),
                                  ],
                                  Flexible(
                                    child: Text(
                                      resumen,
                                      style: NexaTexto.pequeno.copyWith(
                                        color: NexaColors.muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (perfil != null)
                                Text(
                                  [
                                    perfil.email,
                                    if (perfil.telefono != null)
                                      perfil.telefono!,
                                  ].join(' · '),
                                  style: NexaTexto.pequeno.copyWith(
                                    color: NexaColors.tenue,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.xl),
                    _Seccion(texto: l.seccionCuenta),
                    NexaCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Sp.lg,
                        vertical: Sp.xs,
                      ),
                      child: Column(
                        children: [
                          if (perfil != null)
                            _Opcion(
                              icono: Icons.person_outline,
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
                            icono: Icons.star_outline,
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
                    Material(
                      color: NexaColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Rad.lg),
                        side: const BorderSide(color: NexaColors.line),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () =>
                            ref.read(sesionProvider.notifier).logout(),
                        child: Padding(
                          padding: const EdgeInsets.all(Sp.md + 2),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: NexaColors.errorSuave,
                                  borderRadius: BorderRadius.circular(Rad.md),
                                ),
                                child: const Icon(
                                  Icons.logout,
                                  size: 20,
                                  color: NexaColors.error,
                                ),
                              ),
                              const SizedBox(width: Sp.md),
                              Expanded(
                                child: Text(
                                  l.cerrarSesion,
                                  style: NexaTexto.cuerpo.copyWith(
                                    color: NexaColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

/// Etiqueta de sección en mayúsculas («CUENTA»).
class _Seccion extends StatelessWidget {
  const _Seccion({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: Sp.xs, bottom: Sp.sm),
    child: Text(
      texto.toUpperCase(),
      style: NexaTexto.etiqueta.copyWith(color: NexaColors.tenue),
    ),
  );
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
              color: NexaColors.gold,
              diametro: 88,
              trazo: 3,
              relleno: 3,
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
                  radius: 14,
                  backgroundColor: NexaColors.cyan,
                  child: Icon(
                    Icons.photo_camera,
                    size: 14,
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
