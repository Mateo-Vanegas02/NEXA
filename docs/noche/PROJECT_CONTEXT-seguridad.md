# PROJECT_CONTEXT — back-end NEXA (para la auditoría de seguridad)

Spring Boot 3.4.4 · Java 21 · MongoDB · Thymeleaf + JS vanilla · paquete raíz `com.example.MotvirsWeb`.

## Estructura
`Controladores/` (vistas `Controller*`/`AuthController*` + REST `Api*Controller`) · `Service/` · `Repositorios/` (Spring Data Mongo) ·
`Models/` · `Dto/` · `Security/` · `Config/` · `socket/` (STOMP) · `util/`.

## Autenticación
- **Web**: sesión + form login (`/auth/login` → `POST /login`), CSRF activo, BCrypt (`SecurityConfig.passwordEncoder`).
- **API móvil**: `POST /api/auth/login` (solo PASAJERO) → JWT HS256 (`JwtService`, 24 h, secreto Base64 en `JWT_SECRET`); `JwtAuthFilter` lee `Authorization: Bearer`.
- Conductores: `CustomUserDetailsService` rechaza los no APROBADOS. Admin inicial opcional por `ADMIN_EMAIL`/`ADMIN_PASSWORD`.
- Reglas por URL en `SecurityConstants` + `SecurityConfig` (orden: roles específicos → `/api/**` autenticado → resto autenticado).

## Endpoints (rol requerido)
| Método | Ruta | Rol |
|---|---|---|
| GET | `/`, `/auth/**` (login, registro, forgot/reset password), `/registro/**`, `/public/**` (home, surge) | público |
| POST | `/auth/registro/pasajero`, `/auth/registro/conductor`, `/auth/forgot-password`, `/auth/reset-password` | público (rate limit) |
| POST | `/public/chat` (Gemini), `/public/contact` | público (rate limit) |
| POST | `/api/auth/login` | público (rate limit) |
| GET/POST | `/pasajero/**` (panel, solicitar/cancelar viaje, historial, servicios/{id}, calificar) | PASAJERO |
| GET/POST | `/conductor/**` (panel, aceptar/iniciar/finalizar/cancelar, disponibles, en-curso, servicios/{id}, historial, ingresos) | CONDUCTOR |
| GET/POST | `/api/pasajero/**` (perfil, solicitar-viaje, cancelar-viaje/{id}, historial, servicios/{id}, calificar-servicio/{id}) | PASAJERO |
| GET/POST | `/api/conductor/**` (perfil, servicios-disponibles, aceptar/iniciar/finalizar/cancelar-servicio/{id}, servicios-en-curso, historial, ingresos, optimizar) | CONDUCTOR |
| GET/POST/PUT/DELETE | `/admin/**`, `/api/admin/**` (dashboard, aprobar/rechazar-conductor, notas CRUD, chat IA, `ml/entrenar`, `ml/resultado`, config/notificaciones) | ADMIN |
| GET | `/api/niveles/me`, `/api/niveles/viajes/{id}/desglose` | PASAJERO o CONDUCTOR |
| PUT/DELETE | `/api/niveles/dias-nexa`, `/api/niveles/favoritos/{id}` | PASAJERO |
| GET/POST | `/rating`, `/rating/calificar`, `/profile/**` (cambiar contraseña) | autenticado (rating: el rol del parámetro debe coincidir) |
| GET | `/api/user-id` | autenticado |
| WS | `/ws` (SockJS/STOMP); topics `/topic/pasajero/{id}`, `/topic/conductor/{id}`, `/topic/servicios-disponibles`, `/topic/admin/registros` | sesión; SUBSCRIBE autorizado por rol+id (`WebSocketAuthInterceptor`) |

## Entidades (MongoDB)
`Usuario` (abstracta, colección `Usuarios`; subclases `Pasajero`, `Conductor`, `Admin` por `@TypeAlias`; índice único `(email, rol)`), `Servicio` (embebe `PasajeroEmbedded`/`ConductorEmbedded`), `Vehiculo`, `NotaAdmin`, `ModeloInfo`, `XpEvento`, `BeneficioUso`, `CreditoNexa`.

## Configuración de seguridad (estado tras la auditoría)
CSRF: activo; `/api/**` solo se exime con cabecera `Bearer`; `/auth/**` y `/public/**` exentos (flujos sin sesión), WebSocket exento. Sin CORS configurado (mismo origen). Cabeceras: Spring por defecto + Referrer-Policy + Permissions-Policy. `RateLimitFilter` (por IP). Secretos solo por entorno (`EntornoObligatorioPostProcessor`). Sin Actuator, Swagger ni consola H2; `spring-boot-devtools` es `optional/runtime` (no va en el JAR).

## Dependencias (pom.xml)
Spring Boot 3.4.4 parent; starters: data-mongodb, security, thymeleaf (+extras-springsecurity6), web, validation, mail, websocket; Spring AI 1.1.4 (google-genai); jjwt 0.12.5; Weka 3.8.6; OR-Tools 9.8.3296; Lombok; devtools; test: starter-test, spring-security-test.
