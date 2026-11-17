# Fase 3.1 — estado verificable

El propietario confirmó que la conexión `motvirsweb` inspeccionada es de producción.

La rama de trabajo es `codex/fase-3-validacion`. Se revisó `ServicioServiceImpl` y se añadieron actualizaciones condicionadas para inicio, finalización, cancelación y calificación. No se ha desplegado ni fusionado este trabajo.

La fase **no está cerrada**. Las pruebas unitarias focales pasaron, pero las pruebas nuevas de MongoDB real no pudieron arrancar en este equipo porque Testcontainers no encontró Docker. El resultado de CI de la fase 3 anterior no valida estas modificaciones. Véanse `FASE3_1_PRUEBAS.md` y `FASE3_1_CONCURRENCIA.md`.

La conexión de Compass mostró la base `motvirsweb` con 18 colecciones, `Usuarios` con 54 documentos y `servicios` con 610. El propietario confirmó que es **producción**. Ambas colecciones muestran solamente el índice `_id_`; el inventario de duplicados no está confirmado. No se modificaron datos de Atlas.

Se implementó una transacción Mongo para las transiciones de viaje, una bandeja persistente con reintentos de avisos y registro de deuda/cargo en el mismo commit de cancelación. La suite local sin Mongo pasó, pero este cambio aún necesita la ejecución de integración con MongoDB real. La entrega de avisos es al menos una vez; el cliente debe ignorar identificadores de evento repetidos. Quedan pendientes el análisis de secretos históricos y cualquier operación de respaldo o migración. No se reescribió el historial Git.

Identidad y sesiones: `AuthService` permite registrar por rol, mientras `CustomUserDetailsService`, `PasswordResetService` y `JwtAuthFilter` operan con correo como identificador. Sin recuento de duplicados normalizados y decisión de negocio no es seguro imponer unicidad global. `JwtService` firma tokens HS256 con correo, `userId` y roles; el filtro vuelve a consultar la cuenta, pero no invalida tokens por cambio de contraseña. Un `tokenVersion` exigiría una transición definida para tokens ya emitidos y pruebas de compatibilidad móvil. No se alteró el contrato de login.
