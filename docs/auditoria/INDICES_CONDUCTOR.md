# Unicidad de licencia y SOAT: plan de despliegue

`AuthService` hace comprobaciones `exists` para mensajes tempranos. No son garantía bajo concurrencia. `Conductor` declara `@Indexed(unique=true)` para licencia, SOAT y tarjeta de propiedad, pero comparte `Usuarios` con pasajeros y administradores. La creación automática de índices no está activada en la configuración revisada; las anotaciones no prueban que el índice exista. Índices únicos de campo simple podrían colisionar con valores ausentes, `null` o `0` heredados.

## Comprobación previa (solo copia aislada)

- Inventariar `db.Usuarios.getIndexes()` y anotar nombre, claves, unicidad y filtro parcial.
- Agrupar conductores por licencia y SOAT, incluyendo tipo BSON, `null`, ausentes y cero; revisar también tarjeta de propiedad. Resolver duplicados con el dueño de los datos. Verificar que valores numéricos no se mezclan con cadenas heredadas.
- Crear y probar índices únicos **parciales** por rol `CONDUCTOR` y valores válidos en una copia. Los filtros exactos se fijan según los tipos observados; no ejecutar una receta genérica a ciegas. Mantener las comprobaciones previas y traducir `DuplicateKeyException` a conflicto sin detalles internos.
- Correr registros simultáneos reales contra Mongo de pruebas: exactamente uno debe persistir por licencia/SOAT, y conductores distintos deben registrarse. Probar pasajeros, documentos heredados y valores ausentes.
- Desplegar código e índices con respaldo, plan de reversión y ventana de observación. No eliminar índices existentes hasta verificar los reemplazos.

Esta fase traduce las colisiones de índice al cliente, pero no afirma unicidad concurrente en producción mientras no se inspeccionen y creen los índices adecuados.
