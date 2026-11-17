# Fase 3.1 — concurrencia de viajes

También se reemplazó la escritura completa de confirmación de llegada por una actualización condicional; falta ejecutarla contra MongoDB real aislado.

Se confirmó que inicio, finalización, cancelaciones y calificación utilizaban lectura seguida de `save()` del documento completo. Ese patrón podía sobrescribir una transición más reciente. `ServicioRepository` ahora expone escrituras condicionales por `_id`, estado y participante. `ServicioServiceImpl` comprueba el recuento modificado y responde con conflicto si perdió la carrera. Los efectos posteriores de estas rutas se ejecutan solo cuando la transición se persistió. La finalización actualiza recorrido, deuda y resultado de niveles por campos, sin volver a guardar todo el viaje.

`ViajeEnVivoService.recorridoActual` toma una instantánea antes de la transición para calcular la fracción de cobro sin detener el seguimiento antes de confirmar la escritura.

La prueba unitaria focal de conflicto y las pruebas de `Phase3MongoIntegrationTest` cubren una carrera inicio/cancelación, doble finalización, doble calificación y rechazo de otro conductor o de estados cerrados. Las 11 pruebas de integración pasaron en CI con MongoDB 7 en réplica; el equipo local no tiene Docker.

Se añadió `MongoTransactionManager` y `@Transactional` a aceptación, llegada, inicio, finalización y cancelaciones. `AvisosPendientesService` inserta el aviso en la misma transacción, reclama avisos con un plazo de bloqueo, y reintenta después de fallos. `DeudaService.registrar` escribe la deuda dentro de la transacción de cancelación; si encuentra otra deuda, el viaje se revierte y el cliente puede repetir la solicitud. El correo de deuda sale de la bandeja después del commit. Los efectos del seguimiento en memoria se ejecutan después del commit.

La prueba nueva confirmó en MongoDB real la reversión conjunta de viaje/deuda/aviso y el reintento tras fallo de socket. Los métodos `@Update` usados por estas pruebas quedaron validados. Pendientes fuera del alcance de este cierre: carrera específica de llegada y fallos de campos derivados. Los avisos usan entrega al menos una vez: si el proveedor acepta un envío y el proceso cae antes de marcarlo, puede repetirse. La app debe deduplicar avisos push por `eventoId`; el correo de deuda podría repetirse en ese caso.
