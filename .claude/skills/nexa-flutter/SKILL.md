---
name: nexa-flutter
description: App móvil de NEXA (Flutter 3 / Dart 3, Riverpod 3, go_router, Dio, freezed) para pasajero y conductor, en la rama feature/flutter-app, carpeta mobile/. Úsala al crear o modificar pantallas, controladores, repositorios, tema, textos, pruebas, distribución o el contrato de la app con la API del backend Java.
---

# NEXA — App móvil (Flutter)

## Dónde vive
- Solo existe en la rama **`feature/flutter-app`**, carpeta `mobile/` (rama huérfana: no comparte historia con `master`; para integrarla se copia `mobile/`, no se hace merge). La web está en `master`.
- La app cubre **pasajero y conductor**; el admin sigue en la web.
- Paquete `com.nexa.nexa_mobile`, versión en `mobile/pubspec.yaml`. Se distribuye por Firebase App Distribution (`mobile/docs/DISTRIBUCION.md`, `tool/distribuir.ps1`). El keystore de firma queda **fuera del repo**: nunca lo subas.
- Lee antes de tocar: `mobile/docs/DECISIONES.md` (cronológico: una fase posterior reemplaza a una anterior, p. ej. el precio ajustable y el estimado local ya se retiraron), `API_CONTRATO.md` y `PENDIENTES_BACKEND.md`. Si decides algo nuevo, agrégalo a `DECISIONES.md`.

## Estructura
- `lib/core/`: `config/env.dart`, `errors/`, `network/` (Dio, `TokenStorage`), `router/app_router.dart`, `theme/`, `l10n/`, `utils/`, `widgets/`, `providers.dart`.
- `lib/features/{auth,niveles,viajes,home}/` con `data/` (repositorio real + mock), `domain/` (modelos freezed y la interfaz del repositorio) y `presentation/{controllers,screens,widgets}`. En `viajes`, las pantallas se separan en `pasajero/` y `conductor/`.
- Los repositorios se eligen en `core/providers.dart` según `useMocksProvider`. Un repositorio nuevo lleva interfaz, implementación real, mock y su provider ahí.

## Reglas
1. **Estado:** Riverpod 3 (`Notifier` / `AsyncNotifier`). La lógica va en el controlador; el `Widget` solo pinta y reacciona. Nada de lógica de negocio en `build`.
2. **Navegación:** go_router con guards por rol en `redirigir` (`app_router.dart`). El rol sale del claim `roles` del JWT (el login solo devuelve `{token}`). Una ruta nueva se registra ahí con su rol.
3. **El servidor decide el negocio.** La app **no calcula** precio, XP, nivel, comisión, ETA, distancia ni fase: los pide al servidor (`POST /api/pasajero/cotizar`, `GET /api/niveles/me`, respuesta de `POST /conductor/ubicacion`). Ya se retiraron del código y los textos: tarifa local, precio ajustable, Días NEXA, créditos, tasa de servicio, escudo, upgrade, cashback y nombres de nivel (los niveles son números, desde 1 y sin techo). El único monto extra del pasajero es el *extra voluntario* (+$500/+$1.000/+$2.000), con el tope que pone el servidor. Modelo vigente: `docs/niveles/` en `master` (v2.3).
4. **Privacidad por rol.** El conductor ve «Cobra al pasajero», su ganancia y el saldo con NEXA; no muestres comisión, tarifa bruta ni deuda del pasajero. Pinta solo los campos que el servidor entrega.
5. **Red:** un solo cliente Dio (`crearDio`): `Authorization: Bearer`, mapeo de errores a `AppException` y, ante un 401 en ruta autenticada, cierra la sesión (el backend no tiene refresh de token). Las peticiones públicas (login) usan `extra: {kSinToken: true}`. Las consultas a Nominatim usan un Dio propio y **nunca** llevan el token de NEXA. Las imágenes protegidas se piden como bytes con el token en la cabecera; no uses `Image.network` con el token en la URL.
6. **Tiempo real = polling.** Cada `Env.pollingInterval` (5 s), solo con viaje activo o con el conductor en línea; cancela el temporizador al salir. El WebSocket del backend autentica por sesión web, no por JWT, así que no uses STOMP todavía. El conductor reporta posición con `POST /conductor/ubicacion` cada 5 s (`disponible: true/false`). Al abrir la app se retoma con `viaje-activo` (conductor) o `viaje-en-camino` (pasajero). Los errores 409 (otro conductor tomó la solicitud) y 403 (fuera de su ola) se muestran y la solicitud sale de la lista.
7. **Configuración y secretos.** Todo entra por `--dart-define` en `Env` (`API_BASE_URL`, `USE_MOCKS`). `release` usa producción (HTTPS); `debug` usa `http://10.0.2.2:8080` y el HTTP sin cifrar solo se permite en `android/app/src/debug`. El token vive en `flutter_secure_storage`. Sin claves ni credenciales en el código.
8. **Diseño:** usa solo los tokens de `core/theme/tokens.dart` (`NexaColors`, `Sp` en múltiplos de 4, `Rad`, `Sizes`: área táctil 48, botón 56), alineados con `nexa-design.css` de la web. Tema oscuro de marca por defecto (#020A12, tarjeta #03192E, cian #00C4FF; fuente Montserrat incluida). Nada de colores o espaciados sueltos. Respeta «reducir animaciones».
9. **Textos:** en `lib/core/l10n/app_es.arb`, generados con `flutter gen-l10n`; la salida de `lib/core/l10n/gen` se versiona.
10. **Código generado:** los `*.g.dart` y `*.freezed.dart` **se versionan** para que compile sin `build_runner`. Tras cambiar un modelo, regénéralos y commitéalos.

## Calidad y comandos
Lints: `flutter_lints` + `strict-casts`, `strict-inference`, `strict-raw-types`, `prefer_single_quotes`, `require_trailing_commas`, `unawaited_futures`, `avoid_print`, `prefer_const_*`.
```bash
cd mobile
flutter pub get
dart format lib test            # no sobre "." (falla con rutas largas en build/)
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter run --dart-define=USE_MOCKS=true      # demo sin backend
```
Pruebas en `test/unit/` con `mocktail`; sustituye `useMocksProvider` y `selectorImagenProvider` (cámara/galería) con overrides, y usa `test/helpers.dart`. Cubre el caso feliz, un error mapeado a `AppException` y el 401. Las pruebas no deben depender de `Env`.

## Pendientes conocidos (ver `PENDIENTES_BACKEND.md`)
Sin refresh de token, sin WebSocket con JWT, sin push (FCM), «rechazar solicitud» solo local, etiquetas de calificación concatenadas al comentario, ruta dibujada en línea recta, y llamar/mensaje, compartir viaje y SOS sin backend (SOS llama al 123). Parte de ese documento quedó desactualizado: la posición en vivo del conductor y el registro por JSON ya existen en `master`.

## Checklist antes de terminar
- [ ] `dart format`, `flutter analyze` y `flutter test` limpios.
- [ ] La pantalla no calcula negocio; usa lo que entrega el servidor.
- [ ] Solo tokens de diseño y textos del `.arb`.
- [ ] Controlador con su prueba; repositorio con interfaz, real y mock.
- [ ] Modelos regenerados y versionados; ningún secreto ni keystore en el repo.
- [ ] `DECISIONES.md` actualizado si cambió una decisión.
