# NEXA Mobile

App móvil (Flutter) de NEXA para los roles **pasajero** y **conductor**. El admin sigue en la web.

## 1. Resumen
- Flutter 3 / Dart 3 con Clean Architecture por feature: `auth`, `niveles`, `viajes`.
- Estado con Riverpod, navegación con go_router (guards por rol), red con Dio (token, errores mapeados, logging solo en debug).
- Pasajero: mapa OpenStreetMap, solicitud de viaje con estimado y desglose, seguimiento, calificación, historial y niveles (descuento y prioridad de recogida).
- Conductor: en línea/fuera de línea, solicitudes (aceptar/rechazar), viaje activo (en camino → recogido → completado), ganancias, comisión y requisitos de calidad; estado bloqueado si el admin aún no lo aprobó.
- Nivel/XP visible en los dashboards, toast "+N XP" y animación de subida de nivel (una sola vez). Textos en español vía ARB.

## 2. Cómo correrlo
Requisitos: Flutter estable (probado con 3.47) y un emulador/dispositivo Android o iOS.

Por defecto la app habla con el **backend real**: en debug con el backend local (`http://10.0.2.2:8080` en el emulador de Android) y en `release` con producción (HTTPS). No hace falta ningún `--dart-define` salvo para cambiar eso.

```bash
cd mobile
flutter pub get
# Contra el backend local (debug):
flutter run
# Contra otra URL (p. ej. un staging):
flutter run --dart-define=API_BASE_URL=https://<tu-dominio>
# Modo demostración, sin backend ni internet (datos simulados):
flutter run --dart-define=USE_MOCKS=true
```

Para probar contra el backend local hay que levantarlo antes (`./mvnw spring-boot:run` en la raíz del repositorio, con `MONGODB_URI` y `JWT_SECRET`). Los endpoints de login de conductores, registro por JSON y seguimiento del pasajero están en la rama `feat/api-movil-auth` del backend (ver `docs/PENDIENTES_BACKEND.md`).

Usuarios del modo demostración (cualquier contraseña de 6+ caracteres): un correo que contenga `conductor` entra como conductor aprobado, `pendiente` como conductor pendiente de aprobación y cualquier otro como pasajero. En demostración, el viaje solicitado avanza solo (aceptado a los 5 s, en curso a los 10 s, finalizado a los 18 s).

Calidad:
```bash
flutter analyze
dart format --set-exit-if-changed lib test
flutter test
flutter build apk --debug
# Vista previa en navegador (sin emulador): flutter create --platforms web . (una vez) y
flutter run -d chrome --dart-define=USE_MOCKS=true
# Tras cambiar modelos freezed o ARB:
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```
Ninguna credencial va en el código: solo `API_BASE_URL` y `USE_MOCKS` por `--dart-define`. La URL de producción es pública y está en `lib/core/config/env.dart`.

## 3. Arquitectura
```
lib/
  main.dart, app.dart      arranque, MaterialApp.router, tope de textScaler 1.3
  core/
    config/                Env (--dart-define)
    network/               Dio + interceptores, almacenamiento seguro del token
    errors/                AppException (mapeo de errores del backend)
    router/                go_router y guards por rol (función `redirigir`)
    theme/                 tokens (colores, espaciado 4/8/12/16/24/32, radios) y temas
    l10n/                  app_es.arb + código generado en gen/
    utils/, widgets/       formato COP/fechas, responsive, NexaButton/TextField/Card, skeleton, vacío, error, mapa
    providers.dart         inyección: mock vs API real
  features/<feature>/{domain,data,presentation}
    auth/     login, registro, splash, onboarding, perfil, sesión
    niveles/  LevelProgressBar, pantalla de niveles, celebraciones
    viajes/   pasajero (inicio, solicitar, seguimiento, historial) y conductor (panel, ganancias)
```
`domain` define modelos (freezed) e interfaces de repositorio; `data` tiene la implementación Dio y el mock (`mock_backend.dart`); `presentation` tiene notifiers y pantallas.

