# Fase 3.3 — Preparación para la evaluación de producción

Fecha: 17 de noviembre de 2026. Alcance: este repositorio y las ramas `main`, `app`, `codex/fase-2-integridad` y `codex/fase-3-validacion`. Ningún cambio de este documento se aplicó a Atlas ni a AWS.

## Revisado y cambiado

- PR #2 (`fase-2-integridad` → `main`) y #3 (`fase-3-validacion` → `fase-2-integridad`): ambos abiertos, fusionables según GitHub, con CI verde en sus cabezas; #3 también tiene Secret scan verde. Se actualizaron sus descripciones. El escaneo histórico de Gitleaks y la clasificación de tres hallazgos están en `FASE3_2_SECRETOS.md`: uno es ficticio de CI, uno es el enlace público de Power BI y uno es la clave pública de Firebase Android. No se confirmó una credencial de servidor en el historial. No se reescribió Git.
- PR #4 (`codex/fase-3-3-backend` → `codex/fase-3-validacion`) y #5 (`codex/fase-3-3-app` → `app`) quedaron abiertos. En sus cabezas verificadas, #4 pasó CI y Secret scan, y #5 pasó análisis, pruebas y compilación Android del workflow Mobile. Ninguno se fusionó.
- El correo se normaliza en `Correo.normalizar` (`trim` y `Locale.ROOT`) antes de guardarse; las búsquedas del repositorio lo normalizan en un solo punto. Un correo puede repetirse entre roles. El login web y `/api/auth/login` aceptan rol explícito para un correo compartido; sin rol, la consulta ambigua falla cerrada. El JWT con `userId` resuelve la cuenta por id, no por el orden de Mongo. Recuperación y cambio de contraseña también pueden seleccionar la cuenta. Se añadieron pruebas de mayúsculas, espacios, ambos y selección de rol.
- `normalizar-correos.js` muestra en plan los afectados enmascarados y las colisiones por `{email, rol}`. `aplicar` omite las colisiones, actualiza solo si el valor sigue igual y sincroniza las copias `servicios.pasajero.email` y cualquier copia antigua en `dispositivos`. `ConductorEmbedded` y el modelo vigente de `dispositivos` no guardan correo. `indice` crea `email_rol_unique_idx` solo cuando todos los correos están normalizados y no hay colisiones. Ninguno de estos modos se ejecutó en producción.
- El push FCM ya llevaba `eventoId` estable. El servidor ahora agrega `avisoId` a STOMP (el id de `avisos_viaje_pendientes` cuando sale de la bandeja). La app guarda ids vistos durante 48 h, con máximo 256, incluso tras reiniciar; separa recepción y toque para que una notificación recibida pueda abrirse una vez. Antes de navegar pide el viaje vigente a la API. Los avisos duplicados no repiten aceptación ni apertura. Detalle del contrato en `docs/AVISOS_PUSH.md`.
- El despliegue existente es **EC2** `nexa-servidor`, imagen en ECR y `deploy-aws.yml` manual. `preparar.sh` carga `/nexa/prod/*` de Parameter Store a un `.env` local con permisos 600; `docker-compose.aws.yml` lo inyecta al contenedor. El código confirma el recorrido. La consola de AWS solicitó iniciar sesión y no hay CLI AWS disponible aquí, así que no se comprobaron la existencia ni el tipo actuales de cada parámetro.
- `pbix_extracted/` contiene un modelo binario; las búsquedas de texto no hallaron correos, teléfonos ni cadenas de conexión literales. Los scripts Power BI contienen nombres de columnas de personas y viajes. El modelo binario requiere revisión fuera de Git antes de afirmar que no lleva filas reales. `.dockerignore` excluye ambas carpetas de la imagen.

## Orden de PRs y despliegue

1. Con aprobación explícita del propietario, fusionar #2 en `main`.
2. Cambiar la base de #3 a `main`, revisar el diff y los conflictos, esperar CI y Secret scan verdes en la nueva base y pedir aprobación explícita antes de fusionarlo. No hacer force push.
3. Revisar y fusionar por separado los PR de backend y app de fase 3.3, después de sus CI. El workflow `Deploy AWS` solo se ejecuta manualmente y **no** se ejecutó aquí.
4. Ejecutar la normalización e índice en Atlas solo después de un respaldo nuevo, restaurado y verificado. El propietario ejecuta los comandos de la sección siguiente.

## Comandos PowerShell para Atlas, en orden

Ejecutar desde la raíz del repositorio con MongoDB Database Tools, `mongosh` y un MongoDB local aislado disponibles. Los comandos piden la contraseña de forma interactiva; no ponerla en la URI, el historial de la terminal ni archivos del repositorio. El respaldo contiene datos personales: guardarlo cifrado fuera de Git. Reemplazar solo los marcadores de host y usuario.

