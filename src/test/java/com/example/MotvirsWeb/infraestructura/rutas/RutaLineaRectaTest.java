package com.example.MotvirsWeb.infraestructura.rutas;

import com.example.MotvirsWeb.dominio.regla.ModeloNexaPropertiesTestSupport;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.regla.Ruta;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class RutaLineaRectaTest {

    private final RutaLineaRecta rutas = new RutaLineaRecta(ModeloNexaPropertiesTestSupport.cargar());

    @Test
    void distanciaEsLaRectaPorElFactor() {
        PuntoGeo centro = new PuntoGeo(10.4236, -75.5487);
        PuntoGeo pasacaballos = new PuntoGeo(10.2850, -75.5180);
        Ruta r = rutas.calcular(centro, pasacaballos);
        assertEquals(15.8, r.distanciaRectaKm(), 0.1);
        assertEquals(r.distanciaRectaKm() * 1.3, r.distanciaKm(), 1e-9);
        assertEquals("recta", r.fuente());
    }

    @Test
    void mismoPuntoEsCero() {
        PuntoGeo p = new PuntoGeo(10.4, -75.5);
        assertEquals(0, rutas.calcular(p, p).distanciaKm(), 1e-12);
    }

    @Test
    void haversineConocido() {
        // Un grado de latitud ≈ 111,2 km
        assertEquals(111.2, new PuntoGeo(10, -75).distanciaKm(new PuntoGeo(11, -75)), 0.1);
    }

    @Test
    void coordenadasImposiblesSeRechazan() {
        assertThrows(IllegalArgumentException.class, () -> new PuntoGeo(91, 0));
        assertThrows(IllegalArgumentException.class, () -> new PuntoGeo(0, -181));
        assertThrows(IllegalArgumentException.class, () -> new PuntoGeo(Double.NaN, 0));
    }

    @Test
    void factorMenorQueUnoNoArranca() {
        var cfg = ModeloNexaPropertiesTestSupport.cargar();
        cfg.getRutas().setFactorRecta(0.9);
        assertThrows(IllegalStateException.class, () -> new RutaLineaRecta(cfg));
    }
}
