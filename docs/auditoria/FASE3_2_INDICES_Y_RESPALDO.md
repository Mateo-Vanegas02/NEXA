# Fase 3.2 — Índices de producción y respaldo (preparación, sin aplicar)

Estado: **nada se aplicó en Atlas.** Este documento y los scripts de `scripts/atlas/` preparan la inspección, la
propuesta de índices y el respaldo. La inspección de solo lectura ya se ejecutó en producción; sus resultados están
en la sección 1.1.

## 1. Inspección en solo lectura

`scripts/atlas/inspeccion-solo-lectura.js` (mongosh). Requiere un usuario de Atlas con el rol **read** sobre
`motvirsweb` (Database Access → Add New Database User → Built-in Role "Only read any database", o un rol personalizado
de solo lectura sobre esa base).

```bash
mongosh "mongodb+srv://<cluster>/" --username <usuario-lectura> \
  --eval 'var BASE="motvirsweb"' --file scripts/atlas/inspeccion-solo-lectura.js > inspeccion.json
```

Informa, solo como cifras agregadas: versión y topología (si admite transacciones), índices reales de las 18
colecciones, tipos BSON de los campos que se consultan, duplicados de correo (exacto, normalizado, por rol y entre
roles), licencia/SOAT/tarjeta (duplicados, ceros, tipos, presencia fuera de conductores), tokens de recuperación,
deudas y su coherencia con el cargo del viaje, viajes abiertos o atascados, cargos pagados y condonados a la vez,
duplicados que impedirían los índices únicos de `xp_eventos` y `dispositivos`, y el plan de ejecución de las
consultas frecuentes (S1–S8, U1–U2). Lee desde un secundario cuando existe. No imprime correos, nombres, teléfonos,
números de documento, tokens ni ids.

Verificación: CI lo ejecuta sobre datos sintéticos en el Mongo de `docker-compose`, compara el `dbHash` de la base
antes y después (no escribe) y comprueba las cifras y que la salida no contenga ningún dato sembrado
(`scripts/atlas/prueba/`).

## 1.1 Resultados de la inspección de producción (17 de noviembre de 2026)

Ejecutada por el propietario con un usuario de solo lectura (`nexa-lectura`). La salida no contenía correos, nombres
ni ids. Cifras relevantes:

- **Servidor:** MongoDB 8.0.37, replica set de 3 nodos: **admite las transacciones** que usa esta versión.
- **Índices existentes:** `Usuarios` y `servicios` solo tienen `_id_`. Ya existen, creados por `NivelesIndices` en
  algún arranque anterior, `xp_eventos.viaje_rol_motivo_unique_idx` (único), `dispositivos.token` (único) y el TTL de
  48 h de `acciones_idempotentes`; sin duplicados en `xp_eventos` ni en `dispositivos`.
- **Usuarios (54: 30 pasajeros, 23 conductores, 1 admin):** sin correos duplicados, ni exactos ni normalizados ni
  entre roles; 5 correos con mayúsculas o espacios. Licencia: sin duplicados, tipos `int` (18) y `long` (5), sin
  ceros. SOAT: sin duplicados, un cero. **Tarjeta de propiedad: un grupo de 2 conductores con el mismo número.**
- **Tokens de recuperación:** ninguno con el formato actual (hash); **2 cuentas conservan el campo antiguo del token
  en texto claro**, ambos vencidos.
- **servicios (610):** 573 finalizados, 34 cancelados, **3 EN_CURSO con más de un día** (2 de ellos del mismo
  conductor); ningún SOLICITADO abierto. `pasajero._id` es ObjectId en todos; `conductor._id` falta en 16 (cancelados
  antes de aceptarse); `canal` falta en 603 (la app los trata como WEB); `solicitadoEn` falta en 75 (viajes anteriores
  a niveles). Una deuda vigente, coherente con su cargo abierto.
