# Sistema de niveles y XP — decisiones

## Reconocimiento (Fase 0)
- Backend: Spring Boot 3.4.4 / Java 21 / Maven. Frontend: Thymeleaf + JS vanilla (`static/js`, `static/css`), sin bundler.
- Persistencia: **MongoDB** (Spring Data), sin ORM ni migraciones → "tablas" = colecciones; la "migración" son campos nuevos con valor por defecto (los documentos viejos se leen con 0/null) e índices creados por `@Indexed`/`@CompoundIndex`.
- Modelos: `Usuario` (abstracta) → `Pasajero`, `Conductor`, `Admin` en la colección `Usuarios`; viaje = `Servicio` (colección `servicios`, estados `SOLICITADO→ACEPTADO→EN_CURSO→FINALIZADO|CANCELADO`).
- Tarifa: no se calcula en el servidor; el cliente envía `tarifa` y `distanciaKM` en `ServicioServiceImpl.solicitarViaje`. No existía comisión ni tarifa dinámica (`nexa-surge.js` es solo una animación de la landing).
- Fin de viaje: `ServicioServiceImpl.finalizarServicio` (conductor). La calificación llega después vía `calificarServicio`.
- Matching: no hay asignación automática; el conductor ve `obtenerServiciosDisponibles` y acepta con `aceptarServicio`.
- Dashboards: `templates/pasajero/panel_pasajero.html` + `Dashboard_P_v2.js`, `templates/conductor/panel_conductor.html` + `Dashboard_C.js`.

