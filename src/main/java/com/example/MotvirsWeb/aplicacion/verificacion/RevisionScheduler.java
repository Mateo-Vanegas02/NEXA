package com.example.MotvirsWeb.aplicacion.verificacion;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/** Job diario: rechaza las solicitudes EN_REVISION cuyo plazo venció. */
@Slf4j
@Component
@RequiredArgsConstructor
public class RevisionScheduler {

    private final RevisionConductorService revision;

    @Scheduled(cron = "${verification.review-cron:0 30 6 * * *}", zone = "${nexa.zona-horaria:America/Bogota}")
    public void ejecutar() {
        try {
            int n = revision.vencerPlazos();
            if (n > 0) {
                log.info("Se rechazaron {} solicitudes por plazo de revisión vencido", n);
            }
        } catch (Exception e) {
            log.error("Falló el vencimiento de plazos de revisión", e);
        }
    }
}