- **Planes:** las 10 consultas medidas hacen `COLLSCAN`; con estos volúmenes tardan 0–1 ms. Los índices son
  preparación para el crecimiento, no una urgencia de rendimiento.

Consecuencias para la propuesta:

| Índice | Decisión con los datos reales |
|---|---|
| I1–I4, I8, I9 | Viables: no dependen de los datos. Aplicar tras el respaldo verificado. |
| I5 licencia, I6 SOAT | Viables: sin duplicados. El índice compara números aunque haya `int` y `long` mezclados; el SOAT en 0 queda fuera del filtro parcial. |
| I7 tarjeta de propiedad | **Bloqueado**: hay 2 conductores con la misma tarjeta. Puede ser legítimo (dos conductores de la misma moto), así que primero hay que decidir si la tarjeta debe ser única por conductor. Hoy los vehículos viven además en la colección `Vehiculos`. |
| Correo único | **Técnicamente posible hoy** (sin duplicados). Antes de crearlo, decidir la política (global o por rol) y normalizar los 5 correos con mayúsculas o espacios; si no, el índice no impide registrar el mismo correo con otras mayúsculas. |

Hallazgos de datos que piden una decisión del propietario (correcciones de datos, no índices; no se ejecutaron):

1. **3 viajes EN_CURSO atascados desde hace más de un día.** Bloquean el cierre de sesión de sus conductores y
   pasajeros (`BloqueoCierreSesionFilter`) y uno de los conductores tiene dos viajes activos a la vez. Hay que
   decidir si se finalizan o se cancelan, con la misma lógica de cobro que en la app.
2. **2 tokens de recuperación antiguos en texto claro** (vencidos). La versión actual no los lee, pero conviene
   borrar ese campo (`$unset`) tras el respaldo.
3. Colecciones de funciones retiradas o con nombres antiguos (`Servicio`, `Vehiculo`, `creditos_nexa`,
   `beneficios_uso`, `ModeloInfo`): candidatas a archivarse cuando se confirme que ninguna versión desplegada las usa.

## 2. Hallazgos del código que condicionan los índices

- **`auto-index-creation` está apagado (bien) y no debe activarse.** `Conductor` declara `@Indexed(unique = true)` en
  `licencia`, `soat` y `tarjeta_de_propiedad`, sin filtro parcial. Como pasajeros, conductores y admins comparten
  `Usuarios`, esos índices tratarían como duplicado a todo documento sin ese campo: la creación fallaría o, peor,
  bloquearía registros. Los índices de documentos deben ser **parciales** (`rol: CONDUCTOR` y valor > 0), como los
  que ya prueba `Phase3MongoIntegrationTest`.
- **`NivelesIndices` crea índices al arrancar** (en producción ya existen y sin duplicados, ver 1.1) (`xp_eventos` único `(viajeId, rol, motivo)`, `dispositivos.token`
  único, TTL de 48 h en `acciones_idempotentes`). El primer arranque de esta versión contra `motvirsweb` los creará
  sin pasar por este procedimiento. Si `xp_eventos` tiene duplicados, el índice único falla (queda en el log) y el XP
  deja de ser idempotente sin que nadie lo note. **Antes del primer despliegue** hay que ejecutar la inspección y
  confirmar `xp_eventos.duplicadosViajeRolMotivo.grupos = 0` y `dispositivos.duplicadosDeToken.grupos = 0`.
- **Cada petición con JWT consulta `Usuarios` por correo** (`JwtAuthFilter` → `CustomUserDetailsService.findByEmail`).
  Sin índice en `email`, cada llamada de la app recorre la colección.
- El correo no se normaliza al guardar ni al buscar: `Ana@x.com` y `ana@x.com` son cuentas distintas para la app.
  Un índice único global de correo es una **decisión de negocio** pendiente (fase 2, `MIGRACION_IDENTIDAD.md`); aquí
  solo se propone el índice no único que acelera la búsqueda.

## 3. Índices propuestos

