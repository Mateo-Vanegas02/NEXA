# Cambios de la rama `servicio-de-niveles` (PR #14)

Todo lo que trae esta rama respecto a `master`, por área. Las decisiones de diseño del sistema de niveles están en
[`niveles/DECISIONES.md`](niveles/DECISIONES.md); el informe de seguridad en [`SEGURIDAD.md`](SEGURIDAD.md); la
verificación de conductores en [`VERIFICACION.md`](VERIFICACION.md).

| Área | Qué cambia | Dónde |
|---|---|---|
| Niveles y XP | Sistema completo para pasajero y conductor (XP, niveles, beneficios, comisión, tasa de servicio) | `Service/Niveles*`, `MotorXp`, `CalculadoraTarifa`, `levels.properties` |
| Interfaz | Diseño oscuro moderno (negro azulado y cian) en inicio, registro, inicio del conductor y paneles; login y recuperación de contraseña conservan su diseño original | `templates/`, `static/css/nexa-*.css`, `static/js/nexa-ui.js` |
| Seguridad | 17 hallazgos corregidos, credenciales fuera del repositorio | `Security/`, `docs/SEGURIDAD.md` |
| Verificación | Verificación de placa y documento de conductores con auditoría | `Verificacion/`, `docs/VERIFICACION.md` |
| Mapa | Simulación del recorrido fluida (60 fps) | `static/js/ruta-animada.js` |
| Herramientas | `CLAUDE.md`, skills del proyecto, bitácoras | `CLAUDE.md`, `.claude/skills/`, `docs/noche/` |

---

## 1. Sistema de niveles y XP

**XP:** `10 + 2 × km` por viaje finalizado (tope 90), tope diario de 300, antifraude de distancia mínima (1 km). La
distancia que cuenta es `min(km declarado, línea recta origen→destino × 2)`. El conductor recibe además un ajuste cuando
el pasajero lo califica (5★ ×1,2 · 4★ ×1,0 · ≤3★ ×0,5). Un viaje nunca da XP dos veces (índice único en `xp_eventos`) y un
barrido cada 10 min completa los que se hayan quedado a medias.

**Niveles:** Nuevo (0) · Bronce (100) · Plata (600) · Oro (1.800) · Diamante (4.500).
- Pasajero: por XP total; baja un nivel tras 90 días sin viajar.
- Conductor: por XP de los últimos 90 días **y** calidad (Plata ≥ 4,60; Oro ≥ 4,75 y aceptación ≥ 80 %; Diamante ≥ 4,85,
  aceptación ≥ 85 % y cancelación ≤ 5 %).

**Beneficios del pasajero (acumulables):** recogida prioritaria (N1) · Días NEXA, 30 % de descuento con tope de $3.000 (N2)
· escudo de tarifa dinámica 1,25x y cancelación gratis (N3) · cashback del 5 % en Créditos NEXA, conductores favoritos y
upgrade mensual (N4).

**Dinero:** comisión del conductor 25 / 24 / 22 / 20 / 18 % según nivel y tasa de servicio al pasajero (5 %, mín. $800,
máx. $2.500). Guardia de margen: `ingreso_plataforma ≥ tarifa × 3 %`; los beneficios los absorbe la plataforma y la
ganancia del conductor nunca baja por ellos.

**API:** `GET /api/niveles/me`, `GET /api/niveles/viajes/{id}/desglose` (cada rol ve su propia versión),
`PUT /api/niveles/dias-nexa`, `PUT|DELETE /api/niveles/favoritos/{id}`.

**UI:** barra de nivel animada en ambos dashboards, modal con beneficios bloqueados/desbloqueados, checklist de calidad del
conductor, toast "+N XP" y celebración única al subir de nivel.

**Configuración:** todos los números viven en `src/main/resources/levels.properties`. `levels.xp.min-minutos=0` porque la
simulación del viaje dura siempre ~10 s.

## 2. Interfaz: diseño oscuro moderno

Se adoptó el **diseño oscuro de la versión React** (negro azulado con resplandor cian, tarjetas con efecto cristal,
hero limpio con la tarjeta del velocímetro), portado a HTML/CSS/JS plano sobre las plantillas Thymeleaf:
- Cambian el inicio (`index`), el inicio del conductor (`home_conductor`), `inicio`, `registros` y los paneles de
  pasajero y conductor. El login, la recuperación de contraseña y el rating conservan su diseño original, que ya era oscuro.
- Archivos nuevos: `static/css/nexa-design.css`, `static/css/nexa-panel.css`, `static/js/nexa-ui.js`.
- Los paneles siguen mostrando la barra de niveles (punto 1) y el panel del conductor la animación del mapa (punto 5).
- **Corrección incluida:** el formulario de contacto del inicio necesita un token CSRF que Thymeleaf crea cuando la
  respuesta ya empezó a enviarse, lo que provocaba un error en el log en cada primera visita. Se crea la sesión antes de
  renderizar (`ControllerPublic` y el nuevo `ControllerInicio` para `/`).
