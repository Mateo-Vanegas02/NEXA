# NEXA ML — minería de datos con TensorFlow

Rama `ml-tensorflow` del repositorio NEXA_Origin. Contiene **solo Python**: no comparte historia con
`master` (rama huérfana). Reemplazará al árbol J48 de Weka que hoy vive en el backend Java
(`SatisfaccionClienteService`).

## Qué predice

La **satisfacción** ("si" / "no") en los dos lados de cada viaje, con un solo modelo de dos salidas:

| Objetivo | Sale de | "si" |
|---|---|---|
| `satisfaccion_pasajero` | `calificacionConductor` (la nota que el pasajero le pone al conductor) | 4 o 5 estrellas |
| `satisfaccion_conductor` | `calificacionPasajero` (la nota que el conductor le pone al pasajero) | 4 o 5 estrellas |

- Cada lado se aprende por separado: si en un viaje solo calificó uno, ese viaje sirve para ese lado
  y el otro se ignora (pérdida con máscara). Se descartan solo los viajes sin ninguna nota.
- Las dos salidas comparten las capas del viaje (esperas, precio, recorrido) y cada una tiene su rama
  final; el lado con menos notas, normalmente el del conductor, aprovecha lo que aprende el otro.
- El modelo da la probabilidad de "no" (la clase rara e importante); el umbral de cada lado se elige
  en validación.

Entradas (25, `nexa_ml/caracteristicas.py`, versión 3): recorrido (distancia, duración real frente a
la estimada, si terminó antes del destino), esperas de cada lado (hasta la aceptación, la llegada del
conductor, el conductor esperando en el punto, distancia de recogida, ola), dinero del pasajero
(tarifa, total, $/km, descuento, recargo, extra, deuda cobrada), dinero del conductor (ganancia,
ganancia por minuto), niveles, hora y día. Se retiraron `pago_efectivo` (hoy todo es efectivo) y
`comision_pct` (sale del nivel del conductor).

Solo se usan viajes del viaje real en vivo: con solicitud, aceptación, llegada, inicio y fin en orden
y desglose final. Los anteriores, sin llegada ni esperas, se descartan en vez de rellenarse con ceros,
igual que los que tienen la espera hasta la aceptación mayor de 4 h (fechas guardadas con zonas
horarias distintas antes de la corrección del reloj en el backend). `metadatos.json` cuenta los
descartes por motivo. **Ninguna calificación entra como variable**: ni
la del mismo lado ni la del otro, porque al predecir todavía no existen.

## Diferencias con el J48 actual

| | J48 (hoy) | Esta rama |
|---|---|---|
| Objetivo | Un solo "si/no" con el **promedio** de las dos notas: mezcla a quien califica | Dos objetivos, uno por lado; cada nota mide a quien la puso |
| Viaje con una sola nota | Usa esa nota para todo | Solo cuenta para el lado que calificó |
| Variables | duración, distancia, tarifa (casi redundantes: la tarifa sale de la distancia) | 25 variables del viaje, incluidas las del conductor |
| Evaluación | Ninguna: se entrena con todo y no se mide el error | División por tiempo (70/15/15), PR-AUC, ROC-AUC, recall, matriz de confusión por lado |
| Línea base | No | Regresión logística y "siempre satisfecho"; se reporta si la red les gana |
| Desbalance | No se trata | Pesos por clase en cada lado y umbral elegido en validación |
| Mínimo de datos | 30 viajes | 300 notas y 30 "no" por lado |
| Uso en producción | `predecirSatisfaccion` no se llama en ningún lado; el "simulador" del panel admin es una regla escrita en JS | Lambda con contrato JSON y pruebas |

## Estructura

```
nexa_ml/
  caracteristicas.py  viaje → vector (sin TensorFlow; lo comparten entrenamiento y Lambda)
  datos.py            lectura desde MongoDB o desde un JSON de mongoexport
  modelo.py           red Keras, regresión logística base, conversión a TFLite
  entrenar.py         entrena, evalúa, exporta (python -m nexa_ml.entrenar)
  inferencia.py       predicción con LiteRT (ai-edge-litert), sin TensorFlow
  exportar.py         dataset en CSV / ARFF tal como lo ve el modelo (Excel, WEKA, entregable)
  metricas.py         ROC-AUC, PR-AUC, umbral (NumPy)
  sinteticos.py       viajes FALSOS para pruebas (dinero con las reglas reales de modelo-nexa.properties)
lambda_fn/
  handler.py          función AWS Lambda
  construir.sh        arma lambda.zip (Python 3.13, x86_64)
tests/                19 pruebas (pytest)
```

