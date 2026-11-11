# Discrepancias lógicas del modelo de datos

Hallazgos al pasar las 12 colecciones de MongoDB a una vista relacional ([`nexa_eer.png`](nexa_eer.png)). El diagrama no las marca; aquí
van numeradas. **Ninguno está aplicado**: son propuestas para decidir.

Gravedad: **Alta** = puede romper el sistema o corromper datos · **Media** = inconsistencia o deuda con riesgo · **Baja** = orden/estilo.

| # | Gravedad | Qué pasa | Propuesta |
|---|---|---|---|
| 7 | **Alta** | El índice único es `(email, rol)`, así que el mismo correo puede registrarse como pasajero **y** como conductor. Pero el login (`CustomUserDetailsService`), `PasswordResetService` y `UsuarioContextHelper` usan `findByEmail(email)` que devuelve un solo resultado: con dos documentos lanza `IncorrectResultSizeDataAccessException` y esa persona no puede entrar. | Opción A: índice único solo por `email` (un correo = un usuario, un rol). Opción B: mantener dos roles por correo y que el login pida el rol. A es más simple y es lo que ya asume el resto del código. |
| 3 | **Alta** | `Usuario.crearUsuario(CONDUCTOR)` asigna `licencia=0`, `soat=0`, `tarjeta_de_propiedad=0` y los tres tienen índice **único**: el segundo conductor que se registra antes de completar documentos choca con el primero. Además, esos índices están sobre la colección compartida `Usuarios` (donde pasajeros y admin no tienen el campo): un índice único no *sparse* trata los ausentes como `null` y solo admitiría uno. *No verificado contra la base real; depende de si Atlas tiene creados esos índices.* | Dejar los campos en `null` (no `0`) y declarar los índices como `sparse` o parciales por `rol = CONDUCTOR`. Revisar los índices reales en Atlas (`db.Usuarios.getIndexes()`). |
| 1 | Media | La relación Conductor–Vehículo (1:N) está guardada **tres veces**: `Conductor.vehiculos[]` (ids), `Vehiculo.conductorAsignado` (`@DBRef`) y `Vehiculo.conductor` (copia embebida con nombre y correo). Al registrar, `conductor.setVehiculos(List.of(...))` pisa la lista anterior. Las copias del nombre/correo quedan desactualizadas si el conductor cambia. | Una sola fuente de verdad: `Vehiculo.conductorId` (ObjectId). Eliminar `Conductor.vehiculos[]` y la copia embebida; consultar con `findByConductorId`. |
| 2 | Media | `soat` y `tarjeta_de_propiedad` son documentos **del vehículo** pero están en `Conductor`. Un conductor con dos vehículos solo puede tener un SOAT. | Moverlos a `Vehiculo` (`soat`, `tarjeta_propiedad`, únicos). Deja `licencia` en el conductor. |
| 4 | Media | `licencia` es `int`: un número de 10+ dígitos se desborda (máx. 2.147.483.647). `soat` y `tarjeta` ya son `Long`. | Pasar `licencia` a `Long` o a `String` (los documentos de identidad suelen tratarse como texto). |
| 5 | Media | Identificadores mezclados: `ObjectId` en usuarios y notas, `String` en vehículos, servicios, eventos, créditos y beneficios; referencias mezcladas: copia embebida (`Servicio.pasajero/conductor`), `@DBRef` (`Servicio.vehiculo`, `Vehiculo.conductorAsignado`), arreglos de `ObjectId` y correos. | Convención única: referencias por id (`ObjectId`) y copia embebida solo como *snapshot* explícito del viaje (nombre/placa al momento del servicio), nunca `@DBRef`. |
| 6 | Media | `auditoria_verificacion` se une al conductor y al admin por **correo** (`conductorEmail`, `adminEmail`), no por id. Si alguien cambia de correo se pierde el historial. | Agregar `conductorId` y `adminId` (ObjectId); conservar el correo solo como dato informativo. |
| 8 | Media | Datos derivados duplicados: `xpGanadoPasajero/Conductor` en `servicios` vs. suma de `xp_eventos`; `xpTotal`/`nivel` en el usuario (aceptable como caché, pero sin regla clara de cuál manda); copias de nombre/correo en `Servicio`. Ya se vio un fallo real de esta clase (XP en 0 al reintentar). | Declarar `xp_eventos` como fuente de verdad y el resto como caché recalculable; o quitar `xpGanado*` de `servicios`. |
| 12 | Media | Sin índices visibles en `servicios` (por `pasajero.id`, `conductor.id`, `estado`, `solicitadoEn`) aunque es la colección que más crece y la que más se consulta. *No verificado en Atlas.* | Añadir `@CompoundIndex` para las consultas reales; revisar con `explain()`. |
| 10 | Media | `tecnomecanicaId` (int) no apunta a ninguna entidad: es un número que escribe el usuario en el registro (`Integer.parseInt`). El nombre sugiere una FK que no existe. | Renombrar a `numeroTecnomecanica` (String) o crear la entidad `Tecnomecanica` con vigencia si se quiere controlar vencimiento. |
| 9 | Baja | Nombres inconsistentes: `nombre_y_Apellido`, `ntelefono` (Long), `tarjeta_de_propiedad` (snake_case) en Conductor frente a `nombreCompleto`, `telefono` (String) en Pasajero. Colecciones: `Usuarios`, `Vehiculos`, `NotasAdmin` (Pascal) frente a `servicios`, `xp_eventos` (snake). | Unificar a camelCase (`nombreCompleto`, `telefono` String) y nombres de colección en minúscula. Requiere migrar documentos existentes (`$rename`). |
| 11 | Baja | El rol está duplicado: campo `rol` y discriminador `@TypeAlias` (`_class`). Pueden contradecirse. | Mantener `rol` como único criterio de negocio (ya lo usan las consultas) y tratar `_class` solo como detalle técnico. |
| 13 | Baja | `NotaAdmin` no registra quién la escribió (`autorId`). Con varios admins no hay trazabilidad. | Agregar `autorId`. |

## Orden sugerido

1. **#7 y #3** (rompen cosas hoy): primero verificar en Atlas qué índices existen realmente.
2. **#1, #2, #4**: un solo cambio coordinado de `Conductor`/`Vehiculo`, con script de migración.
3. **#6, #8, #12**: aditivos (campos e índices nuevos), sin riesgo para datos actuales.
4. **#5, #9, #10, #11, #13**: limpieza; conviene hacerla junto con una migración.

Todo cambio que toque campos existentes necesita un script de migración y copia previa de la base; ninguno se aplica sin confirmación.
