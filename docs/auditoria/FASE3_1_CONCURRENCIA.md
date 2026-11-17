# Fase 3.1 — concurrencia de viajes

También se reemplazó la escritura completa de confirmación de llegada por una actualización condicional; falta ejecutarla contra MongoDB real aislado.

Se confirmó que inicio, finalización, cancelaciones y calificación utilizaban lectura seguida de `save()` del documento completo. Ese patrón podía sobrescribir una transición más reciente. `ServicioRepository` ahora expone escrituras condicionales por `_id`, estado y participante. `ServicioServiceImpl` comprueba el recuento modificado y responde con conflicto si perdió la carrera. Los efectos posteriores de estas rutas se ejecutan solo cuando la transición se persistió. La finalización actualiza recorrido, deuda y resultado de niveles por campos, sin volver a guardar todo el viaje.

`ViajeEnVivoService.recorridoActual` toma una instantánea antes de la transición para calcular la fracción de cobro sin detener el seguimiento antes de confirmar la escritura.

La prueba unitaria focal de conflicto y las pruebas nuevas en `Phase3MongoIntegrationTest` cubren una carrera inicio/cancelación, doble finalización, doble calificación y rechazo de otro conductor o de estados cerrados. Estas últimas están compiladas pero no ejecutadas: Testcontainers no encuentra Docker en el entorno local.

Se añadió `MongoTransactionManager` y `@Transactional` a aceptación, llegada, inicio, finalización y cancelaciones. `AvisosPendientesService` inserta el aviso en la misma transacción, reclama avisos con un plazo de bloqueo, y reintenta después de fallos. `DeudaService.registrar` escribe la deuda dentro de la transacción de cancelación; si encuentra otra deuda, el viaje se revierte y el cliente puede repetir la solicitud. El correo de deuda sale de la bandeja después del commit. Los efectos del seguimiento en memoria se ejecutan después del commit.

Pendientes: ejecutar en MongoDB real la prueba nueva de reversión de viaje/deuda/aviso y reintento tras fallo de socket; confirmar el mapeo de `@Update`; cubrir llegada concurrente y fallos de campos derivados. Los avisos usan entrega al menos una vez: si el proveedor acepta un envío y el proceso cae antes de marcarlo, puede repetirse. La app deduplica avisos push por `eventoId`; el correo de deuda podría repetirse en ese caso. No se debe declarar integridad total del ciclo de vida hasta pasar la integración y revisar estos límites.
