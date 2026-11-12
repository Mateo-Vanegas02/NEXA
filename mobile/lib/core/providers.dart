import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/data/auth_repository_mock.dart';
import '../features/auth/data/perfil_repository_impl.dart';
import '../features/auth/domain/auth.dart';
import '../features/auth/domain/perfil.dart';
import '../features/niveles/data/niveles_repository_impl.dart';
import '../features/niveles/domain/niveles_repository.dart';
import '../features/satisfaccion/data/satisfaccion_repository_impl.dart';
import '../features/satisfaccion/data/satisfaccion_repository_mock.dart';
import '../features/satisfaccion/domain/satisfaccion_repository.dart';
import '../features/viajes/data/mock_backend.dart';
import '../features/viajes/data/viajes_repository_impl.dart';
import '../features/viajes/domain/viajes_repository.dart';
import 'config/env.dart';
import 'notificaciones/notificaciones_locales.dart';
import 'permisos/guia_permisos.dart';
import 'permisos/permisos_dispositivo.dart';
import 'utils/selector_imagen.dart';
import 'network/api_client.dart';
import 'network/token_storage.dart';

/// Tiempo mínimo que se muestra el splash (la sesión se restaura casi al instante).
final splashMinimoProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 2200),
);

/// `true` = repositorios simulados. Sobrescribible en tests.
final useMocksProvider = Provider<bool>((ref) => Env.useMocks);

/// Notificaciones del teléfono. `main` lo sustituye por la instancia ya
/// inicializada (con sus canales); en pruebas queda la inactiva.
final notificacionesProvider = Provider<NotificacionesLocales>(
  (ref) => const NotificacionesInactivas(),
);

/// Permisos del teléfono (ubicación). En pruebas se sustituye por
/// `PermisosFijos`.
final permisosProvider = Provider<PermisosDispositivo>(
  (ref) => const PermisosGeolocator(),
);

/// Qué pantalla de permisos toca y cuáles ya vio el usuario.
final guiaPermisosProvider = Provider<GuiaPermisos>(
  (ref) => GuiaPermisos(
    permisos: ref.watch(permisosProvider),
    notificaciones: ref.watch(notificacionesProvider),
    store: ref.watch(secureStoreProvider),
  ),
);

/// Cámara y galería. Sobrescribible en tests.
final selectorImagenProvider = Provider<SelectorImagen>(
  (ref) => const SelectorImagenPlugin(),
);

final secureStoreProvider = Provider<SecureStore>(
  (ref) => const FlutterSecureStore(),
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(secureStoreProvider)),
);

/// Gancho que el controlador de sesión registra para cerrar sesión ante un 401
/// (evita un ciclo de dependencias entre Dio y la sesión).
class SesionHook {
  void Function()? alExpirar;
}

final sesionHookProvider = Provider<SesionHook>((ref) => SesionHook());

final dioProvider = Provider<Dio>(
  (ref) => crearDio(
    tokens: ref.watch(tokenStorageProvider),
    onSesionExpirada: () => ref.read(sesionHookProvider).alExpirar?.call(),
  ),
);

final mockBackendProvider = Provider<MockBackend>((ref) => MockBackend());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final tokens = ref.watch(tokenStorageProvider);
  return ref.watch(useMocksProvider)
      ? MockAuthRepository(tokens)
      : ApiAuthRepository(ref.watch(dioProvider), tokens);
});

final perfilRepositoryProvider = Provider<PerfilRepository>(
  (ref) => ref.watch(useMocksProvider)
      ? MockPerfilRepository()
      : ApiPerfilRepository(ref.watch(dioProvider)),
);

final pasajeroRepositoryProvider = Provider<PasajeroRepository>(
  (ref) => ref.watch(useMocksProvider)
      ? MockPasajeroRepository(ref.watch(mockBackendProvider))
      : ApiPasajeroRepository(ref.watch(dioProvider)),
);

final conductorRepositoryProvider = Provider<ConductorRepository>(
  (ref) => ref.watch(useMocksProvider)
      ? MockConductorRepository(ref.watch(mockBackendProvider))
      : ApiConductorRepository(ref.watch(dioProvider)),
);

final nivelesRepositoryProvider = Provider<NivelesRepository>(
  (ref) => ref.watch(useMocksProvider)
      ? MockNivelesRepository(ref.watch(mockBackendProvider))
      : ApiNivelesRepository(ref.watch(dioProvider)),
);

/// URL de la Lambda de satisfacción. Sobrescribible en tests.
final satisfaccionUrlProvider = Provider<String>((ref) => Env.satisfaccionUrl);

/// Dio hacia la Lambda `nexa-satisfaccion`: misma sesión (JWT del admin) y el
/// mismo manejo de 401, pero sin el prefijo `/api` del backend.
final satisfaccionDioProvider = Provider<Dio>(
  (ref) => crearDio(
    tokens: ref.watch(tokenStorageProvider),
    onSesionExpirada: () => ref.read(sesionHookProvider).alExpirar?.call(),
    baseUrl: ref.watch(satisfaccionUrlProvider),
    prefijo: '',
  ),
);

/// Una sola instancia del mock para que el entrenamiento simulado avance entre pantallas.
final mockSatisfaccionProvider = Provider<MockSatisfaccionRepository>(
  (ref) => MockSatisfaccionRepository(),
);

final satisfaccionRepositoryProvider = Provider<SatisfaccionRepository>((ref) {
  if (ref.watch(useMocksProvider)) return ref.watch(mockSatisfaccionProvider);
  if (ref.watch(satisfaccionUrlProvider).isEmpty) {
    return const SatisfaccionNoConfigurada();
  }
  return ApiSatisfaccionRepository(ref.watch(satisfaccionDioProvider));
});