- **Se evaluó una SPA de React + Vite y se eliminó:** todo el front es Thymeleaf + JavaScript plano. Sigue en el
  historial de git (commits `1a25aaa` … `b300fcd`), igual que dos variantes del rediseño de plantillas (una clara y una
  con el diseño original de `master`, restaurada en `1ea0b32`) por si se quiere retomar alguna.

## 3. Seguridad del back-end (`docs/SEGURIDAD.md`)

**Crítico:** administrador por defecto con contraseña fija (ahora el primer admin se crea solo con `ADMIN_EMAIL` y
`ADMIN_PASSWORD`); secretos reales como valores por defecto en `application.properties`; hash de contraseña expuesto por la API.

**Alto:** IDOR en viajes (iniciar, leer y calificar viajes ajenos); `/api/auth/login` era inalcanzable (401); CSRF desactivado
para todo `/api/**` con sesión; WebSocket sin autorización por canal y con origen `*`; sin límite de intentos (ahora
`RateLimitFilter`, 429 con `Retry-After`).

**Medio y bajo:** enumeración de cuentas, recuperación de contraseña de conductores rota, política de contraseñas, validación
de entradas, fugas de excepciones, logging DEBUG/TRACE activo por defecto, regex libre en búsquedas, cabeceras de seguridad.

**Qué implica para quien despliega:**
- **Estado actual de los secretos:** salen de `application.properties` y se leen de variables de entorno o del `.env`
  local (`spring.config.import`). El validador de arranque está activo. Rotar las credenciales (siguen en el historial
  de git) y definir las variables en Azure queda **pendiente a cargo de Mateo**.
- Las llamadas a `/api/**` con sesión (sin JWT) ahora exigen el token CSRF (`X-CSRF-TOKEN`). `niveles.js` ya lo envía.
- Con login por JWT (móvil) no hace falta CSRF.
- **Rotar las credenciales**: están en el historial de git y siguen como valores por defecto en `application.properties`.

## 4. Verificación de conductores (`docs/VERIFICACION.md`)

- Interfaz `DriverVerificationProvider` con proveedores `mock`, `manual` (verificación asistida por el admin) y `real` (HTTP,
  listo para activarse). Selección con `VERIFICATION_PROVIDER` (por defecto `manual`).
- Panel de admin: estado de verificación por conductor y botones aprobar/rechazar con motivo. Cada decisión queda en la
  colección `auditoria_verificacion` (quién, cuándo, resultado, fuente). Endpoints en `/api/admin/verificacion/**`, solo ADMIN.
- **Aprobar ahora exige una verificación vigente** (`VERIFICATION_REQUIRE_VERIFIED=true`); se puede desactivar.
- No existe una API oficial, gratuita y por consulta del RUNT (usa captcha y evadirlo está prohibido): el documento
  explica las fuentes evaluadas y el siguiente paso recomendado.

## 5. Mapa: simulación fluida del recorrido

`static/js/ruta-animada.js` reemplaza el `setInterval` anterior del dashboard del conductor:
- Avanza por **distancia real** (velocidad constante), no por vértice de la ruta, con arranque y frenado suaves.
- `requestAnimationFrame` (~60 fps) y giro de la moto suavizado.
- Temporizador de respaldo: la llegada ocurre a tiempo aunque la pestaña esté oculta.
- La petición de ruta (OSRM) tiene un tope de 8 s y cae a línea recta.
- 14 pruebas con `node --test src/test/js/ruta-animada.test.mjs`.

## 6. Herramientas y documentación

`CLAUDE.md` (guía para Claude Code), skills del proyecto `nexa-backend` y `nexa-frontend` en `.claude/skills/`,
`docs/niveles/DECISIONES.md`, y las bitácoras de las sesiones nocturnas en `docs/noche/`.

## 7. Pruebas

- **Back-end:** 165 tests en verde (niveles, flujo completo con repositorios en memoria, seguridad HTTP, IDOR, WebSocket,
  verificación). Los `@SpringBootTest` que necesitan MongoDB están etiquetados `requiere-mongo` y excluidos por defecto.
- **JavaScript:** 14 pruebas de la animación.
- No se probó la app completa en un navegador contra una base de datos.

## 8. Pendientes conocidos

- Rotar credenciales y definir las variables en Azure (ver punto 3).
- Login de conductores por JWT: `/api/auth/login` solo admite pasajeros.
- Canjear Créditos NEXA no está implementado; "cancelación gratis" y "upgrade" quedan como elegibilidad y costo registrado,
  porque la app no tiene cargo por cancelación ni categorías de vehículo.
- El aviso por WebSocket de un viaje nuevo sigue siendo broadcast (el servidor rechaza aceptar un pedido prioritario durante su ventana).
- El cobro incluye la tasa de servicio, pero la pantalla aún no muestra la línea de desglose.
- Pendientes de seguridad de menor urgencia (revocación de JWT, CSP, rate limit distribuido, Docker como root,
  actualizar dependencias): tabla al final de `SEGURIDAD.md`.
