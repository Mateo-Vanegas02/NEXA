# Rediseño móvil de NEXA: informe para continuar

Estado al 22 nov. 2026, 01:06 (hora de Bogotá). El trabajo quedó pausado a petición de Mateo.

Repositorio: `github.com/Mateo-Vanegas02/NEXA`.
- Rama `app`: app Flutter en `mobile/` y modelo ML en `ml/`.
- Rama `main`: backend Spring Boot 3.4 / Java 21. **Un merge a `main` despliega a producción en AWS.**

Instrucciones del proyecto: `CLAUDE.md`, `.claude/skills/nexa-flutter/SKILL.md`, `mobile/docs/DECISIONES.md`. Las reglas principales:
- Textos y código en español. Commits con Conventional Commits.
- Solo tokens de diseño: `NexaColors`, `Sp`, `Rad`, `Sizes`, `NexaShadows`, `NexaTexto`.
- El servidor decide el negocio (precio, XP, ETA, rutas); la app no lo calcula.
- Los archivos generados se versionan: freezed (`*.freezed.dart`, `*.g.dart`) y l10n (`lib/core/l10n/gen`).

---

## 1. Origen

1. Mateo pidió un rediseño visual completo de la app móvil (público, pasajero, conductor y admin), entregado en un video en español. El video ya se entregó (10:36 min).
2. Luego pidió llevar a código todo lo del video, con permiso para cambiar app y backend.
3. Problemas que había reportado el conductor tras probar la app en la calle:
   - El mapa no se podía poner claro u oscuro a elección.
   - El mapa era muy estático.
   - La ubicación del conductor se actualizaba lento: la moto avanzaba a saltos o se congelaba.
   - La ruta no se recalculaba cuando el conductor tomaba otras calles.
   - La ubicación del pasajero no se actualizaba.
   - Los marcadores del mapa eran feos.
   - Al cerrar el viaje salían mensajes contradictorios: «el pasajero canceló», «finalizado» y «aún no llegas».
4. Aclaración de Mateo: que el porcentaje de avance retroceda **no es un error**, porque el conductor volvía al punto de salida.

---

## 2. Pull requests abiertos

| PR | Rama → base | Contenido | Estado |
|---|---|---|---|
| **#6** | `feat/ruta-desde-posicion` → `main` | Backend de rutas en vivo (`POST`/`PUT /api/conductor/rutas/{servicioId}`) | Abierto; 617 pruebas `mvn test` en verde (local) |
| **#7** | `feature/flutter-rediseno-video` → `app` | App, fase 1: mapa en vivo | Abierto; CI verde |
| **#8** | `feat/admin-operacion` → `main` | Backend: `GET /api/admin/operacion` y `hora` en `/conductor/ingresos` | Abierto; 610 pruebas `mvn test` en verde (local) |
| *(sin PR aún)* | `feature/flutter-rediseno-pantallas` (sale de `feature/flutter-rediseno-video`) | App, fases 2 a 4: pantallas de pasajero, conductor y admin | Subida; **la CI del último commit (`bc5f25f`) seguía corriendo** |

Orden sugerido de merge:
1. #6 y #8 a `main`. Son independientes entre sí.
2. #7 a `app`.
3. El PR de `feature/flutter-rediseno-pantallas`. Ábrelo con base `feature/flutter-rediseno-video`, o con base `app` cuando #7 ya esté unido.

---

## 3. Lo que ya está hecho

### 3.1 Backend (PR #6): rutas en vivo
- `ProveedorRutas.alternativas` y `RutaOsrm.alternativas`: OSRM con `alternatives=2`, sin caché, `parsearTodas`.
- `ServicioRepository.cambiarRutaEnCurso`: actualización atómica de `rutaGeometria`, solo si el viaje está `EN_CURSO` y es de ese conductor.
- `RutaEnVivoService`:
  - Ofrece hasta 3 rutas desde la posición del conductor hasta la recogida (`ACEPTADO`) o el destino (`EN_CURSO`).
  - Etiquetas `RAPIDA`, `CORTA` y `ALTERNATIVA`.
  - Las ofertas valen 10 min.
  - Errores: 403 si no es su viaje, 404 si la oferta venció, 409 si el viaje no está activo.
- `ApiConductorController`:
  - `POST /api/conductor/rutas/{id}` con cuerpo `{latitud, longitud}` → lista de opciones.
  - `PUT /api/conductor/rutas/{id}` con cuerpo `{indice}` → `{geometria}`.
- DTO: `presentacion/dto/RutasEnVivoDto.java`.
- Pruebas actualizadas: `SeguridadHttpTest` (con `csrf()`) y `ApiConductorCalificacionTest`.

