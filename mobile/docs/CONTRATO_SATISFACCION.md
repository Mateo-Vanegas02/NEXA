# Contrato: API de satisfacción (Lambda ↔ app Flutter del admin) — v0.3

Punto de unión entre el frente AWS (Lambda `nexa-satisfaccion`) y la app. Cualquier cambio sube la versión y se avisa al otro frente. El mock de la app (`MockSatisfaccionRepository`) devuelve exactamente estos JSON.

Cambios de la v0.3 (11 nov. 2026): solo datos reales. `modo` pasa a ser `"real"` o `"sin_modelo"` (ya no
`"demo"`) y `POST /entrenamientos` ya no acepta `?demo=true` (si llega, se ignora). Sin los mínimos de datos responde
422 y la app deshabilita «Entrenar ahora». El entrenamiento corre en ECS Fargate.

Cambios de la v0.2 (9 nov. 2026):
- El historial puede traer `estado: "DATOS_INSUFICIENTES"` (intento manual sin datos).
- La app pide `/riesgo?lado=todos&limite=50` y filtra por lado en el teléfono.

## Generalidades
- Base: Function URL de la Lambda (us-east-2). La app la trae por defecto (`Env.satisfaccionUrlAws`) y `--dart-define=SATISFACCION_URL=https://...` la cambia (`Env.satisfaccionUrl`). Con una URL vacía el panel muestra "no configurado".
- Autenticación: `Authorization: Bearer <JWT de NEXA>`. La Lambda valida firma (HS256, mismo `JWT_SECRET` del backend, leído de Parameter Store), expiración y que el rol sea `ADMIN`. 401 sin token o vencido (la app cierra la sesión); 403 si no es admin.
- JSON en camelCase, fechas ISO 8601 con zona (`2026-11-08T02:14:00-05:00`), porcentajes de 0 a 100 con un decimal, probabilidades de 0 a 1.
- `modo`: `"real"` (hay un modelo entrenado con viajes reales) o `"sin_modelo"` (todavía no; no hay factores ni riesgo). La satisfacción observada (`satisfechosPct`, `tasaRespuestaPct`) siempre es real; `modo` solo afecta a predicciones y factores.
- Errores: `{ "error": "codigo", "mensaje": "texto para mostrar" }`.

## GET /resumen?desde=AAAA-MM-DD&hasta=AAAA-MM-DD
```json
{
  "desde": "2026-10-09", "hasta": "2026-11-08", "modo": "real",
  "pasajero":  { "satisfechosPct": 86.0, "variacionPts": 3.0, "tasaRespuestaPct": 62.0, "calificaciones": 112 },
  "conductor": { "satisfechosPct": 79.0, "variacionPts": -2.0, "tasaRespuestaPct": 41.0, "calificaciones": 34 },
  "tendencia": [ { "semana": "2026-W38", "pasajeroPct": 82.0, "conductorPct": 80.0 } ],
  "riesgoTotal": 7,
  "factorPrincipal": { "lado": "pasajero", "etiqueta": "Espera hasta que un conductor acepta" }
}
```
`variacionPts` compara con el período anterior de igual duración (`null` si no hay base). `satisfechosPct` es `null` si no hubo calificaciones. `tendencia` trae hasta 12 semanas; una semana sin calificaciones va con `null`.

## GET /factores?lado=pasajero|conductor
```json
{
  "lado": "pasajero", "modo": "real", "version": 3,
  "importancia": [ { "variable": "espera_aceptacion_min", "etiqueta": "Espera hasta que un conductor acepta", "pesoPct": 22.0 } ],
  "otrosFactores": { "cantidad": 20, "pesoMaximoPct": 5.0 },
  "curvas": [
    { "variable": "espera_aceptacion_min", "etiqueta": "Espera a aceptar",
      "tramos": [ { "etiqueta": "0–1 min", "satisfechosPct": 93.0, "viajes": 210 } ],
      "hallazgo": "Si la espera pasa de 3 minutos, la satisfacción cae 16 puntos. 41 de 478 viajes están en ese tramo." }
  ]
}
```
`importancia`: por permutación sobre el conjunto de prueba, normalizada a 100, de mayor a menor; la app muestra las 5 primeras. `curvas`: satisfacción observada por tramos, máximo 3 variables (las de mayor peso). `etiqueta` de la curva es corta (va en un chip).