Cada uno nace de una consulta concreta del código. `scripts/atlas/indices-propuestos.js` los aplica en este orden y,
para los únicos, verifica antes que no haya duplicados (si los hay, no lo crea y lo informa).

| Id | Colección y clave | Opciones | Consulta que lo justifica (archivo · método) | Frecuencia | Prerrequisito |
|---|---|---|---|---|---|
| I1 | `servicios {estado: 1, fechaFinalizacion: 1}` | — | `DespachoScheduler.revisar` y `ServicioServiceImpl.obtenerServiciosDisponibles` → `findByEstado(SOLICITADO)` (S1); `NivelesService.reprocesarPendientes` → `findPendientesDeNiveles` (S6); `SaldoConductorService.consulta` (FINALIZADO + fecha) | Cada 5 s (despacho) y cada 20 s por conductor conectado | Ninguno |
| I2 | `servicios {"pasajero._id": 1, estado: 1}` | — | `BloqueoCierreSesionFilter` → `existsByPasajeroIdAndEstadoIn` (S2); `solicitarViaje` → `existsByPasajeroIdAndEstado`; `solicitud-activa`, `viaje-en-camino`, `SeguimientoPasajeroService` → `findByPasajeroIdAndEstado`; `DeudaService.historialDe` | En cada sondeo del pasajero y en cada cierre de sesión | `pasajero._id` como ObjectId en todos los documentos (`tipos["pasajero._id"]`) |
| I3 | `servicios {"conductor._id": 1, estado: 1}` | — | `viaje-activo`, historial y ganancias → `findByConductorIdAndEstado` (S3); `existsByConductorIdAndEstadoIn`; `VehiculoConductorService` | En cada recarga del panel del conductor | `conductor._id` como ObjectId |
| I4 | `Usuarios {email: 1}` | no único | `JwtAuthFilter`/`CustomUserDetailsService` → `findByEmail` (U1); `existsByEmail` en registro | **En cada petición con JWT** | Ninguno |
| I5 | `Usuarios {licencia: 1}` | único, parcial `{rol: "CONDUCTOR", licencia: {$gt: 0}}` | `AuthService.registrarConductor` → `existsByRolAndLicencia` + `DuplicateKeyException` | Registro | `usuarios.licencia.duplicadosMayoresQueCero.grupos = 0` y tipos solo `long`/`int` (un valor guardado como texto queda fuera del filtro y escapa a la unicidad) |
| I6 | `Usuarios {soat: 1}` | único, parcial `{rol: "CONDUCTOR", soat: {$gt: 0}}` | `existsByRolAndSoat` | Registro | Igual que I5 con `soat` |
| I7 | `Usuarios {tarjeta_de_propiedad: 1}` | único, parcial | Registro de conductor (`Conductor.tarjeta_de_propiedad`) | Registro | Igual que I5 |
| I8 | `avisos_viaje_pendientes {estado: 1, proximoIntento: 1}` | — | `AvisosPendientesService.procesar` (barrido) | Cada 5 s | Ninguno (colección nueva) |
| I9 | `avisos_viaje_pendientes {enviadoEn: 1}` | TTL 7 días | Retención de avisos ENVIADO | — | Ninguno |

I8 e I9 los puede crear la propia app con `nexa.avisos-pendientes.crear-indices=true`; mientras no se apruebe, el
valor por defecto es `false`.

**Evaluados y no propuestos por ahora** (colecciones pequeñas o consultas raras de administración; revisar con los
planes S4, S5, S7, S8 y U2 de la inspección cuando crezcan los datos):

- `servicios {"conductor._id": 1, fechaHora: 1}` (`NivelesService.calidad` → `findResumenDeCalidad`, S4): I3 ya
  reduce la búsqueda al conductor; crear solo si S4 sigue examinando muchos más documentos de los que devuelve.