## Decisiones
- `COMPLETADO` del enunciado = `EstadoServicio.FINALIZADO`.
- Config central: `src/main/resources/levels.properties` (prefijo `levels.`), cargado con `@PropertySource` en `NivelesProperties`. Ningún número de negocio en el código.
- Endpoints bajo `/api/niveles/**` (no `/niveles/**`): así heredan JWT/sesión, exención de CSRF y la regla `/api/** authenticated` de `SecurityConstants`.
- Sin transacción multi-documento (no hay `MongoTransactionManager`; activarlo exige replica set). La idempotencia la da el índice único `(viajeId, rol, motivo)` en `xp_eventos`: el evento se inserta primero y solo si entra se actualiza al usuario.
- La calificación llega después de finalizar: el XP del conductor se otorga al finalizar con ×1.0 y, al calificar, se registra un evento `AJUSTE_CALIFICACION` por `base × (mult − 1)` (idempotente, fuera del tope diario).
- Tope diario 300 XP: se cuenta por usuario y rol con eventos `VIAJE` del día calendario; el XP se recorta al remanente.
- Duración del viaje = `fechaFinalizacion − fechaInicio`; sin `fechaInicio` se usa `fechaAceptacion`.
- Pasajero que baja de nivel por inactividad (90 d): `xpTotal` pasa al umbral del nivel anterior y `nivelActualizadoEn = ahora` (la siguiente baja requiere otros 90 d).
- Conductor: nivel = mayor nivel con `xp90d ≥ umbral` y requisitos de calidad cumplidos. Calificación = promedio de `calificacionConductor` de los últimos 90 d. No existe registro de ofertas rechazadas, así que **aceptación = finalizados / (finalizados + cancelados por el conductor)** y **cancelación = cancelados por el conductor / aceptados**. Se añade `Servicio.canceladoPor`; los servicios viejos (null) no penalizan.
- Sin calificaciones suficientes los requisitos de calificación se consideran no cumplidos (solo para N2+).
- Cotización: `tarifa` enviada por el cliente = tarifa base. Hora pico configurable (`levels.pico.*`, factor por defecto `1.0` = desactivado para no cambiar precios actuales). `Servicio.tarifa` pasa a ser la tarifa bruta (base × factor); la ganancia del conductor se calcula sobre ella.
- Beneficios se calculan al **solicitar** el viaje con la comisión **mínima** de la tabla (peor caso, 18 %): si cumple el margen así, cumple con cualquier conductor. Al **finalizar** se reutilizan los montos cotizados (el pasajero paga lo cotizado), se recalcula el lado de la comisión real, la guardia se vuelve a ejecutar y se guarda el desglose definitivo.
- Orden de recorte de la guardia: descuento Día NEXA → ahorro del escudo → costo del upgrade.
- Beneficios se "reservan" (colección `beneficios_uso`) al solicitar y se liberan si el viaje se cancela.
- Upgrade de categoría: no existen categorías de vehículo; se modela como costo absorbido por la plataforma (`levels.upgrade.costo-pct`) marcado en el servicio cuando el pasajero N4 lo pide (`upgrade=true`, 1/mes).
- Cancelación gratis N3: no existe cargo por cancelación en la app; se expone la elegibilidad (`cancelacionSinCargo` en la respuesta de cancelar) y queda registrada, sin cobro real.
- Cashback N4: 5 % del total pagado sin la tasa de servicio, a `creditos_nexa` con vencimiento a 60 d. Solo se acumula y se muestra el saldo; **canjear créditos no está implementado** (pendiente).
- Recogida prioritaria: el conductor elige de una lista, así que se implementa como ventana de prioridad (los pedidos de pasajeros N1+ solo los ven conductores ≥ umbral de calificación durante N segundos, creciente con el nivel) y orden por puntaje. Cercanía/ETA solo si el cliente envía `lat`/`lng`.
- Favoritos N4: lista de ids en `Pasajero.conductoresFavoritos`; un favorito (a ≤ 5 min si hay ubicación) ve el pedido durante la ventana.
- Zona horaria del negocio `America/Bogota` (`levels.zona-horaria`): hora pico, Día NEXA, tope diario y ventanas usan ese reloj (`Clock` en `NivelesConfig`), no la zona del servidor.
- `Servicio.solicitadoEn` (reloj del servidor) fija la ventana de prioridad; `fechaHora` viene del cliente y no es confiable para eso.
- `aceptarServicio` rechaza (403) un pedido prioritario que el conductor aún no puede ver. El aviso por WebSocket (`notificarNuevoServicioDisponible`) sigue siendo broadcast: el conductor puede verlo en tiempo real pero no aceptarlo hasta que termine la ventana.
- `obtenerIngresosConductor` devuelve `monto` neto de comisión cuando hay desglose definitivo (servicios viejos: la tarifa completa) y agrega `montoBruto`.
- Un fallo del módulo de niveles al finalizar se registra en log y nunca impide completar el viaje.
- Toast/celebración del front se calculan comparando con la última visita (localStorage), así funcionan aunque el usuario pase por la pantalla de calificación entre el viaje y el dashboard; la celebración se muestra una sola vez por nivel.
- Los tests `@SpringBootTest` existentes no se pudieron ejecutar en este entorno (requieren el Atlas real); se verificó el cableado con `NivelesWiringTest` y el flujo con `NivelesFlujoIntegrationTest` (repositorios en memoria).
- `levels.xp.min-minutos=0`: la simulación del viaje dura siempre ~10 s, así que una duración mínima impediría todo el XP. Quedan activos la distancia mínima (1 km) y el tope diario; una duración mínima real exige medir la duración real del viaje.
- Desglose por rol: `Servicio.desglose` es `@JsonIgnore` (nunca sale en la entidad ni en WebSocket). El pasajero recibe `DesglosePasajeroDto` (sin comisión ni margen) y el conductor `DesgloseConductorDto` (sin descuentos del pasajero ni margen); `GET /api/niveles/viajes/{id}/desglose` devuelve la vista del rol que pregunta y 403 a terceros.
- Distancia para XP: la declara el cliente, así que se acota a la línea recta origen-destino × `levels.xp.factor-rodeo` (2.0). Una distancia inventada no infla el XP; el antifraude de 1 km usa la distancia acotada.
- Reintentos: el XP se aplica en dos fases (evento `aplicado=false` → suma al usuario → `aplicado=true`), un desglose definitivo nunca se reescribe y `NivelesScheduler` barre cada 10 min los viajes FINALIZADOS de los últimos 7 días con `solicitadoEn` presente (posteriores al despliegue) cuyo desglose no es definitivo. Los viajes históricos no se reprocesan.
- Seguridad: `/api/niveles/me` y `/viajes/**` exigen PASAJERO o CONDUCTOR, y `/dias-nexa` y `/favoritos/**` solo PASAJERO, declarados en `SecurityConstants`/`SecurityConfig` (el control ya no vive solo dentro del controlador).
- Calidad del conductor: ya no se guarda `calificacionPromedio` en el documento. Se calcula desde sus viajes de la ventana con una consulta de solo 3 campos y una caché de `levels.cache-stats-segundos` (60 s). Así los conductores existentes tienen su promedio real desde el primer momento, sin esperar al job.
- Favoritos del listado de pedidos: una sola consulta (`findAllById`) por listado en vez de una por pedido VIP.
- Job diario: paginación con orden por `_id` y actualización puntual con `$set` solo si algo cambió; ya no guarda el documento entero del usuario.
- `Conductor.xpTotal` se mantiene (el enunciado lo pide) pero es informativo: el nivel sale de `xp90d` y la calidad.
- El cliente guarda el último XP visto y el nivel celebrado por rol **y usuario** (`usuarioId` en `/api/niveles/me`), así dos cuentas en un mismo navegador no se mezclan. `aria-valuenow` se acota al rango de la barra.

