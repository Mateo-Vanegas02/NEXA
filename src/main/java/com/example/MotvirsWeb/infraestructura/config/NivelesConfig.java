package com.example.MotvirsWeb.infraestructura.config;

import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

import java.time.Clock;
import java.time.ZoneId;

@Configuration
@EnableScheduling
public class NivelesConfig {

    /** Reloj del sistema de niveles, en la zona horaria del negocio (nexa.zona-horaria). */
    @Bean
    public Clock nivelesClock(ModeloNexaProperties cfg) {
        return Clock.system(ZoneId.of(cfg.getZonaHoraria()));
    }
}
