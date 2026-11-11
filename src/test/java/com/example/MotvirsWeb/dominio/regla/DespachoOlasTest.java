package com.example.MotvirsWeb.dominio.regla;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class DespachoOlasTest {

    private final DespachoOlas olas = new DespachoOlas(ModeloNexaPropertiesTestSupport.cargar());

    @Test
    void laOlaCrecePorElTiempoTranscurrido() {
        assertEquals(1, olas.ola(0));
        assertEquals(1, olas.ola(24));
        assertEquals(2, olas.ola(25));
        assertEquals(3, olas.ola(50));
        assertEquals(4, olas.ola(75));
        assertEquals(4, olas.ola(100_000));
        assertEquals(4, olas.totalOlas());
        assertEquals(0, olas.inicioSegundos(1));
        assertEquals(75, olas.inicioSegundos(4));
    }

    @Test
    void elRadioCreceHastaElTopeDeSeisKm() {
        assertEquals(1.5, olas.radioKm(1));
        assertEquals(2.5, olas.radioKm(2));
        assertEquals(4.0, olas.radioKm(3));
        assertEquals(6.0, olas.radioKm(4));
    }

    @Test
    void unRadioCeroSigueSignificandoTodaLaZona() {
        ModeloNexaProperties cfg = ModeloNexaPropertiesTestSupport.cargar();
        cfg.getDespacho().setOlaRadioKm(new double[] { 1.5, 2.5, 4, 0 });
        DespachoOlas abiertas = new DespachoOlas(cfg);
        assertTrue(Double.isInfinite(abiertas.radioKm(4)));
        assertTrue(abiertas.visible(120, 40.0));
    }

    @Test
    void soloVenLaSolicitudLosQueEstanDentroDelRadioDeLaOla() {
        assertTrue(olas.visible(10, 1.4));
        assertFalse(olas.visible(10, 1.6));
        assertTrue(olas.visible(35, 2.4));
        assertFalse(olas.visible(35, 2.6));
        assertTrue(olas.visible(120, 5.9));
        assertFalse(olas.visible(120, 6.1)); // más allá del tope nunca le llega
    }

    @Test
    void sinPosicionVigenteSoloVeLaUltimaOla() {
        assertFalse(olas.visible(10, null));
        assertFalse(olas.visible(74, null));
        assertTrue(olas.visible(75, null));
    }

    @Test
    void segundosParaLaSiguienteOla() {
        assertEquals(15L, olas.segundosParaSiguiente(10));
        assertEquals(15L, olas.segundosParaSiguiente(60));
        assertNull(olas.segundosParaSiguiente(80));
    }

    @Test
    void laConfiguracionInvalidaNoArranca() {
        ModeloNexaProperties cfg = ModeloNexaPropertiesTestSupport.cargar();
        cfg.getDespacho().setOlaRadioKm(new double[] { 1.0 });
        assertThrows(IllegalStateException.class, () -> new DespachoOlas(cfg));

        ModeloNexaProperties otra = ModeloNexaPropertiesTestSupport.cargar();
        otra.getDespacho().setOlaSegundos(new int[] { 0, 60, 30, 90 });
        assertThrows(IllegalStateException.class, () -> new DespachoOlas(otra));
    }

    @Test
    void elExtraVoluntarioAdelantaUnaOla() {
        assertEquals(1, olas.ola(0, false));
        assertEquals(2, olas.ola(0, true));
        assertEquals(4, olas.ola(50, true));
        assertEquals(4, olas.ola(90, true));   // nunca pasa de la última
        assertEquals(1, olas.olasPorExtra());
    }

    @Test
    void conExtraSeVeAntesYLaSiguienteOlaLlegaAntes() {
        assertFalse(olas.visible(0, 2.4, false));
        assertTrue(olas.visible(0, 2.4, true));
        assertNull(olas.segundosParaSiguiente(60, true));   // con extra ya está en la última
        assertEquals(15L, olas.segundosParaSiguiente(60, false));
    }
}