## Modelo v2.0, fase 1: reglas puras (oct. 2026)
Fuente: `docs/niveles/NEXA_Modelo_Tarifa_XP_Niveles_v2.3.docx`. Convive con el sistema anterior hasta que la fase 2 cambie `NivelesService` y `ServicioServiceImpl` a estas reglas; entonces se retiran `CalculadoraTarifa`, `MotorXp` y `levels.properties`.
- Config: `src/main/resources/modelo-nexa.properties` (prefijo `nexa.`, bound en `dominio/regla/ModeloNexaProperties`). Ningún número de negocio en el código.
- `ModeloTarifa`: tarifa base 3.000 + 1.200/km (mínimo $4.000, redondeo a $100), espera $400/min tras 5 min de gracia (máx. 10 min, recargo máx. $2.000), descuento por nivel 2–5 % con tope $800 que nunca baja de la mínima ni deja a la plataforma por debajo del 10 %, comisión 20→15 % por nivel del conductor, cargo por cancelación. Sin tasa de servicio.
- Dinero en pesos enteros (`long`): `M·T0` se redondea al peso antes de repartir y la plataforma recibe `P − C`, así `C + I = P` siempre. El descuento se redondea hacia abajo para no romper el margen.
- `ModeloXp`: XP con un decimal; viaje válido con ≥ 2 min, ≥ 0,5 km de `D_xp` y ≤ 2 viajes por pareja al día; factor del día y de espera; sin registro de llegada el factor de espera es neutro (1,0). Niveles del pasajero desde 1 y sin techo (`X_n = 10·round(270·(n−1)^1,5/10)`); conductor `400·(n−1)²` con tope en el nivel 5 (la tabla de comisión termina ahí).
- Zona de servicio (`ZonaServicio`): polígono aproximado del área urbana de Cartagena (Manzanillo del Mar y Bayunca al norte, Pasacaballos al sur, Mamonal) que excluye Turbaco, Tierra Bomba y Barú. Ruta máxima 40 km: el viaje urbano más largo, Bayunca → Pasacaballos, mide 30,4 km en línea recta (≈ 39,5 km de ruta). El mapa de la app no está limitado a la ciudad, así que el servidor rechaza todo lo de fuera.
- Distancia: puerto `aplicacion/puerto/ProveedorRutas`; hoy `infraestructura/rutas/RutaLineaRecta` (línea recta × 1,3). Rutas reales (p. ej. OSRM) se añaden como otra implementación y se elige con `nexa.rutas.proveedor`.
- Los datos actuales de Atlas son de prueba (algunos con distancias exageradas) y no se migran.

### Espera y cancelación (v2.1, 21 oct. 2026)
Decididas con el equipo; reemplazan el cargo de media tarifa mínima y la tarifa mínima completa por no presentarse.
- Espera: $400/min después de **5 minutos** de gracia (como Uber en Colombia en 2018), máximo 10 minutos (recargo máx. $2.000). Va completa al conductor, sin descuento ni XP.
- Cancelación (`ModeloTarifa.cargoCancelacion(nivel, T0, situacion)`): 0 antes de aceptar o hasta 2 min después (5 min desde el nivel 4); después, **20 % de la tarifa base T0** del servicio; si el conductor ya llegó, el mayor entre el 20 % y la espera acumulada. **Sin tope**: depende del servicio (27.000 → 5.400). Se paga el cargo o la espera, nunca los dos.
- Deuda: en efectivo el cargo queda como **deuda del pasajero, una sola a la vez** (el monto es el del servicio cancelado) y **bloquea nuevos viajes hasta pagarla**. La plataforma se lo reconoce de inmediato al conductor en su saldo (`S` baja en `Q`), solo con llegada verificada (≈150 m del punto de recogida y hora del servidor). Con pago inmediato (tarjeta, cuando exista) se cobra al cancelar.
- Aún no implementado (fase 2/3): campo de deuda en `Pasajero`, bloqueo en `solicitarViaje`, estado "llegué" con ubicación, registro del pago. Abierto: canal para pagar la deuda sin pasarela (transferencia o billetera confirmada por un administrador).
- Abierto: `nexa.xp.espera-sin-penalizar=3` hace que el factor F(e) reste XP desde el minuto 3, antes de que empiece el recargo (minuto 5).

