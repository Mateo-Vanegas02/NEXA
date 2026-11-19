# Identidad por correo: decisión y migración pendiente

`Usuario` declara índice único `(email, rol)`, mientras login web, login móvil, recuperación, cambio de contraseña y JWT identifican una cuenta solo por `email`. Las comprobaciones de registro también son por rol. Por ello dos cuentas con el mismo correo y distinto rol pueden existir bajo el esquema declarado. Spring Data espera un solo resultado para `Optional<Usuario> findByEmail`: ante múltiples coincidencias se rechaza la operación; no se debe escoger una fila arbitraria.

Se eliminó la consulta redundante de recuperación y se convirtió el fallo por duplicidad en un error de autenticación genérico. No se cambió el contrato de registro ni los índices sin conocer cuentas existentes. Hasta resolver la identidad, un correo compartido no puede iniciar sesión ni recuperar contraseña de forma segura. Se requiere una decisión de producto: una cuenta global con varios roles, correos distintos por rol, o login con selector de rol. La primera opción encaja con el contrato actual, pero exige migración.

## Plan sin pérdida de datos

1. En una copia aislada y restaurable de `Usuarios`, inspeccionar `getIndexes()` y agrupar por correo normalizado; incluir diferencias de mayúsculas, espacios, ausencia y `null`. Identificar cada cuenta duplicada y propietario, sin copiar contraseñas entre cuentas.
2. Acordar con el dueño la política de identidad y resolver manualmente cada colisión; dar un canal de recuperación a las personas afectadas. No fusionar cuentas ni cambiar correos automáticamente.
3. Añadir campo de correo normalizado, rellenarlo por lotes reanudables en copia, verificar recuentos y construir índice único allí. Probar login web/móvil, reset y registro con correo único y compartido.
4. Preparar respaldo y reversión antes de ejecutar en producción. Activar lectura/escritura consistente y después el índice nuevo; retirar el índice compuesto antiguo solo tras verificar la nueva política. Monitorear errores de duplicado y solicitudes de soporte.

El acceso a datos de producción y la decisión sobre cuentas compartidas están pendientes. Ningún script de migración se ejecutó.
