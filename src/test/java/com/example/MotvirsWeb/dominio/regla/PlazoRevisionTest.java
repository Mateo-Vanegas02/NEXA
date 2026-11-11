package com.example.MotvirsWeb.dominio.regla;

import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

class PlazoRevisionTest {

    @Test
    void quinceDiasHabilesDesdeUnJuevesSonTresSemanas() {
        // jueves 22-oct-2026 + 15 hábiles = jueves 12-nov-2026
        assertEquals(LocalDate.of(2026, 11, 12), PlazoRevision.sumarDiasHabiles(LocalDate.of(2026, 10, 22), 15));
    }

    @Test
    void desdeUnSabadoCuentaDesdeElLunes() {
        // sábado 24-oct + 1 hábil = lunes 26-oct
        assertEquals(LocalDate.of(2026, 10, 26), PlazoRevision.sumarDiasHabiles(LocalDate.of(2026, 10, 24), 1));
    }

    @Test
    void cantidadCeroDevuelveLaMismaFecha() {
        assertEquals(LocalDate.of(2026, 10, 22), PlazoRevision.sumarDiasHabiles(LocalDate.of(2026, 10, 22), 0));
    }

    @Test
    void venceSoloDespuesDelUltimoDia() {
        LocalDate plazo = LocalDate.of(2026, 11, 12);
        assertFalse(PlazoRevision.vencido(plazo, plazo));
        assertTrue(PlazoRevision.vencido(plazo, plazo.plusDays(1)));
        assertFalse(PlazoRevision.vencido(null, plazo));
    }
}