## Modelo v2.1, fase 2, paso 1: cotización y cobro en el servidor (21 oct. 2026)
- El cliente ya no decide precio ni distancia. `POST /pasajero/cotizar` y `POST /api/pasajero/cotizar` reciben solo origen y destino y devuelven `{distanciaKm, tarifa, descuento, precio, multiplicador}` (sin comisión ni margen). Las rutas ya quedaban cubiertas por `/pasajero/**` y `/api/pasajero/**` en `SecurityConstants`.
- `CotizacionService` valida la zona de Cartagena y la ruta máxima de 40 km (`ZonaServicio`), obtiene la distancia del puerto `ProveedorRutas` y fija el precio con `ModeloTarifa.cotizar` (comisión mínima: el peor caso para el margen). Fuera de zona, ruta demasiado larga u origen = destino responden 400 con el motivo.
- `solicitar-viaje` recalcula todo en el servidor; `tarifa`, `distanciaKM` y `upgrade` ya no existen en el cuerpo (un cliente antiguo que los envíe no falla: se ignoran). `Servicio.tarifa` pasa a ser lo que paga el pasajero y `Servicio.distanciaKM` la distancia cobrada.
- Finalización: `NivelesService.procesarFinalizacion` fija el desglose definitivo con `ModeloTarifa.cobrar` y la comisión real del conductor, con la distancia y el multiplicador de la cotización. El precio final puede ser menor que el cotizado (más comisión deja más margen para el descuento), nunca mayor.
- Equivalencia transitoria de niveles (`aplicacion/util/EquivalenciaNiveles`): nivel guardado `ℓ` (0–4, sistema anterior) → nivel `ℓ+1` del modelo. Desaparece cuando el paso 3 migre los niveles.
- `Servicio.DesgloseTarifa` gana `descuentoNivel` y `recargoEspera`; los campos del sistema anterior (tasa, Día NEXA, escudo, upgrade, cashback) quedan en 0 hasta el paso 4. `DesglosePasajeroDto` y `DesgloseConductorDto` se reducen a los campos del modelo v2.1.
- Front: `Dashboard_P_v2.js` llama a `/pasajero/cotizar`, muestra el precio y el descuento del servidor y deja el campo de precio de solo lectura; OSRM solo dibuja el trayecto.
- Limpieza (paso 4, hecho el 24 oct. 2026): ya no existen `CalculadoraTarifa`, los campos de Día NEXA, escudo, upgrade, cashback y tasa de servicio del desglose, ni `cancelacionSinCargo`. Los documentos viejos de Mongo pueden conservar esos campos: se ignoran al leer.

## Modelo v2.1, fase 2, paso 2: llegada, espera, cancelación y deuda (21 oct. 2026)
- **Llegué:** `POST /conductor/llegue/{id}` y `/api/conductor/llegue/{id}` con `{latitud, longitud}`. Solo el conductor asignado, con el servicio ACEPTADO y a ≤ `nexa.llegada.radio-metros` (150 m) del punto de recogida (`RegistroLlegada`). La hora (`fechaLlegada`) la pone el servidor; repetir la llamada no la mueve. No hay estado nuevo: "llegó" es `fechaLlegada != null` en un servicio ACEPTADO.
- **Espera:** al iniciar, `minutosEspera` = minutos entre llegada e inicio; `procesarFinalizacion` la pasa a `ModeloTarifa.cobrar` (5 min de gracia, $400/min, máx. $2.000). Sin llegada verificada no hay recargo.
- **Cancelación del pasajero:** `ModeloTarifa.cargoCancelacion` con T0 del desglose (o recalculada si no hay), nivel traducido y situación real (minutos desde la aceptación, llegada, espera). Respuesta: `cargoCancelacion` y `cancelacionSinCargo`. Se retira `NivelesService.cancelacionSinCargo` (regla N3 anterior).
- **Deuda:** `Pasajero.deuda` (`DeudaCancelacion`: servicioId, monto, creadaEn). Se crea con un `updateFirst` condicionado a que no exista otra (una sola a la vez); si ya debe, el nuevo cargo no se cobra (queda en 0 y se registra en el log). `solicitarViaje` responde 402 mientras haya deuda; se lee de la base, no del objeto de la sesión. Sin pasarela, todos los métodos de pago generan deuda.
- **Pago:** `GET /api/admin/deudas` lista los deudores y `POST /api/admin/deudas/{pasajeroId}/confirmar-pago` libera al pasajero. El pasajero consulta la suya en `GET /pasajero/deuda` y `/api/pasajero/deuda`.
- **Conductor:** con llegada verificada `cargoAcreditadoConductor` queda en true al cancelar; sin ella, al confirmar el pago de la deuda (junto con `cargoPagadoEn`).
- **Front:** botón "Llegué" (geolocalización del navegador) en el modal del conductor, aviso del cargo al cancelar y aviso de deuda al entrar al panel del pasajero. El panel de administración aún no tiene pantalla para confirmar pagos (solo el endpoint).
- **Resuelto el 24 oct. 2026:** el admin confirma pagos desde el panel, el medio de pago es el siguiente viaje y el saldo del conductor se calcula (ver "Deuda en el siguiente viaje y saldo del conductor").

