# Contrato de la API NEXA (app móvil)

Fuente de verdad: backend de `master` (commit `8a51e3e`, modelo v2.3), leído de `ApiAuthController`,
`ApiPasajeroController`, `ApiConductorController`, `ApiNivelesController`, `ApiPerfilController` y `presentacion/dto`.
Todo lo marcado **[PENDIENTE]** no existe aún en el backend y hay que crearlo (ver `PENDIENTES_BACKEND.md`).

## Base y autenticación
- Base URL: la web de AWS por defecto (`Env.urlAws`); `API_BASE_URL` la cambia (emulador Android con backend local: `http://10.0.2.2:8080`). Prefijo `/api`.
- `POST /api/auth/login` `{email, password}` → `200 {token}` (JWT, 24 h, sin refresh).
  - Hoy responde `403 {error}` si el usuario NO es pasajero. **[PENDIENTE]** abrirlo a conductores aprobados.
  - Claims del JWT: `sub`=email, `roles`, `userId`.
- Resto de rutas: `Authorization: Bearer <token>`. Con Bearer no se exige CSRF.
- **[PENDIENTE]** registro por JSON/multipart (hoy solo `/auth/registro/*` con formulario web y CSRF).
- Errores: `{ "error": "mensaje" }` (a veces también `message`); validaciones de `@Valid` devuelven 400.
  Códigos con significado: 402 (falta aceptar la deuda), 403 (fuera de su ola / no es suyo), 409 (otro conductor tomó la solicitud, estado cambió, ya hay una solicitud).

## Estados del servicio
`SOLICITADO → ACEPTADO → EN_CURSO → FINALIZADO` y `CANCELADO`. La fase visible sale de `estado` + `fechaLlegada`
(`A_RECOGER` = ACEPTADO sin llegada, `EN_EL_PUNTO` = ACEPTADO con `fechaLlegada`, `EN_VIAJE` = EN_CURSO).

## Pasajero (`/api/pasajero/**`)
| Método y ruta | Cuerpo | Respuesta |
|---|---|---|
| `GET /perfil` | — | `Pasajero` |
| `POST /cotizar` | `{ubicacionOrigen:{latitud,longitud}, ubicacionDestino:{...}}` | `{distanciaKm, tarifa, descuento, precio, multiplicador, deudaPendiente, totalAPagar}` (valida zona de Cartagena; 4xx con `error`) |
| `POST /solicitar-viaje` | `{origen, destino, ubicacionOrigen, ubicacionDestino, fechaHora?, metodoPago?, ubicacionPasajero?, aceptaDeuda}` | `Servicio`. 400 si el pin está a >300 m del pasajero; 402 si hay deuda y `aceptaDeuda=false`; 409 si ya tiene una solicitud |
| `GET /solicitud-activa` | — | `{activa:false}` o `{activa:true, servicioId, estado, ...datos de oferta (tarifa, extra, margen, pasos, despacho)}` |
| `POST /subir-oferta/{id}` | `{incremento}` (500/1000/2000; tope 5000 por viaje) | `Servicio`; 409 si cambió |
| `GET /viaje-en-camino` | — | `{activo:false}` o `{activo:true, id, estado, conductor:{nombre, fotoUrl}, ...}` (en `master` el backend añade `servicio` y `espera`: verificar al implementar) |
| `POST /ubicacion/{id}` | `{latitud, longitud}` | 204 (solo con viaje `ACEPTADO`; 403/409 si no) |
| `POST /cancelar-viaje/{id}` | — | `Servicio` |
| `GET /historial?fecha=&conductor=` | — | `[Servicio]` |
| `GET /servicios/{id}` | — | `Servicio` |
| `POST /calificar-servicio/{id}` | `{calificacion 0..5, comentarios}` | `Servicio` |
| `GET /deuda`, `GET /historial-cargos` | — | deuda por cancelación del pasajero |

El pasajero **nunca** finaliza el viaje. Cada rol ve solo su propia calificación (ver "Privacidad").

## Conductor (`/api/conductor/**`)
| Método y ruta | Cuerpo | Respuesta |
|---|---|---|
| `GET /perfil` | — | `Conductor` (incluye `estadoValidacion`) |
| `GET /servicios-disponibles?lat=&lng=` | — | `[Servicio]` filtrados por la ola del conductor |
| `POST /ubicacion` | `{latitud, longitud, disponible}` | `200 PosicionViaje` con viaje, `204` sin viaje. Reportar cada ≥3–5 s / ≥10–30 m / latido 8–30 s; vence a los 45 s |
| `POST /aceptar-servicio/{id}` | — | `Servicio`; 403 fuera de su ola, 409 si otro la tomó |
| `GET /viaje-activo` | — | `Servicio` (ACEPTADO/EN_CURSO) o 204 |
| `GET /pasajero-ubicacion/{id}` | — | `{latitud, longitud, ...}` o 204 (consultar cada 4 s) |
| `POST /llegue/{id}` | `{latitud, longitud}` | `Servicio`; 409 si está a >50 m de la recogida |
| `POST /iniciar-servicio/{id}` | — | `Servicio`; 409 sin `fechaLlegada` |
| `POST /finalizar-servicio/{id}` | — | `Servicio`; en cualquier tramo, cobra según lo recorrido (ver docs/niveles) |
| `POST /cancelar-servicio/{id}` | — | `Servicio` (también en curso) |
| `GET /servicios-en-curso`, `GET /historial?fecha=&pasajero=` | — | `[Servicio]` |
| `GET /ingresos?periodo=&fecha=` | — | `[{fecha, hora, monto, montoBruto, descripcion}]` (`hora` ISO, desde `feat/admin-operacion`) |
| `GET /saldo?dias=30` | — | saldo con NEXA (vista sin comisión ni deudas); la app pide 1, 7 o 30 días |
| `POST /rutas/{id}` | `{latitud, longitud}` | `[{indice, geometria, distanciaKm, duracionMin, etiqueta}]` (hasta 3, la sugerida primero; `etiqueta` = `RAPIDA`/`CORTA`/`ALTERNATIVA`) desde esa posición hasta la recogida (ACEPTADO) o el destino (EN_CURSO). 403 si no es su viaje, 409 si no está activo. Las ofertas valen 10 min |
| `PUT /rutas/{id}` | `{indice}` | `{geometria}`; con el viaje EN_CURSO cambia `rutaGeometria` (el pasajero la ve). 404 si la oferta venció |

