package com.example.MotvirsWeb.dominio.regla;

import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import static org.junit.jupiter.api.Assertions.*;

class PuntoRecogidaTest {

    private final PuntoRecogida regla = new PuntoRecogida(ModeloNexaPropertiesTestSupport.cargar());
    private static final PuntoGeo PASAJERO = new PuntoGeo(10.4236, -75.5253);

    /** Punto a {@code metros} al norte del pasajero. */
    private static PuntoGeo alNorte(double metros) {
        return new PuntoGeo(PASAJERO.latitud() + metros / 111195.0, PASAJERO.longitud());
    }

    @Test
    void unPuntoDentroDelRadioSeAcepta() {
        assertTrue(regla.cerca(PASAJERO, alNorte(200)));
        assertDoesNotThrow(() -> regla.exigirCerca(PASAJERO, alNorte(200)));
        assertEquals(200, regla.metrosHasta(PASAJERO, alNorte(200)), 1);
    }

    @Test
    void masAlladelRadioSeRechazaConElLimiteEnElMensaje() {
        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> regla.exigirCerca(PASAJERO, alNorte(900)));
        assertEquals(400, e.getStatusCode().value());
        assertTrue(e.getReason().contains(String.valueOf(Math.round(regla.radioMaxMetros()))), e.getReason());
    }

    @Test
    void sinLaPosicionDelPasajeroNoHayNadaQueComparar() {
        assertTrue(regla.cerca(null, alNorte(5000)));
        assertDoesNotThrow(() -> regla.exigirCerca(null, alNorte(5000)));
        assertEquals(-1, regla.metrosHasta(null, PASAJERO));
    }
}
