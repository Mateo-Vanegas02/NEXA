# Arquitectura por capas

Paquete raíz: `com.example.MotvirsWeb`. Cada capa solo puede depender de las que están **por debajo** en la tabla; el dominio no depende de nada del proyecto.

| Capa | Paquete | Contiene |
|---|---|---|
| Presentación | `presentacion.web` | Controladores Thymeleaf (`Controller*`, `AuthController*`, perfil, recuperación de contraseña) |
| | `presentacion.api` | Controladores REST `/api/**`, chat de IA y canal WebSocket de usuario |
| | `presentacion.dto` | Objetos de entrada/salida de la API y formularios |
| Aplicación | `aplicacion.servicio` | Casos de uso: viajes, niveles y XP, autenticación, administración, chat, ML y optimización |
| | `aplicacion.herramientas` | Herramientas (`@Tool`) que Gemini puede invocar (`NexaTools`, `AdminTools`) |
| | `aplicacion.verificacion` | Caso de uso de verificación de conductores, contrato `DriverVerificationProvider`, validaciones y excepciones |
| | `aplicacion.comando` | Datos de entrada de los casos de uso (`SolicitudViaje`), independientes del formato HTTP |
| | `aplicacion.puerto` | Interfaces (puertos de salida) que la aplicación necesita del exterior: `NotificadorCorreo`, `NotificadorTiempoReal`, `EmisorTokens` |
| | `aplicacion.util` | Utilidades de contexto de usuario |
| Dominio | `dominio.modelo` | Entidades y enums de MongoDB (`Usuario`, `Servicio`, `XpEvento`...) |
| | `dominio.regla` | Reglas de negocio puras: `MotorXp`, `CalculadoraTarifa`, `PrioridadRecogida`, `PoliticaPassword`, `NivelesProperties` |
| | `dominio.repositorio` | Interfaces de repositorio (Spring Data MongoDB): la aplicación las usa; Spring Data genera la implementación |
| Infraestructura | `infraestructura.seguridad` | Spring Security, JWT (`JwtService` implementa `EmisorTokens`), filtros y rutas por rol |
| | `infraestructura.config` | Configuración de arranque, validador de variables de entorno, índices, cliente de IA |
| | `infraestructura.correo` | Envío de correos (`EmailService` implementa `NotificadorCorreo`) |
| | `infraestructura.socket` | STOMP/WebSocket (`WebSocketService` implementa `NotificadorTiempoReal`) |
| | `infraestructura.verificacion` | Proveedores `manual`, `mock` y `real` de verificación |

## Modelo de datos

Diagrama EER (estilo MySQL Workbench) con las relaciones declaradas: [`modelo/nexa_eer.png`](modelo/nexa_eer.png) (vectorial: [`nexa_eer.svg`](modelo/nexa_eer.svg); se regenera con `python3 docs/modelo/generar_eer.py docs/modelo/nexa_eer.png`, requiere `matplotlib`). Discrepancias lógicas detectadas y propuestas: [`modelo/DISCREPANCIAS.md`](modelo/DISCREPANCIAS.md).

Vista física de las 12 colecciones tal como se guardan en MongoDB: [`modelo/nexa_er.png`](modelo/nexa_er.png) (fuente Graphviz: [`nexa_er.dot`](modelo/nexa_er.dot), se regenera con `dot -Tpng -Gdpi=170 nexa_er.dot -o nexa_er.png`).

## Flujo habitual

`presentacion` (valida la entrada, usa DTOs) → `aplicacion` (orquesta el caso de uso) → `dominio` (reglas y entidades) · `infraestructura` (persistencia, seguridad y servicios externos).

## Estado y deuda conocida

- **Inversión de dependencias (hecha):** los servicios usan los puertos de `aplicacion.puerto` y los repositorios de `dominio.repositorio`; `aplicacion` ya no importa nada de `infraestructura`. Excepción conocida: `UserController` (presentación) usa `CustomUserDetails`, el principal de Spring Security que lleva el id del usuario.
- `dominio.modelo` usa anotaciones de Spring Data (`@Document`); se acepta por pragmatismo.
- Las entradas de solicitar viaje, calificar y Días NEXA ya usan DTOs con `@Valid` (`presentacion.dto`), con errores JSON `{error, message}`. Siguen pendientes las **respuestas** que se arman con `Map<String,Object>` y los endpoints de admin.
- Las entidades sin `@TypeAlias` (`Servicio`, `XpEvento`, `NotaAdmin`...) guardan el campo `_class` con el nombre completo de la clase. Los documentos antiguos tienen el paquete anterior (`...Models.Servicio`); Spring Data lo ignora si la clase no existe y lee con el tipo del repositorio. Conviene confirmarlo contra una copia de la base (ver `docs/CAMBIOS.md`, pendientes).

## Variables de entorno

Ver `.env.example`, `README.md` y `docs/SEGURIDAD.md`. Los secretos solo viven en `.env` (local, ignorado por git) o en variables del sistema.