## Modelo v2.2: extra voluntario del pasajero y solicitud sin expiración (22 oct. 2026)
Decididas con el equipo; documentadas en la sección 12A del modelo (el archivo conserva el nombre `..._v2.1.docx`, la versión interna es 2.2).
- **Extra voluntario:** mientras la solicitud espera conductor, el pasajero puede sumar +$500, +$1.000 o +$2.000 (tope $5.000 por viaje, supuesto a validar en el piloto). Excepción acotada al precio cerrado: la tarifa la sigue fijando el servidor y el extra es un monto aparte. Va completo al conductor (`C + E`): sin comisión, descuento ni XP; la parte de la plataforma `I` no cambia y el margen del 10 % no se ve afectado. Solo sube, nunca baja. En efectivo no entra en el saldo del conductor. El cargo por cancelación se calcula sobre T0 y no incluye el extra; cancelar antes de aceptar no cobra nada. Cada oferta se registra con monto y hora.
- **Solicitud sin expiración:** no se cancela sola; dura hasta que un conductor la acepta o el pasajero la cancela. Con una solicitud abierta el pasajero no puede pedir otro viaje ni cerrar sesión (ya implementado: `BloqueoCierreSesionFilter` y 409 en `solicitarViaje`).
- **Despacho por olas:** se avisa primero a los conductores más cercanos y, si nadie acepta, se amplía el radio; tiempos y radios por calibrar.
- **Se quita el "precio ajustable"** previo de la app móvil (±$1.000): lo sustituye el extra voluntario.
- **Aún no implementado:** campo del extra en `Servicio` y su historial, endpoint para subir la oferta (solo en estado SOLICITADO), reparto `C + E` al finalizar, despacho por olas, "Ganas $X" neto y etiquetas en la tarjeta del conductor. Diseño en Figma (marcos "Subir oferta" y "Oferta enviada").

## Modelo v2.2, fase 2, pasos 3 y 4: XP, niveles y beneficios (24 oct. 2026)
- **XP y niveles:** `ModeloXp` reemplaza a `MotorXp`. El pasajero empieza en el nivel 1 y no tiene techo; el conductor va de 1 a 5 por XP de 90 días más requisitos de calidad. El XP se guarda con un decimal; el viaje solo da XP si pasa el antifraude (duración, distancia acotada contra rodeos, máx. viajes por pareja y día) y el factor del día `A(n)` cuenta los viajes con XP del día de Bogotá.
- **Beneficios:** descuento `min(1 % · nivel, 5 %)` desde el nivel 2 (lo absorbe la plataforma), prioridad de recogida 15/25/35/45 s en los niveles 2–5 (el 6 en adelante conserva 45 s), favoritos desde el nivel 5 (cercanía 5 min; 8 min desde el 7). `CatalogoBeneficios` arma la tabla que ve el cliente; los niveles 8+ (insignia, soporte prioritario, acceso anticipado, reconocimiento) son solo informativos por ahora.
- **Inactividad:** 90 días sin viajar → `X' = min(X, X_{L−1})` (baja al inicio del nivel anterior). Aviso por correo 15 días antes (`nexa.niveles.aviso-inactividad-dias`), una sola vez por racha: `Pasajero.avisoInactividadEn`; volver a viajar permite un aviso nuevo en la siguiente racha. Nivel 1 no recibe aviso porque no puede bajar.
- **Retirado:** tasa de servicio, Días NEXA, escudo de tarifa, upgrade, cashback y Créditos NEXA (código, colecciones del modelo, endpoint `/api/niveles/dias-nexa`, `levels.properties`, `MotorXp`, `CalculadoraTarifa`, `EquivalenciaNiveles`). Los campos en cero de `DesgloseTarifa` se conservan para no romper datos ya guardados.
- **Migración:** `NivelesMigracion` corre una vez al arrancar (marcador `niveles-v2.2` en `migraciones`): cada nivel guardado ℓ pasa a ℓ+1 y el XP del pasajero a `X_{ℓ+1}`. Los conductores se limitan al nivel 5; su XP de ventana lo recalcula el mantenimiento diario.
- **UI:** `niveles.js` muestra "Nivel N", la escalera hasta un nivel por encima del actual, descuento y prioridad vigentes (pasajero) o comisión y checklist de calidad (conductor).

