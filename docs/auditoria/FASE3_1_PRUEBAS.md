# Fase 3.1 — pruebas

La suite Java completa llegó a 566 pruebas con agente Mockito explícito: hubo 1 fallo de `ModeloNexaWiringTest` al crear `RutaOsrm` y 6 errores iniciales de mocks en `ServicioAccesoTest`. Se corrigieron esos mocks y las clases focales `ServicioAccesoTest` (16 pruebas) y `ServicioServiceImplTest` (17 pruebas) pasaron después. El fallo de `RutaOsrm` permanece sin resolver.

Después se ejecutaron todas las clases de pruebas Java salvo `ModeloNexaWiringTest` y el grupo `requiere-mongo`: **565 pruebas, 0 fallos, 0 errores**, en 70 suites. `ModeloNexaWiringTest` sigue pendiente de resolver; `Phase3MongoIntegrationTest` sigue pendiente de Docker.

- `mvnw.cmd -q -DskipTests test-compile`: pasó después de la transacción, bandeja y prueba de reversión/reintento.
- `ServicioServiceImplTest` con agente Mockito explícito: 17 pruebas, 0 fallos, 0 errores.
- `Phase3MongoIntegrationTest` con `-Dexcluded.groups=none`: no arrancó; Testcontainers informó `Could not find a valid Docker environment`. No hay resultado de las nuevas carreras en MongoDB real.
- La suite Java completa iniciada sin agente Mockito explícito quedó sin resultado y se interrumpió; no se cuenta como aprobada.
- JavaScript: no se encontraron `package.json` ni archivos de prueba JavaScript en este repositorio; no hay una suite identificada para ejecutar.
- Escaneo histórico de secretos y Docker/CI para esta rama modificada: no ejecutados en esta tanda. `gitleaks`, `docker`, `mongosh` y `mongodump` no están disponibles en PATH local.

Las siete pruebas MongoDB registradas en el workflow de la fase 3 corresponden al código anterior; no validan los métodos añadidos en la fase 3.1.

Nueva ejecución local tras los cambios de avisos/deuda: `-Dtest=*,!ModeloNexaWiringTest` con agente Mockito, **565 pruebas, 0 fallos, 0 errores**; el grupo `requiere-mongo` siguió excluido. El job `mongo-integration` de `.github/workflows/ci.yml` debe ejecutar la prueba nueva al publicar la rama.