## 4. Pantallas por rol
Diseño basado en las pantallas de Figma (`Descripcion_Pantallas_NEXA1.docx`). El rediseño oscuro con cian neón (mockups en `docs/mockups-nexa-dark.html`) y su estado por fases están en `docs/PLAN_REDISENO.md`.
- **Público:** splash, onboarding (3, solo la primera vez), **Home** (hero + servicios), login, registro.
- **Pasajero:** dashboard (saludo, buscador "¿A dónde vas hoy?", nivel/XP, accesos rápidos, viajes recientes), **Pedir viaje** (mapa + hoja con precio ajustable y método de pago), **Viaje en curso** (pasos, conductor, llamar/mensaje/compartir, SOS), **Calificación** (estrellas, etiquetas, comentario), historial, niveles/Días NEXA, perfil.
- **Conductor:** panel (en línea, solicitudes, viaje activo, estado bloqueado si no está aprobado), ganancias, niveles/comisión, perfil.
- El dashboard de admin (Machine Learning) de la maqueta sigue en la web.

## 5. Changelog
- `feat(mobile): estructura Flutter, contrato de API, tema, repositorios, auth y pantallas base` — proyecto, `docs/API_CONTRATO.md`, tema, red, modelos, repos API/mock, auth, niveles, pasajero y conductor.
- `test(mobile): pruebas unitarias y de widgets` — errores, repositorios, notifiers, guards, mock, widgets en 360×640 / 390×844 / 800×1280 con textScaler 1.3.
- `docs(mobile): README y sección App móvil` — entrega.
- `feat(mobile): rediseño según Figma ... y reorganización por capas` — home, dashboard, pedir viaje, viaje en curso, calificación; `presentation/{controllers,screens,widgets}`.
- `fix(mobile): formato COP, logo en auth y limpieza de assets`.

## 6. Decisiones tomadas
Ver [docs/DECISIONES.md](docs/DECISIONES.md). Contrato del backend: [docs/API_CONTRATO.md](docs/API_CONTRATO.md).

## 7. Pendientes y bloqueos reales
Detalle en [docs/PENDIENTES_BACKEND.md](docs/PENDIENTES_BACKEND.md). Los principales:
- El login JWT (`/api/auth/login`) solo admite pasajeros: los conductores solo funcionan en modo mock hasta que el backend lo abra.
- No hay registro por JSON (solo formularios web con CSRF), ni refresh de token, ni WebSocket con JWT (se usa polling de 5 s).
- Tarifa estimada local; el total real viene de `/api/niveles/viajes/{id}/desglose`.
- Sin verificar en dispositivo físico ni iOS (no hay Xcode en este entorno): la compilación iOS no se probó.

## 8. Siguientes pasos recomendados
1. Abrir `/api/auth/login` a conductores y exponer registro JSON.
2. Endpoint de cotización de tarifa y de viaje activo del pasajero.
3. STOMP con JWT para reemplazar el polling.
4. Geocodificación de direcciones (destino por texto) y ruta dibujada en el mapa.
5. Notificaciones push para nuevas solicitudes y cambios de estado del viaje.

## Distribución
Firma release y Firebase App Distribution: ver [docs/DISTRIBUCION.md](docs/DISTRIBUCION.md) (`.	ool\distribuir.ps1`).

## Build del APK
`flutter build apk --debug` compila correctamente (salida: `build/app/outputs/flutter-apk/app-debug.apk`). Requiere Android SDK (`ANDROID_HOME`; se instaló en `C:\Android\sdk`) y JDK 17-21. La primera compilación descarga componentes (platform 35, CMake) y tarda ~15 min.
Nota: en el entorno automatizado de desarrollo Gradle fallaba con `Unable to establish loopback connection` (Java NIO sin loopback en esa sesión); en la terminal normal del usuario funciona.
