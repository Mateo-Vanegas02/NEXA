import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
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
          // Tarjetas de rol (diseño A04).
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _TarjetaRol(
                    icono: Icons.place_outlined,
                    titulo: l.rolViajar,
                    texto: l.rolViajarSub,
                    elegida: _rol == Rol.pasajero,
                    onTap: () => setState(() => _rol = Rol.pasajero),
                  ),
                ),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: _TarjetaRol(
                    icono: Icons.two_wheeler,
                    titulo: l.rolConducir,
                    texto: l.rolConducirSub,
                    elegida: _rol == Rol.conductor,
                    onTap: () => setState(() => _rol = Rol.conductor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Sp.xl),
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
                  icono: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (v) => validarNombre(l, v),
                ),
                const SizedBox(height: Sp.md),
                NexaTextField(
                  controller: _tel,
                  label: l.telefono,
                  icono: Icons.phone_outlined,
                  pista: '300 123 4567',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (v) => validarTelefono(l, v),
                ),
                const SizedBox(height: Sp.md),
                NexaTextField(
                  controller: _email,
                  label: l.email,
                  icono: Icons.mail_outline,
                  pista: 'tu@correo.co',
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
                  icono: Icons.lock_outline,
                  obscure: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) => validarPasswordNueva(l, v),
                ),
                const SizedBox(height: Sp.md),
                NexaTextField(
                  controller: _pass2,
                  label: l.confirmarPassword,
                  icono: Icons.lock_outline,
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
        const SizedBox(height: Sp.xl),
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
      ],
      pie: NexaButton(
        label: l.yaTienesCuenta,
        variant: NexaButtonVariant.fantasma,
        onPressed: () => context.go('/login'),
      ),
    );
  }
}

/// Tarjeta para elegir cómo usar NEXA (viajar o conducir).
class _TarjetaRol extends StatelessWidget {
  const _TarjetaRol({
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.elegida,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final bool elegida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: elegida,
    child: Material(
      color: elegida ? NexaColors.raised : NexaColors.card,
      borderRadius: BorderRadius.circular(Rad.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(Rad.lg),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(Sp.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Rad.lg),
            border: Border.all(
              color: elegida ? NexaColors.cyan : NexaColors.line,
              width: elegida ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: elegida ? NexaColors.cyan : NexaColors.cyanSuave,
                      borderRadius: BorderRadius.circular(Rad.md),
                    ),
                    child: Icon(
                      icono,
                      size: 22,
                      color: elegida ? NexaColors.bg : NexaColors.cyan,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    elegida ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 22,
                    color: elegida ? NexaColors.cyan : NexaColors.tenue,
                  ),
                ],
              ),
              const SizedBox(height: Sp.md),
              Text(titulo, style: NexaTexto.subtitulo),
              const SizedBox(height: Sp.xs),
              Text(
                texto,
                style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
