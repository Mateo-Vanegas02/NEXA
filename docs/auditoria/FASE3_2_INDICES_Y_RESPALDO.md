# Fase 3.2 — Índices de producción y respaldo (preparación, sin aplicar)

Estado: **nada se aplicó en Atlas.** Este documento y los scripts de `scripts/atlas/` preparan la inspección, la
propuesta de índices y el respaldo. Las cifras reales de producción salen de ejecutar la inspección (paso 1) y aún no
se conocen; lo confirmado hasta hoy es lo que reportó Compass: base `motvirsweb`, 18 colecciones, `Usuarios` (54
documentos) y `servicios` (610) solo con el índice `_id_`.

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

## 2. Hallazgos del código que condicionan los índices

- **`auto-index-creation` está apagado (bien) y no debe activarse.** `Conductor` declara `@Indexed(unique = true)` en
  `licencia`, `soat` y `tarjeta_de_propiedad`, sin filtro parcial. Como pasajeros, conductores y admins comparten
  `Usuarios`, esos índices tratarían como duplicado a todo documento sin ese campo: la creación fallaría o, peor,
  bloquearía registros. Los índices de documentos deben ser **parciales** (`rol: CONDUCTOR` y valor > 0), como los
  que ya prueba `Phase3MongoIntegrationTest`.
- **`NivelesIndices` crea índices al arrancar** (`xp_eventos` único `(viajeId, rol, motivo)`, `dispositivos.token`
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

## 6. Pendiente (requiere acceso o autorización del propietario)

1. Crear el usuario de solo lectura y ejecutar la inspección (paso 1); compartir `inspeccion.json` tras revisarlo.
2. Con esas cifras, decidir la política de correo (único global o por rol) y cómo resolver duplicados.
3. Respaldo y restauración verificados (pasos 5.2–5.3).
4. Ensayo en la copia y aprobación de los índices (5.4–5.5).
5. Antes del primer despliegue de esta versión: confirmar que `xp_eventos` y `dispositivos` no tienen duplicados
   (los índices de `NivelesIndices` se crean al arrancar).
