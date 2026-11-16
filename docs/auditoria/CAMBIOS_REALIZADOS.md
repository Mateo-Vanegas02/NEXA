# Cambios realizados

## Seguridad de recuperación de contraseña

- `Usuario` ahora persiste `resetPasswordTokenHash`, no el token en claro.
- `PasswordResetService` genera 256 bits aleatorios, almacena SHA-256 codificado en Base64 URL y vuelve a calcular el hash al validar.
- El token se elimina junto con su expiración tras un uso correcto.
- `UsuarioRepository` consulta por el hash indexado.
- Se actualizaron las pruebas de serialización y se añadieron tres pruebas unitarias de almacenamiento, consumo único/limpieza y expiración.

Los campos antiguos que pudieran existir en documentos MongoDB no se migraron ni eliminaron automáticamente. Deben invalidarse mediante una migración controlada cuando el propietario autorice acceso a la base.

## Entrenamiento ML

- `ModeloController` acepta el entrenamiento únicamente mediante POST.
- `Dashboard_A.js` envía POST con el token CSRF que ya contiene el panel de administración.
- `GET /api/admin/ml/resultado` permanece disponible para consulta.
- Se agregó prueba de regresión para GET rechazado, POST sin CSRF, rol ajeno y POST administrativo válido.

## Registro de conductores

- `AuthService.registrarConductor` consulta la existencia de licencia y SOAT por rol mediante métodos derivados de `UsuarioRepository`, sin materializar todos los conductores.
- Se conserva la validación previa y los campos persistidos. Dos pruebas comprueban el registro y el rechazo de licencia repetida.
- El índice y los datos existentes deben verificarse en una base aislada antes de cualquier ajuste de esquema. La comprobación previa no sustituye una restricción de unicidad atómica ante registros simultáneos.
