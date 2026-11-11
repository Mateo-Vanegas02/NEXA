import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/auth.dart';
import '../controllers/session_controller.dart';
import '../widgets/auth_scaffold.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Registro en dos pasos: datos básicos y contraseña.
/// Si el rol es conductor, el botón lleva al formulario de conductor.
class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _formDatos = GlobalKey<FormState>();
  final _formClave = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _tel = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  Rol _rol = Rol.pasajero;
  int _paso = 1;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_nombre, _email, _tel, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  void _siguiente() {
    if (!_formDatos.currentState!.validate()) return;
    setState(() {
      _paso = 2;
      _error = null;
    });
  }

  void _atras() {
    if (_paso == 2) {
      setState(() => _paso = 1);
    } else {
      context.go('/login');
    }
  }

  Future<void> _enviar() async {
    if (!_formClave.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await ref
          .read(sesionProvider.notifier)
          .registrarPasajero(
            RegistroPasajero(
              nombre: _nombre.text.trim(),
              email: _email.text.trim(),
              telefono: _tel.text.trim(),
              password: _pass.text,
            ),
          );
    } on Object catch (e) {
      if (mounted) setState(() => _error = AppException.from(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final claves = _rol == Rol.pasajero && _paso == 2;
    return AuthScaffold(
      titulo: claves ? l.registroPaso2Titulo : l.registroTitulo,
      subtitulo: claves ? l.registroPaso2Sub : l.registroPaso1Sub,
      paso: claves ? 2 : 1,
      pasos: 2,
      onAtras: _atras,
      children: [
        if (!claves) ...[
          SegmentedButton<Rol>(
            segments: [
              ButtonSegment(
                value: Rol.pasajero,
                label: Text(l.rolPasajero),
                icon: const Icon(Icons.person),
              ),
              ButtonSegment(
                value: Rol.conductor,
                label: Text(l.rolConductor),
                icon: const Icon(Icons.two_wheeler),
              ),
            ],
            selected: {_rol},
            onSelectionChanged: (s) => setState(() => _rol = s.first),
          ),
          const SizedBox(height: Sp.lg),
        ],
        if (_rol == Rol.conductor)
          NexaCard(child: Text(l.registroConductorIntro))
        else if (!claves)
          Form(
            key: _formDatos,
            child: Column(
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
                  textInputAction: TextInputAction.next,
                  validator: (v) => validarTelefono(l, v),
                ),
                const SizedBox(height: Sp.md),
                NexaTextField(
                  controller: _email,
                  label: l.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _siguiente(),
                  validator: (v) => validarEmail(l, v),
                ),
              ],
            ),
          )
        else
          Form(
            key: _formClave,
            child: Column(
              children: [
                NexaTextField(
                  controller: _pass,
                  label: l.password,
                  obscure: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) => validarPasswordNueva(l, v),
                ),
                const SizedBox(height: Sp.md),
                NexaTextField(
                  controller: _pass2,
                  label: l.confirmarPassword,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _enviar(),
                  validator: (v) => validarConfirmacion(l, v, _pass.text),
                ),
              ],
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: Sp.md),
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: Sp.lg),
        NexaButton(
          label: switch ((_rol, claves)) {
            (Rol.conductor, _) => l.registroConductorBoton,
            (_, true) => l.crearCuenta,
            _ => l.continuar,
          },
          onPressed: switch ((_rol, claves)) {
            (Rol.conductor, _) => () => context.go('/registro/conductor'),
            (_, true) => _enviar,
            _ => _siguiente,
          },
          cargando: _cargando,
        ),
        const SizedBox(height: Sp.sm),
        TextButton(
          onPressed: () => context.go('/login'),
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(Sizes.touch),
          ),
          child: Text(l.yaTienesCuenta, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
