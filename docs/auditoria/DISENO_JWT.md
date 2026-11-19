# Diseño de revocación JWT (propuesta, no desplegada)

## Contrato actual

`POST /api/auth/login` devuelve `LoginResponse(token)`; el Bearer contiene `sub` (correo), `roles`, `userId`, `iat` y `exp`, firmado con HS256. `jwt.expiration=86400000` (24 h). `JwtAuthFilter` verifica firma y expiración y vuelve a cargar el usuario por correo. La web usa sesión y no depende de este token. No hay refresh token ni revocación persistida. Un cambio de contraseña deja válidos los JWT emitidos hasta su expiración.

## Propuesta compatible

1. Resolver primero la ambigüedad de correo descrita en `MIGRACION_IDENTIDAD.md`.
2. Añadir a `Usuario` una versión de credenciales (`tokenVersion`, valor inicial 0). Emitir una claim nueva `ver` y comprobarla frente al usuario persistido en cada petición Bearer. Aumentarla atómicamente al restablecer/cambiar contraseña y en un cierre de sesión **de todos los dispositivos**. Los tokens antiguos sin `ver` se aceptarán solo durante una ventana de transición acotada; después se rechazarán. No guardar JWT en claro.
3. Mantener `LoginResponse.token` y los campos JWT existentes durante la transición móvil. La primera versión no requiere cambios en la app para iniciar sesión de nuevo tras un 401.
4. Evaluar access tokens más breves y refresh tokens rotados por dispositivo solo después de confirmar con los clientes móviles el almacenamiento seguro, respuesta del login, reintentos ante 401 y logout. Guardar únicamente hash de refresh token con expiración/TTL; revocar su familia ante reutilización.

## Alternativas y riesgos

Una marca temporal `validAfter` evita una claim nueva, pero la precisión de `iat` en segundos y los relojes requieren cuidado; una versión entera evita ese borde. La versión revoca todos los dispositivos, no uno solo. Para logout de un dispositivo harían falta identificadores de sesión persistidos y expiración; no se justifica añadir Redis solo para esto. MongoDB ya es el almacén disponible. Un fallo de lectura de versión debe rechazar la autenticación, no aceptar un token sin comprobar.

## Validación antes de activar

Pruebas de firma/expiración, versión correcta/incorrecta y token legado; reset y cambio de contraseña invalidan JWT anteriores; dos cambios concurrentes no pierden la versión; usuario deshabilitado no accede; login móvil conserva JSON y roles; reintento móvil tras 401; sesión web permanece funcional. Desplegar servidor compatible antes de exigir la claim nueva y medir rechazos durante la ventana de transición.