```powershell
$fecha = Get-Date -Format 'yyyy-MM-dd'
$atlas = 'mongodb+srv://<cluster>/'
$lector = '<usuario-lectura>'
$escritor = '<usuario-mantenimiento>'
$carpeta = Join-Path $env:USERPROFILE 'NEXA-respaldos'
New-Item -ItemType Directory -Force -Path $carpeta | Out-Null
$respaldo = Join-Path $carpeta "motvirsweb-$fecha.archive.gz"

# 1. Respaldo, huella y restauración de comprobación en MongoDB local aislado.
mongodump --uri $atlas --username $lector --db motvirsweb --readPreference secondaryPreferred --gzip --archive $respaldo
$huella = (Get-FileHash -Algorithm SHA256 -LiteralPath $respaldo).Hash
if (-not $huella) { throw 'Respaldo sin huella' }
mongorestore --uri 'mongodb://localhost:27017/?directConnection=true' --gzip --archive $respaldo --nsFrom 'motvirsweb.*' --nsTo 'motvirsweb_copia.*' --drop
mongosh 'mongodb://localhost:27017/?directConnection=true' --eval 'var BASE="motvirsweb_copia"' --file scripts/atlas/inspeccion-solo-lectura.js > (Join-Path $carpeta "inspeccion-copia-$fecha.json")
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $respaldo).Hash -ne $huella) { throw 'Cambió el respaldo' }
# Comparar los conteos agregados de la copia con una inspección nueva de Atlas antes de seguir.
mongosh $atlas --username $lector --eval 'var BASE="motvirsweb"' --file scripts/atlas/inspeccion-solo-lectura.js > (Join-Path $carpeta "inspeccion-atlas-$fecha.json")

# 2. Plan: solo correos enmascarados y conteos; no escribe.
mongosh $atlas --username $lector --eval 'var BASE="motvirsweb"' --file scripts/atlas/normalizar-correos.js

# 3. Aplicar solo si la restauración y los conteos quedaron verificados.
mongosh $atlas --username $escritor --eval "var BASE='motvirsweb'; var MODO='aplicar'; var PRODUCCION_APROBADA='$fecha'" --file scripts/atlas/normalizar-correos.js

# 4. Inspección posterior; exigir 0 afectados y 0 colisiones antes del índice.
mongosh $atlas --username $lector --eval 'var BASE="motvirsweb"' --file scripts/atlas/normalizar-correos.js
mongosh $atlas --username $escritor --eval "var BASE='motvirsweb'; var MODO='indice'; var PRODUCCION_APROBADA='$fecha'" --file scripts/atlas/normalizar-correos.js
mongosh $atlas --username $lector --eval 'var BASE="motvirsweb"' --file scripts/atlas/inspeccion-solo-lectura.js > (Join-Path $carpeta "inspeccion-final-$fecha.json")
```

Si el plan informa una colisión, **detenerse antes de `aplicar` o `indice`** y decidir cada cuenta. No corregir una colisión por suposición.

## Lista de verificación del propietario

### Atlas

- [ ] Confirmar que `nexa-web` conserva la contraseña rotada y solo `readWrite` sobre la base de aplicación (`nexa` según la decisión del propietario; confirmar el nombre real en la URI efectiva: el código y los scripts de la fase anterior usan `motvirsweb`). No dar `readWriteAnyDatabase` ni permisos de admin.
- [ ] Limitar Access List a la IP de salida efectiva de EC2; retirar rangos amplios y usuarios temporales cuando ya no hagan falta.
- [ ] Restaurar y verificar el respaldo reciente, ejecutar plan, aplicar e inspección con los comandos anteriores. Confirmar que `email_rol_unique_idx` existe y que no quedan correos no normalizados.

### AWS, antes del despliegue

- [ ] Ejecutar esta consulta **sin `--with-decryption`**. Debe listar `MONGODB_URI`, `JWT_SECRET`, `GEMINI_API_KEY`, `SPRING_MAIL_USERNAME`, `SPRING_MAIL_PASSWORD`, `APP_BASE_URL`, `FIREBASE_CREDENCIALES` y además `DOMINIO` (lo exige `preparar.sh`). Los sensibles deben ser `SecureString`; revisar también los no sensibles según política.

```powershell
aws ssm describe-parameters --region us-east-2 --parameter-filters 'Key=Name,Option=BeginsWith,Values=/nexa/prod/' --query 'Parameters[].[Name,Type]' --output table
```

- [ ] Confirmar en EC2 que el perfil de instancia puede leer exactamente esos parámetros y descifrarlos; el script de arranque usa `get-parameters-by-path --with-decryption`. No imprimir `.env` ni salidas con valores.
- [ ] Confirmar que `FIREBASE_CREDENCIALES` aparece como `SecureString` y que `PushConfig` activa FCM al arrancar; sin ella el servidor arranca con push desactivado.