## Despacho por olas (24 oct. 2026)
- **Olas:** 0/30/60/90 s con radios de 1,5/3/5 km y toda la zona (`nexa.despacho.*`, por calibrar en el piloto). La ola se calcula del tiempo transcurrido desde `solicitadoEn`; no hay estado ni job que la avance. El único job (`DespachoScheduler`, 5 s) detecta el cambio de ola para avisar a los clientes.
- **Posición del conductor:** solo en memoria (`UbicacionConductorService`), vence a los 45 s; no se escribe en Mongo en cada reporte. Con varias instancias del servidor habría que moverla a una colección con índice TTL.
- **Reporte:** cada 5 s si se movió ≥ 30 m y latido de 30 s. Un conductor en un viaje reporta `disponible=false` y no cuenta en "Avisamos a N".
- **Opción B (decidida):** sin posición vigente el conductor ve las solicitudes solo en la última ola. En web el navegador deja de reportar con la pantalla bloqueada; la app Flutter lo resolverá con servicio en segundo plano.
- **Privacidad:** el canal `/topic/servicios-disponibles` dejó de enviar la solicitud completa (nombre, teléfono, destino) a todos los conductores; ahora solo `{id, estado}` y cada cliente pide su lista filtrada.
- **Extra y conteo (24 oct. 2026):** una solicitud con extra voluntario va `nexa.despacho.olas-por-extra` olas (1) por delante, sin pasar de la última. En la última ola, "Avisamos a N" suma a los conductores disponibles cuya posición venció hace menos de `nexa.despacho.retencion-minutos` (10): siguen en línea y la ven por la opción B. `purgar()` ya no borra a los 45 s sino al terminar la retención.

## Calibración del despacho (24 oct. 2026)
- **Supuestos:** 10–40 conductores en línea en hora normal sobre ~80 km² urbanos de Cartagena (≈ 1 conductor cada 3 km²); moto a 25 km/h con factor de ruta 1,3, es decir ~3 min de recogida por km en línea recta.
- **Olas:** 0/25/50/75 s → 1,5/2,5/4/6 km (antes 0/30/60/90 s → 1,5/3/5 km/toda la zona). Con 25 conductores se avisa a ~2, ~6, ~15 y casi todos. Saltos de 25 s: con flota pequeña esperar más solo retrasa; quedan ~15 s para leer la tarjeta y decidir.
- **Tope de 6 km (≈ 19 min de recogida), decidido por el negocio:** la última ola ya no es toda la zona. Un conductor con posición a más de 6 km nunca ve la solicitud; uno sin posición vigente la sigue viendo en la última ola (opción B, distancia desconocida). `ola-radio-km` con 0 sigue significando toda la zona.
- **Medición:** al aceptar se guarda `olaAceptacion` y `distanciaRecogidaKm` en el `Servicio` (sin bloquear la aceptación si falla). `GET /api/admin/despacho/metricas?dias=7|30|90` (tarjeta "Despacho por olas" en el inicio del panel admin, `despacho-metricas.js`) da aceptadas por ola, medianas de tiempo y distancia, p90 del tiempo y % sin conductor (canceladas antes de aceptar o > 10 min sin conductor). Recalibrar con ≥ 30 viajes medidos.
- **Interacción con la prioridad del pasajero:** la ventana de prioridad (15–45 s, conductores ≥ 4,7) se aplica encima de la ola; un favorito a más de 1,5 km no ve la solicitud hasta la ola que lo cubre.

