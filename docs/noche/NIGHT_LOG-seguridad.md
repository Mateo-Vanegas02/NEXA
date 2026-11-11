# NIGHT_LOG — sesión backend-security

## 🔴 CRÍTICO — credenciales en el historial de git (ROTAR)
No se reescribió historial. Nunca copiar los valores. Aunque ya salgan de HEAD, **el dueño debe rotarlas**:
- `src/main/resources/application.properties` (commits `70d7698`, `28dcadc`, `0953d5f`, `3ef31a9`, y otros intermedios): `MONGODB_URI` (usuario+contraseña de Atlas), `SPRING_MAIL_PASSWORD`, `JWT_SECRET`, `GEMINI_API_KEY`.
- `.env` versionado en `0169f86` (eliminado en `9f63d27`): `MONGODB_URI`, `SPRING_MAIL_PASSWORD`, `JWT_SECRET`, `GEMINI_API_KEY`, `TURNSTILE_SITE_KEY`, `TURNSTILE_SECRET_KEY`.
- `Models/Admin.java` (historial): contraseña fija del admin por defecto (`admin@gmail.com`). Si existe en la BD, cambiarla.
- Rotar además: usuario/contraseña de Atlas (y restringir IP), contraseña de aplicación de Gmail, API key de Gemini, secreto JWT (invalida tokens), claves Turnstile.

## Hecho
- Paso 0: `PROJECT_CONTEXT.md`.
- Secretos fuera de `application*.properties` (solo `${VAR}`), `.env.example`, `.gitignore`, README, validador de arranque (`EntornoObligatorioPostProcessor`), perfil `dev` con logging detallado, surefire con valores ficticios.
- Admin inicial por env (sin credenciales fijas). `@JsonIgnore` en hash/tokens.
- IDOR (iniciar, leer, calificar, rating), `/api/auth/login` público, CSRF con sesión, rate limit, WebSocket autorizado, política de contraseñas, sin enumeración de cuentas, validación de DTO, mensajes de error sin internos.
- Tests: `SeguridadHttpTest` (401/403/CSRF/429/cabeceras/JSON), `ServicioAccesoTest` (IDOR), `WebSocketAuthInterceptorTest`, `EntornoObligatorioPostProcessorTest`, `RateLimitFilterTest`, `PoliticaPasswordTest`. Suite `mvn test`: 117 verdes.
- `docs/SEGURIDAD.md` con hallazgos, variables de Azure y checklist.

## Pendiente
Ver tabla "Pendiente / requiere decisión" de `docs/SEGURIDAD.md` (rotación, revocación JWT, hash de tokens de reset, GET→POST en entrenar, unicidad de email, DTOs, CSP, rate limit distribuido, dependencias, Docker no-root).

## Decisiones pendientes de revisión
1. **`@SpringBootTest` etiquetados `requiere-mongo` y excluidos por defecto** (surefire `excludedGroups`): antes usaban Atlas vía credenciales por defecto, algo que ya no existe. Reversible: `-Dexcluded.groups=none`.
2. `SPRING_MAIL_USERNAME` pasó a variable obligatoria (antes fijo en el properties; es el correo público de contacto, no un secreto).
3. `Admin(PasswordEncoder)` → `Admin(String email, String passwordHash)` y se eliminaron `DEFAULT_EMAIL`/`DEFAULT_PASSWORD`. Otra sesión (verificación de conductores) podría tocar `Admin.java`: posible conflicto trivial al fusionar.
4. Se eliminaron los campos duplicados `conductor_reset_password_token*` de `Conductor`; tokens de reset pendientes de conductores quedan inválidos (expiraban a los 30 min).
5. `SecurityConfig`: CSRF ya no se exime para todo `/api/**`; si el front React llama a `/api/**` con cookie de sesión debe enviar `X-CSRF-TOKEN` (o usar JWT Bearer).
6. WebSocket: orígenes = `APP_BASE_URL` (+ localhost fuera de `prod`). Si el front se sirve desde otro origen, añadirlo.
7. `server.forward-headers-strategy=framework` en prod (IP real para el limitador detrás de Azure/proxy).
8. Dependencias nuevas: ninguna.

## Bugs encontrados
- Login JWT móvil inalcanzable (401) — corregido. Reset de contraseña de conductores nunca funcionaba — corregido.
- `calificarServicio` marcaba cualquier viaje como FINALIZADO — corregido.
- Sin corregir: licencia `int` vs 15 dígitos en el registro (NumberFormatException → mensaje genérico ahora); `PasswordResetService` busca dos veces lo mismo (código muerto); `PasswordResetController.initiatePasswordReset` es un método vacío huérfano; `registrarConductor` carga todos los conductores.

## Comandos para probar
```powershell
$env:JAVA_HOME='C:\Users\FRANK SALCEDO\AppData\Local\Temp\nexa-tools\jdk\jdk-21.0.12.1+1'
& 'C:\Users\FRANK SALCEDO\.m2\wrapper\dists\apache-maven-3.9.12\59fe215c0ad6947fea90184bf7add084544567b927287592651fda3782e0e798\bin\mvn.cmd' -o test
```
Local con app: copiar `.env.example` a `.env`, completar, exportar variables y `SPRING_PROFILES_ACTIVE=dev`.
