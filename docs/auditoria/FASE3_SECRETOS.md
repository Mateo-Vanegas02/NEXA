# Fase 3: inventario de secretos

Gitleaks 8.30.1 verificó todas las referencias Git alcanzables con redacción total. Halló una coincidencia `gcp-api-key` en `mobile/android/app/google-services.json` de la rama `app`; corresponde a configuración cliente Android Firebase. Se debe revisar restricción de la clave y uso autorizado en Google Cloud. No se comprobó si sigue activa. No se publican sus valores.

La inspección de las versiones alcanzables de `application.properties` (tres) y `.env.example` (tres) halló referencias a variables y valores vacíos, respectivamente; no halló versiones de `.env`. No se confirmó una contraseña de servidor expuesta en las referencias de este repositorio. `docs/SEGURIDAD.md` menciona otro repositorio, `NEXA_Origin`; requiere auditoría separada antes de atribuirle una exposición a NEXA.

El escaneo del árbol de trabajo marcó un JWT ficticio de CI y una URL de publicación Power BI en la plantilla de administración. La URL merece revisión de visibilidad del informe; no se clasifica como credencial. El directorio compilado repitió esa coincidencia. Ninguno de los commits nuevos de esta fase produjo hallazgos en el escaneo Git.

No se rotaron ni revocaron credenciales: faltan confirmación de actividad y acceso al proveedor. Si la clave cliente carece de restricciones adecuadas, restringirla o sustituirla siguiendo el procedimiento del proveedor, comprobar web/móvil y revocar la anterior. Mantener secretos de servidor en variables de entorno y fuera de logs. `.gitignore` excluye `.env`; `.env.example` usa valores vacíos. El workflow `Secret scan` escanea commits nuevos con Gitleaks verificado por checksum. Revisar si GitHub Secret Scanning y Push Protection están disponibles y habilitarlos con el propietario.
