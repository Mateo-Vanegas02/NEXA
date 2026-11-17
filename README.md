# NEXA - Servicio de MotoTaxis Web App

Aplicación web desarrollada con Spring Boot para el servicio de mototaxis NEXA. Permite a los usuarios registrarse como pasajeros o conductores, reservar viajes, rastrear conductores en tiempo real y ofrece un ChatBot IA para resolver dudas y dar soporte.

Para empezar: [arquitectura](docs/ARQUITECTURA.md), [flujo de viajes](docs/FLUJO_VIAJES.md), [API](docs/API.md), [configuración](docs/CONFIGURACION.md), [contribución](CONTRIBUTING.md) y [auditoría vigente](docs/auditoria/AUDITORIA_INICIAL.md).

## 🚀 Requisitos Previos

Antes de ejecutar la aplicación, asegúrese de tener instalado:

- **Java JDK 21** o superior
- **Maven** (o usar el wrapper de maven incluido `mvnw`)
- Una cuenta en **MongoDB Atlas** o una instancia local de MongoDB
- Una API Key de **Google Gemini** para el ChatBot (Opcional, pero recomendado)

## 🛠️ Instalación y Configuración

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/Mateo-Vanegas02/NEXA.git
   cd NEXA
   ```

2. **Definir las variables de entorno** (los secretos NO viven en `application.properties`; si falta alguna obligatoria la app no arranca y lo indica):

   | Variable | Descripción |
   |---|---|
   | `MONGODB_URI` | Cadena de conexión de MongoDB |
   | `JWT_SECRET` | Secreto HMAC en Base64 (>= 256 bits): `openssl rand -base64 48` |
   | `GEMINI_API_KEY` | API key de Google Gemini (chatbot) |
   | `SPRING_MAIL_USERNAME` / `SPRING_MAIL_PASSWORD` | Cuenta SMTP (Gmail: contraseña de aplicación) |
   | `APP_BASE_URL` | URL pública, sin barra final (obligatoria en `prod`; en dev usa `http://localhost:8080`) |
   | `SPRING_PROFILES_ACTIVE` | `dev` (logging detallado) o `prod` |
   | `ADMIN_EMAIL` / `ADMIN_PASSWORD` | Opcional: crea el administrador inicial (clave >= 12 caracteres) |

   **Forma recomendada en local:** copia `.env.example` a `.env` en la raíz y completa los valores. Spring Boot lo lee solo al arrancar (`spring.config.import=optional:file:.env[.properties]`), sin plugins ni dependencias. Escribe `CLAVE=valor` **sin comillas**. Las variables reales del sistema tienen prioridad sobre el `.env`. **Nunca subas `.env` a git** (ya está en `.gitignore`).

   - **Terminal (PowerShell):** `$env:MONGODB_URI="..."; $env:JWT_SECRET="..."; ./mvnw spring-boot:run`
   - **Terminal (bash):** `export MONGODB_URI="..." JWT_SECRET="..."` y luego `./mvnw spring-boot:run`
   - **IntelliJ / Eclipse / VS Code:** *Run configuration → Environment variables* (no hace falta si usas el archivo `.env`).
   - **Docker:** copia `.env.example` a `.env`, complétalo y ejecuta `./deploy.sh` (o `docker compose up -d --build`). Detalles en la sección *Docker* más abajo.
   - **Producción AWS:** Parameter Store (`/nexa/prod/*`) alimenta las variables en EC2 mediante el workflow manual `Deploy AWS`. Configuración y controles en [`docs/CONFIGURACION.md`](docs/CONFIGURACION.md) y [`docs/SEGURIDAD.md`](docs/SEGURIDAD.md).

3. **Compilar el proyecto:**
   ```bash
   ./mvnw clean install
   ```

## ▶️ Ejecución

Para iniciar la aplicación en desarrollo:

```bash
./mvnw spring-boot:run
```

La aplicación estará disponible en: `http://localhost:8080/`

## 🏗️ Estructura del Proyecto y Tecnologías

- **Framework Principal:** Spring Boot 3.4.4
- **Seguridad:** Spring Security (Autenticación basada en Roles y JWT)
- **Base de Datos:** MongoDB (Spring Data MongoDB)
- **Frontend:** Thymeleaf, HTML5, Vanilla JavaScript, CSS3
- **Inteligencia Artificial:** Spring AI con Google GenAI (Gemini)
- **Machine Learning:** Weka (Análisis de satisfacción)
- **Comunicaciones:** WebSockets (STOMP)

## 🔒 Estructura de Usuarios y Roles

La aplicación implementa herencia en MongoDB y gestión controlada por roles:
- **`ROLE_PASAJERO`:** Puede solicitar viajes, calificar, ver historial y acceder a las páginas de usuario final.
- **`ROLE_CONDUCTOR`:** Requiere validación y aprobación por administrador. Puede aceptar solicitudes, finalizar viajes, agregar vehículos.
- **`ROLE_ADMIN`:** Panel general administrativo con analíticas y aprobación de cuentas.

## 🪪 Verificación de conductores y protección de datos personales
El admin verifica placa y licencia de cada conductor antes de aprobarlo (`docs/VERIFICACION.md`). Por defecto (`VERIFICATION_PROVIDER=manual`) la revisión es manual y auditada; nunca se aprueba automáticamente.

**Datos personales (Colombia):** la placa, la licencia, el documento del propietario y los datos del conductor son datos personales. La Ley 1581 de 2012 y el Decreto 1074 de 2015 (habeas data) exigen, entre otros, contar con autorización del titular y finalidad informada, limitar la recolección a lo necesario, garantizar seguridad y permitir consulta, actualización y supresión. Esta aplicación enmascara el documento en la auditoría, no lo guarda en logs y no persiste el documento del propietario. **Esto no es asesoría legal:** se recomienda revisión por un abogado antes de activar una fuente externa (política de tratamiento, autorizaciones, transferencia a terceros y registro de bases de datos ante la SIC si aplica).

## 🤝 Mantenimiento de Ramas y Commits

Este proyecto recomienda seguir la convención de [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) para facilitar el versionado y el registro de cambios:

- `feat:` Nuevas funcionalidades
- `fix:` Correcciones de errores
- `docs:` Cambios en la documentación
- `style:` Formato o cambios de diseño que no afectan la lógica
- `refactor:` Cambios en el código que no corrigen errores ni añaden funcionalidades

## Docker

- **Imagen:** `Dockerfile` multi-etapa (Maven + JDK 21 compila; JRE 21 ejecuta), con usuario sin privilegios, caché de dependencias, modelo Weka incluido y `HEALTHCHECK`. Los secretos **no** entran en la imagen: llegan por variables de entorno.
- **Levantar:** `./deploy.sh` (comprueba que existe `.env`, construye, arranca y espera a que esté saludable). Equivale a `docker compose up -d --build`.
- **Con MongoDB local:** `NEXA_LOCAL_DB=1 ./deploy.sh` (o `docker compose --profile local-db up -d --build`) y en `.env` pon `MONGODB_URI=mongodb://mongo:27017/nexa`.
- **Probar por http en local:** el perfil `prod` exige HTTPS (cookie `Secure`). Para probar en `http://localhost:8080` añade `NEXA_PROFILE=dev` al `.env`.
- **Logs y parada:** `docker compose logs -f nexa-backend` · `docker compose down`.
- **CI:** el workflow `ci.yml` construye la imagen y la arranca contra una MongoDB desechable en cada push (no despliega nada).
