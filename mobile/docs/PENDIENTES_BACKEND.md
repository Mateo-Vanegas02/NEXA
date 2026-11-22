# Pendientes del backend (la app los cubre con mocks o soluciones locales)

| # | Necesidad | Estado actual | Solución en la app |
|---|-----------|---------------|--------------------|
| 1 | ~~Login JWT para conductores~~ | **Resuelto** en la rama `feat/api-movil-auth` del backend (pendiente de integrar a `master` y desplegar). Conductor sin aprobar: 403 con `estadoValidacion` y `motivo` | La app muestra el estado y el motivo |
| 2 | Registro JSON | **Resuelto** en `feat/api-movil-auth`: `POST /api/auth/registro/pasajero` (JSON) y `/conductor` (multipart con 4 fotos) | Conectado en la app: pasajero (JSON) y conductor (multipart con 4 fotos, `image_picker`) |
| 3 | Refresh de token | No existe (JWT de 24 h) | Se cierra sesión al recibir 401 |
| 4 | WebSocket/STOMP con JWT | `/ws` autentica por sesión web | Polling cada 5 s solo con viaje activo / conductor en línea |
| 5 | Viaje activo del pasajero | No hay `GET /pasajero/viaje-activo` | Se deduce de `GET /pasajero/historial` (estado activo) |
| 6 | ~~Cotización de tarifa~~ | **Resuelto**: `POST /api/pasajero/cotizar` ya existe en `master` | La app usa el precio del servidor |
| 7 | Rechazar solicitud / estado en línea del conductor | No existen | Rechazo local; "en línea" solo controla el polling |
| 8 | Estado de aprobación del conductor | Solo dentro de `GET /conductor/perfil` (`estadoValidacion`) | Se lee de ahí |
| 9 | Geocodificación / búsqueda de direcciones | No existe | Destino por toque en el mapa |
| 10 | ~~Formato de `diasNexa`~~ | Ya no existe: Días NEXA se retiró del modelo v2.3 | Eliminado de la app |
| 11 | Reputación del conductor (calificación, viajes, moto, placa, teléfono) en el servicio | `ConductorEmbedded` solo trae id y nombre | Campos opcionales en la app; con el backend real no se muestran |
| 12 | Calificación/viajes del pasajero en `GET /pasajero/perfil` | Solo datos básicos | Viajes = finalizados del historial; calificación omitida si no llega |
| 13 | ~~Posición en vivo del conductor~~ | **Resuelto** en `feat/api-movil-auth`: `GET /api/pasajero/posicion-conductor/{id}` (pendiente de integrar a `master`) | La app consulta cada 5 s; la ruta dibujada sigue siendo una línea recta |
| 14 | Etiquetas de calificación como campo propio | No existe | Se concatenan al comentario |

**Pendiente del lado del conductor (Fase 4):** la tarjeta de solicitud muestra la tarifa y el extra, no «Ganas $X»: para calcularlo hace falta la comisión del conductor (`/api/niveles/me?rol=conductor`, Fase 5). Tampoco hay aún notificaciones push: el conductor ve solicitudes nuevas solo con la app abierta (polling de 5 s).

## Pendientes del rediseño NEXA Pulso (14-nov-2026)

Lo que el diseño Pulso muestra y la app **no** implementó porque depende del servidor
(la app no inventa datos de negocio):

| # | Necesidad | Qué falta en el servidor | Estado en la app |
|---|-----------|--------------------------|------------------|
| P1 | Código de viaje (PIN que el pasajero le dicta al conductor para iniciar) | Generarlo al aceptar, entregarlo solo al pasajero y validarlo en `iniciar-servicio` | No se muestra |
| P2 | Compartir viaje con enlace público en vivo | Enlace firmado y con vencimiento + vista pública de solo lectura | Se comparte un texto (destino y conductor) |
| P3 | SOS con aviso a NEXA y a contactos de confianza | Endpoint de alerta con la posición y contactos del usuario | El SOS (mantener presionado) solo llama al 123 |
| P4 | Pago en la app (ePayco) | Integración de pagos y conciliación | Solo efectivo |
| P5 | Promedio por variable en el riesgo de un viaje | `/riesgo` solo trae el valor del viaje, no el promedio para comparar | Se muestran los factores sin comparación |
| P6 | Pérdida por época del entrenamiento | El entrenamiento solo publica el resultado final | La red se anima, sin curva de pérdida |
| P7 | Progreso del viaje en la notificación (Android 16, `Notification.ProgressStyle`) | Push de avance por fase con distancia restante | Notificación normal del viaje |

## Pendientes del rediseño del video (22-nov-2026)

| # | Necesidad | Qué falta en el servidor | Estado en la app |
|---|-----------|--------------------------|------------------|
| V1 | Posición en vivo por WebSocket | Autenticar el STOMP de `/ws` con el JWT de la app y publicar la posición del conductor | Sondeo cada 2 s (conductor envía, pasajero consulta) |
| V2 | Vencimiento de SOAT y tecnomecánica | Guardar la fecha de vencimiento de cada documento | El perfil del conductor muestra la moto, sin vencimientos; el admin ve las fotos y números |
| V3 | Zonas con más solicitudes (mapa de calor del conductor) | Agregado de solicitudes recientes por zona | No se muestra |
| V4 | Ruta que evita giros a la izquierda | OSRM no lo ofrece; haría falta otro perfil de ruteo | Se ofrecen la más rápida, la más corta y una alternativa |
| V5 | Nombres de calle en la maniobra | Instrucciones paso a paso de OSRM (`steps=true`) | Giro y distancia, sin calle |
| V6 | Contactar al pasajero desde «viajes en riesgo» | La Lambda no envía datos de contacto (privacidad) | Solo la razón probable |
