# Infraestructura de NEXA en AWS (us-east-2)

El código del modelo (TensorFlow, Lambda) vive en la rama `app`, carpeta `ml/`; aquí solo está la infraestructura.

Plantillas de CloudFormation, una pila por fase. Se cargan desde la consola
(CloudFormation → Create stack → Upload a template file). Nada de esto guarda secretos.

| Pila | Plantilla | Qué crea | Estado |
|---|---|---|---|
| `nexa-00-cuenta` | `cloudformation/00-cuenta.yml` | Usuario IAM `nexa-github-deploy` con permisos mínimos para desplegar | creada (10 nov.) |
| `nexa-10-web` | `cloudformation/10-web.yml` | EC2 t3.small (Amazon Linux 2023, Docker, 2 GB de swap), IP fija, security group 80/443, rol del servidor y repositorio ECR `nexa-backend` | creada (10 nov.): IP `18.227.59.40`, web desplegada en `https://18-227-59-40.sslip.io` (11 nov.) |
| `nexa-20-ml-datos` | `cloudformation/20-ml-datos.yml` | Bucket S3 privado `nexa-ml-<cuenta>` (exportaciones, modelos) y tabla DynamoDB `nexa-entrenamientos` | creada (11 nov.) |
| `nexa-30-ml-prediccion` | `cloudformation/30-ml-prediccion.yml` | Lambda mediadora `nexa-satisfaccion` + URL de función, su rol y el rol de EventBridge Scheduler | creada (11 nov.); actualizar con `VersionCodigo=2` y `mediadora.zip` v2 después de crear `nexa-40` |
| `nexa-40-ml-entrenamiento` | `cloudformation/40-ml-entrenamiento.yml` | ECR `nexa-entrenamiento`, cluster ECS `nexa`, tarea Fargate (1 vCPU, 4 GB) con sus roles, logs (14 días) y security group solo de salida | por crear |

Hecho a mano en la consola: presupuesto `nexa-mensual` (USD 30, alertas por correo) y los parámetros de
Parameter Store `/nexa/prod/*` (web) y `/nexa/ml/MONGODB_URI` (entrenamiento), cargados por el dueño de la cuenta.

Sin dominio propio todavía: la web se prueba en `https://<ip-con-guiones>.sslip.io` (salida `DireccionPrueba`
de `nexa-10-web`). Route 53 Domains no está disponible en cuentas Free Tier; el dominio se compra afuera.

## Entrenamiento con viajes reales (Fargate)
TensorFlow no cabe en una Lambda de 512 MB: la mediadora lanza con `ecs:RunTask` la tarea `nexa-entrenamiento`
(IP pública en las subredes por defecto, sin NAT) y la tarea solo existe mientras entrena (unos minutos). Orden:
1. Actualizar `nexa-00-cuenta` (el usuario de GitHub puede subir también a `nexa-entrenamiento`).
2. Crear `nexa-40-ml-entrenamiento` (exporta cluster, tarea, subredes, security group y roles).
3. Actions → Imagen entrenamiento → Run workflow (workflow en `main`, construye `ml/` de la rama `app` y sube `:latest` a ECR).
4. Subir el zip como `s3://nexa-ml-<cuenta>/codigo/mediadora-v2.zip` y actualizar `nexa-30-ml-prediccion` con
   `ClaveCodigo=codigo/mediadora-v2.zip` y `VersionCodigo=2`. **Cada versión con un nombre nuevo**: si la ruta no cambia,
   CloudFormation no vuelve a cargar el código de la Lambda
   (ya importa los valores de `nexa-40`, por eso va después).

## Por qué un usuario IAM y no OIDC
La cuenta pertenece a una organización cuya SCP niega todas las operaciones sobre proveedores
OIDC de IAM (verificado el 10 nov. 2026). GitHub Actions usa entonces claves de acceso de un
usuario sin consola y con lo mínimo: subir a ECR la imagen `nexa-backend` y mandar comandos por
SSM solo a la instancia etiquetada `Name=nexa-servidor`. Las claves se crean en la consola y se
guardan únicamente en los secretos del repositorio (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`).
Rotarlas cada 90 días.

## Despliegue de la web
- `servidor/docker-compose.aws.yml`: la web (imagen de ECR) y Caddy (HTTPS con Let's Encrypt).
- `servidor/Caddyfile`: proxy a la web en `{$DOMINIO}`.
- `servidor/preparar.sh`: corre en el servidor; arma `.env` desde `/nexa/prod/*`, entra a ECR, levanta la versión pedida y espera a que la web responda.
- `.github/workflows/deploy-aws.yml`: por ahora solo manual (Actions → Deploy AWS → Run workflow). Necesita los secretos
  `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` del usuario `nexa-github-deploy` y, opcional, la variable `NEXA_URL_PUBLICA`
  (p. ej. `https://18-227-59-40.sslip.io`) para comprobar por HTTPS al final.