- `servicios {"pasajero._id": 1, fechaCancelacion: -1}` parcial `cargoCancelacion > 0` (historial de cargos, S5).
- `servicios {solicitadoEn: 1}` (métricas del despacho del admin, S7).
- `servicios {cargoPagadoEn: -1}` y `{cargoCondonadoEn: -1}` (listados del admin, S8).
- `Usuarios {"deuda.servicioId": 1}` parcial (`listarDeudores`, U2), `{rol: 1, estadoValidacion: 1}` (conteos del
  panel): con 54 usuarios no compensan el costo de escritura.
- `servicios {"pasajero._id": 1, fechaHora: 1}`: `findByPasajeroIdAndFechaHoraBetween` existe en el repositorio
  pero ningún código lo usa.
- Índice **único** de correo (global o por rol): pendiente de la decisión de identidad y de normalizar los correos.

## 4. Cómo medir cada índice (planes de ejecución)

La sección `planes` de la inspección muestra, por consulta, las etapas del plan ganador, documentos y claves
examinados, devueltos y milisegundos. Criterio: antes del índice se espera `COLLSCAN` con `docsExaminados` ≈ total
de la colección; después, `IXSCAN(<nombre>)` con `docsExaminados` cercano a `devueltos`. Se compara en la copia
restaurada antes y después del paso 5.4; si un índice no cambia su plan, no se crea en producción.

## 5. Respaldo, restauración y reversión

Ningún cambio en producción sin un respaldo **restaurado y verificado** (no basta con tener el archivo).

### 5.1 Elegir el método según el nivel del clúster

- **Free (antes M0):** sin Cloud Backups; respaldo lógico con `mongodump`/`mongorestore`.
- **Flex:** Atlas toma snapshots diarios automáticos (sin snapshot a demanda); además, `mongodump` antes del cambio.
- **M10 o superior:** snapshot a demanda desde Atlas (Backup → Take Snapshot Now) y restauración a un clúster nuevo.

En todos los casos se recomienda el `mongodump` del paso 5.2: es portátil y permite restaurar en local.

### 5.2 Respaldo lógico

Requiere MongoDB Database Tools y el usuario de solo lectura del paso 1.

```bash
fecha=$(date +%F)
mongodump --uri "mongodb+srv://<cluster>/motvirsweb" --username <usuario-lectura> \
  --readPreference=secondaryPreferred --gzip --archive="motvirsweb-$fecha.archive.gz"
sha256sum "motvirsweb-$fecha.archive.gz" > "motvirsweb-$fecha.sha256"
```

Guardar el archivo y su hash fuera del equipo (almacenamiento cifrado). Contiene datos personales: no subirlo al
repositorio ni a chats.

### 5.3 Verificar integridad y restaurar en un entorno aislado

```bash
sha256sum -c "motvirsweb-$fecha.sha256"
docker compose --profile local-db up -d mongo          # replica set rs0 local, sin acceso a Atlas
mongorestore --uri "mongodb://localhost:27017/?directConnection=true" --gzip \
  --archive="motvirsweb-$fecha.archive.gz" \
  --nsFrom='motvirsweb.*' --nsTo='motvirsweb_copia.*' --drop
mongosh "mongodb://localhost:27017/?directConnection=true" \
  --eval 'var BASE="motvirsweb_copia"' --file scripts/atlas/inspeccion-solo-lectura.js > copia.json
```

La copia es válida si `copia.json` coincide con `inspeccion.json` (paso 1) en el número de documentos por colección
y en las cifras agregadas (las diferencias solo pueden venir de escrituras ocurridas entre ambos momentos).

### 5.4 Ensayo sobre la copia

```bash
mongosh "mongodb://localhost:27017/?directConnection=true" \
  --eval 'var BASE="motvirsweb_copia"; var MODO="plan"' --file scripts/atlas/indices-propuestos.js
# resolver en la copia los duplicados que bloqueen un índice único y documentar cómo, luego:
mongosh "mongodb://localhost:27017/?directConnection=true" \
  --eval 'var BASE="motvirsweb_copia"; var MODO="crear"' --file scripts/atlas/indices-propuestos.js
mongosh "mongodb://localhost:27017/?directConnection=true" \
  --eval 'var BASE="motvirsweb_copia"' --file scripts/atlas/inspeccion-solo-lectura.js > copia-con-indices.json
```

