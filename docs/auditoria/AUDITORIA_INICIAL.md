# Auditoría inicial de NEXA

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
