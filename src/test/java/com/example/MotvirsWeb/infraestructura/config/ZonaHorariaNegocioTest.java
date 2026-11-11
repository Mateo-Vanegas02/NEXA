package com.example.MotvirsWeb.infraestructura.config;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.time.Clock;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.TimeZone;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class ZonaHorariaNegocioTest {

    private TimeZone original;

    @BeforeEach
    void guardar() {
        original = TimeZone.getDefault();
    }

    @AfterEach
    void restaurar() {
        TimeZone.setDefault(original);
    }

    @Test
    void usaElPrimerCandidatoValido() {
        assertEquals(ZoneId.of("America/Lima"), ZonaHorariaNegocio.resolver(null, " ", "America/Lima", "UTC"));
    }

    @Test
    void ignoraZonasInvalidasYCaeABogota() {
        assertEquals(ZoneId.of("UTC"), ZonaHorariaNegocio.resolver("Marte/Olympus", "UTC"));
        assertEquals(ZoneId.of("America/Bogota"), ZonaHorariaNegocio.resolver(null, "no-existe"));
    }

    @Test
    void conLaZonaAplicadaNowCoincideConElRelojDeNiveles() {
        TimeZone.setDefault(TimeZone.getTimeZone("UTC")); // como en Docker y Azure
        ZoneId zona = ZonaHorariaNegocio.aplicar();
        LocalDateTime jvm = LocalDateTime.now();
        LocalDateTime negocio = LocalDateTime.now(Clock.system(ZoneId.of("America/Bogota")));
        assertEquals(ZoneId.of("America/Bogota"), zona);
        assertEquals(0, Duration.between(jvm, negocio).toMinutes());
    }
}
