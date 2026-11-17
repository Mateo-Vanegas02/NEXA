# Configuración y ejecución

- Java 21; `./mvnw clean install` compila y ejecuta pruebas unitarias. Los tests `@Tag("requiere-mongo")` necesitan una MongoDB aislada y se habilitan con `-Dexcluded.groups=none`.
- Copiar `.env.example` a `.env` para desarrollo local; nunca versionar el archivo. Las variables de entorno tienen prioridad.
- Obligatorios: `MONGODB_URI`, `JWT_SECRET` (Base64 de al menos 256 bits), `GEMINI_API_KEY`, `SPRING_MAIL_USERNAME`, `SPRING_MAIL_PASSWORD`. En `prod`, también `APP_BASE_URL`. `FIREBASE_CREDENCIALES` es opcional.
- `SPRING_PROFILES_ACTIVE=prod` activa cookie `Secure` y respeta cabeceras del proxy. El modelo Weka se carga desde `motvirs.model.path`.
- El workflow manual `.github/workflows/deploy-aws.yml` construye imagen en ECR con etiqueta del commit, copia configuración a EC2 vía SSM y arranca `infra/servidor/docker-compose.aws.yml`. `preparar.sh` obtiene parámetros de `/nexa/prod` y comprueba el puerto. Elegir una rama en Actions despliega esa rama al servidor actual; no crea un entorno aparte.
- `ci.yml` ejecuta pruebas y arranque Docker con MongoDB desechable; no despliega. El `Dockerfile` usa usuario `nexa` sin privilegios.
