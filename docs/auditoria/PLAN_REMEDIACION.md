# Plan de remediación

## Estado tras fase 3.2 (17 de noviembre de 2026)

De la "Continuación de fase 3.1" quedan hechos los puntos 1 (gate de integración con Mongo, ahora 24 pruebas),
3 (agregados de producción, respaldo y restauración en copia, índices aplicados) y la auditoría de secretos de
este repositorio del punto 4. Siguiente secuencia, en orden:

1. Revisar y fusionar el PR de la rama; desplegar con un usuario de MongoDB propio y la base ya indexada.
2. Decidir la política de correo, normalizar los 5 correos con mayúsculas o espacios y crear el índice único.
3. Confirmar en la app móvil la deduplicación por `eventoId`.
4. Restringir la clave de Firebase y revisar el informe público de Power BI.
5. Abordar los heredados: JWT (`DISENO_JWT.md`), CSP (`ESTRATEGIA_CSP.md`), paginación del admin.
6. Consolidar `docs/auditoria/` según la propuesta de `FASE3_2.md`.

## Continuación de fase 3.1

1. Las 11 pruebas de `Phase3MongoIntegrationTest` pasaron en CI con MongoDB 7 en réplica. Mantener ese job como requisito antes de integrar nuevas transiciones.
2. Añadir prueba específica de llegada concurrente y verificar deduplicación por `eventoId` en móvil. Revisar la posibilidad de correo repetido si el proceso cae entre envío y acuse.
3. La conexión de Atlas fue confirmada como producción. Obtener agregados redactados de duplicados y tipos. Respaldar y restaurar en un entorno aislado antes de ensayar índices o migraciones.
4. Auditar secretos de NEXA y NEXA_Origin por separado. Preparar rotación coordinada y simulación de saneamiento solo para exposiciones confirmadas.
5. Revisar JWT y contrato móvil, actualizar la matriz de compatibilidad y ejecutar Java, JavaScript, integración, Docker y escaneo de secretos. No desplegar mientras los puntos anteriores no estén verificados.

## Secuencia tras fase 3

1. Revisar PR #3 sobre PR #2 y conservar la prueba de integración Mongo y el escaneo de secretos como gates de CI. Fusionar en orden únicamente tras revisión.
2. Identificar con acceso autorizado la base y su entorno; inventariar datos agregados e índices sin exponer información personal. Crear respaldo recuperable y ensayar restauración en copia antes de cualquier migración.
3. Decidir política de identidad, resolver colisiones con propietarios y ensayar índice global y parciales de licencia/SOAT en copia. Programar despliegue de datos con reversión y observación.
4. Hacer condicionales las transiciones restantes de viaje y probar finalización/cancelación/calificación concurrentes con Mongo real, verificando cobros y eventos posteriores a la escritura ganadora.
5. Revisar restricciones de Firebase y publicación Power BI. Auditar `NEXA_Origin` por separado. Rotar solo credenciales confirmadas y, si se justifica, simular filtrado Git en clon aislado y presentar impacto concreto antes de alterar referencias remotas.

## Próximos pasos de fase 2

1. Definir política de correo compartido con el dueño; inventariar duplicados en copia restaurable; ejecutar `MIGRACION_IDENTIDAD.md` antes de crear un índice global.
2. Revisar índices reales, tipos y duplicados de licencia/SOAT en copia; crear índices parciales seguros y ejecutar prueba de registros simultáneos según `INDICES_CONDUCTOR.md`.
3. Correr pruebas de integración de consumo de token y registro concurrente con Mongo aislado. Las unitarias simulan el resultado de la actualización, pero no prueban el servidor de base de datos.
4. Paginar listados administrativos e historiales grandes con contrato de cliente acordado; medir planes de consulta e índices antes de añadirlos.
5. Coordinar revocación JWT con la app móvil (`DISENO_JWT.md`), revalidación de conexiones STOMP y CSP Report-Only (`ESTRATEGIA_CSP.md`) antes de activar controles nuevos.

## Etapa 1 — seguridad inmediata

1. Mantener el almacenamiento hash de tokens de recuperación y documentar la invalidación controlada de tokens antiguos.
2. Cambiar el entrenamiento ML a POST, actualizar el frontend y añadir prueba de método HTTP/rol/CSRF.
3. Añadir pruebas de serialización y expiración del flujo de recuperación.

## Etapa 2 — autorización e integridad

1. Revisar endpoints de viajes con pruebas negativas por propietario, rol y estado.
2. Auditar todos los destinos STOMP y añadir pruebas de suscripción privada, administrativa y ajena.
3. Modelar revocación/rotación JWT solo después de confirmar el contrato de la aplicación móvil.

## Etapa 3 — rendimiento y escalabilidad

1. Reemplazar búsquedas globales de conductores por consultas selectivas e índices revisados.
2. Medir consultas de historial y paginación con MongoDB de pruebas.
3. Documentar el límite del broker simple y del rate limiting local; evaluar infraestructura compartida solo si existe despliegue multiinstancia confirmado.

## Etapa 4 — calidad y onboarding

1. Inventariar scripts inline y recursos antes de aplicar CSP.
2. Actualizar README, API, configuración, arquitectura y ciclo de vida de viajes a partir de los contratos reales.
3. Clasificar artefactos heredados y añadir controles CI de dependencias, secretos y Docker.
