import '../../../../core/providers.dart';
import '../../domain/auth.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class SesionState {
  const SesionState({
    this.sesion,
    this.inicializado = false,
    this.onboardingVisto = false,
    this.bienvenida = false,
  });

  final Sesion? sesion;

  /// `false` mientras se restaura la sesión guardada (splash).
  final bool inicializado;

  final bool onboardingVisto;

  /// `true` justo tras iniciar sesión o registrarse: muestra el popup de bienvenida.
  final bool bienvenida;

  SesionState copyWith({
    Sesion? sesion,
    bool limpiar = false,
    bool? onboardingVisto,
    bool? bienvenida,
  }) => SesionState(
    sesion: limpiar ? null : (sesion ?? this.sesion),
    inicializado: true,
    onboardingVisto: onboardingVisto ?? this.onboardingVisto,
    bienvenida: limpiar ? false : (bienvenida ?? this.bienvenida),
  );

  bool get autenticado => sesion != null;
}

/// Sesión del usuario: restaurar, login, registro y logout.
/// Los errores se propagan como `AppException` para que la UI los muestre.
class SesionController extends Notifier<SesionState> {
  @override
  SesionState build() {
    ref.read(sesionHookProvider).alExpirar = () => logout();
    return const SesionState();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  static const _kOnboarding = 'onboarding_visto';

  Future<void> iniciar() async {
    if (state.inicializado) return;
    // El splash se muestra al menos [splashMinimoProvider], aunque la sesión
    // se restaure al instante.
    final minimo = Future<void>.delayed(ref.read(splashMinimoProvider));
    final s = await _repo.restaurar();
    final visto = await ref.read(secureStoreProvider).read(_kOnboarding) == '1';
    await minimo;
    state = SesionState(sesion: s, inicializado: true, onboardingVisto: visto);
  }

  Future<void> completarOnboarding() async {
    await ref.read(secureStoreProvider).write(_kOnboarding, '1');
    state = state.copyWith(onboardingVisto: true);
  }

  Future<void> login(String email, String password) async {
    final s = await _repo.login(email, password);
    state = state.copyWith(sesion: s, bienvenida: true);
  }

  Future<void> registrarPasajero(RegistroPasajero datos) async {
    final s = await _repo.registrarPasajero(datos);
    state = state.copyWith(sesion: s, bienvenida: true);
  }

  void consumirBienvenida() => state = state.copyWith(bienvenida: false);

  Future<void> logout() async {
    await _repo.logout();
    state = state.copyWith(limpiar: true);
  }
}

final sesionProvider = NotifierProvider<SesionController, SesionState>(
  SesionController.new,
);
