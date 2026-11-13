package com.example.MotvirsWeb.dominio.regla;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ReglaSinConexionTest {

    private static final LocalDateTime AHORA = LocalDateTime.of(2026, 11, 13, 10, 0);

    @Test
    void conViajeEnCursoLaToleranciaEsLaDuracionSiEsMayor() {
        assertEquals(5, ReglaSinConexion.toleranciaMinutos(5, false, 30));
        assertEquals(30, ReglaSinConexion.toleranciaMinutos(5, true, 29.2));
        assertEquals(5, ReglaSinConexion.toleranciaMinutos(5, true, 3));
        assertEquals(5, ReglaSinConexion.toleranciaMinutos(5, true, 0));
    }

    @Test
    void aceptaLaHoraDelTelefonoDentroDeLaTolerancia() {
        LocalDateTime hace3 = AHORA.minusMinutes(3);
        assertEquals(hace3, ReglaSinConexion.horaEvento(AHORA, hace3, null, 5));
    }

    @Test
    void sinHoraOEnElFuturoUsaLaDelServidor() {
        assertEquals(AHORA, ReglaSinConexion.horaEvento(AHORA, null, null, 5));
        assertEquals(AHORA, ReglaSinConexion.horaEvento(AHORA, AHORA.plusMinutes(2), null, 5));
    }

    @Test
    void recortaLaHoraMuyViejaAlLimite() {
        assertEquals(AHORA.minusMinutes(5), ReglaSinConexion.horaEvento(AHORA, AHORA.minusHours(1), null, 5));
    }

    @Test
    void nuncaAntesDelPasoAnteriorDelViaje() {
        LocalDateTime llegada = AHORA.minusMinutes(2);
        assertEquals(llegada, ReglaSinConexion.horaEvento(AHORA, AHORA.minusMinutes(4), llegada, 5));
        // Un paso anterior «en el futuro» (reloj raro) no deja la hora después de ahora
        assertEquals(AHORA, ReglaSinConexion.horaEvento(AHORA, AHORA.minusMinutes(1), AHORA.plusMinutes(1), 5));
    }

    @Test
    void puntosDelLoteSoloDentroDeLaTolerancia() {
        assertTrue(ReglaSinConexion.puntoAceptable(AHORA, AHORA.minusMinutes(4), 5));
        assertFalse(ReglaSinConexion.puntoAceptable(AHORA, AHORA.minusMinutes(6), 5));
        assertFalse(ReglaSinConexion.puntoAceptable(AHORA, AHORA.plusMinutes(1), 5));
        assertFalse(ReglaSinConexion.puntoAceptable(AHORA, null, 5));
    }
}
