# Plan: llevar el rediseño dark a la app Flutter

Referencia visual: [`mockups-nexa-dark.html`](mockups-nexa-dark.html) (19 pantallas de 390 × 844, tema oscuro con cian neón).
Regla de trabajo: cada fase cambia **solo la capa visual** y conserva controladores, repositorios y rutas; las pruebas existentes avisan si algo se rompe. Todo en `feature/flutter-app`, un commit por fase, sin push a `master`.

## Mapa de pantallas

| Mockup | Pantalla actual | Trabajo |
|---|---|---|
| 01–04 Acceso | `onboarding`, `login`, `registro`, `registro_conductor` | Rediseñar. Registro de pasajero en 2 pasos. Logo en `assets/images/nexa_logo.png`. |
| 05 Inicio pasajero | `inicio_pasajero_screen` | Reescribir: mapa a pantalla completa con hoja inferior. |
| 06 Elegir destino | `campo_lugar` dentro de `solicitar_viaje` | Pantalla nueva sobre `geocoding_service.dart`. |
| 07 Confirmar | `solicitar_viaje_screen` | Precio dentro del botón; desglose bajo demanda. |
| 08–09 Buscando / en camino | `viaje_en_curso_screen` | Dividir por fases con hojas inferiores. |
| 10 Calificación | `calificacion_screen` | Rediseñar. |
| 11–12 Niveles / perfil | `niveles_screen`, `perfil_screen` | Rediseñar; anillo de nivel en el avatar. |
| 13–16 Conductor | `inicio_conductor`, `ganancias` | 13 y 16 se rediseñan; 14 (solicitud entrante) y 15 (viaje activo) son nuevas. |
| 17–19 Administrador | no existe | Pendiente de decisión (ver abajo). |

## Fases

0. **Fundamentos**: Montserrat incluida como archivo de la app; tokens y tema (formas, brillos, tipografía); widgets compartidos: botón con precio, chip de cristal, avatar con anillo de XP, barra de navegación flotante, hoja inferior, «desliza para confirmar», mapa oscuro con ruta de neón.
1. **Acceso** (01–04).
2. **Pasajero: pedir** (05–07).
3. **Pasajero: viaje** (08–10): buscando con extra voluntario, conductor en camino, calificación.
4. **Niveles y perfil** (11–12).
5. **Conductor** (13–16).
6. **Administrador** (17–19), según la decisión 1.
7. **Pulido y entrega**: accesibilidad (contraste, áreas táctiles, letra grande), 360 × 640, pruebas, versión nueva. Publicar en Firebase solo con autorización.

Al cerrar cada fase: `flutter analyze`, `dart format --set-exit-if-changed lib test`, `flutter test`.

## Decisiones abiertas

1. **Administrador**: hoy vive solo en la web. Opciones: dejar 17–19 como diseño de referencia (recomendado por ahora) o construir un tercer rol en la app.
2. **Tema claro**: los mockups son solo oscuros. Opciones: app solo oscura (más rápido y coherente) o mantener ambos temas (duplica la revisión visual).
3. **Mapa oscuro**: filtro de color sobre los mosaicos de OpenStreetMap (sin servicio externo; punto de partida) o mosaicos oscuros de un proveedor (mejor aspecto, con sus condiciones de uso y atribución).

## Lo que el backend hoy no entrega

Se mostrará oculto o calculado hasta que haya endpoint:
- Lugares guardados («Casa», «Universidad») y recientes con precio.
- Llamar y mensajear al conductor, compartir viaje, botón de seguridad (ya en `PENDIENTES_BACKEND.md`).
- Viajes por día para la gráfica de ganancias (ver si se calcula con los viajes que ya llegan).
- Mejor día de la semana y XP ganado por viaje en la calificación.

## Riesgos

- Reescribir pantallas que funcionan: se mitiga conservando controladores y repositorios.
- Teléfonos pequeños: revisar 360 × 640 y letra grande del sistema.
- Rendimiento del mapa con hojas flotantes y brillos en equipos modestos.

## Estado (29 oct. 2026)

Hechas, en `feature/flutter-app` (un commit por fase, sin push a `master`):

| Fase | Contenido | Commit |
|---|---|---|
| 0 | Montserrat incluida, tokens, mapa oscuro por filtro y widgets compartidos (`core/widgets/nexa_diseno.dart`) | `e600de9` |
| 1 | Acceso: bienvenida, login, registro en 2 pasos, avance de documentos del conductor | `1a7d5d4` |
| 2 | Pasajero: inicio con mapa, pantalla «Tu ruta», confirmar con el precio en el botón | `c36299f` |
| 3 | Pasajero: buscando conductor, conductor en camino, calificación | `2838157` |
| 4 | Niveles (anillo y escalera) y perfil (anillo en la foto) | `ed49979` |
| 5a | Conductor: panel con botón de conexión y ganancias | `ae72995` |
| 5b | Conductor: solicitud entrante y viaje activo con «desliza para confirmar» | `c841236` |
| 7 | Pulido: prueba de letra al 200 % en todas las pantallas nuevas y barra de navegación con el estilo nuevo | este commit |

### Diferencias con los mockups (por datos que el backend no entrega)

- Sin «Casa», «Universidad» ni recientes con precio en el inicio; sin motos cercanas en el mapa.
- Sin «Avisamos a N conductores» ni radar al buscar conductor.
- La solicitud entrante del conductor es una tarjeta en la hoja, sin pantalla completa ni cuenta regresiva (el servidor no manda vencimiento).
- Ganancias: barras por viaje (no por día) y sin selector Hoy / Semana / 30 días.
- La barra de navegación es la de Material con el estilo nuevo; la píldora flotante del mockup queda pendiente.

### Pendiente

- **Fase 6 (administrador):** no se construyó. Requiere cambios de backend: el login móvil (`ApiAuthController.login`) solo admite pasajeros, y las cifras reales del panel web (registros por mes, conductores por estado, saldos) no son las del mockup. Hacerla en una rama aparte.
- Probar en un teléfono real (en especial el filtro del mapa oscuro) y ajustar.
- Decisión abierta: tema claro (hoy la app conserva ambos, el rediseño es oscuro).
- Publicar una versión nueva en Firebase solo con autorización.