## Condonar deudas e historial de cargos (24 oct. 2026)
- **Condonar:** `POST /api/admin/deudas/{pasajeroId}/condonar` con `{motivo}` obligatorio (5–300 caracteres). Libera al pasajero sin cobrarle y deja en el `Servicio` la fecha, el correo del administrador y el motivo (`cargoCondonadoEn/Por`, `cargoMotivoCondonacion`). Es una salida distinta a "pagada": no llena `cargoPagadoEn`, así que no cuenta como recaudo. El borrado de la deuda es condicional a que siga siendo la misma deuda (409 si otro administrador ya la cerró).
- **Conductor:** condonar no cambia lo que ya se le reconoció (`cargoAcreditadoConductor`): lo absorbe la plataforma. Si el cargo no se le había reconocido (no hubo llegada verificada) tampoco se le acredita al condonar.
- **Panel admin:** botón "Condonar" junto a "Confirmar pago", modal con el motivo, filtro "Condonadas" y fila con quién la condonó y el motivo. `GET /api/admin/deudas` agrega `condonadas` (últimos 30 días).
- **Historial del pasajero:** `GET /pasajero/historial-cargos` (y `/api/pasajero/...`) lista hasta 50 cargos con estado PENDIENTE, PAGADO, CONDONADO o REGISTRADO; se muestra en Historial solo si hay alguno. Al pasajero se le muestra el motivo de la condonación, no el administrador que la autorizó.
- **Resuelto el 24 oct. 2026:** el canal de pago es el siguiente viaje y el pasajero recibe correo al condonarse (ver la sección siguiente).

## Deuda en el siguiente viaje y saldo del conductor (24 oct. 2026)
Decidido por el negocio: NEXA es solo efectivo, así que la deuda por cancelación se cobra con el próximo viaje.
- **Pasajero:** la deuda ya no bloquea. `POST /pasajero/cotizar` devuelve `deudaPendiente` y `totalAPagar`; el panel muestra "Deuda de una cancelación" y "Total en efectivo". Antes de pedir el viaje se le pregunta si acepta pagar el total; el cuerpo de `solicitar-viaje` lleva `aceptaDeuda: true`. Sin aceptarla, el servidor responde 402 con el monto y la app pregunta y reintenta. El desglose del pasajero (`DesglosePasajeroDto`) lleva `deudaAnterior` y `totalAPagar`.
- **Servicio:** guarda `deudaPorCobrar` y `deudaServicioId` al pedirlo, y `deudaCobrada` al finalizar. `DeudaService.cobrarEnViaje` quita la deuda con un update condicional a que siga siendo la misma (si un admin la cobró o condonó entre tanto, cobra 0) y marca el cargo original como pagado con método `COBRADO_EN_VIAJE`. Cancelar el viaje nuevo no cobra la deuda: sigue pendiente.
- **Conductor:** ve un solo monto, "Cobra al pasajero en efectivo" (`DesgloseConductorDto.cobrarAlPasajero` = total del pasajero + deuda cobrada), sin saber que lleva deuda. Su comisión y ganancia salen solo de la tarifa del viaje.
- **Admin:** ve el desglose real: el cargo original aparece pagado con `COBRADO_EN_VIAJE` y la nota del viaje que lo cobró, y en "Saldo de los conductores" la columna "Deudas cobradas".
- **Saldo del conductor:** `SaldoConductorService` (no es una cuenta con movimientos; se calcula de los viajes del periodo). Saldo = efectivo recibido (total del pasajero + deuda cobrada) − ganancia del conductor − cargos de cancelación reconocidos. Positivo: el conductor le debe a NEXA; negativo: NEXA le debe a él. `GET /conductor/saldo` y `/api/conductor/saldo` (Billetera) y `GET /api/admin/conductores/saldos` (sección Deudas del admin), con `dias` de 1 a 365.
- **Correos:** al registrarse una deuda (se cobrará con el próximo viaje), al condonarse, y el aviso de bajar de nivel. Un correo que falla nunca tumba la operación.
- **Pendiente:** registrar cuándo el conductor le entrega a NEXA lo que le debe (hoy el saldo solo se calcula, no se liquida).

## Punto de recogida elegido por el pasajero (24 oct. 2026)
- La posición del pasajero sigue saliendo de su GPS. El punto de recogida arranca ahí y él puede moverlo arrastrando el pin o tocando el mapa (como Uber), con un círculo punteado del radio permitido y "Volver a mi ubicación".
- El pin se acerca al borde si se suelta más lejos de `nexa.recogida.radio-max-metros` (300 m) y se pega a la calle más cercana con OSRM `/nearest` si el ajuste es de 120 m o menos (si es mayor, se respeta lo marcado). Si el pasajero camina y el punto queda fuera del radio, se trae al borde.
- `solicitar-viaje` lleva `ubicacionPasajero`; `PuntoRecogida.exigirCerca` responde 400 si el punto de recogida está a más de 300 m. Un cliente que no la envíe (app antigua) no se valida.

