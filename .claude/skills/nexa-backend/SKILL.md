---
name: nexa-backend
description: Backend avanzado de NEXA (Spring Boot 3.4, Java 21, MongoDB, Spring Security + JWT, WebSocket, Spring AI/Gemini, OR-Tools, Weka). Úsala al crear o modificar controladores, servicios, repositorios, modelos, DTOs, reglas del modelo de tarifa/XP/niveles, despacho de viajes, privacidad por rol, seguridad, endpoints /api, WebSocket o pruebas Java.
---

# NEXA — Backend

## Stack
- Spring Boot 3.4.4, Java 21, Maven (`./mvnw`), Lombok.
- Persistencia: Spring Data MongoDB (`dominio/repositorio`, documentos en `dominio/modelo`).
- Seguridad: `infraestructura/seguridad/SecurityConfig.java` = sesión (form login para las vistas Thymeleaf) + `JwtAuthFilter` para `/api/**`. Las rutas y roles viven en `SecurityConstants.java`; roles: `PASAJERO`, `CONDUCTOR` (requiere aprobación del admin), `ADMIN`.
- IA: Spring AI con Google GenAI (`infraestructura/config/LlmConfig.java`, `ChatBotController`, `AdminChatService`). Optimización: OR-Tools (`OptimizerService`). ML: Weka con `modelo_satisfaccion_j48_v2.0.model`.
- Despliegue: Docker (`JAVA_OPTS=-Xms512m -Xmx1024m`, contenedor 1,5 GB) en un servidor de 2 GB. Azure Web App "NEXA" vía `.github/workflows/master_nexa.yml`.

## Paquetes (`com.example.MotvirsWeb`)
`presentacion/{web,api,dto}` → `aplicacion/{servicio,herramientas,verificacion,puerto,util}` → `dominio/{modelo,regla,repositorio}`; `infraestructura/{seguridad,config,correo,socket,verificacion,almacenamiento}` implementa lo técnico. Las dependencias solo apuntan hacia el dominio (ver `docs/ARQUITECTURA.md`). Los nombres van en español; respeta esa convención.

Las dependencias externas se usan a través de puertos en `aplicacion/puerto` (`ProveedorRutas`, `NotificadorCorreo`, `NotificadorTiempoReal`, `EmisorTokens`, `AlmacenDocumentos`, `LectorDocumentos`). Un servicio nuevo depende del puerto, nunca de la clase concreta.

## Reglas generales
1. **Capas:** el controlador valida y delega en un servicio; el servicio usa repositorios. Nunca devuelvas entidades de `dominio/modelo` desde `/api`: usa un DTO en `presentacion/dto` (`record` si es inmutable).
2. **Validación:** `@Valid` + Bean Validation en los DTOs de entrada; los errores salen con el formato de `ManejadorErroresValidacion`.
3. **Seguridad:**
   - Toda ruta nueva se registra en `SecurityConstants`, en el bloque de su rol y *antes* de la regla general `/api/**`.
   - `@PreAuthorize` para reglas por método (`@EnableMethodSecurity` está activo).
   - Verifica la propiedad del recurso: un pasajero solo ve sus servicios (IDOR).
   - No registres en logs tokens, contraseñas ni datos personales.
4. **Dos superficies HTTP:** los `Controller*` sirven vistas con sesión + CSRF; los `Api*Controller` exponen `/api/**` con JWT. Lo que use la app móvil debe existir bajo `/api/**`. Un POST/PUT/DELETE a `/api/**` desde el navegador con sesión necesita `X-CSRF-TOKEN`.
5. **MongoDB:** consultas derivadas o `@Query`; `@Indexed` en campos de búsqueda frecuente; evita el N+1 con `findAllById`; pagina con `Pageable`. Nunca cargues colecciones completas (servidor de 2 GB).
6. **Errores:** códigos HTTP correctos (400/401/402/403/404/409). 409 cuando otro actor ganó la carrera (p. ej. dos conductores aceptan el mismo viaje).
7. **WebSocket:** las rutas de `SecurityConstants.WEBSOCKET_URLS` están exentas de CSRF, así que valida al usuario en `WebSocketAuthInterceptor` (un topic del pasajero solo lo escucha su dueño).

