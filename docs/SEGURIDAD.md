# Informe de seguridad del back-end (auditoría nocturna)

Rama `claude/backend-security-8edf62`. Ningún valor de secreto aparece en este documento: solo archivo, nombre y commit.

> **Estado actual de la rama `Nexa_New_Arquitecture`:** `application.properties` ya **no** trae valores por defecto
> para los secretos; se leen de variables de entorno o del archivo `.env` local (ignorado por git). El validador de
> arranque está activo. **Sigue pendiente (a cargo del dueño):** rotar las credenciales, porque siguen en el historial de
> git, y definir las variables en Azure antes de fusionar a `master`.

## ⚠️ Antes de fusionar a `master` (producción en Azure)

Producción dependía de los valores por defecto que estaban escritos en `application.properties`. **Esa rama ya no los trae**: si se fusiona sin definir las variables, la app **no arranca** (falla con un mensaje que lista lo que falta).

Variables a definir en Azure App Service → *Configuration → Application settings* **antes** del merge:

| Variable | Obligatoria | Notas |
|---|---|---|
| `MONGODB_URI` | sí | cadena de conexión de Atlas (la actual, o la nueva tras rotar) |
| `JWT_SECRET` | sí | Base64, ≥ 32 bytes decodificados. Genera: `openssl rand -base64 48`. **Cambiarlo invalida las sesiones JWT activas** |
| `GEMINI_API_KEY` | sí | API key de Gemini |
| `SPRING_MAIL_USERNAME` | sí | cuenta SMTP (antes estaba fija en el properties) |
| `SPRING_MAIL_PASSWORD` | sí | contraseña de aplicación de Gmail |
| `APP_BASE_URL` | sí en `prod` | `https://<dominio>` sin barra final (enlaces de recuperación y orígenes WebSocket) |
| `SPRING_PROFILES_ACTIVE` | sí | `prod` (cookie `Secure`, `forward-headers`, logging reducido). Sin él se usa el perfil base, igualmente con logging seguro |
| `ADMIN_EMAIL`, `ADMIN_PASSWORD` | opcional | solo si hay que crear el primer admin (≥ 12 caracteres). Retirar después |

Checklist de despliegue seguro:
1. **Rotar** todas las credenciales listadas en NIGHT_LOG.md (están en el historial de git) y cargar las nuevas en Azure.
2. Cambiar la contraseña del admin existente (`admin@gmail.com` / contraseña fija conocida en el repo): ver hallazgo S-01.
3. Definir las variables de la tabla y `SPRING_PROFILES_ACTIVE=prod`; confirmar HTTPS-only en Azure.
4. CI (`master_nexa.yml`): `mvn clean install` ya no necesita secretos; los `@SpringBootTest` llevan `@Tag("requiere-mongo")` y se omiten por defecto (antes usaban Atlas con las credenciales por defecto). Para correrlos: `mvn test -Dexcluded.groups=none` con `MONGODB_URI` real/local.
5. Tras el despliegue, comprobar `/auth/login`, el login JWT móvil (`/api/auth/login`) y el chat.
6. Si hay varias instancias, el limitador de peticiones es por instancia (ver S-14).

## Hallazgos

### Crítica
- **S-01 Admin por defecto con contraseña fija.** `AdminConfig` creaba `admin@gmail.com` con una contraseña escrita en `Models/Admin.java` y publicada en el repo. **Corregido en código** (el admin solo se crea con `ADMIN_EMAIL`/`ADMIN_PASSWORD`; constantes eliminadas). **Pendiente (humano):** si la base de producción ya tiene esa cuenta, cambiar su contraseña o eliminarla.
- **S-02 Secretos reales en `application.properties` (y en historial).** URI de MongoDB Atlas con usuario/contraseña, contraseña de correo, secreto JWT y API key de Gemini como valores por defecto; además un `.env` se versionó en el commit `0169f86` (quitado en `9f63d27`) con las mismas claves y las de Turnstile. **Corregido en HEAD** (solo `${VAR}`); **historial intacto por regla** → rotar todo (ver NIGHT_LOG.md).
- **S-03 Hash de contraseña expuesto por la API.** `GET /api/pasajero/perfil`, `/api/conductor/perfil` y `/api/admin/conductores` serializaban la entidad completa (hash BCrypt y tokens de reset). **Corregido** con `@JsonIgnore` en `Usuario`.

