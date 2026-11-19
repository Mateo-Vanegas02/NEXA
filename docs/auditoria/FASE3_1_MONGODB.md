# Fase 3.1 — MongoDB Atlas

El propietario confirmó que la conexión inspeccionada corresponde a **producción**. Cualquier respaldo, restauración, índice o migración requiere un procedimiento aislado y autorización específica para modificar datos.

La pestaña de índices de `servicios` también mostró únicamente `_id_` (único). No se observaron índices para estado, conductor, pasajero o fechas en esa colección.

Inspección de lectura mediante MongoDB Compass sobre `motvirsweb` del host guardado `motvirs.uaqijwe.mongodb.net`. La base contiene 18 colecciones. Recuentos visibles: `Usuarios` 54, `servicios` 610, `creditos_nexa` 0, `beneficios_uso` 0, `acciones_idempotentes` 0, `xp_eventos` aproximadamente 1.5 mil. No se copiaron documentos personales al informe.

La pestaña de índices de `Usuarios` muestra solo `_id_` (único). Esto no demuestra unicidad de correo, licencia o SOAT en la base actual. La fase 3 previa probó índices parciales en una base aislada; no los creó aquí. Faltan versión del servidor, duplicados normalizados, tipos BSON y valores nulos o ausentes. No se ejecutaron migraciones ni se creó un respaldo: no hay un destino aislado y restauración verificada.

Antes de crear índices únicos, se necesitan agregados redactados de duplicados y tipos reales; luego respaldo consistente, restauración de ensayo y prueba sobre la copia. El índice propuesto debe corresponder a los nombres y tipos persistidos de `Usuarios`.