## Reglas propias de NEXA
8. **El negocio vive en reglas puras.** Tarifa, XP, niveles, comisión, espera, extra voluntario y despacho están en `dominio/regla` (`ModeloTarifa`, `ModeloXp`, `ModeloExtra`, `DespachoOlas`, `ReglaViaje`, `PrioridadRecogida`…), sin Spring ni Mongo. Todo número de negocio sale de `modelo-nexa.properties` (prefijo `nexa.`, `ModeloNexaProperties`), nunca del código. El servicio solo orquesta. Si cambias una fórmula, cambia también el modelo en `docs/niveles/`.
9. **El servidor decide.** Precio, distancia, ETA, fase del viaje, XP, nivel y comisión se calculan aquí; web y móvil solo los muestran.
10. **Privacidad por rol.** Todo `Servicio` que salga hacia un navegador o app (REST y STOMP) pasa por `VisibilidadServicio.paraConductor` / `paraPasajero`. El conductor nunca ve comisión, tarifa bruta ni la deuda del pasajero; cada rol ve solo la calificación que él puso. Un endpoint o mensaje nuevo con un `Servicio` sin ese filtro es un bug.
11. **Concurrencia.** Los cambios de estado se hacen con un update condicional atómico en el repositorio (`tomarSiDisponible`, `subirExtra`), no con leer → modificar → `save()` del documento completo, que pisa escrituras ajenas. Usa `$set`/update parcial. Las operaciones con efecto económico son idempotentes (XP: índice único `(viajeId, rol, motivo)`).
12. **Estado efímero en memoria** (posición del conductor, seguimiento del pasajero, posición en vivo) con vigencia en `nexa.*`: no sobrevive a un reinicio ni a varias instancias. Si algo debe sobrevivir, va a Mongo.
13. **Tiempo.** Usa el `Clock` inyectado, no `LocalDateTime.now()` (hoy hay 22 usos sueltos: deuda conocida). La zona America/Bogota no está fijada en Docker; no asumas la zona de la JVM.
14. **Secretos** solo en variables de entorno y sin valor por defecto (`.env.example`, `docs/SEGURIDAD.md`); `EntornoObligatorioPostProcessor` aborta el arranque si faltan. No restaures valores por defecto en `application*.properties`.

## Pruebas
- Estructura espejo de `src/test/java/...`. Primero reglas puras (JUnit 5, sin Spring), luego servicios (Mockito).
- Controladores: el repo hoy no usa `@WebMvcTest` (ningún test); los `@SpringBootTest` llevan `@Tag("requiere-mongo")` y se omiten por defecto. Para endpoints nuevos prefiere `@WebMvcTest` + `spring-security-test` (`@WithMockUser(roles=...)`): no necesita Mongo.
- Cubre siempre un caso feliz, uno con rol incorrecto (403) y uno sin autenticación (401 o redirección).
- `./mvnw test` · `./mvnw -Dtest=Clase#metodo test` · `./mvnw -Dexcluded.groups=none test` (necesita `MONGODB_URI` con una Mongo real) · `node --test src/test/js/*.test.mjs` para el JS.

## Git y despliegue
- Commits en Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `style:`).
- Un push a `master` compila y **despliega a producción** en Azure: no lo hagas sin intención de desplegar.

## Checklist antes de terminar
- [ ] Compila y las pruebas pasan (Java y JS).
- [ ] La ruta nueva tiene su rol en `SecurityConstants`.
- [ ] El endpoint usa DTO, valida la entrada y tiene prueba.
- [ ] Todo `Servicio` que sale pasa por `VisibilidadServicio`.
- [ ] Los números de negocio están en `modelo-nexa.properties` y la regla pura tiene su prueba.
- [ ] Las escrituras concurrentes usan update condicional, no `save()` de documento completo.
- [ ] No quedan secretos ni datos sensibles en el código ni en los logs.
