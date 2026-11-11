package com.example.MotvirsWeb.dominio.regla;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class PrioridadRecogidaTest {

    private final PrioridadRecogida prio = new PrioridadRecogida(ModeloNexaPropertiesTestSupport.cargar());

    @Test
    void ventanaSegunLaTablaDelModelo() {
        assertEquals(0, prio.ventanaSegundos(1));
        assertEquals(15, prio.ventanaSegundos(2));
        assertEquals(45, prio.ventanaSegundos(5));
        assertEquals(45, prio.ventanaSegundos(12)); // sin techo: usa el último valor
    }

    @Test
    void sinPrioridadTodosLosConductoresLoVenDeInmediato() {
        assertTrue(prio.visiblePara(1, 3.0, false, 0));
    }

    @Test
    void duranteLaVentanaSoloVenConductoresBienCalificados() {
        assertFalse(prio.visiblePara(2, 4.2, false, 5));
        assertTrue(prio.visiblePara(2, 4.7, false, 5));
        assertTrue(prio.visiblePara(2, 4.2, false, 20)); // pasó la ventana del nivel 2 (15 s)
    }

    @Test
    void laVentanaCreceConElNivel() {
        assertFalse(prio.visiblePara(5, 4.0, false, 30)); // nivel 5: 45 s
        assertTrue(prio.visiblePara(3, 4.0, false, 30));  // nivel 3: 25 s
    }

    @Test
    void favoritosDesdeElNivelCinco() {
        assertFalse(prio.puedeTenerFavoritos(4));
        assertTrue(prio.puedeTenerFavoritos(5));
        assertEquals(5.0, prio.favoritoEtaMinutos(5), 1e-9);
        assertEquals(8.0, prio.favoritoEtaMinutos(7), 1e-9);
        assertTrue(prio.favoritoCercano(5, 4.0));
        assertFalse(prio.favoritoCercano(5, 6.0));
        assertTrue(prio.favoritoCercano(7, 6.0));
        assertFalse(prio.favoritoCercano(4, 1.0));
    }

    @Test
    void puntajeCreceConNivelCalificacionYCercania() {
        assertTrue(prio.puntaje(5, 4.8, 2.0, false) > prio.puntaje(2, 4.8, 2.0, false));
        assertTrue(prio.puntaje(3, 4.8, 1.0, false) > prio.puntaje(3, 4.8, 10.0, false));
        assertTrue(prio.puntaje(3, 4.8, 5.0, false) > prio.puntaje(3, 4.0, 5.0, false));
        assertEquals(0, prio.puntaje(1, 5.0, 1.0, true));
        assertTrue(prio.puntaje(5, 4.0, null, true) > prio.puntaje(5, 4.0, null, false));
    }

    @Test
    void etaYDistancia() {
        assertEquals(60.0, prio.etaMinutos(25.0), 1e-9);
        assertEquals(0.0, PrioridadRecogida.distanciaKm(4.7110, -74.0721, 4.7110, -74.0721), 1e-9);
        assertTrue(PrioridadRecogida.distanciaKm(4.7110, -74.0721, 4.6486, -74.0600) > 5);
    }
}
