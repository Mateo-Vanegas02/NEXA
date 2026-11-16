# Pruebas y resultados

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
