# Plan de remediación

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
