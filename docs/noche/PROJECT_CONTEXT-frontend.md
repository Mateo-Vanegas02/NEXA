# PROJECT_CONTEXT — Front-end NEXA

## Estructura (relevante al front)
```
src/main/resources/
  templates/   home_conductor, index, inicio (login), registros, surge, rating,
               panel_admin, auth/{forgot,reset}-password, private/change-password,
               pasajero/panel_pasajero, conductor/panel_conductor   (Thymeleaf)
  static/js/   Dashboard_P_v2 (pasajero), Dashboard_C (conductor), Dashboard_A (admin),
               niveles, chatbot, nexa-login, script_registro, nexa-surge, rating, home*, mapAnimations
  static/css/  un CSS por vista + niveles.css, chatbot.css, modal.css
frontend/      (NUEVO) SPA React + Vite — esta sesión
```

## Pantallas del front actual
| Ruta (Thymeleaf) | Vista | Notas |
|---|---|---|
| `/` , `/public/home/pasajero`, `/public/home/conductor`, `/public/surge` | landing pública | `/public/contact` (POST) formulario de contacto |
| `/auth/login` | inicio.html | form login → POST `/login` (sesión) |
| `/auth/registro` | registros.html | pasajero (nombre, apellido, email, tel, password) y conductor (wizard 3 pasos, vehículo/documentos) |
| `/auth/forgot-password`, `/auth/reset-password` | recuperación | |
| `/profile/change-password` | cambio de clave | |
| `/pasajero/panel` | panel pasajero | mapa Leaflet + OSRM + Nominatim, solicitar/cancelar viaje, historial, niveles |
| `/conductor/panel` | panel conductor | solicitudes, en curso, historial, ingresos, niveles |
| `/admin/dashboard` | panel admin | **fuera de alcance** (otra sesión) |
| `/rating` | calificación | |

## Endpoints REST (método + ruta) que usará la SPA
Auth: `POST /api/auth/login` `{email,password}` → `{token}` (JWT con claims `roles`, `userId`).
Pasajero (`ROLE_PASAJERO`): `GET /api/pasajero/perfil`, `POST /api/pasajero/solicitar-viaje`
(`origen,destino,ubicacionOrigen{latitud,longitud},ubicacionDestino,tarifa,distanciaKM,fechaHora?,metodoPago?,upgrade?`),
`POST /api/pasajero/cancelar-viaje/{id}`, `GET /api/pasajero/historial?fecha&conductor`,
`GET /api/pasajero/servicios/{id}`, `POST /api/pasajero/calificar-servicio/{id}` `{calificacion,comentarios}`.
Conductor (`ROLE_CONDUCTOR`): `GET /api/conductor/{perfil,servicios-disponibles,servicios-en-curso,historial,ingresos,optimizar}`,
`POST /api/conductor/{aceptar,iniciar,finalizar,cancelar}-servicio/{id}`.
Niveles (pasajero y conductor): `GET /api/niveles/me` → `NivelDto` (nivel, nombre, nombreSiguiente, xpActual, xpNivelActual, xpSiguienteNivel, xpFaltante, progreso, beneficiosActivos…), `GET /api/niveles/viajes/{id}/desglose`;
solo pasajero: `PUT /api/niveles/dias-nexa`, `PUT|DELETE /api/niveles/favoritos/{id}`.
Públicos del back actual: `POST /public/chat`, `POST /public/contact`.
Registro: **solo existe como form-POST con redirect** (`POST /auth/registro/pasajero`, `/auth/registro/conductor`), no JSON → ver NIGHT_LOG (brecha).
WebSocket STOMP/SockJS `/ws`, topics `/topic/pasajero/{userId}`, `/topic/conductor/{userId}`, `/topic/servicios-disponibles`; `GET /api/user-id`.

## Autenticación
- Web actual: form login `/login` → cookie de sesión `JSESSIONID` (HttpOnly) + CSRF para rutas no-API.
- API: `Authorization: Bearer <jwt>` leído por `JwtAuthFilter`. CSRF desactivado en `/api/**`, `/auth/**`, `/public/**`.
- No hay CORS configurado → la SPA debe ser same-origin (en dev, proxy de Vite).
- El back no emite cookie HttpOnly para el JWT → el token vive en el cliente (riesgo documentado).