Regresión: arrancar la app contra la copia (`MONGODB_URI=mongodb://localhost:27017/motvirsweb_copia?directConnection=true`,
perfil `dev`) y recorrer los flujos de registro, login web y app, pedir/aceptar/llegué/iniciar/finalizar/cancelar,
calificar, confirmar pago y condonar desde el admin; además `./mvnw clean install` y la integración con
`-Dexcluded.groups=none`. Comparar los planes de `copia-con-indices.json` con los de `copia.json` (sección 4).

**Ensayo hecho el 17 de noviembre de 2026** (opción B: base `motvirsweb_copia` en el mismo clúster, sin tocar
`motvirsweb`):

- `mongorestore` con `--nsFrom motvirsweb.* --nsTo motvirsweb_copia.*`: **2267 documentos restaurados, 0 fallidos**
  (la suma exacta de las 18 colecciones del respaldo) y los mismos índices que tenía producción.
- La inspección de la copia es **idéntica** a la de producción tomada antes de las correcciones (mismos conteos,
  tipos, duplicados e índices). El respaldo se puede restaurar completo.
- `indices-propuestos.js` en la copia: I1–I6, I8 e I9 creados; I7 bloqueado por la tarjeta repetida.
- Planes antes → después de los índices (documentos examinados):

| Consulta | Antes | Después |
|---|---|---|
| S1 `findByEstado(SOLICITADO)` | COLLSCAN, 610 | IXSCAN `estado_fechaFinalizacion`, 0 |
| S2 `existsByPasajeroIdAndEstadoIn` | COLLSCAN, 610 | IXSCAN `pasajero_estado`, 0 (1 clave) |
| S3 `findByConductorIdAndEstado` | COLLSCAN, 253 para 50 | IXSCAN `conductor_estado`, 50 para 50 |
| S4 `findResumenDeCalidad` | COLLSCAN, 253 para 50 | IXSCAN `conductor_estado`, 50 para 50 |
| S5 historial de cargos | COLLSCAN, 610 | IXSCAN `pasajero_estado`, 166 |
| S6 `findPendientesDeNiveles` | COLLSCAN, 610 | IXSCAN `estado_fechaFinalizacion`, 458 |
| U1 `findByEmail` | COLLSCAN, 54 | IXSCAN `email`, 0 |
| S7, S8, U2 | COLLSCAN | COLLSCAN (sin índice propuesto, como se esperaba) |

Cada índice propuesto cambia el plan de la consulta para la que se diseñó; ninguno sobra.

### 5.5 Aplicar en producción (solo con aprobación explícita)

Con el respaldo del día verificado y el ensayo aprobado:

```bash
mongosh "mongodb+srv://<cluster>/" --username <usuario-con-permiso-de-indices> \
  --eval 'var BASE="motvirsweb"; var MODO="crear"; var PRODUCCION_APROBADA="AAAA-MM-DD"' \
  --file scripts/atlas/indices-propuestos.js
```

El script se niega a escribir en `motvirsweb` sin `PRODUCCION_APROBADA`. Desde MongoDB 4.2 la construcción de
índices no bloquea la colección durante casi todo el proceso; con estos volúmenes tarda segundos. Un índice único
que encuentre duplicados no se crea y no modifica datos.

### 5.6 Reversión

```bash
mongosh "<uri>" --eval 'var BASE="motvirsweb"; var MODO="revertir"; var PRODUCCION_APROBADA="AAAA-MM-DD"' \
  --file scripts/atlas/indices-propuestos.js
```

Borra solo los índices de la lista (por nombre); los datos no cambian. Si un cambio de datos hecho para resolver
duplicados saliera mal, se restaura el respaldo del paso 5.2 sobre una base nueva y se compara antes de reemplazar.