`PosicionViaje` = `{servicioId, fase, latitud, longitud, distanciaRestanteKm, etaMinutos, en}`. ETA y distancia las calcula
el servidor; la app no las calcula.

## Admin (`/api/admin/**`, solo ROLE_ADMIN)
| Método y ruta | Cuerpo | Respuesta |
|---|---|---|
| `GET /operacion` | — | `{viajesHoy, finalizadosHoy, canceladosHoy, enCurso, yendoARecoger, solicitudesAbiertas, conductoresEnLinea, conductoresDisponibles, conductoresPendientes, flota:[{latitud, longitud, disponible}], alertas:[{tipo, texto, servicioId, minutos}]}` |
| `GET /conductores?estado=PENDIENTE\|EN_REVISION\|APROBADO\|RECHAZADO` | — | `[Conductor]` (`email`, `nombre_y_Apellido`, `ntelefono`, `fechaRegistro`, `revisionMensaje`) |
| `GET /verificacion/documentos?email=` | — | `[{id, tipo, numeroDeclarado, contentType, subidoEn}]` |
| `GET /verificacion/documentos/{id}/archivo` | — | la foto (bytes) |
| `GET /verificacion/vehiculos?email=` | — | `[{id, placa, marca, modelo, color, verificado}]` |
| `GET /verificacion/estado?email=` | — | `{ultimaVerificacion:{resultado}, ...}` |
| `POST /verificacion/manual` | `{email, resultado:"VERIFIED", nota}` | auditoría (el admin revisó los documentos) |
| `POST /verificacion/decision` | `{email, aprobar, motivo}` | auditoría; aprobar exige verificación VERIFIED |
| `POST /verificacion/solicitar-info` | `{email, mensaje}` | auditoría; queda EN_REVISION |

## Servicio (campos relevantes)
`id, pasajero{id,nombre,email,fotoUrl}, conductor{id,nombre,fotoUrl,nivel,calificacion,vehiculo,placa}, origen, destino,
distanciaKM, duracionEstimadaMin, rutaGeometria (polyline), ubicacionOrigen/Destino{latitud,longitud}, fechaHora,
fechaAceptacion, fechaLlegada, fechaInicio, fechaFinalizacion, tarifa, extraVoluntario, metodoPago, estado,
calificacionConductor/Pasajero + comentarios (solo la propia), nivelPasajero, finalizadoAntesDelDestino, fraccionCobrada,
deudaCobrada, cargoCancelacion, xpGanadoPasajero, xpGanadoConductor`.
`recorrido` y `distanciaRecorridaKm` no llegan al cliente.

## Niveles (`/api/niveles/**`)
- `GET /me?rol=` → `NivelDto`: `usuarioId, rol, nivel (desde 1, sin techo en pasajero; conductor 1–5), xpActual, xpNivelActual,
  xpSiguienteNivel?, xpFaltante, progreso 0..1, descuento, prioridadSegundos, niveles[{nivel,xp,descuento?,beneficios,comision?}],
  beneficiosActivos[{clave,titulo,descripcion,nivelRequerido,activo}], conductor?{comisionActual, comisionSiguiente?, calificacion?,
  aceptacion, cancelacion, requisitosSiguiente[{texto,cumplido}], bloqueadoPorCalidad}`.
- `GET /viajes/{id}/desglose` → pasajero: `{tarifa, descuentoNivel, recargoEspera, extraVoluntario, totalPasajero, deudaAnterior, totalAPagar}`;
  conductor: `{recargoEspera, extraVoluntario, gananciaConductor, cobrarAlPasajero}` (sin comisión).
- `PUT|DELETE /favoritos/{conductorId}` (solo pasajero, desde nivel 5).
- **Se eliminaron** Días NEXA, tasa de servicio, escudo, upgrade, cashback y Créditos NEXA: la app no debe mostrarlos.

## Perfil (`/api/perfil`)
`GET /api/perfil` → `{id, rol, nombre, email, telefono, licencia, estadoValidacion, miembroDesde, tieneFoto, fotoUrl}`;
`PUT /api/perfil` `{nombre, telefono}`; `PUT /api/perfil/foto` (multipart `foto`, JPG/PNG/WebP, máx. 5 MB); `DELETE /api/perfil/foto`;
`GET /api/usuarios/{id}/foto`.

## Privacidad por rol
El conductor no ve comisión, tarifa bruta ni la deuda del pasajero; el pasajero no ve la calificación que le puso el conductor.
Los campos que no llegan son opcionales en los modelos de la app.

## Tiempo real
STOMP en `/ws` (`/topic/pasajero/{id}/posicion`, `/topic/servicios-disponibles`). El socket autentica por sesión web:
**[VERIFICAR]** si `WebSocketAuthInterceptor` acepta JWT. Mientras tanto la app usa polling (5 s con viaje activo; el conductor envía su posición cada 2 s y el pasajero pide la de la moto cada 2 s).
