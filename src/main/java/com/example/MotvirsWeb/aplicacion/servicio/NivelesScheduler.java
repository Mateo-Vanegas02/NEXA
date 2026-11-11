package com.example.MotvirsWeb.aplicacion.servicio;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/** Job diario: caída por inactividad (pasajeros) y ventana móvil de XP (conductores). */
@Slf4j
@Component
@RequiredArgsConstructor
public class NivelesScheduler {

    private final NivelesService nivelesService;

    @Scheduled(fixedDelayString = "${nexa.job.reproceso-minutos}",
            initialDelayString = "${nexa.job.reproceso-minutos}", timeUnit = java.util.concurrent.TimeUnit.MINUTES)
    public void reprocesar() {
        try {
            int n = nivelesService.reprocesarPendientes();
            if (n > 0) {
                log.warn("Se reprocesaron {} viajes con niveles pendientes", n);
            }
        } catch (Exception e) {
            log.error("Falló el reproceso de niveles", e);
        }
    }

    @Scheduled(cron = "${nexa.job.cron}", zone = "${nexa.zona-horaria}")
    public void ejecutar() {
        try {
            nivelesService.mantenimientoDiario();
        } catch (Exception e) {
            log.error("Falló el mantenimiento diario de niveles", e);
        }
    }
}
