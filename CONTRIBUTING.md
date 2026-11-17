# Contribuir a NEXA

1. Crear una rama desde `main` actualizado y usar commits convencionales (`fix:`, `feat:`, `docs:`, `test:`).
2. Mantener las rutas públicas y el contrato móvil; registrar rutas nuevas en `SecurityConstants.java`. Para servicios con viajes, aplicar `VisibilidadServicio` antes de devolver entidades o emitir mensajes.
3. No introducir secretos en Git ni ejecutar pruebas contra producción. Para índices o migraciones, usar una copia restaurable y documentar duplicados, compatibilidad y reversión.
4. Correr pruebas dirigidas, `./mvnw clean install`, `node --test src/test/js/*.test.mjs` y revisar `git diff --check`. Los tests de integración Mongo requieren una instancia aislada.
5. Abrir un PR con problema, cambios, pruebas ejecutadas y límites de validación. El despliegue AWS es manual y afecta al servidor actual.
