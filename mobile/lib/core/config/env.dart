import 'package:flutter/foundation.dart' show kReleaseMode;

/// Configuración por entorno. Se inyecta con `--dart-define`; no hay secretos aquí.
abstract final class Env {
  /// Backend de producción (HTTPS, Azure). Es el que usan los builds `release`.
  static const String urlProduccion =
      'https://nexa-ece5b3dbfecvf3cq.eastus2-01.azurewebsites.net';

  /// Backend local desde el emulador de Android (solo builds debug: el tráfico
  /// HTTP sin cifrar está permitido únicamente en `android/app/src/debug`).
  static const String urlLocal = 'http://10.0.2.2:8080';

  static const String _urlDefinida = String.fromEnvironment('API_BASE_URL');

  /// URL base del backend (sin `/api`). Con `--dart-define=API_BASE_URL=...` gana
  /// esa; si no, `release` usa producción y `debug` el backend local.
  static String get apiBaseUrl => _urlDefinida.isNotEmpty
      ? _urlDefinida
      : (kReleaseMode ? urlProduccion : urlLocal);

  /// `true` = repositorios simulados (modo demo, sin backend). Por defecto la app
  /// habla con el backend real; para la demo: `--dart-define=USE_MOCKS=true`.
  static const bool useMocks = bool.fromEnvironment('USE_MOCKS');

  /// URL de la función de satisfacción (Lambda `nexa-satisfaccion`, ver
  /// `docs/CONTRATO_SATISFACCION.md`). Vacía = el panel del admin avisa que no
  /// está configurada. Se define con `--dart-define=SATISFACCION_URL=...`.
  static const String satisfaccionUrl = String.fromEnvironment(
    'SATISFACCION_URL',
  );

  /// Intervalo de polling del viaje activo.
  static const Duration pollingInterval = Duration(seconds: 5);
}
