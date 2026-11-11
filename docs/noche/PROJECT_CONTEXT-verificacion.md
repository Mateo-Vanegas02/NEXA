# PROJECT_CONTEXT — verificación de conductores (rama claude/gov-verification-d6c3d1)

País: Colombia (teléfono ^3\d{9}, SOAT, tecnomecánica, licencia, RUNT). Fuente natural: RUNT.

## Archivos involucrados (flujo actual de aprobación)
- Registro: `Controladores/AuthController.java` (`POST /auth/registro/conductor`) → `Service/AuthService.registrarConductor` (crea `Conductor` PENDIENTE) + guarda `Vehiculo` (placa en mayúsculas).
- DTO registro: `Dto/ConductorRegistroRequest.java` (placa `^[A-Za-z]{3}[A-Za-z0-9]{3}$`, licencia 6-15 dígitos).
- Aprobación web (form POST + CSRF): `Controladores/AuthControllerDashboard.java` → `POST /admin/aprobar-conductor|rechazar-conductor` (param `email`), redirige a `/admin/dashboard`.
- Aprobación API: `Controladores/ApiAdminController.java` → `GET /api/admin/conductores?estado=`, `POST /api/admin/aprobar-conductor|rechazar-conductor`.
- Lógica: `Service/AdminService(+Impl)` (`aprobarConductor/rechazarConductor`: solo si PENDIENTE; cambia `estadoValidacion`, sin auditoría).
- Login: `AuthService` (~l.141) bloquea conductores no APROBADOS.
- Vista: `templates/panel_admin.html` (tabla + modal `#infoModal`), `static/js/Dashboard_A.js` (`openDriverModal`, forms creados por JS).
- Seguridad: `Security/SecurityConstants.ADMIN_URLS` (`/admin/**`, `/api/admin/**` → ROLE_ADMIN) en `SecurityConfig`; CSRF ignorado en `/api/**`. `@EnableMethodSecurity` activo.

## Entidades
- `Conductor extends Usuario` (colección `Usuarios`, alias CONDUCTOR): nombre_y_Apellido, ntelefono, licencia(int), soat(Long), tarjeta_de_propiedad(Long), vehiculos(List<ObjectId>), estadoValidacion (APROBADO|RECHAZADO|PENDIENTE), niveles.
- `Vehiculo` (colección `Vehiculos`): placa (única), marca, modelo, color, tecnomecanicaId, `@DBRef conductorAsignado`, activo, fechaRegistro. Repo: `findByPlaca`, `findByConductorAsignado`.
- No existe cédula del conductor ni del propietario: solo licencia, SOAT y tarjeta de propiedad.

## Añadido por esta rama
Paquete `Verificacion/` (proveedores, servicio, auditoría), colección nueva `auditoria_verificacion`, endpoints `/api/admin/verificacion/**`. Ver `docs/VERIFICACION.md`.