## GET /riesgo?lado=todos&limite=50
```json
{
  "umbral": 0.45, "modo": "real", "total": 7,
  "viajes": [
    { "id": "A7F3", "fecha": "2026-11-08T08:12:00-05:00", "origen": "Bocagrande", "destino": "Manga", "distanciaKm": 4.2,
      "lado": "pasajero", "probabilidadNo": 0.71,
      "motivos": [ { "variable": "espera_aceptacion_min", "texto": "Esperó 7 min a que aceptaran", "severidad": "alta" } ] }
  ]
}
```
Solo viajes de los últimos 30 días sin la calificación de ese lado y con `probabilidadNo ≥ umbral`. `id`: 4 últimos caracteres del id del servicio (sin nombres ni teléfonos). `origen`/`destino`: barrio. `severidad`: `alta` | `media`. Los `motivos` salen de las variables del viaje que más se alejan del promedio.

## GET /modelo
```json
{
  "version": 3, "entrenadoEn": "2026-11-08T02:14:00-05:00", "viajes": 478, "variables": 25, "modo": "real",
  "metricas": {
    "pasajero":  { "redPrAuc": 0.40, "regresionPrAuc": 0.43, "supera": false },
    "conductor": { "redPrAuc": 0.32, "regresionPrAuc": 0.41, "supera": false }
  },
  "datos": { "pasajero": { "calificaciones": 112, "no": 9 }, "conductor": { "calificaciones": 34, "no": 3 },
             "minimos": { "calificaciones": 300, "no": 30 }, "suficientes": false },
  "programacion": { "activa": true, "frecuencia": "semanal", "dias": ["DOM"], "hora": "02:00", "cadaHoras": null,
                    "soloConDatosNuevos": true, "minimoViajesNuevos": 20, "publicarSoloSiMejora": true,
                    "proxima": "2026-11-15T02:00:00-05:00" },
  "entrenamientoActivo": null,
  "historial": [ { "id": "e-20261108-0214", "fecha": "2026-11-08T02:14:00-05:00", "origen": "programado", "version": 3,
                   "estado": "PUBLICADO", "modo": "real", "mensaje": null } ]
}
```
`version` es `null` si nunca se publicó un modelo (la app muestra el avance de los datos). `historial`: últimos 10. `entrenamientoActivo`: `null` o el objeto de `GET /entrenamientos/{id}`.

## POST /entrenamientos
Sin cuerpo. 202 `{ "id": "e-20261108-2310" }`. 409 `entrenamiento_en_curso`. 422 `datos_insuficientes`. Siempre con viajes reales; la app no lo llama si `datos.suficientes` es `false`.

## GET /entrenamientos/{id}
```json
{ "id": "e-20261108-2310", "estado": "ENTRENANDO", "progresoPct": 62, "epoca": 31, "epocas": 50,
  "pasos": { "exportar": "hecho", "entrenar": "en_curso", "comparar": "pendiente", "publicar": "pendiente" },
  "detalleExportar": "512 viajes completos · 34 descartados", "mensaje": null, "terminaEstimado": "2026-11-08T23:16:00-05:00" }
```
`estado`: `EN_COLA` | `EXPORTANDO` | `ENTRENANDO` | `COMPARANDO` | `PUBLICANDO` | `PUBLICADO` | `GUARDADO_SIN_PUBLICAR` | `SIN_DATOS_NUEVOS` | `FALLIDO` | `CANCELADO` | `DATOS_INSUFICIENTES`. Pasos: `hecho` | `en_curso` | `pendiente`. La app consulta cada 5 s mientras la pantalla está abierta y el estado no es final.

## DELETE /entrenamientos/{id}
204. 409 si ya terminó.

## PUT /programacion
Cuerpo igual a `programacion` sin `proxima`. `frecuencia`: `diaria` | `semanal` | `cada_horas`; `cadaHoras` entre 1 y 168 solo con `cada_horas` (la app ofrece 1, 3, 6, 12, 24 y 48); `dias` (LUN, MAR, MIE, JUE, VIE, SAB, DOM) solo con `semanal`; `hora` `HH:mm` en America/Bogota. Responde 200 con la programación guardada y `proxima`. 400 `programacion_invalida`.

## Pantallas (Figma `mKq1Yb7s7nBW9TmAf2O2wn`) y código
| Pantalla | Endpoints | Código |
|---|---|---|
| Resumen (`5:199`) | `/resumen` | `resumen_screen.dart` |
| Factores (`5:308`) | `/factores` | `factores_screen.dart` |
| Viajes en riesgo (`6:40`) | `/riesgo` | `riesgo_screen.dart` |
| Modelo y entrenamiento (`6:122`) | `/modelo`, `POST /entrenamientos` | `modelo_screen.dart` |
| Programar entrenamiento (`7:77`) | `PUT /programacion` | `programar_sheet.dart` |
| Entrenando (`7:193`) | `GET` y `DELETE /entrenamientos/{id}` | `entrenando_screen.dart` |
| Datos insuficientes (`7:248`) | `/modelo` con `version = null` y `datos.suficientes = false` | `modelo_screen.dart` |
