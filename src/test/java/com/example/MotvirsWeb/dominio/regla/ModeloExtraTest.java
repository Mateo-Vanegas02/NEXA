package com.example.MotvirsWeb.dominio.regla;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class ModeloExtraTest {

    private final ModeloExtra extra = new ModeloExtra(ModeloNexaPropertiesTestSupport.cargar());

    @Test
    void laConfiguracionTraeTopeYPasos() {
        assertEquals(5000, extra.tope());
        assertArrayEquals(new long[] { 500, 1000, 2000 }, extra.pasos());
    }

    @Test
    void sumaUnPasoPermitido() {
        assertEquals(1000, extra.nuevoTotal(0, 1000));
        assertEquals(3500, extra.nuevoTotal(1500, 2000));
    }

    @Test
    void rechazaUnMontoQueNoEsPaso() {
        assertThrows(IllegalArgumentException.class, () -> extra.nuevoTotal(0, 700));
        assertThrows(IllegalArgumentException.class, () -> extra.nuevoTotal(0, -500), "nunca baja");
        assertThrows(IllegalArgumentException.class, () -> extra.nuevoTotal(0, 0));
    }

    @Test
    void rechazaPasarseDelTope() {
        assertEquals(5000, extra.nuevoTotal(3000, 2000));
        assertThrows(IllegalArgumentException.class, () -> extra.nuevoTotal(4500, 1000));
    }

    @Test
    void margenEsLoQueFaltaParaElTope() {
        assertEquals(5000, extra.margen(0));
        assertEquals(1500, extra.margen(3500));
        assertEquals(0, extra.margen(6000));
    }
}