### Google Cloud y Firebase

- [ ] En el proyecto de FCM, **IAM y administración → IAM**: la cuenta de servicio usada por el servidor debe tener `Firebase Cloud Messaging API Admin` (`roles/firebasecloudmessaging.admin`) y ningún rol más amplio innecesario. En **Cuentas de servicio → cuenta → Claves**, identificar las claves antiguas; deshabilitarlas, comprobar que el envío sigue funcionando y luego eliminarlas. Google recomienda deshabilitar antes de borrar.
- [ ] En **APIs y servicios → Credenciales**, abrir la clave Android que corresponde a `mobile/android/app/google-services.json`. En **Restricciones de aplicación → Apps Android**, agregar `com.nexa.nexa_mobile` con el SHA-1 de **debug** y una segunda entrada con el SHA-1 de **release**. Obtener debug con `cd mobile/android; ./gradlew signingReport`; obtener release desde el keystore externo de distribución con `keytool -list -v -keystore <ruta-fuera-del-repo> -alias <alias>`, sin compartir el keystore ni su contraseña. En **Restricciones de API**, permitir solo las APIs Firebase realmente usadas; para este cliente FCM, verificar al menos **Firebase Installations API** y las APIs que muestre la configuración/uso del proyecto. Probar la recepción tras guardar.
- [ ] `GoogleService-Info.plist` no está en la rama `app`: el push iOS no está configurado. Si se habilita iOS, usar una clave de cliente distinta restringida a **Apps iOS** con bundle ID `com.nexa.nexaMobile` y limitar sus APIs. No usar una clave de servidor en la app.

### Power BI

- [ ] Abrir el informe y el modelo de `pbix_extracted/` fuera de Git y comprobar si contienen filas reales (correos, teléfonos, nombres, ubicaciones) o cadenas de conexión. Si las contienen, retirar `pbix_extracted/` y `powerbi_scripts/` del árbol público en un PR y sustituirlos por datos sintéticos o documentación. `.dockerignore` ya los excluye de la imagen. Sacarlos del árbol actual **no los borra del historial**: si hubo datos reales, evaluar la exposición, revocar credenciales y coordinar una limpieza histórica sin force push unilateral.
- [ ] En Power BI/Fabric, abrir el espacio de trabajo del informe → **Configuración → Administrar códigos para insertar**; localizar códigos de **Publicar en la web** activos y eliminar los que expongan datos. El administrador de Fabric también puede revisarlos en **Portal de administración → Códigos para insertar**. Deshabilitar solo la opción de publicación no elimina los códigos existentes.

### Después del despliegue

- [ ] Arranque sin errores de entorno (`EntornoObligatorioPostProcessor`) ni de conexión a Mongo; imagen y commit correctos.
- [ ] Login web y `POST /api/auth/login`: pasajero, conductor y correo compartido con rol seleccionado; un rol equivocado falla sin abrir otra cuenta.
- [ ] Viaje completo de prueba en el replica set: solicitar, aceptar, llegar, iniciar, finalizar y comprobar transacciones e idempotencia.
- [ ] Verificar que el barrido de `AvisosPendientesService` corre y que los avisos pendientes pasan a `ENVIADO` o quedan trazados como `FALLIDO`; probar un reintento FCM sin doble navegación.

## Riesgos pendientes

- No se consultaron metadatos vivos de AWS ni se abrió Atlas, Google Cloud o Power BI desde este entorno. El propietario debe completar las casillas anteriores antes de declarar el despliegue listo.
- El almacén seguro de ids vistos se comparte entre el isolate de primer plano y el receptor de segundo plano, pero sus operaciones no son una transacción entre procesos. Un arribo simultáneo excepcional puede mostrar dos veces una notificación; la aceptación y el estado del viaje siguen validados por el servidor. Para garantía estricta entre procesos haría falta una tabla local con unicidad transaccional.
- El modelo binario de Power BI no se puede declarar libre de datos personales con una búsqueda de texto. El enlace público de `panel_admin.html` sigue requiriendo revisión manual.
- Las restricciones de clave de Firebase y el rol IAM se proponen conforme a la documentación oficial: [claves Firebase](https://firebase.google.com/docs/projects/api-keys), [restricciones Google Cloud](https://docs.cloud.google.com/docs/authentication/api-keys), [rol FCM](https://firebase.google.com/docs/projects/iam/roles-predefined-product), [claves de cuenta de servicio](https://docs.cloud.google.com/iam/docs/keys-create-delete) y [códigos públicos Power BI](https://learn.microsoft.com/en-us/power-bi/collaborate-share/service-publish-to-web).
