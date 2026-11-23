# Avisos push y canales WEB / APP

Fase 2 del plan «NEXA app: segundo plano, notificaciones y giroscopio». Contrato entre el backend y la app
Flutter (rama `app`, Android por ahora).

## Canal del viaje
Un viaje pedido en la web se atiende en la web y uno pedido en la app, en la app.

- `Servicio.canal` = `WEB` | `APP`, lo fija el servidor al crear la solicitud: `APP` si la petición llegó con token
  Bearer (lo marca `JwtAuthFilter`), `WEB` si llegó con la sesión del navegador (puerto `CanalPeticion`).
  Los viajes anteriores (sin canal) cuentan como `WEB`.
- La posición del conductor (`POST /conductor/ubicacion` o `/api/...`) guarda el canal por el que se reportó.
  Cada conductor solo ve y cuenta para las solicitudes de su canal (`obtenerServiciosDisponibles`,
  «Avisamos a N conductores»).
- Aceptar, «llegué», iniciar, finalizar y cancelar (conductor o pasajero) por el otro canal responden **409** con
  el texto de `CanalServicio.mensajeOtroCanal()`.
- Push solo para viajes `APP`; la web sigue con STOMP.

## Registro del teléfono
| Método | Ruta | Cuerpo | Respuesta |
|---|---|---|---|
| PUT | `/api/dispositivos` | `{token, plataforma?}` (`ANDROID` por omisión, o `IOS`) | 204 |
| DELETE | `/api/dispositivos` | `{token}` | 204 |

Cualquier rol con sesión (PASAJERO, CONDUCTOR, ADMIN). La app llama `PUT` al iniciar sesión y cuando FCM rota el
token (`onTokenRefresh`), y `DELETE` **antes** de cerrar sesión. Un token pertenece a una sola cuenta (si otra
persona inicia sesión en el mismo teléfono, pasa a ella); máximo 5 teléfonos por cuenta; los tokens que FCM da por
desregistrados se borran solos. Colección `dispositivos` (token único).

## Mensajes
Cada push trae en `data` (todo texto): `eventoId` (único: la app ignora repetidos), `tipo`, `servicioId` y, si
aplica, `canal`, `titulo`, `cuerpo`. El texto se arma en el servidor para cada destinatario con lo que su rol puede
ver; la app pide el detalle a la API (`viaje-activo`, `viaje-en-camino`, `solicitud-activa`), que pasa por
`VisibilidadServicio`.

`eventoId` se deriva del tipo, el id del servicio y, donde corresponde, el destinatario o la variante. Se conserva
idéntico en los reintentos de `AvisosPendientesService`. Los mensajes STOMP de cambio de estado llevan además
`avisoId` en el objeto del viaje: para la bandeja persistente es el `_id` del aviso (`servicioId:tipo`), y para
otros emisores es `servicioId:estado`. Los mensajes ligeros de solicitud también incluyen `avisoId` sin cambiar
`id`, `estado`, `ola` ni `motivo`; la posición lleva `servicioId:POSICION:en`. El cliente debe tratar el id como
clave de deduplicación y consultar el estado vigente por API antes de navegar o actuar. La app guarda los ids de
push vistos durante 48 h (máximo 256) para cubrir reinicios.

