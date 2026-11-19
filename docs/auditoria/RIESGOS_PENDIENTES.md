# Riesgos pendientes

## Actualización de fase 3.2 (17 de noviembre de 2026)

Detalle y evidencia en `FASE3_2.md`. Las secciones anteriores quedan como registro; esta es la lista vigente.

**Cerrados en esta fase (con prueba en CI o verificación en producción):**

- Transiciones de viaje, deuda y calificación sin `save()` de documento completo: todas condicionales y, donde
  tocan varias colecciones, en una transacción con reintento ante conflictos (409, no 500).
- Bandeja de avisos: reclamación con `lease`, tope de intentos, envío inmediato tras el commit y aislamiento del
  hilo de tareas programadas.
- Inventario de producción hecho en solo lectura (tipos, duplicados, índices); respaldo `mongodump` verificado y
  restauración completa ensayada en una copia.
- Índices de producción: I1–I9 creados (licencia, SOAT y tarjeta únicos y parciales; correo no único; viajes por
  estado, pasajero y conductor; bandeja de avisos). La unicidad de licencia/SOAT ya no depende solo del código.
- Tokens de recuperación antiguos en texto claro: borrados en producción.
- Secretos: auditoría completa del historial sin credenciales de servidor; secret scanning y push protection
  activados en GitHub por el propietario.

**Siguen abiertos:**

- Nada de la rama está desplegado; la versión que sirve producción no tiene estas correcciones.
- Correo: sin duplicados hoy, pero no se normaliza ni es único; falta decidir la política (global o por rol).
- Entrega de avisos al menos una vez: falta confirmar que la app móvil descarta `eventoId` repetidos.
- Clave de Firebase Android (restricciones) e informe público de Power BI (qué datos muestra).
- Credenciales temporales de la fase (usuarios de Atlas, contraseña expuesta en el chat de trabajo) y base de
  ensayo `motvirsweb_copia`: confirmar su eliminación o rotación.
- Heredados de fases 2 y 3: revocación de JWT, CSP, paginación de listados del admin, STOMP y límite de
  peticiones por instancia (ver abajo).

## Actualización de fase 3

## Actualización de fase 3.1 (17 de noviembre de 2026)

- Compass confirmó `motvirsweb.Usuarios` (54 documentos) y `motvirsweb.servicios` (610). El propietario confirmó producción. Ambas colecciones tienen solo `_id_`; faltan índices efectivos de unicidad y análisis agregado de duplicados.
- Se implementaron escrituras condicionales para varias transiciones en la rama de trabajo. Once pruebas MongoDB 7 en réplica pasaron en CI #46; el código no está desplegado.
- Se implementaron transacciones para cargo/deuda y una bandeja persistente de avisos; la reversión y el reintento pasaron con MongoDB real. Falta verificar deduplicación móvil y el límite de entrega al menos una vez; no se ha demostrado todavía integridad completa de todos los efectos.
- La investigación de secretos, rotación y limpieza Git sigue pendiente. Véase `FASE3_1_RESULTADOS.md`.

### Registro histórico de fase 3 (anterior a los cambios locales de 3.1)

- El último workflow de fase 3 registró siete pruebas de integración de MongoDB 7 con datos sintéticos. Los índices reales, tipos BSON y duplicados de la conexión actual siguen sin inventario completo; no hay respaldo verificado.
- La aceptación y el vencimiento usan actualizaciones condicionales probadas. Inicio, finalización, cancelaciones y calificación de viajes aún emplean lectura y `save`; faltan pruebas y transiciones atómicas para evitar sobrescritura o efectos duplicados.
- El inventario Git de NEXA encontró configuración cliente Firebase en `app`, no una contraseña de servidor confirmada. Falta revisar restricciones de la clave en el proveedor y visibilidad del informe Power BI. La exposición descrita para `NEXA_Origin` exige auditoría de ese repositorio por separado.
- Ninguna credencial fue rotada, no se reescribió Git, ni se aplicaron índices o migraciones en producción. La política de identidad por correo sigue pendiente de decisión y revisión de datos reales.

## Fase 2

- Correos compartidos entre roles: el índice `(email, rol)` los permite y el login por correo no puede seleccionar una cuenta de manera inequívoca. Las operaciones sensibles fallan cerradas; se requiere decisión y migración no destructiva (`MIGRACION_IDENTIDAD.md`).
- La traducción de `DuplicateKeyException` solo da una respuesta segura si Mongo tiene índices efectivos. No se inspeccionó producción ni se ejecutó migración; los registros simultáneos podrían duplicarse sin esos índices (`INDICES_CONDUCTOR.md`).
- El consumo del token es condicional y atómico en código, pero no se ejecutó prueba de integración contra Mongo real en esta fase. JWT emitidos antes de un reset siguen válidos hasta expiración (`DISENO_JWT.md`).
- Listados administrativos y gráficas mensuales todavía pueden cargar documentos completos; paginación/agrupación requiere cambios de contrato y medición.
- STOMP conserva autenticación del handshake durante la conexión; un cambio de estado o rol no desconecta de inmediato. El broker simple y el rate limiter siguen limitados a una instancia.
- CSP permanece sin enforcement hasta retirar inline y comprobar recursos externos en Report-Only (`ESTRATEGIA_CSP.md`).

- Tokens antiguos en el campo MongoDB histórico podrían seguir siendo sensibles hasta su expiración o invalidación operativa; no se ejecutó una migración destructiva.
- La revocación de JWT requiere contrato con clientes móviles, almacenamiento de estado y estrategia de transición.
- Cualquier cliente externo que llamara `GET /api/admin/ml/entrenar` debe pasar a POST y enviar CSRF cuando use sesión web; no se identificaron otros clientes en este repositorio.
- El despliegue `infra/servidor/docker-compose.aws.yml` define un solo contenedor `nexa` detrás de Caddy. `RateLimitFilter` y el broker STOMP simple funcionan por proceso: agregar otra réplica dividiría los contadores, conexiones y mensajes. Antes de escalar, se requiere un diseño compartido, pruebas de reconexión y despliegue coordinado; no se justifica introducir Redis o un broker externo en el despliegue actual.
- La validación de licencia/SOAT ya usa consultas selectivas, pero debe verificarse la unicidad efectiva en MongoDB con datos existentes y una prueba de registros simultáneos antes de tocar índices. No se modificaron los campos `long`/`Long` ni el esquema.
- No se puede aplicar una CSP restrictiva aún: `conductor/panel_conductor.html` contiene numerosos `onclick`, `onchange` y estilos inline, y carga Leaflet, Font Awesome y Google Fonts desde dominios externos. Hay que inventariar todas las plantillas, trasladar manejadores y estilos a archivos locales, definir orígenes precisos y probar paneles antes de activar la cabecera.
- JWT se emite con HS256 y 24 h de expiración (`JwtService`, `application.properties`). `JwtAuthFilter` vuelve a cargar el usuario en cada petición, por lo que una cuenta marcada como no aprobada deja de autenticarse; sin embargo, un cambio de contraseña o logout no invalida un JWT ya emitido. Diseñar revocación por usuario y rotación de refresh tokens exige confirmar almacenamiento de tokens y comportamiento de la app móvil. No se modificó el contrato de login.
- La suite completa pasó en este entorno con Mockito como agente JVM y loopback local permitido; conviene conservar esa configuración en los ejecutores Windows de CI.