### 3.2 Backend (PR #8): operación del admin
- `GET /api/admin/operacion` (solo `ROLE_ADMIN`). Lo calcula `OperacionAdminService` y lo devuelve como `OperacionAdminDto`:
  - Cifras: `viajesHoy`, `finalizadosHoy`, `canceladosHoy`, `enCurso`, `yendoARecoger`, `solicitudesAbiertas`, `conductoresEnLinea`, `conductoresDisponibles`, `conductoresPendientes`.
  - `flota`: lista de `{latitud, longitud, disponible}`, sin id ni nombre. Sale de `UbicacionConductorService.flota()`, en memoria.
  - `alertas`: solicitudes sin conductor hace más de 5 min (máx. 10) y conductores por aprobar.
- Conteos nuevos en `ServicioRepository`.
- `/api/conductor/ingresos` ahora envía `hora`: la fecha de finalización, o la de la solicitud si no hay finalización.
- Pruebas: `OperacionAdminServiceTest`, y en `SeguridadHttpTest` la ruta exige token y un conductor recibe 403.

### 3.3 App, fase 1 (PR #7): mapa en vivo
- **Estilo del mapa:** Oscuro, Claro o Automático (oscuro de 18 h a 6 h).
  - Se guarda en el almacenamiento seguro con la clave `nexa.mapa.estilo`.
  - Archivo: `core/mapa/estilo_mapa.dart`.
  - Hoja de capas en `MapaNexa`, con vista previa de cada estilo.
- **Moto fluida:**
  - El conductor ve su moto con su propio GPS (`posicionEnVivoProvider`), no con la respuesta del servidor.
  - Entre un dato y el siguiente la moto se interpola; no se anima con «reducir animaciones».
  - GPS en viaje: cada 1 s o 3 m. El pasajero en camino: cada 2 s o 5 m.
  - La app envía la posición cada 2 s (`Env.pollingPosicion`) y el pasajero pide la de la moto cada 2 s.
- **Desvío de ruta:**
  - `ReglasRuta` y `DetectorDesvio` en `core/mapa/reglas_ruta.dart`: dos lecturas seguidas a más de 35 m de la ruta, con un aviso como máximo cada 30 s.
  - Al detectarlo se piden rutas al servidor y la tarjeta `TarjetaDesvio` (`widgets/rutas_desvio.dart`) muestra hasta 3, con cuenta regresiva de 10 s hacia la sugerida.
  - Botón «Rutas» para pedirlas a mano.
  - El pasajero recibe el aviso «tomó otra ruta» (`rutaCambiadaProvider`).
  - Si el servidor responde 404 o 405, la app solo avisa del desvío.
- **Yendo a recoger:** la app pide la ruta hasta el pasajero y toma la sugerida sola; la tarjeta de navegación da giros también en ese tramo.
- **Mapa:**
  - Ruta en capas: borde, tramo recorrido apagado, lo que falta brillante y alternativas en gris.
  - La cámara sigue a la moto; tras un gesto del conductor espera 15 s, o él toca «Recentrar».
  - Navegación automática al aceptar un viaje.
  - Moto vista desde arriba y bandera de cuadros en el destino.
  - La hoja del conductor arranca al 36 % de la pantalla.
- **Cierre del viaje:**
  - Se corrigió la carrera entre «Finalizar» y el sondeo (bandera `_avanzando`).
  - El resumen de un viaje terminado antes del destino dice «Finalizado antes del destino · Se cobra solo lo recorrido» y muestra la XP.
- Pruebas: `test/unit/reglas_ruta_test.dart` y un grupo de rutas en vivo en `test/unit/conductor_real_test.dart`.
- Documentación: `DECISIONES.md` (entrada del 22 nov., fase 1) y `API_CONTRATO.md`.

### 3.4 App, fases 2 a 4 (rama `feature/flutter-rediseno-pantallas`)

**Pasajero**
- Al confirmar el viaje:
  - El tiempo va sobre la línea de la ruta (`MapaNexa.tiempoEnRuta`).
  - La bandera dice «destino · llegas H:mm» (`etiquetaDestino`).
  - Los rótulos son imágenes en forma de píldora, dibujadas por `dibujarRotulo` en `core/mapa/imagenes_marcadores.dart`. Así no dependen de las fuentes del estilo: `SymbolOptions` de `maplibre_gl` no tiene `textFont`.
- Viaje en curso:
  - `TarjetaLlegada` en `widgets/piezas_viaje.dart`: hora grande, minutos, km restantes y barra de avance.
  - Si el conductor cambia de ruta, la anterior queda tenue (`rutaAnteriorProvider` + `MapaNexa.rutaAnterior`).
