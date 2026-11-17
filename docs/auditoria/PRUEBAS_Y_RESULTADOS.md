# Pruebas y resultados

## Fase 2 (base `cdc989f`)

- Antes de modificar: 551 pruebas Java, 0 fallos, 0 errores, con Mockito como agente JVM. Los tests `requiere-mongo` se excluyen por defecto.
- Después de modificar: 565 pruebas Java, 0 fallos, 0 errores, con el mismo comando (`./mvnw.cmd -q -DargLine=-javaagent:<mockito-core.jar> test`). El reporte XML de Surefire confirma el total.
- `node --test src/test/js/*.test.mjs`: 123 pruebas, 0 fallos.
- `./mvnw.cmd -q -DskipTests package`: compilación y empaquetado correctos.
- Se cubrieron hash/consumo de token, expiración, inexistencia, contraseña débil, error de Mongo simulado y dos intentos simultáneos simulados; correo único/compartido, conflicto de índice, conteos y suscripción STOMP ajena.
- No hay Docker ni MongoDB de pruebas instalado en esta máquina; no se ejecutaron pruebas de integración con una base real. La simulación de `MongoTemplate` verifica la lógica de respuesta, pero no sustituye la comprobación de atomicidad en MongoDB. Tampoco se verificaron índices o datos de producción.

## Ejecutadas

- `./mvnw.cmd -Dtest=PasswordResetServiceTest -DforkCount=0 test` — SUCCESS, 3 tests, 0 fallos, 0 errores.
- `./mvnw.cmd -Dtest=SeguridadHttpTest#entrenamientoMlSoloPostAdminConCsrf -DargLine=-javaagent:<ruta-al-jar-de-mockito-core> test` — SUCCESS, 1 prueba, 0 fallos. Verifica cuatro escenarios de método, rol y CSRF.
- `./mvnw.cmd '-Dtest=AuthServiceTest,SeguridadHttpTest#entrenamientoMlSoloPostAdminConCsrf' -DargLine=-javaagent:<ruta-al-jar-de-mockito-core> test` — SUCCESS, 8 pruebas, 0 fallos.
- Suite completa con Mockito preinstalado como agente — 551 pruebas, 0 fallos, 0 errores, 0 omitidas, ejecutada con permiso de red del entorno local.

## Diagnóstico del fallo de `ModeloNexaWiringTest`

El primer intento con red restringida falló en `RutaOsrm.clienteHttp` al construir `HttpClient`: `UncheckedIOException: Unable to establish loopback connection`, causada por `SocketException: Permission denied: connect` en `PipeImpl`/`WEPollSelectorImpl` de Java en Windows. No hubo petición al servicio OSRM. Tras habilitar permiso de red para el proceso de prueba, el test aislado y la suite completa pasaron sin cambiar código de producción. El fallo estaba causado por la restricción de loopback del entorno de ejecución.

Un intento previo de `./mvnw.cmd test` sin agente Mockito quedó detenido durante la carga dinámica del agente; se interrumpió. Para reproducir el resultado correcto en este Windows, usar `-DargLine=-javaagent:<ruta-al-jar-de-mockito-core>` y permitir loopback local.

## Advertencias observadas

- API deprecated `permissionsPolicy` de Spring Security.
- `@MockBean` deprecated en varias pruebas.
- Mockito intenta auto-adjuntar Byte Buddy en el entorno local; la prueba nueva se diseñó sin Mockito para aislar la validación.

No se ejecutaron pruebas de integración Mongo ni despliegues.
