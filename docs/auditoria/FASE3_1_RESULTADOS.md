# Fase 3.1 — estado verificable

El propietario confirmó que la conexión `motvirsweb` inspeccionada es de producción.

La rama de trabajo es `codex/fase-3-validacion`. Se revisó `ServicioServiceImpl` y se añadieron actualizaciones condicionadas para inicio, finalización, cancelación y calificación. No se ha desplegado ni fusionado este trabajo.

Las pruebas de fase 3.1 se ejecutaron en GitHub Actions con MongoDB 7 desechable en réplica: 11 pruebas de integración, sin fallos. La suite Java y el arranque Docker de ese commit también pasaron. Véanse `FASE3_1_PRUEBAS.md` y `FASE3_1_CONCURRENCIA.md`. No se ha desplegado ni fusionado este trabajo.

La conexión de Compass mostró la base `motvirsweb` con 18 colecciones, `Usuarios` con 54 documentos y `servicios` con 610. El propietario confirmó que es **producción**. Ambas colecciones muestran solamente el índice `_id_`; el inventario de duplicados no está confirmado. No se modificaron datos de Atlas.

Se implementó una transacción Mongo para las transiciones de viaje, una bandeja persistente con reintentos de avisos y registro de deuda/cargo en el mismo commit de cancelación. La prueba de reversión y reintento pasó con MongoDB real en CI. La entrega de avisos es al menos una vez; el cliente debe ignorar identificadores de evento repetidos. Quedan pendientes el análisis de secretos históricos y cualquier operación de respaldo o migración. No se reescribió el historial Git.

Identidad y sesiones: `AuthService` permite registrar por rol, mientras `CustomUserDetailsService`, `PasswordResetService` y `JwtAuthFilter` operan con correo como identificador. Sin recuento de duplicados normalizados y decisión de negocio no es seguro imponer unicidad global. `JwtService` firma tokens HS256 con correo, `userId` y roles; el filtro vuelve a consultar la cuenta, pero no invalida tokens por cambio de contraseña. Un `tokenVersion` exigiría una transición definida para tokens ya emitidos y pruebas de compatibilidad móvil. No se alteró el contrato de login.
