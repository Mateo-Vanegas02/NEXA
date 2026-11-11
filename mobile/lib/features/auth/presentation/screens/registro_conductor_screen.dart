import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/selector_imagen.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/validators_conductor.dart';
import '../../../../core/widgets/nexa_popup.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../../../core/widgets/opciones_foto.dart';
import '../../domain/auth.dart';
import '../widgets/auth_scaffold.dart';

/// Registro de un conductor: datos, moto, número y foto de cada documento.
/// No inicia sesión: la cuenta queda pendiente hasta que un administrador la apruebe.
class RegistroConductorScreen extends ConsumerStatefulWidget {
  const RegistroConductorScreen({super.key});

  @override
  ConsumerState<RegistroConductorScreen> createState() =>
      _RegistroConductorScreenState();
}

class _RegistroConductorScreenState
    extends ConsumerState<RegistroConductorScreen> {
  final _form = GlobalKey<FormState>();
  final _c = {
    for (final k in [
      'nombre',
      'email',
      'telefono',
      'pass',
      'pass2',
      'placa',
      'marca',
      'modelo',
      'color',
      'licencia',
      'tarjeta',
      'soat',
      'tecno',
    ])
      k: TextEditingController(),
  };

  ArchivoImagen? _fotoLicencia;
  ArchivoImagen? _fotoTarjeta;
  ArchivoImagen? _fotoSoat;
  ArchivoImagen? _fotoTecno;
  bool _verFaltantes = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<ArchivoImagen?> _pedirFoto() async {
    final opcion = await mostrarOpcionesFoto(context);
    if (opcion == null || !mounted) return null;
    try {
      return await ref
          .read(selectorImagenProvider)
          .elegir(
            opcion == OpcionFoto.camara
                ? OrigenImagen.camara
                : OrigenImagen.galeria,
          );
    } on Object {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).errorFoto);
      }
      return null;
    }
  }

  Future<void> _enviar() async {
    final fotosOk = [
      _fotoLicencia,
      _fotoTarjeta,
      _fotoSoat,
      _fotoTecno,
    ].every((f) => f != null);
    final formOk = _form.currentState!.validate();
    if (!fotosOk) setState(() => _verFaltantes = true);
    if (!formOk || !fotosOk) return;

    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .registrarConductor(
            RegistroConductor(
              nombre: _c['nombre']!.text.trim(),
              email: _c['email']!.text.trim(),
              telefono: _c['telefono']!.text.trim(),
              password: _c['pass']!.text,
              licencia: _c['licencia']!.text.trim(),
              placa: _c['placa']!.text.trim().toUpperCase(),
              marca: _c['marca']!.text.trim(),
              modelo: _c['modelo']!.text.trim(),
              color: _c['color']!.text.trim(),
              tarjetaPropiedad: _c['tarjeta']!.text.trim(),
              soat: _c['soat']!.text.trim(),
              tecnomecanica: _c['tecno']!.text.trim(),
              fotoLicencia: _fotoLicencia!,
              fotoTarjetaPropiedad: _fotoTarjeta!,
              fotoSoat: _fotoSoat!,
              fotoTecnomecanica: _fotoTecno!,
            ),
          );
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      await mostrarNexaPopup<void>(
        context,
        titulo: l.solicitudEnviada,
        mensaje: l.solicitudEnviadaMsg,
        tipo: NexaPopupTipo.exito,
        acciones: [NexaPopupAccion(etiqueta: l.aceptar)],
      );
      if (mounted) context.go('/login');
    } on Object catch (e) {
      if (mounted) setState(() => _error = AppException.from(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Widget _campo(
    String clave,
    String etiqueta,
    String? Function(String?) validar, {
    TextInputType? teclado,
    bool secreto = false,
    bool ultimo = false,
    ValueChanged<String>? alEnviar,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: Sp.md),
    child: NexaTextField(
      controller: _c[clave]!,
      label: etiqueta,
      keyboardType: teclado,
      obscure: secreto,
      textInputAction: ultimo ? TextInputAction.done : TextInputAction.next,
      onSubmitted: alEnviar,
      validator: validar,
    ),
  );

  Widget _seccion(String titulo) => Padding(
    padding: const EdgeInsets.only(top: Sp.sm, bottom: Sp.md),
    child: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final listos = [
      _fotoLicencia,
      _fotoTarjeta,
      _fotoSoat,
      _fotoTecno,
    ].where((f) => f != null).length;
    return AuthScaffold(
      titulo: l.registroConductorTitulo,
      subtitulo: l.registroConductorIntro,
      paso: 2,
      pasos: 2,
      onAtras: () => context.go('/registro'),
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _seccion(l.seccionDatos),
              _campo('nombre', l.nombreCompleto, (v) => validarNombre(l, v)),
              _campo(
                'email',
                l.email,
                (v) => validarEmail(l, v),
                teclado: TextInputType.emailAddress,
              ),
              _campo(
                'telefono',
                l.telefono,
                (v) => validarTelefono(l, v),
                teclado: TextInputType.phone,
              ),
              _campo(
                'pass',
                l.password,
                (v) => validarPasswordNueva(l, v),
                secreto: true,
              ),
              _campo(
                'pass2',
                l.confirmarPassword,
                (v) => validarConfirmacion(l, v, _c['pass']!.text),
                secreto: true,
              ),
              _seccion(l.seccionVehiculo),
              _campo('placa', l.regPlaca, (v) => validarPlaca(l, v)),
              _campo('marca', l.marca, (v) => validarMarca(l, v)),
              _campo('modelo', l.modelo, (v) => validarModelo(l, v)),
              _campo('color', l.color, (v) => validarColor(l, v)),
              _seccion(l.seccionDocumentos),
              _ProgresoDocumentos(listos: listos, total: 4),
              _campo(
                'licencia',
                l.licencia,
                (v) => validarLicencia(l, v),
                teclado: TextInputType.number,
              ),
              _CampoFoto(
                etiqueta: l.docLicencia,
                archivo: _fotoLicencia,
                falta: _verFaltantes && _fotoLicencia == null,
                alTocar: () async {
                  final f = await _pedirFoto();
                  if (f != null) setState(() => _fotoLicencia = f);
                },
              ),
              _campo(
                'tarjeta',
                l.tarjetaPropiedad,
                (v) => validarTarjetaPropiedad(l, v),
                teclado: TextInputType.number,
              ),
              _CampoFoto(
                etiqueta: l.docTarjeta,
                archivo: _fotoTarjeta,
                falta: _verFaltantes && _fotoTarjeta == null,
                alTocar: () async {
                  final f = await _pedirFoto();
                  if (f != null) setState(() => _fotoTarjeta = f);
                },
              ),
              _campo(
                'soat',
                l.soat,
                (v) => validarSoat(l, v),
                teclado: TextInputType.number,
              ),
              _CampoFoto(
                etiqueta: l.docSoat,
                archivo: _fotoSoat,
                falta: _verFaltantes && _fotoSoat == null,
                alTocar: () async {
                  final f = await _pedirFoto();
                  if (f != null) setState(() => _fotoSoat = f);
                },
              ),
              _campo(
                'tecno',
                l.tecnomecanica,
                (v) => validarTecnomecanica(l, v),
                teclado: TextInputType.number,
                ultimo: true,
              ),
              _CampoFoto(
                etiqueta: l.docTecno,
                archivo: _fotoTecno,
                falta: _verFaltantes && _fotoTecno == null,
                alTocar: () async {
                  final f = await _pedirFoto();
                  if (f != null) setState(() => _fotoTecno = f);
                },
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: Sp.md),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: Sp.lg),
        NexaButton(
          label: l.enviarSolicitud,
          onPressed: _enviar,
          cargando: _cargando,
        ),
      ],
    );
  }
}

