# Fase 3.2 — Auditoría de secretos del repositorio NEXA

Alcance: solo `Mateo-Vanegas02/NEXA`. Fecha: 17 de noviembre de 2026. No se imprimen valores: los informes de
Gitleaks se generaron con `--redact=100` y los fragmentos revisados se leyeron enmascarados.

## Qué se revisó

- Clon espejo (`git clone --mirror`) con **todas** las referencias: 5 ramas (`main`, `app`,
  `codex/auditoria-seguridad`, `codex/fase-2-integridad`, `codex/fase-3-validacion`) y las referencias de los PR
  #1–#3 (`refs/pull/*/head|merge`). No hay etiquetas. 110 commits en total.
- Gitleaks 8.30.1 (binario verificado por checksum) en modo `git --log-opts="--all"` sobre ese espejo, y en modo
  `dir` sobre el árbol de trabajo actual.
- Búsquedas propias en todo el historial: nombres de archivo de credenciales (`.env`, `*.pem`, `*.p12`, `*.jks`,
  `*.keystore`, cuentas de servicio, `google-services.json`, `GoogleService-Info.plist`, `id_rsa`, `.npmrc`,
  `settings.xml`), URIs `mongodb+srv://` con usuario y contraseña, claves privadas PEM, `"private_key"` de cuentas de
  servicio, `SPRING_MAIL_PASSWORD` con valor y propiedades con contraseña, secreto, URI o clave sin `${...}`; todas
  las versiones de `.env.example`.

## Hallazgos y clasificación

| # | Regla | Archivo | Dónde | Clasificación | Acción |
|---|---|---|---|---|---|
| 1 | `generic-api-key` | `.github/workflows/ci.yml` (línea del `JWT_SECRET` de la prueba de arranque) | Todas las ramas salvo `app` | **Secreto ficticio de prueba**: base64 de un texto de prueba, junto a `test-gemini-key` y `test-mail-password` | Ninguna. Registrado en `.gitleaksignore` |
| 2 | `grafana-api-key` | `src/main/resources/templates/panel_admin.html` (iframe de Power BI) | Todas las ramas salvo `app` | **Falso positivo como credencial; riesgo de exposición de datos.** Es un enlace de "Publicar en la web" de Power BI: cualquiera con el enlace ve el informe, y el repositorio es público | El propietario debe confirmar qué datos muestra el informe; si hay datos reales de usuarios o viajes, eliminar su código de inserción desde la administración de códigos de inserción de Power BI y servir el informe con autenticación |
| 3 | `gcp-api-key` | `mobile/android/app/google-services.json` | Solo rama `app` | **Configuración pública de cliente** (Firebase Android, proyecto de push). Va dentro del APK por diseño; no es una credencial de servidor | Confirmar en Google Cloud Console que la clave tiene restricción de aplicación Android (paquete de la app y huella SHA-1) y restricción de API a las de Firebase que se usan. Sin restricciones, cualquiera podría consumir esas APIs con la cuota del proyecto |

Las búsquedas propias no encontraron: archivos `.env` versionados, URIs de MongoDB con credenciales, claves privadas,
cuentas de servicio de Google, ni contraseñas o secretos con valor en `application*.properties`. `.env.example` solo
tuvo variables vacías y `SPRING_PROFILES_ACTIVE` en todas sus versiones. El único `SPRING_MAIL_PASSWORD` con valor
es el ficticio de la prueba de arranque de CI.

**Credenciales de servidor confirmadas: ninguna.** No hay credenciales potencialmente activas que rotar a partir de
este repositorio, y no se justifica reescribir el historial: no hay una ruta o valor sensible confirmado que filtrar.
No se simuló `git-filter-repo` por esa razón.

## Configuración de GitHub

La API del repositorio informa que **secret scanning, push protection y las comprobaciones de validez están
desactivados**. En un repositorio público son gratuitos. Recomendación: activarlos en Settings → Code security
(Secret Protection y Push Protection). No se cambió ninguna configuración desde aquí.

## Prevención (se mantiene)

- `.github/workflows/secret-scan.yml` sigue escaneando los commits nuevos de cada push y PR con Gitleaks verificado
  por checksum.
- `.gitleaksignore` (nuevo) solo contiene el hallazgo 1. Los hallazgos 2 y 3 siguen visibles en un escaneo completo
  hasta que el propietario confirme sus restricciones.

## Pendiente del propietario

1. Revisar el contenido y la visibilidad del informe de Power BI del panel de administración (hallazgo 2).
2. Verificar las restricciones de la clave de Firebase Android (hallazgo 3).
3. Activar secret scanning y push protection en GitHub.
