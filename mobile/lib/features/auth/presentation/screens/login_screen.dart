import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../../satisfaccion/presentation/widgets/satisfaccion_widgets.dart';
import '../controllers/session_controller.dart';
import '../../domain/auth.dart';
import '../widgets/auth_scaffold.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _cargando = false;
  String? _error;
  Rol? _rol;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await ref
          .read(sesionProvider.notifier)
          .login(_email.text.trim(), _pass.text, rol: _rol);
    } on Object catch (e) {
      if (mounted) setState(() => _error = AppException.from(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Volver lleva a la portada (botón de arriba y atrás del teléfono): al
    // login se llega con `go`, así que no hay pantalla debajo.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (hecho, _) {
        if (!hecho) context.go('/inicio');
      },
      child: AuthScaffold(
        onAtras: () => context.go('/inicio'),
        titulo: l.loginTitulo,
        subtitulo: l.loginSubtitulo,
        children: [
          Form(
            key: _form,
            child: Column(
              children: [
                // Tipo de cuenta arriba, como en el rediseño. Es opcional: con
                // una sola cuenta el servidor sabe cuál es; tocar el elegido lo
                // quita.
                Semantics(
                  header: true,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.loginCuenta,
                      style: context.textos.labelMedium,
                    ),
                  ),
                ),
                const SizedBox(height: Sp.xs),
                SelectorSegmentado<Rol?>(
                  opciones: [
                    (Rol.pasajero, l.rolPasajero),
                    (Rol.conductor, l.rolConductor),
                    (Rol.admin, l.rolAdminCorto),
                  ],
                  seleccion: _rol,
                  onSeleccion: (rol) =>
                      setState(() => _rol = rol == _rol ? null : rol),
                ),
                const SizedBox(height: Sp.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l.loginCuentaAyuda,
                    style: context.textos.labelSmall,
                  ),
                ),
                const SizedBox(height: Sp.lg),
                NexaTextField(
                  controller: _email,
                  label: l.email,
                  icono: Icons.mail_outline,
                  pista: 'tu@correo.co',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) => validarEmail(l, v),
                ),
                const SizedBox(height: Sp.md),
                NexaTextField(
                  controller: _pass,
                  label: l.password,
                  icono: Icons.lock_outline,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _enviar(),
                  autofillHints: const [AutofillHints.password],
                  validator: (v) => validarRequerido(l, v),
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
            label: l.ingresar,
            onPressed: _enviar,
            cargando: _cargando,
          ),
        ],
        pie: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l.noTienesCuentaPregunta,
              style: const TextStyle(color: NexaColors.muted, fontSize: 13),
            ),
            TextButton(
              onPressed: () => context.go('/registro'),
              style: TextButton.styleFrom(
                minimumSize: const Size(Sizes.touch, Sizes.touch),
                foregroundColor: NexaColors.cyan,
                textStyle: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(l.crearCuenta),
            ),
          ],
        ),
      ),
    );
  }
}
