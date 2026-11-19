# Fase 3: pruebas y ejecución

Línea base anterior: 565 pruebas Java y 123 JavaScript aprobadas. La primera ejecución de integración Mongo en CI falló al iniciar Testcontainers por una mezcla de versiones del módulo Mongo 2.0.5 y el núcleo 1.20.6 fijado por el BOM de Spring Boot. Se fijó `testcontainers.version=2.0.5`; el árbol de dependencias confirmó la versión coherente y la siguiente ejecución en GitHub Actions (`43993004181`) terminó con los tres jobs correctos. La prueba `Phase3MongoIntegrationTest` registró 6 pruebas, 0 fallos y 0 errores en MongoDB real de contenedor.

Las pruebas cubren identidad ambigua, conteos, índices parciales, registro concurrente, consumo concurrente de token, token expirado/desconocido, contraseña débil con token vigente y aceptación/vencimiento de solicitudes. Después se reforzó la prueba de registro para sincronizar ambas comprobaciones previas y la de expiración para utilizar el hash del token correcto. La ejecución CI `44011991127` pasó con 7 pruebas Mongo, 0 fallos y 0 errores; también pasaron la suite regular y el arranque Docker. La compilación local de pruebas pasó; Docker local no está disponible.

El primer intento del workflow `Secret scan` falló por verificar un archivo descargado con nombre distinto al del manifiesto SHA-256, antes de ejecutar Gitleaks. Se corrigió el nombre y las ejecuciones `44011991088` y `44011998046` pasaron.

No se ejecutaron pruebas con datos productivos ni se pasó una URI externa a las pruebas. El job `mongo-integration` se ejecuta aparte de la suite regular. No se ha demostrado aún la concurrencia de iniciar/finalizar/cancelar/calificar ni restauración de backup. Ver resultados finales en `FASE3_RESULTADOS.md`.
