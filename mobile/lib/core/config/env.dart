/// Configuración por entorno. Se inyecta con `--dart-define`; no hay secretos aquí.
///
/// Este repositorio (`NEXA`, rama `app`) es la versión que consume el despliegue de AWS:
/// por defecto, tanto `debug` como `release` hablan con la web de AWS y con la Lambda del
/// panel de satisfacción. La versión que consume Azure sigue en `NEXA_Origin`.
abstract final class Env {
  /// Web de NEXA en AWS (EC2 + Caddy, HTTPS). Mientras no haya dominio propio se usa
  /// `<ip-con-guiones>.sslip.io`; al comprar el dominio solo cambia este valor.
  static const String urlAws = 'https://18-227-59-40.sslip.io';

  /// Backend local desde el emulador de Android (solo builds debug: el tráfico
  /// HTTP sin cifrar está permitido únicamente en `android/app/src/debug`).
  /// Se usa con `--dart-define=API_BASE_URL=http://10.0.2.2:8080`.
  static const String urlLocal = 'http://10.0.2.2:8080';

  static const String _urlDefinida = String.fromEnvironment('API_BASE_URL');

  /// URL base del backend (sin `/api`). Con `--dart-define=API_BASE_URL=...` gana
  /// esa; si no, la web de AWS (en debug y en release).
  static String get apiBaseUrl =>
      _urlDefinida.isNotEmpty ? _urlDefinida : urlAws;

  /// `true` = repositorios simulados (modo demo, sin backend). Por defecto la app
  /// habla con el backend real; para la demo: `--dart-define=USE_MOCKS=true`.
  static const bool useMocks = bool.fromEnvironment('USE_MOCKS');

  /// Lambda `nexa-satisfaccion` en AWS (URL de función, us-east-2). No es secreta:
  /// cada ruta exige el JWT de un admin. Ver `docs/CONTRATO_SATISFACCION.md`.
  static const String satisfaccionUrlAws =
      'https://5g4llbvy3qoesbdt7wrhfguet40tdabm.lambda-url.us-east-2.on.aws';

  static const String _satisfaccionDefinida = String.fromEnvironment(
    'SATISFACCION_URL',
  );

  /// URL del panel de satisfacción: `--dart-define=SATISFACCION_URL=...` si se
  /// define, si no la Lambda de AWS.
  static String get satisfaccionUrl => _satisfaccionDefinida.isNotEmpty
      ? _satisfaccionDefinida
      : satisfaccionUrlAws;

  /// Estilos del mapa (OpenFreeMap: vectorial, gratis, sin clave ni registro).
  /// Con `--dart-define=MAPA_ESTILO_OSCURO=...` se cambia sin tocar el código
  /// (p. ej. por mapas propios en AWS).
  static const String estiloMapaOscuro = String.fromEnvironment(
    'MAPA_ESTILO_OSCURO',
    defaultValue: 'https://tiles.openfreemap.org/styles/dark',
  );
  static const String estiloMapaClaro = String.fromEnvironment(
    'MAPA_ESTILO_CLARO',
    defaultValue: 'https://tiles.openfreemap.org/styles/liberty',
  );

  /// Intervalo de polling del viaje activo.
  static const Duration pollingInterval = Duration(seconds: 5);

  /// Con un viaje en marcha, la posición de la moto se envía y se consulta más
  /// seguido (rediseño 2026): el mapa la mueve fluida entre un dato y otro.
  static const Duration pollingPosicion = Duration(seconds: 2);
}
