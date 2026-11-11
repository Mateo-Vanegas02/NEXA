package com.example.MotvirsWeb.dominio.regla;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class RegistroLlegadaTest {

    private final RegistroLlegada llegada = new RegistroLlegada(ModeloNexaPropertiesTestSupport.cargar());
    private static final PuntoGeo RECOGIDA = new PuntoGeo(10.4236, -75.5487);

    @Test
    void elRadioVieneDeLaConfiguracion() {
        assertEquals(50, llegada.radioMetros());
    }

    @Test
    void dentroDelRadioCuentaComoLlegada() {
        assertTrue(llegada.enElPuntoDeRecogida(RECOGIDA, RECOGIDA));
        assertTrue(llegada.enElPuntoDeRecogida(new PuntoGeo(10.4236 + 0.0004, -75.5487), RECOGIDA));   // ~44 m
    }

    @Test
    void fueraDelRadioNoCuenta() {
        assertFalse(llegada.enElPuntoDeRecogida(new PuntoGeo(10.4236 + 0.0006, -75.5487), RECOGIDA));  // ~67 m
        assertEquals(1112, llegada.distanciaMetros(new PuntoGeo(10.4336, -75.5487), RECOGIDA), 5);
    }
}
