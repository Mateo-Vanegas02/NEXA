# NIGHT_LOG — sesión front-end (rama claude/front-end-3cbd8a)

## Cambio de rumbo (a pedido del dueño)
Se descartó la SPA (React + Vite + Tailwind). El front vuelve a ser **Thymeleaf + CSS/JS planos servido por Spring en localhost:8080**, conectado al back como siempre (form login `/login`, `/auth/registro/*`, `/public/contact`). La SPA completa sigue en el historial de git (commits e407363…e82b409) por si se retoma.

## Hecho
- [x] `PROJECT_CONTEXT.md` y línea base de bugs (tabla de abajo).
- [x] Diseño (decisión final del dueño): versión CLARA de DESIGN.md con la paleta y tipografía de NEXA (#00C4FF, #004F78, #5EBDDA, Montserrat): lienzo blanco, barras sólidas azul NEXA arriba y abajo, tarjetas grises planas sin sombras, radios de 8 px, pestañas en celeste. Tokens y estilos de texto `nexa-*` en `static/css/nexa-design.css`; comportamiento en `static/js/nexa-ui.js`. La versión oscura (parecida a la app original) se probó y se descartó; sigue en el historial de git (commit c12e41a).
- [x] Pantalla de DESIGN.md completa en el inicio (a pedido): selector de ciudad (Cartagena, CO), titular "Ve a cualquier lugar con NEXA", interruptor "Pedir ahora | Programar · pronto" (Programar deshabilitado: no existe aún), formulario de recogida/destino con la línea de recorrido, botón "Ver precio", ilustración a la derecha, tarjetas de sugerencia con ilustración plana, barra fija inferior "Pedir un viaje" y pie azul de 4 columnas (también en el inicio de conductor). Sin subrayados decorativos en títulos. El formulario guarda recogida/destino en sessionStorage y abre `/pasajero/panel` (pide login si hace falta); el panel los escribe en los campos y dispara las sugerencias del buscador, pero el pasajero debe elegir una sugerencia (calcularRuta exige coordenadas). No probado con el back real.
- [x] Recuperar contraseña, restablecer (con token), cambiar contraseña (sesión iniciada) y calificar servicio: misma barra superior y una tarjeta centrada. Conservan acciones, campos (`email`, `token`, `newPassword`, `confirmPassword`, `currentPassword`) y mensajes `success`/`error` del back. Medidor de seguridad y confirmación de contraseña en `nexa-ui.js` (sin `alert()`); `rating.js` reescrito con estrellas accesibles (botones con aria-pressed, error en línea) y el mismo POST a `/rating/calificar`.
- [x] Login y registro con la misma distribución limpia: barra superior compartida con el inicio (enlaces a las secciones del home y CTA), título grande y tarjeta centrada con el video al lado; la marca ya no se repite dentro de la tarjeta. El inicio ya tenía esa estructura (barra, hero a dos columnas, secciones, banda final).
- [x] Paneles con distribución limpia como en la versión React: barra superior en lugar de la barra lateral, título grande, una columna centrada (máx. 1200 px) y tarjetas con más aire; la barra de nivel (niveles.js) es una tarjeta azul NEXA. Mismas secciones, mismo JS (showSection, modales, mapa). Solo CSS en `nexa-panel.css`. Pendiente verlo con datos reales: la barra de nivel la crea niveles.js y no aparece en la vista previa estática.
- [x] Más presencia en el inicio: ilustración grande en el hero (`hero-pasajero.jpg` y `hero-conductor.jpg`, versiones de 20-30 KB de las ilustraciones originales home2.png y moto_fondo1.png de ~1.5 MB), chips con lo que incluye NEXA, y banda de llamada a la acción azul antes del pie.
- [x] Plantillas reescritas: `index.html` (home pasajero), `home_conductor.html`, `inicio.html` (login), `registros.html` (pasajero + conductor con pestañas). Se conservan acciones, nombres de campos, CSRF (`th:action`), flash attributes y el chatbot.
- [x] Paneles de pasajero y conductor: `static/css/nexa-panel.css` (cargado al final) redefine las variables de sus CSS: tema claro con barra lateral azul NEXA, tarjetas planas y radios de 8 px. El botón "Modo oscuro" (que antes solo cambiaba el mapa) ahora devuelve el tema oscuro original. No se tocó marcado ni JS. El panel admin NO se tocó (lo trabaja otra sesión).
- [x] Accesibilidad: enlace "saltar al contenido", `label` en todos los campos, foco visible, `aria-*` en pestañas/menú/velocímetro, `prefers-reduced-motion`.
- [x] Verificación visual: vista previa estática de las plantillas en el navegador (no se pudo levantar Spring). Las partes con `th:` (mensajes de error/éxito, CSRF) NO se vieron renderizadas.

## Pendiente
- Probar en `localhost:8080` con el back levantado (incluye paneles: barra de niveles, modales, mapa y tablas con datos reales, que la vista previa estática no mostró): login, registro (pasajero y conductor), contacto y mensajes de error.
- No migrados al diseño nuevo: panel admin (otra sesión) y `surge.html` (página de animación con scroll, se dejó como está).
- Archivos que quedaron sin uso por las plantillas nuevas (no se borraron): `home.css`, `Homec.css`, `nexa-login.css`, `style_registro.css`, `rating.css`, `home.js`, `Homec.js`, `home-animations.js`, `speedometer-home.js`, `nexa-login.js`, `script_registro.js`.
- Los bugs de la tabla (XSS por `innerHTML` en paneles y chatbot, `fetch` sin chequear `ok`) siguen sin corregir.

## Decisiones pendientes de revisión
- Se eliminó `frontend/` del árbol de trabajo (decisión del dueño). Los iconos de servicios ahora son Font Awesome (ya cargado antes), no los PNG de 3 MB.
- #00C4FF sobre blanco da ~2:1: solo se usa como relleno/acento (subrayado, fin del arco), nunca como texto.
- "Recordarme" del login se quitó: no hacía nada en el back.
- Nosotros usa pestañas accesibles (historia, misión, visión); el registro usa el mismo patrón para pasajero/conductor.
- El formulario de conductor pasó de 2 pasos con JS a un solo formulario con 3 grupos (menos JS, mismos campos y validaciones HTML).

## Bugs encontrados (front viejo; no se cambian salvo críticos)
| # | Archivo | Problema | Sev. |
|---|---|---|---|
| 1 | `static/js/chatbot.js:145` | `innerHTML` con la respuesta del bot (modelo LLM) → posible XSS/inyección HTML | Alta |
| 2 | `Dashboard_C.js:319-326, 579, 667` | `innerHTML` con `origen`, `destino`, `pasajero.nombre` ingresados por usuarios → XSS almacenado hacia el conductor | Alta |
| 3 | `Dashboard_C.js:239`, `Dashboard_P_v2.js:566` | `showError` usa `innerHTML` con el mensaje | Media |
| 4 | `Dashboard_C.js:156,312,367` | `fetch(...).then(r => r.json())` sin chequear `response.ok`: un 401/500 rompe con `servicios.forEach is not a function` | Media |
| 5 | `Dashboard_C.js:160` | `console.log("[DEBUG]...")` deja datos en consola | Baja |
| 6 | `Dashboard_C.js:278` | `document.querySelector('input[name="_csrf"]').value` lanza TypeError si falta el input | Media |
| 7 | `Dashboard_C/P*.js` | `username` y `profilePic` en `localStorage` (foto base64 pesada, sin límite de tamaño) | Baja |
| 8 | `Dashboard_P_v2.js:143,205`, `Dashboard_C.js:940` | llamadas a Nominatim/OSRM sin timeout ni manejo de rate-limit | Media |
| 9 | `chatbot.js:115` | `res.json()` sin chequear `res.ok` | Baja |
| 10 | `ApiAuthController` | ver brechas 1 y 2 | Alta |
| 11 | `script_registro.js` | validación solo de cliente; el back valida pasajero apenas (solo compara claves) | Media |

## Dependencias instaladas (justificación)
- react, react-dom, react-router-dom: SPA y rutas. vite + @vitejs/plugin-react: build. tailwindcss + @tailwindcss/vite: estilos.
- vitest, jsdom, testing-library (react, jest-dom, user-event): pruebas.
- eslint@9 + @eslint/js@9 (eslint 10 es incompatible con jsx-a11y), globals, plugins react / react-hooks / security / jsx-a11y: calidad, seguridad y accesibilidad.
- `npm audit`: 0 vulnerabilidades.

## Comandos para probar
```
cd frontend
npm install
npm run lint
npm test
npm run build
npm run dev   # necesita el back en :8080
```