## Uso

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pytest

# Entrenar con la base real (la URI por variable de entorno, nunca en el código)
export NEXA_MONGO_URI="mongodb+srv://..."
python -m nexa_ml.entrenar --mongo-uri "$NEXA_MONGO_URI" --base nexa --salida artefactos/

# O con una exportación
mongoexport --uri "$NEXA_MONGO_URI" -c servicios -q '{"estado":"FINALIZADO"}' -o viajes.json
python -m nexa_ml.entrenar --json viajes.json --salida artefactos/
```

Salida en `artefactos/`: `modelo.keras`, `modelo.tflite` (con la normalización incluida: recibe las
variables crudas) y `metadatos.json` (versión, umbral, métricas, rango de fechas, si supera las bases).
Si no hay datos suficientes, el comando termina con código 2 y no exporta nada.

Exportar el dataset (una fila por viaje, 25 variables y las dos clases SI/NO/?):
`python -m nexa_ml.exportar --mongo-uri "$NEXA_MONGO_URI" --csv dataset.csv --arff dataset.arff`

Con datos sintéticos (solo para ver que todo corre):
`python -m nexa_ml.entrenar --sinteticos 3000 --salida artefactos/ --permitir-pocos-datos`

## Lambda mediadora `nexa-satisfaccion` (panel del admin en la app)

`lambda_fn/mediadora.py` implementa el contrato v0.2 (`mobile/docs/CONTRATO_SATISFACCION.md`): `GET /resumen`,
`/factores`, `/riesgo`, `/modelo`, `POST /entrenamientos`, `GET`/`DELETE /entrenamientos/{id}` y `PUT /programacion`.
Valida el JWT de la web (HS256, `JWT_SECRET` de Parameter Store, rol ADMIN), lee Atlas con el usuario de solo lectura,
el modelo publicado de S3 (`modelos/actual.json` → `modelos/vN/`) y la programación e historial de DynamoDB. No entrena:
invoca de forma asíncrona la Lambda `nexa-entrenamiento`. Reglas puras en `nexa_ml/satisfaccion.py`; acceso a la nube en
`nexa_ml/nube.py`; pruebas sin nube en `tests/test_mediadora.py`.

```bash
./lambda_fn/construir_mediadora.sh     # deja mediadora.zip (≈ 38 MB) para subir a s3://nexa-ml-<cuenta>/codigo/
```
Infraestructura: `infra/cloudformation/30-ml-prediccion.yml` en la rama `main`.

**Desfase de 5 h:** los viajes guardados en Azure antes del arreglo de zona horaria tienen `solicitadoEn` 5 h antes;
`caracteristicas.solicitado_corregido` lo corrige (espera hasta la aceptación entre 300 y 330 min) en vez de descartarlos.

## Lambda de predicción directa (opcional)

```bash
./lambda_fn/construir.sh artefactos/   # lambda.zip ≈ 36 MB comprimido, ≈ 109 MB descomprimido
```

- Runtime **python3.13, x86_64**, manejador `handler.lambda_handler`, 512 MB de memoria, 10 s de tiempo límite.
- No lleva TensorFlow (≈ 1,3 GB, no cabe en el límite de 250 MB): usa LiteRT (`ai-edge-litert`).
- Entrada: `{"viajes": [{...campos del Servicio...}]}` (máximo 100) o `{"viaje": {...}}`.
- Salida: `{"version", "predicciones": [{"id", "satisfaccionPasajero": {"satisfaccion": "si"|"no",
  "probabilidadNo"}, "satisfaccionConductor": {...}}]}`.
- Si se define `NEXA_ML_TOKEN`, la URL de función exige la cabecera `x-nexa-token`.

**Quién la llama:** el backend Java (que ya tiene el viaje y la sesión del usuario) y la app Flutter
habla con el backend. La app no debe guardar credenciales de AWS ni el token.

## Antes de borrar el J48

1. Entrenar con los viajes reales y revisar `metadatos.json`: si `supera_bases` es `false`, la red no
   aporta frente a una regresión logística y no conviene reemplazar nada todavía.
2. Comparar en el mismo conjunto de prueba con el J48.
3. Cambiar el panel admin para mostrar métricas reales (hoy muestra el árbol en texto y un simulador inventado).
4. Retirar `weka-stable`, `SatisfaccionClienteService`, `ModeloController` y `modelo_satisfaccion_j48_v2.0.model` de `master`.
