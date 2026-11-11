# Distribución de la app (firma release + Firebase App Distribution)

## 1. Firma release (ya configurada en este equipo)
- Keystore: `C:\Users\FRANK SALCEDO\nexa-keystore\nexa-release.jks` (alias `nexa`, válido ~27 años). Las contraseñas están en `mobile/android/key.properties`, que **no** se versiona (`.gitignore`).
- **Haz copia de seguridad del `.jks` y de `key.properties`** (gestor de contraseñas o disco cifrado). Si se pierden no se podrá actualizar la app instalada ni publicarla en Play con la misma identidad.
- `android/app/build.gradle.kts` usa esa firma en `release`. Sin `key.properties` (p. ej. en otro PC o en CI) cae a la clave debug y avisa.
- Para firmar desde otro equipo: copia el `.jks` y crea `android/key.properties`:
  ```
  storePassword=...
  keyPassword=...
  keyAlias=nexa
  storeFile=C:/ruta/al/nexa-release.jks
  ```

## 2. Firebase App Distribution (lo único que debes hacer tú)
1. En <https://console.firebase.google.com> crea un proyecto (p. ej. "NEXA") y añade una **app Android** con el paquete `com.nexa.nexa_mobile`. No hace falta descargar `google-services.json` (App Distribution no usa el SDK).
2. En el proyecto: *Release & Monitor → App Distribution → Get started*. Crea un grupo de testers llamado `testers` y añade sus correos.
3. Copia el **ID de la app** (Configuración del proyecto → tu app → "ID de la aplicación", formato `1:123456789:android:abc123`).
4. Instala la CLI e inicia sesión (una vez):
   ```
   npm install -g firebase-tools
   firebase login
   ```
5. Define el ID en tu entorno (no va en el repo):
   ```
   setx FIREBASE_APP_ID "1:123456789:android:abc123"
   ```
   (abre una terminal nueva después).

## 3. Publicar una versión
```
cd mobile
.\tool\distribuir.ps1 -Notas "Qué cambió" -Grupos "testers"
```
El script sube el número de compilación (`+N` en `pubspec.yaml`), compila `app-release.apk` firmado y lo sube. Los testers reciben un correo/notificación y actualizan con un toque; al ser la misma firma, los datos se conservan.

Opciones: por defecto el APK usa el backend real de producción (`-UsarMocks $false` y la URL de Azure); `-UsarMocks $true` genera una versión de demostración sin backend, y `-ApiBaseUrl "https://..."` apunta a otro servidor; `-SoloCompilar` para generar el APK sin subirlo; `-SinSubirVersion` para no tocar la versión.

Recuerda hacer commit del cambio de versión en `pubspec.yaml` tras cada publicación.

## 4. Más adelante: Google Play
Mismo keystore, pero con `flutter build appbundle --release` y subida a Play Console (prueba interna → producción). Considera activar *Play App Signing*.

## 5. Estado actual
- Proyecto Firebase: `proyecto-de-aula-440001` ("Proyecto de aula"). App Android "NEXA" (`com.nexa.nexa_mobile`), ID `1:149476826934:android:49bdf096195c1c64829d97` (el ID no es secreto; la autorización es tu sesión de `firebase login`).
- Primera versión distribuida: 1.0.0 (2), invitando directamente por correo (`-Testers`). Para invitar a más personas: `-Testers "a@x.com,b@y.com"` o crea un grupo en la consola y usa `-Grupos`.
- Cada publicación: `$env:FIREBASE_APP_ID = '1:149476826934:android:49bdf096195c1c64829d97'; .\tool\distribuir.ps1 -Testers '...' -Notas '...'`
- 1.0.0 (3): primera versión contra el backend real (`USE_MOCKS=false`, `API_BASE_URL=https://nexa-ece5b3dbfecvf3cq.eastus2-01.azurewebsites.net`). Con el backend real solo inician sesión los pasajeros; no hay registro desde la app.
- 1.0.0 (3) falló al iniciar sesión: producción (`master`) aún no abre `/api/auth/login` (responde 401 "Full authentication is required"); esa ruta solo existe en la rama `servicio-de-niveles`.
- 1.0.0 (4): vuelve a modo demo (`USE_MOCKS=true`) hasta que el backend con login JWT se despliegue.
- 1.0.0 (5): splash visible (2,2 s mínimo) y origen/destino editables con búsqueda de direcciones (modo demo).
- 1.0.0 (6): primera versión conectada al backend real de producción (`USE_MOCKS=false`, URL de Azure). Publicada el 2026-10-27 para `frankjosesalcedo18@gmail.com`, el único tester registrado en Firebase. Firmada con la clave de producción (`CN=NEXA`). El `key.properties` de este equipo está en `C:\Users\FRANK SALCEDO\code\NEXA_Origin\.claude\worktrees\feature-flutter-app-77aea8\mobile\android\`.

## 6. Antes de publicar la próxima versión (checklist)
1. **Backend desplegado.** Producción tiene que traer los endpoints de la rama `feat/api-movil-auth` (login JWT de conductores, `POST /api/auth/registro/pasajero|conductor`, `GET /api/pasajero/posicion-conductor/{id}`). Sin ellos los conductores no pueden iniciar sesión ni nadie registrarse desde la app. Compruébalo: `POST <url>/api/auth/registro/pasajero` con `{}` debe responder 400 (validación), no 401 ni 404.
2. **Calidad.** En `mobile/`: `dart format --set-exit-if-changed lib test`, `flutter analyze` y `flutter test` deben pasar.
3. **Probar contra el backend real** en un teléfono o emulador: registro y login de pasajero y de conductor, pedir un viaje, aceptarlo desde un segundo dispositivo y recorrer «Llegué» → iniciar → completar.
4. **Firma.** Compila con tu `android/key.properties` y el keystore de este equipo (sección 1): con otra clave, Android no deja actualizar encima de la versión instalada.
5. **Publicar.** `$env:FIREBASE_APP_ID = '...'; .\tool\distribuir.ps1 -Testers '...' -Notas '...'`.
6. En iOS, `Info.plist` ya incluye los textos de permiso de cámara y fotos; la app de iOS no se ha compilado ni probado todavía.