## Modelo de satisfacción (Weka J48) con las tarifas v2.2 (24 oct. 2026)
- El reentrenamiento (`POST /api/admin/ml/entrenar`, botón del panel ML, con CSRF para la sesión web) usa solo viajes finalizados desde la fecha del marcador `niveles-v2.2` en `migraciones`, con la tarifa que pagó el pasajero (`desglose.totalPasajero`). Lee solo los campos necesarios (máx. 50.000 viajes) en vez de cargar la colección completa.
- Con menos de 30 viajes calificados no se reentrena y se conserva el modelo anterior. **El reentrenamiento hay que hacerlo en producción** cuando haya datos suficientes: desde aquí no hay acceso a la base real.

## Seguimiento del pasajero hasta la recogida

- **Qué se comparte y con quién:** solo la posición del pasajero, solo con el conductor asignado y solo entre que acepta y que inicia el viaje. Después se deja de pedir y se descarta. No se guarda en Mongo ni queda en el historial del servicio.
- **Por qué consulta (polling) y no WebSocket:** los topics STOMP los puede escuchar cualquier usuario autenticado; la ubicación de una persona no debe depender de que nadie adivine un id. El GET valida que el viaje es del conductor. Si más adelante se quiere push, hay que autorizar la suscripción por usuario.
- **Vigencia de 30 s:** una posición más vieja se oculta ("sin señal") en vez de mostrarla como actual. El navegador del pasajero reenvía su última posición cada 10 s aunque esté quieto, así que un pasajero con la app abierta nunca se ve vencido; con la pantalla apagada sí.
- **El punto de recogida no se mueve:** el conductor va al pin que el pasajero fijó al pedir el viaje. El seguimiento solo le dice si el pasajero está cerca de él. Mover el pin con el viaje ya aceptado queda como decisión aparte (cambiaría la distancia y la tarifa).
- **Pendiente:** al estar en memoria, con más de una instancia del servidor hay que pasarlo a una colección con índice TTL. Una aplicación móvil nativa reportaría con la pantalla bloqueada; la web no.

## Qué ve cada rol (privacidad)

- **Calificaciones:** cada uno ve solo la que él puso (nota y comentario). El pasajero no ve lo que le puso el conductor y viceversa. Se filtra en el servidor (también por WebSocket), no solo en la pantalla.
- **Comisión:** el conductor no ve su monto en ninguna parte: ni en el resumen final, ni en Ingresos, ni en la billetera, ni en el saldo. Tampoco la tarifa bruta, porque con la ganancia permitiría calcularla. Sí ve el porcentaje de su nivel dentro de los beneficios de niveles (es lo que gana al subir) y su ganancia por viaje.
- **Deuda del pasajero:** el conductor ve un solo monto a cobrar. Ese monto ya incluye la deuda y no se explica; el detalle lo ven el pasajero (la suya) y el administrador.
- **Saldo del conductor:** ve efectivo cobrado, ganancias, cargos a su favor y saldo con NEXA. Es el dinero que debe entregar, no se desglosa en comisión ni en deudas.
- **Límite conocido:** quien reste el monto cobrado menos su ganancia en un viaje sin deuda obtiene la comisión. Ocultar eso del todo exigiría no mostrarle una de las dos cifras, y necesita ambas para operar.

## Finalizar en cualquier tramo y llegada a 50 m (2026-10-26)
- **Regla de oro:** el viaje lo finaliza siempre el conductor, en cualquier momento del viaje en curso (antes solo a ≤150 m del destino). El pasajero nunca finaliza: solo ve la advertencia.
- **Cobro si no llegó al destino:** con menos de la mitad de la distancia cotizada recorrida (recorrido real por GPS) se cobra la mitad del viaje; desde la mitad, el viaje completo. Implementación: se factura `distanciaKM × fracción` por el modelo normal (banderazo y mínima siguen aplicando, así que la mitad de la distancia no es exactamente la mitad del precio). El extra voluntario va completo al conductor. Si el servidor perdió el recorrido (reinicio) se estima con la línea recta recogida→posición × factor de ruta; sin posición ni recorrido, se cobra completo.
- **Llegué:** radio de 50 m (`nexa.llegada.radio-metros`) y el cliente usa la posición que ya sigue en vez de pedir otra al navegador.
