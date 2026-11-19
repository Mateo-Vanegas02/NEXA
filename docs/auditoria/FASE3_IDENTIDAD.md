# Fase 3: identidad

En MongoDB aislado se insertaron dos documentos sintéticos con el mismo correo y roles pasajero/conductor. `Usuarios` contó dos; `findByEmail` rechazó el resultado múltiple y `CustomUserDetailsService` falló cerrado. Esto confirma la incompatibilidad entre el índice declarado `(email, rol)` y los flujos que identifican solo por correo. No mide duplicados de usuarios reales.

La política propuesta es una identidad única por correo normalizado con roles asociados, sujeta a decisión de producto y análisis del modelo móvil. Alternativas: correos distintos por rol o identidad explícita por rol en login, reset y JWT. No se fusionaron cuentas ni cambiaron correos.

Antes de migrar: agrupar por correo normalizado (espacios y mayúsculas), contar ausentes/nulos, revisar cada colisión con propietarios sin publicar direcciones, definir recuperación de cuentas y contrato móvil, crear campo normalizado por lotes reanudables en copia, probar login web/móvil, JWT y reset, y construir índice único solamente tras resolver colisiones. Conservar respaldo y plan de reversión. Véase `MIGRACION_IDENTIDAD.md`.
