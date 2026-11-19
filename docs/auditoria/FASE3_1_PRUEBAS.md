# Fase 3.1 — evidencia de pruebas

GitHub Actions CI #46, commit `927b8f5`:

- `mongo-integration`: 11 pruebas, 0 fallos, 0 errores, con MongoDB 7 en réplica y datos sintéticos. Incluye la reversión conjunta de estado/deuda/aviso y el reintento de aviso tras un fallo de socket.
- `test`: `mvn clean install` aprobado.
- `docker`: imagen construida y arranque HTTP aprobado.
- `Secret scan` #12: aprobado.

En este equipo, `-Dtest=*,!ModeloNexaWiringTest` con agente Mockito y exclusión del grupo Mongo ejecutó 565 pruebas, 0 fallos y 0 errores. El entorno local no tiene Docker, por lo que la integración se ejecutó en CI. `ModeloNexaWiringTest` había fallado localmente al crear `RutaOsrm`; el job `test` de CI pasó.

La primera ejecución de CI de fase 3.1 falló porque el contenedor Mongo no era un conjunto de réplica y una prueba asumía que inicio y cancelación no podían ocurrir en secuencia. Se corrigieron ambos puntos antes de CI #46.

GitHub Actions CI #48, commit `c591682`: `mongo-integration` volvió a aprobar con 11 pruebas, 0 fallos y 0 errores; `test` y `docker` aprobaron. `Secret scan` #14 aprobó. Esta ejecución incluye el reintento del aviso de deuda tras fallo SMTP y la prueba unitaria del adaptador SMTP. No se encontró una suite JavaScript en este repositorio (`package.json` y archivos de prueba ausentes).