/// Anillo con "n de total listos" y lo que falta para enviar la solicitud.
class _ProgresoDocumentos extends StatelessWidget {
  const _ProgresoDocumentos({required this.listos, required this.total});

  final int listos;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final completo = listos >= total;
    return Semantics(
      container: true,
      label:
          '${l.docsTitulo}: ${l.docsListos(listos, total)}. '
          '${completo ? l.docsCompletos : l.docsFaltan(total - listos)}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Sp.lg),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: listos / total,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      color: completo ? NexaColors.ok : NexaColors.cyan,
                      backgroundColor: context.colors.outline.withValues(
                        alpha: 0.25,
                      ),
                    ),
                  ),
                  Text(
                    '$listos/$total',
                    style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Sp.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.docsListos(listos, total),
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    completo ? l.docsCompletos : l.docsFaltan(total - listos),
                    style: t.bodySmall?.copyWith(color: context.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón de foto de un documento: miniatura cuando ya hay una, aviso si falta.
class _CampoFoto extends StatelessWidget {
  const _CampoFoto({
    required this.etiqueta,
    required this.archivo,
    required this.falta,
    required this.alTocar,
  });

  final String etiqueta;
  final ArchivoImagen? archivo;
  final bool falta;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tema = Theme.of(context);
    final Uint8List? bytes = archivo?.bytes;
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: etiqueta,
            child: InkWell(
              onTap: alTocar,
              borderRadius: BorderRadius.circular(Rad.lg),
              child: Container(
                constraints: const BoxConstraints(minHeight: Sizes.touch),
                padding: const EdgeInsets.all(Sp.md),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: falta
                        ? tema.colorScheme.error
                        : context.colors.outline,
                  ),
                  borderRadius: BorderRadius.circular(Rad.lg),
                ),
                child: Row(
                  children: [
                    if (bytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Rad.sm),
                        child: Image.memory(
                          bytes,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.image_outlined, size: 48),
                        ),
                      )
                    else
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              (falta ? tema.colorScheme.error : NexaColors.cyan)
                                  .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(Rad.lg),
                        ),
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          color: falta
                              ? tema.colorScheme.error
                              : tema.colorScheme.primary,
                        ),
                      ),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(etiqueta, style: tema.textTheme.bodyMedium),
                          Text(
                            bytes != null ? l.fotoLista : l.agregarFoto,
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: context.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (bytes != null)
                      const Icon(Icons.check_circle, color: NexaColors.ok),
                  ],
                ),
              ),
            ),
          ),
          if (falta)
            Padding(
              padding: const EdgeInsets.only(top: Sp.xs, left: Sp.md),
              child: Text(
                l.faltaFoto,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
