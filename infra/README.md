# Infraestructura de NEXA en AWS (us-east-2)

Plantillas de CloudFormation, una pila por fase. Se cargan desde la consola
(CloudFormation → Create stack → Upload a template file). Nada de esto guarda secretos.

| Pila | Plantilla | Qué crea | Estado |
|---|---|---|---|
| `nexa-00-cuenta` | `cloudformation/00-cuenta.yml` | Usuario IAM `nexa-github-deploy` con permisos mínimos para desplegar | creada (10 nov.) |
| `nexa-10-web` | `cloudformation/10-web.yml` | EC2 t3.small (Amazon Linux 2023, Docker, 2 GB de swap), IP fija, security group 80/443, rol del servidor y repositorio ECR `nexa-backend` | creada (10 nov.): IP `18.227.59.40`, prueba en `https://18-227-59-40.sslip.io` |

Hecho a mano en la consola: presupuesto `nexa-mensual` (USD 30, alertas por correo) y los parámetros de
Parameter Store `/nexa/prod/*` (web) y `/nexa/ml/MONGODB_URI` (entrenamiento), cargados por el dueño de la cuenta.

Sin dominio propio todavía: la web se prueba en `https://<ip-con-guiones>.sslip.io` (salida `DireccionPrueba`
de `nexa-10-web`). Route 53 Domains no está disponible en cuentas Free Tier; el dominio se compra afuera.

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
