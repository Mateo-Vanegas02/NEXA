# NEXA — app móvil y ML

Rama `app` del repositorio NEXA. La web (Spring Boot), que se despliega en AWS, vive en `main`.

| Carpeta | Qué es |
|---|---|
| `mobile/` | App Flutter: pasajero, conductor y el panel de satisfacción del admin. Ver `mobile/README.md` y `mobile/docs/`. |
| `ml/` | Modelo de satisfacción con TensorFlow: entrenamiento, exportador del dataset y Lambda con LiteRT. Ver `ml/README.md`. |

## Cómo encajan
- La app habla con la API de la web (`/api/**`, JWT). El contrato está en `mobile/docs/API_CONTRATO.md`.
- El panel de satisfacción del admin consume la Lambda (`ml/lambda_fn`), contrato en `mobile/docs/CONTRATO_SATISFACCION.md`.
- El entrenamiento lee los viajes de MongoDB Atlas (la misma base de la web) y publica el modelo en S3.

## Comandos rápidos
```bash
cd mobile && flutter pub get && flutter test          # app
cd ml && pip install -r requirements.txt && pytest    # ML (Python 3.12 o 3.13: TensorFlow no tiene versión para 3.14)
```

CI: `.github/workflows/mobile.yml` (textos generados, formato, análisis y pruebas de la app).
