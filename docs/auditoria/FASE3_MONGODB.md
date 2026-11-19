# Fase 3: MongoDB

La prueba `Phase3MongoIntegrationTest` inicia `mongo:7` con Testcontainers en GitHub Actions. Cada método crea una base `nexa_phase3_<UUID>` con documentos sintéticos y borra únicamente esa base. La URI sale del contenedor iniciado por la prueba; no acepta una URI de entorno o de producción. El contenedor es el límite de seguridad de las pruebas.

Se verificaron nombres persistidos de la colección `Usuarios`, del token hash y de su expiración; índices parciales únicos de licencia y SOAT; consultas de conteo; y actualizaciones condicionales. En producción no se conoce versión de servidor, nombres/índices reales, tipos BSON, cardinalidad, duplicados, valores ausentes ni permisos. La conexión guardada en Compass no se inspeccionó por rechazo del control de escritorio.

## Observación de Compass reportada por el propietario

En una conexión de Atlas, el propietario examinó `motvirsweb.creditos_nexa` en modo solo lectura: informó cero documentos, índices `_id_` y `usuarioId + venceEn` ascendentes, sin validador configurado y sin escrituras. Es una observación de esa colección, no un inventario de toda la base ni una verificación directa por este agente. `creditos_nexa` figura en la documentación de beneficios; los modelos de identidad y viajes de esta auditoría mapean a `Usuarios` y `servicios`. Faltan nombres y recuentos de esas colecciones, índices de `Usuarios` y clasificación del entorno antes de cualquier conclusión sobre datos reales.

## Procedimiento antes de una migración real

1. Identificar cluster, entorno y base mediante acceso autorizado de solo lectura. Registrar únicamente metadatos y agregados sin datos personales.
2. Inventariar colecciones, `getIndexes()`, tipos BSON, documentos nulos/ausentes y duplicados por correo normalizado, licencia y SOAT. Comprobar el filtro parcial exacto contra datos reales.
3. Preparar respaldo consistente fuera de Git, con permisos restringidos y cifrado; comprobar espacio, restaurar una muestra en una base aislada y verificar recuentos. Sin respaldo recuperable, no modificar la base original.
4. Ensayar limpieza de colisiones e índices en copia restaurada. Comparar recuentos, planes de consulta y flujos web/móvil. Programar aplicación y reversión con el propietario.

No se creó un respaldo de producción porque no se identificó una conexión segura ni hay Database Tools disponibles. Tampoco se probó una restauración.
