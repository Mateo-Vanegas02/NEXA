# Flujo de un viaje

```mermaid
stateDiagram-v2
    [*] --> SOLICITADO: pasajero solicita
    SOLICITADO --> ACEPTADO: conductor toma (update condicional)
    SOLICITADO --> CANCELADO: pasajero o vencimiento
    ACEPTADO --> EN_CURSO: llegada e inicio
    ACEPTADO --> CANCELADO: cancelación autorizada
    EN_CURSO --> FINALIZADO: conductor finaliza
    EN_CURSO --> CANCELADO: cancelación autorizada
    FINALIZADO --> [*]: calificación opcional
    CANCELADO --> [*]
```

El servidor fija el canal `WEB` o `APP` al crear la solicitud y comprueba el propietario y el estado en cada transición. `ServicioRepository.tomarSiDisponible` impide que dos conductores acepten la misma solicitud. `DespachoService` filtra por ola y posición vigente; `DespachoScheduler` amplía olas y vence solicitudes sin conductor. Tras persistir, `ServicioServiceImpl` avisa por STOMP y, para viajes APP, por push. Las vistas por rol pasan por `VisibilidadServicio`, que oculta calificaciones ajenas, comisiones y deuda según el destinatario. Para límites, tarifas y niveles ver `docs/niveles/DECISIONES.md`.
