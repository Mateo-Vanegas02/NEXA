# Fase 3.2 — Cierre de integridad, seguridad y preparación para producción

Fecha de cierre: 17 de noviembre de 2026. Rama: `codex/fase-3-validacion`. Este documento resume **solo lo nuevo**
de la fase 3.2; el detalle operativo vive en dos anexos:

- [`FASE3_2_INDICES_Y_RESPALDO.md`](FASE3_2_INDICES_Y_RESPALDO.md): inspección de producción, índices, respaldo,
  restauración de ensayo y correcciones de datos.
- [`FASE3_2_SECRETOS.md`](FASE3_2_SECRETOS.md): auditoría de secretos del repositorio.

## Estado en una línea

El código corregido está en la rama, con CI en verde, y **no se ha desplegado**. En la base de producción se
aplicaron, con aprobación explícita del propietario y respaldo verificado, correcciones de datos e índices; la
versión que hoy sirve producción en Azure no cambió.

## Evidencia

- CI de la rama en verde: [ejecución 44050244805](https://github.com/Mateo-Vanegas02/NEXA/actions/runs/44050244805)
  (commit `8ed9391`). Jobs: `test` (603 pruebas Java), `mongo-integration` (24 pruebas con MongoDB 7 en réplica,
  Testcontainers), `mongo-local-replica` (Mongo de `docker-compose` con transacción real y los 5 scripts de
  `scripts/atlas/` sobre datos sintéticos), `docker` y `Secret scan` (Gitleaks).
- Pruebas JavaScript: 123 sin fallos (`node --test src/test/js/*.test.mjs`).
- Al empezar la fase había 11 pruebas de integración y 572 unitarias; las 13 de integración y 31 unitarias nuevas
  cubren las correcciones de esta tabla.

## Problemas, soluciones y estado

Estados: **Verificado** = corregido y con prueba ejecutada en CI; **Aplicado** = operación de datos hecha en
producción y comprobada con una inspección posterior; **Pendiente** = depende de una decisión o acceso del
propietario.

| # | Problema | Archivo y método | Solución | Prueba ejecutada | Estado | Riesgo restante |
|---|---|---|---|---|---|---|
| 1 | Los avisos de cada transición esperaban hasta 5 s al barrido | `AvisosPendientesService.registrar` | Envío tras el commit (`afterCommit`) en el executor `avisosExecutor`; el barrido queda de respaldo | Unitarias + integración (commit envía, rollback no) | Verificado (`f1faba0`) | — |
| 2 | Envíos FCM/SMTP en el hilo único de `@Scheduled`; SMTP sin límite de tiempo: podían frenar el despacho por olas | `AvisosPendientesService.procesar`, `application.properties` | Executor propio, `spring.task.scheduling.pool.size=3`, timeouts SMTP 5/10/10 s | Unitaria: el barrido vuelve sin esperar un envío colgado | Verificado (`f1faba0`) | `avisosExecutor` desactiva el executor por defecto de Spring Boot; hoy nada lo usa |
| 3 | El Mongo de `docker-compose` no era réplica: las transacciones fallaban en local | `docker-compose.yml` | Replica set `rs0` de un nodo; `.env.example`, README y `CLAUDE.md` | CI levanta ese Mongo y ejecuta una transacción | Verificado (`f1faba0`) | El `docker compose` completo con la app no se probó |
| 4 | Un trabajador con el bloqueo vencido podía pisar el aviso tomado por otro | `AvisosPendientesService.despachar` | `lease` (UUID) por reclamación; toda escritura final lo exige | Integración: reclamación simultánea, bloqueo vencido, recuperación tras caída | Verificado (`0b59822`) | — |
| 5 | Reintentos infinitos y push repetido a quien ya lo recibió | `despachar`, `AvisosService.ejecutarConfirmado`, `NotificadorPushFcm.enviarConConfirmacion` | Tope de 8 intentos → `FALLIDO`; STOMP una vez; reintento solo de tokens fallidos | Integración: `FALLIDO` y reintento parcial | Verificado (`0b59822`) | Entrega al menos una vez: la app debe descartar `eventoId` repetidos (sin verificar) |
| 6 | El barrido de respaldo nunca recogía nada (proyección sobre un `record`); introducido en el ítem 1 | `AvisosPendientesService.procesar` | Lee los ids como documento crudo | Integración: recuperación tras caída | Verificado (`6a5ba39`) | — |
| 7 | Una deuda podía confirmarse dos veces, condonarse tras cobrarse o borrarse otra nueva | `DeudaService.confirmarPago`, `condonar`, `cobrarEnViaje`, `registrar` | Escrituras condicionadas a `deuda.servicioId` y cargo abierto, en transacción; 409 si cambió; el panel del admin envía el `servicioId` que ve (campo opcional) | 6 de integración: pagos simultáneos, pago vs condonación, cobro en viaje vs admin, deuda cambiada, reversión, pago repetido | Verificado (`30a9f80`) | — |
| 8 | `ServicioService` exponía calificar sin usuario; el formulario web confiaba en el rol del parámetro (500 si no coincidía) | `ServicioService.calificarServicio`, `ControllerRating.calificarServicio` | Un único método público con el usuario autenticado (401/403); rol desde Spring Security | 11 unitarias (propio, ajeno, cambio de rol, sin sesión, cancelado, repetido, contrato) | Verificado (`7016b52`) | La prueba MockMvc completa sigue omitida (necesita Mongo) |
| 9 | Un conflicto entre transacciones (`WriteConflict`) llegaba como 500 | `EjecutorTransacciones` (nuevo) en las 7 operaciones de viaje y deuda | Hasta 3 reintentos; si persiste, 409 | Unitarias + carrera real repetida 5 veces | Verificado (`755261a`) | — |
| 10 | En `finalizarServicio` un fallo de niveles podía revertir el viaje entero; un fallo del cobro de deuda se absorbía | `ServicioServiceImpl.finalizarServicio` | Crítico en la transacción (estado, fracción, recorrido, deuda, aviso); niveles/XP después del commit con reproceso | Unitarias | Verificado (`755261a`) | — |
| 11 | La tarifa definitiva ya no se guardaba (regresión de fase 3) y el reproceso hacía `save()` del viaje completo | `ServicioRepository.guardarResultadoNiveles`, `NivelesService.reprocesarPendientes` | Se guarda `tarifa` con el desglose; el reproceso usa la escritura parcial | Unitaria | Verificado (`755261a`) | Sin impacto en datos: la versión con la regresión nunca se desplegó |
| 12 | Dos conductores podían registrar la misma moto | `AuthService.registrarConductor`, `RegistroConductorService.registrar`, `VehiculoConductorService.agregar` | Regla del propietario: una moto, un conductor; se valida contra `Usuarios` y `documentos_conductor` | Unitarias + integración | Verificado (`3aae0e9`) | — |
| 13 | `Usuarios` y `servicios` sin índices en producción | `scripts/atlas/indices-propuestos.js` | I1–I9, cada uno ligado a su consulta; ensayados en copia restaurada (COLLSCAN → IXSCAN) | Script probado en CI; inspección antes/después en la copia | Aplicado | — |
| 14 | 3 viajes EN_CURSO atascados ~6 meses; 2 tokens de recuperación en texto claro; 5 colecciones sin uso; 2 conductores de prueba con la misma tarjeta | `scripts/atlas/correcciones-datos-fase3-2.js`, `rechazar-conductores-prueba.js` | Cancelados sin cargo; campos borrados; colecciones archivadas por renombre; cuentas de prueba rechazadas y tarjeta liberada (todo reversible) | Scripts probados en CI; inspección posterior en producción | Aplicado | Placa de la moto de una cuenta de prueba sigue ocupada |
| 15 | Secretos en el repositorio | — | Gitleaks sobre todo el historial y búsquedas propias: ninguna credencial de servidor; `.gitleaksignore` para el valor ficticio de CI | `Secret scan` en verde | Verificado | Revisar el informe público de Power BI y las restricciones de la clave de Firebase |

## Pendiente (requiere decisión, acceso o infraestructura)

1. **Despliegue.** Nada de la rama está en producción. Antes de desplegar: revisar y fusionar el PR, configurar
   `MONGODB_URI` con un usuario propio (no el que quedó expuesto) y desplegar con la base ya indexada.
2. **Política de correo.** Sin duplicados hoy, pero 5 correos tienen mayúsculas o espacios. Decidir unicidad
   global o por rol, normalizar al guardar y crear el índice único.
3. **App móvil.** Verificar que descarta avisos con `eventoId` repetido (la entrega es al menos una vez).
4. **Proveedores.** Restringir la clave de Firebase Android; confirmar qué expone el informe público de Power BI.
5. **Credenciales temporales.** Confirmar que se cambió la contraseña de `nexa-web`, que se eliminaron
   `nexa-lectura` y `nexa-mantenimiento` y que se borró `motvirsweb_copia`; guardar el respaldo fuera del equipo.
6. **Riesgos heredados que siguen abiertos** (detalle en `RIESGOS_PENDIENTES.md`): revocación de JWT, CSP,
   paginación de listados del admin, STOMP y límite de peticiones por instancia.

## Propuesta de consolidación de la documentación (no ejecutada)

`docs/auditoria/` tiene 27 archivos cortos, varios repetidos por fase. Propuesta para una próxima limpieza, sin
borrar historia (los archivos antiguos se mueven, no se eliminan):

| Destino | Contenido | Origen |
|---|---|---|
| `README.md` (índice) | Qué hay en la carpeta y en qué orden leerlo | nuevo |
| `ESTADO_ACTUAL.md` | Riesgos abiertos y plan vigente, una sola lista | `RIESGOS_PENDIENTES.md`, `PLAN_REMEDIACION.md` |
| `FASE3_2.md` + anexos | Cierre vigente (este documento) | — |
| `DISENOS/` | Decisiones técnicas que siguen vigentes | `DISENO_JWT.md`, `ESTRATEGIA_CSP.md`, `MIGRACION_IDENTIDAD.md`, `INDICES_CONDUCTOR.md`, `ROTACION_SECRETOS.md` |
| `historico/` | Registro de fases anteriores, sin cambios | `AUDITORIA_INICIAL.md`, `CAMBIOS_REALIZADOS.md`, `PRUEBAS_Y_RESULTADOS.md`, `FASE3_*.md`, `FASE3_1_*.md` |