### Alta
- **S-04 IDOR en viajes.** Cualquier conductor podía iniciar un viaje ajeno; cualquier usuario autenticado podía calificar cualquier viaje (y forzar su estado a FINALIZADO); cualquier conductor leía `/conductor/servicios/{id}` de otros (datos del pasajero). **Corregido** (`iniciarServicio`, `obtenerServicioDeConductor`, `calificarServicio(..., usuarioId)`, `/rating`), con tests.
- **S-05 `/api/auth/login` inalcanzable.** Estaba bajo `/api/**` autenticado: el login móvil devolvía 401. **Corregido** (ruta pública).
- **S-06 CSRF desactivado para todo `/api/**` con sesión.** El panel admin usa cookie de sesión contra `/api/admin/**` (notas, chat) → CSRF explotable. **Corregido:** se exime solo con cabecera `Bearer` (JWT); el front ya enviaba el token CSRF.
- **S-07 WebSocket sin autorización por topic y origen `*`.** Cualquier usuario autenticado podía suscribirse a `/topic/pasajero/{otro}` o a los registros de admin. **Corregido** (`WebSocketAuthInterceptor`, orígenes = `APP_BASE_URL` + localhost fuera de prod).
- **S-08 Sin límite de intentos.** Login, recuperación, registro, contacto y chats de IA (cuota de Gemini) sin tope. **Corregido** (`RateLimitFilter`, 429 + `Retry-After`).

### Media
- **S-09 Enumeración de cuentas** en "olvidé mi contraseña" (mensaje distinto si no existe). **Corregido.** Además el token ahora viaja como atributo de redirect, no concatenado.
- **S-10 Recuperación de contraseña de conductores rota** (campos duplicados `conductor_reset_password_token` hacían que el token nunca coincidiera). **Corregido** quitando los campos duplicados.
- **S-11 Política de contraseñas** solo existía para conductores. **Corregido** en registro de pasajero, reset y cambio de contraseña (`PoliticaPassword`).
- **S-12 Validación de entrada:** registro de pasajero, `ContactForm` (inyección de saltos de línea en el asunto del correo), `LoginRequest`, tamaño de mensaje del chat (coste de tokens). **Corregido.**
- **S-13 Fugas de información:** `e.getMessage()` de excepciones internas devuelto al cliente (registro, chat admin, entrenamiento del modelo), `printStackTrace`, correo del destinatario en logs. **Corregido.**
- **S-14 Logging DEBUG/TRACE de Spring Security/Web y `debug=true` activos por defecto** (podían volcar cabeceras y tokens). **Corregido:** base segura, DEBUG solo con perfil `dev`.
- **S-15 Regex libre en búsqueda de notas** (`$regex` con texto del usuario/LLM). **Corregido** con `Pattern.quote`.

### Baja / informativo
- **S-16** Cabeceras: añadidas `Referrer-Policy` y `Permissions-Policy`; Spring ya envía `X-Content-Type-Options`, `X-Frame-Options`, `Cache-Control`. Cookie de sesión `HttpOnly`, `SameSite=Lax`, y `Secure` en prod.
- **S-17** Errores: `server.error.include-*=never`.
- Sin Actuator, Swagger, consola de BD ni subida de archivos en el proyecto. BCrypt para contraseñas; consultas por Spring Data (parametrizadas), sin concatenación SQL/Mongo.

## Pendiente / requiere decisión
| Tema | Por qué no se tocó |
|---|---|
| Rotar credenciales y limpiar historial | Regla: no reescribir historial; rotar es acción del dueño |
| JWT sin revocación, 24 h | Cambio de diseño (lista de revocación / refresh tokens) |
| Tokens de reset en claro en BD | Guardar el hash exige migración; expiran a los 30 min |
| `GET /api/admin/ml/entrenar` cambia estado por GET (CSRF si la sesión admin está abierta) | El front actual lo llama con GET; pasar a POST toca el front de otra sesión |
| `findByEmail` con el mismo correo en dos roles (índice único es `(email, rol)`) | Login/reset pueden resolver al usuario equivocado; requiere decidir unicidad de email global |
| Contenido del broadcast `/topic/servicios-disponibles` (incluye email del pasajero) | Reducir a un DTO exige coordinar con el front |
| `solicitarViaje`/`calificar` aceptan `Map<String,Object>` | Migrar a DTO con `@Valid` toca el contrato del front |
| CSP | Requiere inventariar scripts/estilos inline y CDNs del front (en rediseño) |
| Rate limit distribuido | Por instancia; con >1 réplica usar Redis/bucket4j |
| `AuthService.registrarConductor` carga todos los conductores en memoria; licencia `int` vs regex de 15 dígitos | Cambio de esquema / rendimiento |
| Dependencias | Sin red para `versions:display-dependency-updates`/OWASP. Recomendado subir Spring Boot 3.4.4 → último 3.4.x (parches de Tomcat/Spring Security), jjwt 0.12.5 → 0.12.6+, y correr `mvn org.owasp:dependency-check-maven:check` en CI |
| Contenedor | `Dockerfile` ejecuta como root; añadir usuario no-root |
