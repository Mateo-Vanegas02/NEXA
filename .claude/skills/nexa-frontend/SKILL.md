---
name: nexa-frontend
description: Frontend web de NEXA (plantillas Thymeleaf + JavaScript vanilla + CSS, sin bundler). Úsala al crear o modificar vistas en templates/, scripts en static/js, estilos en static/css, paneles de pasajero, conductor y admin, el panel del viaje en curso, mapas Leaflet, el chatbot o llamadas fetch/WebSocket al backend, y sus pruebas con node --test.
---

# NEXA — Frontend web

## Estructura
- Vistas: `src/main/resources/templates/` (Thymeleaf + `thymeleaf-extras-springsecurity6`). Paneles: `pasajero/panel_pasajero.html`, `conductor/panel_conductor.html`, `panel_admin.html`.
- JS: `static/js/`, un archivo por vista o por responsabilidad (`Dashboard_P_v2.js`, `Dashboard_C.js`, `Dashboard_A.js`, `chatbot.js`, y los módulos del viaje: `viaje-fases.js`, `viaje-panel.js`, `viaje-mapa.js`, `viaje-pasajero.js`, `viaje-activo.js`).
- CSS: `static/css/`, un archivo por vista. Los tokens de diseño están en `nexa-design.css` (variables en `:root`); `nexa-panel.css` es la base de los paneles.
- No hay npm ni bundler: todo es JS nativo del navegador.
- Es la misma app que la móvil (`feature/flutter-app`): colores, nombres de fase y textos de negocio deben coincidir (fondo #020a12, tarjeta #03192e, cian #00c4ff, Inter).

## Reglas
1. **Lógica pura separada del DOM.** La lógica va en funciones puras (formato, fases, reglas de reporte, filtros) en su propio archivo; el DOM se toca en otro. Los scripts son clásicos (IIFE/UMD que exporta con `module.exports` y también funciona en el navegador) para poder probarlos con `node --test`. Cada archivo puro nuevo lleva su prueba en `src/test/js/<nombre>.test.mjs` (modelo: `viaje-fases.js` + `viaje-fases.test.mjs`). No contamines `window`.
2. **El navegador no calcula negocio.** Precio, distancia, ETA, fase y XP los entrega el servidor (`/pasajero/cotizar`, `PosicionViaje`, `viaje-en-camino`…); la web solo los muestra. Las ayudas visuales (habilitar «Llegué» por cercanía) nunca reemplazan la validación del servidor.
3. **Seguridad en el cliente:**
   - El panel web usa **sesión + CSRF**, no JWT: todo POST/PUT/DELETE a `/api/**` envía `X-CSRF-TOKEN` (de `input[name="_csrf"]`); sin él responde 403 «Forbidden». El `Authorization: Bearer` es para la app móvil, no para estos paneles.
   - Nunca uses `innerHTML` con datos del usuario o de la API: usa `textContent` o crea los nodos. Modelo a seguir: `viaje-panel.js` (esqueleto fijo, solo actualiza textos). Hoy 8 scripts aún usan `innerHTML`: si tocas uno, migra esos usos y escapa lo que venga de datos.
   - No guardes datos sensibles en `localStorage`/`sessionStorage`. Lo «visto» de las tarjetas vive en `sessionStorage` por navegador, no por cuenta; no lo uses para decisiones de negocio.
4. **Privacidad por rol.** El servidor ya filtra el `Servicio` (`VisibilidadServicio`). No pidas ni pintes comisión, tarifa bruta o deuda en el panel del conductor, ni calificaciones ajenas.
5. **Fetch robusto.** Cada módulo define hoy su propio `api(path, opts)` (hay más de diez copias): al tocar uno, conserva el contrato (401 → `/auth/login`, 403, errores de red, timeout con `AbortController`). Unificarlos en un helper común es deuda conocida. Muestra siempre los estados de carga, vacío y error.
6. **Tiempo real.** STOMP: `/topic/servicios-disponibles` (solo `{id, estado}`; el cliente recarga la lista filtrada), `/topic/pasajero/{id}/posicion` (viaje en vivo). Cierra los WebSocket y limpia los `setInterval` al salir de la vista.
7. **GPS.** El pasajero usa `watchPosition` y el conductor reporta con `POST /conductor/ubicacion`; un navegador con la pantalla bloqueada deja de reportar (limitación conocida de la web, por eso existe la app móvil). Sin permiso de ubicación no se puede pedir viaje.
8. **Thymeleaf:** `th:text` (escapa) en vez de `th:utext`; `th:href="@{...}"` / `th:src="@{...}"`; `sec:authorize` para mostrar según el rol, sin confiar solo en eso (el backend también valida).
9. **CSS:**
   - Variables de `nexa-design.css`; nada de colores o espaciados sueltos.
   - Sin estilos en línea en plantillas nuevas (`panel_conductor.html` tiene 69 `style=""`: deuda; no la aumentes).
   - Mobile-first con `clamp()`, grid y flex. El panel del viaje pasa a hoja inferior en ≤ 720 px.
   - Respeta `prefers-reduced-motion`.
10. **Rendimiento:** scripts con `defer`, imágenes con `loading="lazy"` y dimensiones, videos con `preload="metadata"`, debounce en inputs y scroll. La geocodificación/rutas públicas (Nominatim, OSRM) tienen límites de uso: el servidor es el que debe llamarlas en producción.
11. **Accesibilidad:** HTML semántico, `label` en todos los inputs, foco visible, contraste AA y `aria-live` para chatbot y notificaciones.

## Verificación
- `node --test src/test/js/*.test.mjs` para la lógica pura.
- `./mvnw spring-boot:run` y abre `http://localhost:8080`; prueba en 375 px y en escritorio, con la consola sin errores y con cada rol aplicable (necesita las variables de entorno y una MongoDB).
- Los archivos grandes (`Dashboard_C.js`, `Dashboard_P_v2.js` y sus CSS) mezclan lógica, plantillas y estilo: al agregar algo nuevo, crea un módulo aparte en vez de seguir engordándolos.

## Checklist antes de terminar
- [ ] No hay `innerHTML`/`th:utext` con datos externos en lo que escribiste.
- [ ] Los POST/PUT/DELETE a `/api/**` llevan `X-CSRF-TOKEN`.
- [ ] Se manejan los estados de carga, error y vacío.
- [ ] La lógica nueva es pura, está en su archivo y tiene prueba en `src/test/js`.
- [ ] Es responsive, sin errores en consola y sin estilos en línea nuevos.
- [ ] No calcula precio, ETA ni XP en el navegador.
