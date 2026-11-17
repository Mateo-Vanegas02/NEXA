# Auditoría inicial de NEXA

## Fase 2 — evaluación desde `cdc989f` (2026-11-16)

| ID | Severidad | Estado | Ubicación y evidencia | Solución y pruebas | Compatibilidad |
|---|---|---|---|---|---|
| P1-01 | P1 | Parcial | `Usuario` permite `(email,rol)` y `findByEmail` asume un solo usuario; `PasswordResetService` repetía la consulta | Se retiró la segunda consulta; login convierte múltiples resultados en fallo genérico. `CustomUserDetailsServiceTest` y `PasswordResetServiceTest`. Migración en `MIGRACION_IDENTIDAD.md` | Cuentas con correo compartido siguen sin poder autenticarse o recuperar de forma inequívoca; no se cambiaron índices |
| P1-02 | P1 | Parcial | `AuthService.registrarConductor`: `exists` seguido de `save`; índices declarados no verificados en Mongo | Se traduce `DuplicateKeyException` a conflicto; prueba de servicio. Plan en `INDICES_CONDUCTOR.md` | La unicidad concurrente depende de índices reales; no se tocaron datos |
| P1-03 | P1 | Corregido en código | `PasswordResetService.resetPassword`: lectura y guardado separados | `MongoTemplate.updateFirst` exige ID, hash y expiración; actualiza clave y elimina token en una operación. Pruebas de éxito, expiración, política y dos intentos | La respuesta web conserva el mismo contrato; falta integración real con Mongo aislado |
| P2-01 | P2 | Parcial | `UsuarioRepository.countConductoresByEstados` cargaba conductores completos | Usa `countByRolAndEstadoValidacionIn`; pruebas de varios, uno y ningún estado | Resultado numérico igual; otros listados grandes requieren paginación |
| P2-02 | P2 | Diseño | `JwtService` emite JWT de 24 h sin revocación | `DISENO_JWT.md` documenta versión por usuario y transición móvil | No se cambió el token ni el login móvil |
| P2-03 | P2 | Parcial | `WebSocketAuthInterceptor` autoriza por destino e ID; broker simple local | Prueba del interceptor para topic ajeno y `SEND`; límite de escala en `ARQUITECTURA.md` | Sin cambios de protocolo; desconexión tras cambio de rol pendiente |
| P2-04 | P2 | Diseño | Plantillas con inline y recursos externos | Inventario y plan Report-Only en `ESTRATEGIA_CSP.md` | No se activó una CSP que pudiera romper paneles |

La auditoría original que sigue abajo es histórica. El estado vigente se complementa con `CAMBIOS_REALIZADOS.md`, `RIESGOS_PENDIENTES.md` y `PRUEBAS_Y_RESULTADOS.md`.

Fecha: 2026-11-16

Commit base: `893d1c8`

Rama local: `codex/auditoria-seguridad`

## Alcance y línea base

Se inspeccionaron `README.md`, `CLAUDE.md`, `pom.xml`, configuraciones Spring, `docs/SEGURIDAD.md`, Docker, Compose, workflows, controladores HTTP/STOMP, repositorios MongoDB y pruebas. El proyecto es un monolito Spring Boot 3.4.4/Java 21 con MongoDB, Thymeleaf, API JWT, sesiones web y WebSocket/STOMP.

Se compilaron 188 clases principales y 76 clases de prueba. La suite completa pasó (551 pruebas) al ejecutar Mockito como agente JVM y permitir loopback local en el entorno de pruebas. Los intentos iniciales restringidos se documentan en `PRUEBAS_Y_RESULTADOS.md`.

## Hallazgos

| ID | Severidad | Problema | Evidencia | Estado |
|---|---|---|---|---|
| S-01 | P1 | Tokens de recuperación se almacenaban en texto claro | `PasswordResetService` escribía el token en `Usuario.resetPasswordToken`; `UsuarioRepository.findByResetPasswordToken` lo consultaba directamente | CORREGIDO |
| S-02 | P1 | Reentrenamiento ML producía efectos secundarios mediante GET | `ModeloController.entrenarModelo()` y `Dashboard_A.js`; ahora usan POST con CSRF | CORREGIDO |
| S-03 | P2 | Rate limiting es local a cada instancia | `RateLimitFilter` usa `ConcurrentHashMap` en memoria y lo documenta como “por instancia” | CONFIRMADO / DOCUMENTADO |
| S-04 | P2 | Registro de conductor cargaba todos los conductores para validar licencia/SOAT | `AuthService.registrarConductor` usaba `findByRol(Rol.CONDUCTOR).stream()`; ahora usa consultas `exists` | CORREGIDO |
| S-05 | P2 | JWT tiene expiración de 24 horas y no hay revocación visible | `application.properties` fija `jwt.expiration=86400000`; no se observó lista de revocación ni refresh token | CONFIRMADO / REQUIERE DISEÑO MÓVIL |
| S-06 | P2 | Broker STOMP simple no escala entre réplicas | `WebSocketConfig.configureMessageBroker` usa `enableSimpleBroker("/topic")` | CONFIRMADO / PENDIENTE |
| S-07 | P2 | CSP no está configurada explícitamente | `SecurityConfig.cabeceras` configura Referrer-Policy y Permissions-Policy, pero no Content-Security-Policy | CONFIRMADO / REQUIERE INVENTARIO FRONTEND |
| S-08 | P3 | Identidad técnica heredada | `pom.xml` y `spring.application.name` conservan `com.example:MotvirsWeb`/`MotvirsWeb`; el README contiene referencias históricas | CONFIRMADO / DOCUMENTACIÓN |
| S-09 | P3 | Artefactos heredados voluminosos requieren clasificación | `debug_test_output.txt`, `test_output.txt`, `nuget.exe`, `pbix_extracted/` y `powerbi_scripts/` están versionados | CONFIRMADO / NO ELIMINAR SIN USO |

## Protecciones confirmadas

- Secretos principales se leen desde entorno y hay validación de `JWT_SECRET` en `EntornoObligatorioPostProcessor`.
- El administrador inicial no usa credenciales fijas: `AdminConfig` exige `ADMIN_EMAIL` y `ADMIN_PASSWORD`.
- Docker crea y usa el usuario no privilegiado `nexa`.
- La aceptación de servicios usa actualización condicional según `CLAUDE.md` y `ServicioRepository`.
- La autorización STOMP compara rol e ID para canales privados y rechaza `SEND`.
- La API Bearer usa sesión `STATELESS`; la superficie web mantiene CSRF para sesiones.

## Limitaciones

No se accedió a MongoDB, SMTP, Gemini, Firebase, AWS/Azure ni producción. No se imprimieron secretos ni valores históricos. La verificación de índices reales, datos antiguos y compatibilidad móvil requiere una instancia de pruebas aislada y contratos de clientes.