### 5.7 Correcciones de datos aprobadas (17 de noviembre de 2026)

El propietario decidió: cancelar los viajes EN_CURSO atascados, borrar los campos antiguos del token de
recuperación después del respaldo y archivar las colecciones sin uso. `scripts/atlas/correcciones-datos-fase3-2.js`
lo hace en un solo paso, con los mismos modos y la misma guardia que el script de índices:

- Viajes EN_CURSO con más de 24 h desde la aceptación → `CANCELADO`, `canceladoPor: SISTEMA`, sin cargo, con
  `cancelacionAdministrativa` (fecha y motivo) para trazabilidad.
- `$unset` de `resetPasswordToken`, `resetPasswordTokenExpiry` y `usuario_reset_password_token`, y del vencimiento
  actual solo en cuentas sin token vigente con el formato nuevo.
- `Servicio`, `Vehiculo`, `creditos_nexa`, `beneficios_uso` y `ModeloInfo` → `archivo_20261117_<nombre>` (ninguna se
  usa en el código de este repositorio; reversible con `MODO="revertir-archivo"`).

Repetirlo no cambia nada más (idempotente). CI lo prueba en la base sintética: plan, guardia de producción, aplicar,
segunda pasada sin cambios y reversión del archivo.

**Aplicado en producción el 17 de noviembre de 2026** por el propietario, con un usuario temporal de escritura y
después de:

- Respaldo `mongodump` de las 18 colecciones en una carpeta fuera del repositorio, con huellas SHA-256 guardadas.
  `bsondump` leyó todos los archivos completos y los conteos coinciden con la inspección: `Usuarios` 54,
  `servicios` 610, `xp_eventos` 1483 y el resto. No se ensayó una restauración completa (sin Docker en ese equipo);
  queda pendiente antes de crear índices.
- Plan previo: 3 viajes atascados (unas 4377 h, unos 6 meses, desde la aceptación), 2 cuentas con token antiguo y
  5 colecciones (8 documentos).

Resultado: 3 viajes cancelados, 2 cuentas y 2 vencimientos limpiados, 5 colecciones archivadas. La inspección
posterior confirma: `servicios` 573 FINALIZADO y 37 CANCELADO, sin viajes abiertos ni conductores con varios
viajes activos; `conTokenAntiguoEnClaro` y `conTokenVencido` en 0; las colecciones `archivo_20261117_*` con los
mismos documentos (4, 3, 0, 0, 1); el resto de colecciones sin cambios y la deuda vigente sigue coherente.

## 6. Pendiente (requiere acceso o autorización del propietario)

1. ~~Crear el usuario de solo lectura y ejecutar la inspección~~: hecho el 17 de noviembre (resultados en 1.1).
   Borrar el usuario `nexa-lectura` cuando termine la fase si no se creó como temporal.
2. Con esas cifras, decidir la política de correo (único global o por rol) y cómo resolver duplicados.
3. ~~Respaldo y restauración~~: hechos y verificados el 17 de noviembre (restauración completa en
   `motvirsweb_copia`, 5.4).
4. Ensayo en la copia y aprobación de los índices (5.4–5.5).
5. ~~Confirmar que `xp_eventos` y `dispositivos` no tienen duplicados~~: confirmado el 17 de noviembre (0 grupos;
   los índices ya existen).
6. ~~Viajes atascados, tokens antiguos y colecciones sin uso~~: aplicado y verificado el 17 de noviembre (5.7).
   Tarjeta de propiedad: el propietario decidió que una moto solo puede tener un conductor (el código ya lo
   valida en el registro y al agregar vehículos). El par repetido son dos conductores aprobados con viajes,
   registrados con 7 meses de diferencia y sin fotos de documentos; puede ser un error de digitación o una moto
   que cambió de conductor (el SOAT se renueva cada año, así que un SOAT distinto no lo descarta). Un administrador
   debe confirmarlo con ambos; después se crea I7.