- Búsqueda: lo escrito sale resaltado (`core/utils/resaltar.dart`, sin distinguir tildes ni mayúsculas).
- Actividad:
  - Miniatura de la ruta de cada viaje (`core/widgets/mini_ruta.dart`, un `CustomPainter` sin teselas).
  - Cifras del mes: gasto y km.
  - Filtros en una sola línea.

**Conductor**
- Fuera de línea (`widgets/panel_turno.dart`): saludo, «¿Listo para rodar?», deslizar para conectarse y lo ganado hoy y en los últimos 7 días.
- En línea: lo ganado hoy, barras por hora (usa `hora` de `/ingresos`) y el estado del GPS.
- En viaje: la hora de llegada arriba de `ViajeActivoCard`.
- Cierre (`ResumenViajeCard`):
  - Una sola píldora de estado.
  - Si terminó antes del destino, miniatura del tramo recorrido (`fraccionCobrada`) con «X de Y km recorridos».
  - Recargo por espera en el desglose.
- Ganancias (reescrita):
  - Selector Hoy · Semana · 30 días; son ventanas que terminan hoy (`domain/resumen_ganancias.dart`).
  - Barras por día, o por hora en «Hoy».
  - Cobrado y «Debes a NEXA» del mismo período. `saldoProvider` ahora es `family<int>`, según los días.
- `Ingreso` tiene un campo nuevo `hora` (freezed, ya regenerado).
- Perfil: tarjeta «Tu moto» con la placa (`GET /api/conductor/vehiculos`; `VehiculosRepository` en `features/auth`).

**Todos los roles**
- Sección «Mapa» en el perfil, con `SelectorEstiloMapa`, el mismo selector de la hoja de capas.

**Administrador (`features/admin/`)**
- `/a/inicio` es `OperacionScreen` y ahora es el inicio del admin (`_inicio(Rol.admin)`):
  - Muestra cifras, flota en el mapa (`MapaNexa.flota`) y alertas.
  - Se refresca cada 15 s.
- `/a/conductores` es `ConductoresScreen`: lista por estado (`PENDIENTE`, `EN_REVISION`, `APROBADO`, `RECHAZADO`).
- `/a/conductores/revision` es `RevisionConductorScreen`:
  - Moto, estado de la verificación y las fotos de los 4 documentos con el número declarado.
  - Aprobar: si no hay verificación `VERIFIED`, pide una casilla «Revisé los documentos…», llama a `POST /admin/verificacion/manual` y luego a `/decision`.
  - Pedir información y rechazar exigen motivo.
- Usa endpoints de admin que ya existían (`/api/admin/conductores`, `/api/admin/verificacion/*`) y el nuevo `/api/admin/operacion`.
- Se eliminó `AdminProximamenteScreen`.

**Pruebas nuevas o ajustadas**
- `test/unit/rediseno_pantallas_test.dart`
- `test/widget/admin_test.dart`
- `panel_conductor_test`, `pantallas_test`, `admin_satisfaccion_test` y `satisfaccion_test` (el inicio del admin ahora es `/a/inicio`).
- Capturas nuevas: D00 (inicio del admin) y D05 (conductores).

**Documentación**
- `DECISIONES.md`: entrada «fases 2 a 4».
- `API_CONTRATO.md`: sección Admin.
- `PENDIENTES_BACKEND.md`: tabla V1–V6.

---

## 4. Estado exacto al pausar

- **Sin commit en `feature/flutter-rediseno-pantallas`:** el texto `adminEnLinea` cambió de «Conductores en línea» a «En línea ahora», en estos archivos:
  - `mobile/lib/core/l10n/app_es.arb`
  - `mobile/lib/core/l10n/gen/app_localizations.dart`
  - `mobile/lib/core/l10n/gen/app_localizations_es.dart`

  Motivo: en la tarjeta del inicio del admin el título salía cortado. Hay que hacer commit, o descartar el cambio.
- La CI de `bc5f25f` estaba corriendo. Las fallas que se vieron en la corrida anterior ya se corrigieron en `bc5f25f`; falta confirmar que pase.
- La captura **N08** falla con «A Timer is still pending». Ya fallaba en `app` antes de este trabajo y el paso de capturas no bloquea la CI.
- El PR de `feature/flutter-rediseno-pantallas` todavía no está abierto.

---

## 5. Lo que falta

