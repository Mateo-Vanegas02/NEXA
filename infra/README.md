# Infraestructura de NEXA en AWS (us-east-2)

Plantillas de CloudFormation, una pila por fase. Se cargan desde la consola
(CloudFormation → Create stack → Upload a template file). Nada de esto guarda secretos.

| Pila | Plantilla | Qué crea | Estado |
|---|---|---|---|
| `nexa-00-cuenta` | `cloudformation/00-cuenta.yml` | Usuario IAM `nexa-github-deploy` con permisos mínimos para desplegar | por crear |

Hecho a mano en la consola: presupuesto `nexa-mensual` (USD 30, alertas por correo).

## Por qué un usuario IAM y no OIDC
La cuenta pertenece a una organización cuya SCP niega todas las operaciones sobre proveedores
OIDC de IAM (verificado el 10 nov. 2026). GitHub Actions usa entonces claves de acceso de un
usuario sin consola y con lo mínimo: subir a ECR la imagen `nexa-backend` y mandar comandos por
SSM solo a la instancia etiquetada `Name=nexa-servidor`. Las claves se crean en la consola y se
guardan únicamente en los secretos del repositorio (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`).
Rotarlas cada 90 días.