| `tipo` | Para | Canal Android | Forma | Texto de ejemplo | La app abre |
|---|---|---|---|---|---|
| `SOLICITUD_NUEVA` | conductores de la app que entran en la ola (incluye, en la última, los que tienen la pantalla bloqueada) | `nexa_solicitudes` | solo datos (la app arma la notificación con «Ver» / «Aceptar» y la cuenta regresiva); vence a los 45 s | Nueva solicitud · Ganas $6.964 — A 700 m · 3,4 km de viaje · C.C. Unicentro | tarjeta de la solicitud |
| `SOLICITUD_EXTRA` | quienes ya la ven | `nexa_solicitudes` | solo datos | Ahora ganas $7.964 (+$1.000) | tarjeta |
| `SOLICITUD_RETIRADA` | conductores avisados (menos el que la tomó) | — | silencioso; `motivo` = `TOMADO` o `CANCELADO` | — | quita la tarjeta |
| `SOLICITUD_RECIBIDA` | pasajero, al pedir | `nexa_viaje` | solo datos; la app dibuja «Buscando tu conductor» fija, con barra en movimiento | Ola 1 de 4 · radio de 1,5 km | buscando conductor |
| `BUSQUEDA_AMPLIADA` | pasajero, en cada ola | `nexa_viaje` | solo datos; actualiza la misma notificación sin sonar (`eventoId` con la ola) | Ola 2 de 4 · radio de 2,5 km | buscando conductor |
| `VIAJE_ACEPTADO` | pasajero | `nexa_viaje` | solo datos (la app arma la notificación) | Carlos va por ti — Yamaha NMAX · gris · Placa KZT 38F · ★ 4,3 | conductor en camino |
| `CONDUCTOR_LLEGO` | pasajero | `nexa_viaje` | solo datos | Carlos está en tu punto — Yamaha NMAX · gris · Placa KZT 38F | conductor llegó |
| `VIAJE_INICIADO` | pasajero | `nexa_viaje` | solo datos, sin sonar | Vas camino a C.C. Unicentro | viaje en curso |
| `VIAJE_FINALIZADO` | pasajero | `nexa_viaje` | solo datos | ¡Llegaste a tu destino! — $4.400 · Toca para ver el total y calificar a Carlos | llegaste + calificar |
| `VIAJE_CANCELADO` | el otro lado | `nexa_viaje` | solo datos | Laura canceló el viaje / Tu conductor canceló el viaje | inicio |
| `SIN_CONDUCTORES` | pasajero (una vez, 45 s después del inicio de la última ola) | `nexa_viaje` | solo datos | Sin conductores cerca por ahora | buscando conductor (E03) |
| `SOLICITUD_VENCIDA` | pasajero (la solicitud esperó `nexa.despacho.vencimiento-solicitud-minutos` y se canceló sola, sin cargo; a los conductores avisados les llega `SOLICITUD_RETIRADA` con motivo `VENCIDA`) | `nexa_viaje` | solo datos | No encontramos conductor | inicio |

Desde el 23-nov-2026 el canal `nexa_viaje` viaja **solo como datos**: la app (desde la versión que trae
`mostrarAvisoViaje`) dibuja cada etapa con su diseño, con estos datos además de `titulo` y `cuerpo`:
`conductor`, `vehiculo`, `placa`, `calificacion`, `destino`, `total` (al terminar) y, en la búsqueda, `ola`,
`olas` y `radio`. Una app vieja no muestra estos avisos: hay que instalar la app nueva junto con este despliegue.

Los avisos del mismo viaje usan `tag = viaje-<servicioId>`: uno nuevo reemplaza al anterior en la bandeja.
Vigencias en `modelo-nexa.properties` (`nexa.avisos.*`): solicitud 45 s, viaje 10 min, cuenta 24 h.

Canales que la app debe crear al arrancar: `nexa_solicitudes` (importancia alta, sonido propio), `nexa_viaje`
(alta) y `nexa_cuenta` (normal).

Pendientes para una fase siguiente: avisos de cuenta (deuda registrada o condonada, nivel, saldo con NEXA,
conductor aprobado, entrenamiento terminado para el admin) y «en 1 min empieza a cobrarse la espera».

## Configuración
`FIREBASE_CREDENCIALES`: cuenta de servicio del proyecto **nuevo** de Firebase (el de FCM, no el de App
Distribution), en base64 y en una línea (`base64 -w0 cuenta.json`). En AWS: Parameter Store
`/nexa/prod/FIREBASE_CREDENCIALES` (SecureString), la carga el dueño de la cuenta; `preparar.sh` ya la pasa al
contenedor con las demás. Es opcional: sin ella el servidor arranca y los avisos se descartan (log «Push
desactivado»). El envío usa la API HTTP v1 de FCM con una cola de 1000 avisos y 2 hilos, y reintenta una vez ante
429/5xx.