### 5.1 Para terminar lo empezado
1. Confirmar que la CI de `feature/flutter-rediseno-pantallas` quede en verde (detalle en la sección 7).
2. Revisar las capturas de la CI, sobre todo C01, C08, C10, P07, P10, D00 y D05.
3. Abrir el PR de `feature/flutter-rediseno-pantallas`. Debe decir que depende de #7 (rama base) y de #8 (por `hora` y `/admin/operacion`). Sin #8, la app funciona, pero sin barras por hora y con error en el inicio del admin.
4. Probar en un teléfono real, con el backend desplegado:
   - El desvío de ruta.
   - Que la moto se mueva sin saltos.
   - Que los rótulos-imagen se vean en el mapa.
   - La flota del admin.
   - Aprobar y rechazar un conductor.

### 5.2 Del video que no se implementó porque depende del servidor (`PENDIENTES_BACKEND.md`, V1–V6)
- **V1 – WebSocket con JWT.** Hoy la app sondea cada 2 s. Falta autenticar el STOMP de `/ws` con el token de la app y publicar ahí la posición del conductor.
- **V2 – Vencimiento de SOAT y tecnomecánica.** No se guarda ninguna fecha de vencimiento, así que no hay alerta de «SOAT vencido» ni vencimientos en el perfil del conductor.
- **V3 – Zonas con más solicitudes** (mapa de calor del conductor).
- **V4 – Ruta «sin giros a la izquierda».** OSRM no la ofrece.
- **V5 – Nombres de calle en la maniobra.** Faltan las instrucciones de OSRM con `steps=true`.
- **V6 – «Contactar» desde viajes en riesgo.** La Lambda no envía contacto, por privacidad.

### 5.3 Del video que no se hizo y no depende del servidor
- Velocidad en un círculo flotante sobre el mapa durante el viaje. `NavegacionConductor` ya muestra la velocidad del GPS.
- Solicitud entrante a pantalla completa; hoy es la tarjeta del panel.
- Inicio del pasajero: destinos recientes con precio aproximado. Hoy son los viajes recientes con su precio.
- Chips «Casa» y «Universidad» en la búsqueda. No existen lugares guardados en el backend.
- Niveles del conductor con los requisitos de calidad marcados como en el video. Revisar `conductor_info_card.dart`: los datos ya llegan en `ConductorInfo.requisitosSiguiente`.
- Pulido de accesibilidad y modo claro de toda la app (fase 5 del video).

---

## 6. Archivos clave

| Tema | Archivo |
|---|---|
| Mapa | `mobile/lib/core/widgets/mapa_nexa.dart` |
| Reglas de ruta | `mobile/lib/core/mapa/reglas_ruta.dart` |
| Estilo del mapa | `mobile/lib/core/mapa/estilo_mapa.dart` |
| Imágenes y rótulos del mapa | `mobile/lib/core/mapa/imagenes_marcadores.dart` |
| Miniatura de ruta | `mobile/lib/core/widgets/mini_ruta.dart` |
| Conductor (controlador) | `mobile/lib/features/viajes/presentation/controllers/viaje_conductor_controller.dart` |
| Pasajero (controlador) | `mobile/lib/features/viajes/presentation/controllers/viaje_pasajero_controller.dart` |
| Pantalla del conductor | `mobile/lib/features/viajes/presentation/conductor/inicio_conductor_screen.dart` |
| Pantalla del pasajero en viaje | `mobile/lib/features/viajes/presentation/pasajero/viaje_en_curso_screen.dart` |
| Admin | `mobile/lib/features/admin/` |
| Backend | `RutaEnVivoService.java`, `OperacionAdminService.java`, `ApiConductorController.java`, `ApiAdminController.java` |

---

## 7. Cómo trabajar

- **CI:** `.github/workflows/mobile.yml`, que corre en `app` y en `feature/flutter-**`.
  - Si el formato o los archivos generados no coinciden, imprime un parche en el log, en base64 y gzip, entre `PARCHE-INICIO` y `PARCHE-FIN`. Se aplica con `base64 -d | gunzip | git apply`.
  - Solo falla si difieren los generados (`*.g.dart`, `*.freezed.dart` o `l10n/gen`). Si solo difiere el formato, avisa sin fallar.
  - Pasos: análisis (`flutter analyze --no-fatal-infos`; los avisos sí fallan), pruebas, capturas (no bloquea) y APK debug.
  - Si el APK falla con 429 de Maven Central, es temporal: vuelve a correr el job.
- **Textos:** agrégalos en `app_es.arb` y corre `flutter gen-l10n`. Los generados se versionan.
- **Backend:** `mvn -q -B test`.
- **Al publicar:** nunca hagas push directo a `main`; usa ramas y PR.

Comandos de la app (desde `mobile/`):

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze
flutter test
```
