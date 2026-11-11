# CLAUDE.md

Rama `app` del repositorio NEXA: solo la app móvil (`mobile/`) y el modelo de satisfacción (`ml/`).
La web Spring Boot está en la rama `main`; aquí no hay código Java.

## App (`mobile/`)
Flutter 3 / Dart 3, Riverpod 3, go_router, Dio, freezed. Roles pasajero, conductor y admin (solo el panel
de satisfacción). Reglas y comandos en `.claude/skills/nexa-flutter/SKILL.md` y `mobile/docs/DECISIONES.md`.
El servidor decide el negocio (precio, XP, niveles, ETA): la app no lo calcula.
Por defecto consume el despliegue de AWS (`Env.urlAws` y la Lambda `Env.satisfaccionUrlAws` en
`lib/core/config/env.dart`); `--dart-define=API_BASE_URL=...` la cambia.

```bash
cd mobile
flutter pub get
flutter gen-l10n
dart format lib test
flutter analyze
flutter test
```

## ML (`ml/`)
Python 3.12/3.13 con TensorFlow para entrenar y LiteRT para la Lambda. Detalle en `ml/README.md`.

```bash
cd ml
pip install -r requirements.txt
pytest
```
- Solo datos reales: el generador de viajes falsos está en `ml/tests/` y solo lo usan las pruebas.
- En AWS: la Lambda `nexa-satisfaccion` (`lambda_fn/mediadora.py`) atiende el panel y lanza la entrenadora en ECS
  Fargate (`nexa_ml/entrenadora.py`, imagen `ml/Dockerfile.entrenamiento` → ECR por `imagen-entrenamiento.yml` de la rama `main`).
- La URI de Mongo va por variable de entorno (`NEXA_MONGO_URI`) y la base es `motvirsweb` (`--base motvirsweb`).
- Nunca una calificación como variable de entrada.

## Convenciones
Código y textos en español. Commits con Conventional Commits (`feat:`, `fix:`, `docs:`, ...).
Sin secretos en el repositorio: el keystore de firma y las URIs con credenciales quedan fuera.
