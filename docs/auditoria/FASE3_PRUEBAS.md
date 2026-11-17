# Fase 3: pruebas y ejecución

Línea base anterior: 565 pruebas Java y 123 JavaScript aprobadas. La primera ejecución de integración Mongo en CI falló al iniciar Testcontainers por una mezcla de versiones del módulo Mongo 2.0.5 y el núcleo 1.20.6 fijado por el BOM de Spring Boot. Se fijó `testcontainers.version=2.0.5`; el árbol de dependencias confirmó la versión coherente y la siguiente ejecución en GitHub Actions (`43993004181`) terminó con los tres jobs correctos. La prueba `Phase3MongoIntegrationTest` registró 6 pruebas, 0 fallos y 0 errores en MongoDB real de contenedor.

Las seis pruebas que ya pasaron cubren identidad ambigua, conteos, índices parciales, registro concurrente, consumo concurrente de token, token expirado/desconocido y aceptación/vencimiento de solicitudes. Después se reforzó la prueba de registro para sincronizar ambas comprobaciones previas y la de expiración para utilizar el hash del token correcto. La nueva ejecución CI (`44011544135`) pasó. Se añadió una séptima prueba que verifica que una contraseña débil no consume un token vigente; su ejecución CI está pendiente. La compilación local de pruebas también pasó; Docker local no está disponible.

El primer intento del workflow `Secret scan` falló por verificar un archivo descargado con nombre distinto al del manifiesto SHA-256, antes de ejecutar Gitleaks. Se corrigió el nombre; la nueva ejecución debe confirmar el workflow.

No se ejecutaron pruebas con datos productivos ni se pasó una URI externa a las pruebas. El job `mongo-integration` se ejecuta aparte de la suite regular. No se ha demostrado aún la concurrencia de iniciar/finalizar/cancelar/calificar ni restauración de backup. Ver resultados finales en `FASE3_RESULTADOS.md`.
