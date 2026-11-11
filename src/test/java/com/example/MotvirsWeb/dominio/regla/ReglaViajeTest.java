package com.example.MotvirsWeb.dominio.regla;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class ReglaViajeTest {

    private final ReglaViaje regla = new ReglaViaje(ModeloNexaPropertiesTestSupport.cargar());

    private static final PuntoGeo DESTINO = new PuntoGeo(10.4236, -75.5253);

    @Test
    void puedeFinalizarDentroDelRadioDelDestino() {
        assertTrue(regla.enElDestino(new PuntoGeo(10.4240, -75.5253), DESTINO));   // ~44 m
        assertTrue(regla.enElDestino(DESTINO, DESTINO));
    }

    @Test
    void noPuedeFinalizarFueraDelRadio() {
        assertFalse(regla.enElDestino(new PuntoGeo(10.4260, -75.5253), DESTINO));  // ~270 m
        assertFalse(regla.enElDestino(new PuntoGeo(10.5000, -75.5253), DESTINO));
    }

    @Test
    void elRadioVieneDeLaConfiguracion() {
        assertEquals(150, regla.radioDestinoMetros());
        assertTrue(regla.exigeDestino());
    }

    @Test
    void etaSeCalculaConLaVelocidadUrbana() {
        // 25 km/h: 5 km = 12 min; cualquier distancia positiva es al menos 1 min
        assertEquals(12, regla.etaMinutos(5.0));
        assertEquals(1, regla.etaMinutos(0.05));
        assertEquals(0, regla.etaMinutos(0));
    }

    @Test
    void kmPorCalleAplicaElFactorDeRuta() {
        PuntoGeo a = new PuntoGeo(10.4236, -75.5253);
        PuntoGeo b = new PuntoGeo(10.4326, -75.5253);
        assertEquals(a.distanciaKm(b) * 1.3, regla.kmPorCalle(a, b), 1e-9);
    }

    @Test
    void soloSeGuardaElPuntoSiAvanzoLoSuficiente() {
        PuntoGeo ultimo = new PuntoGeo(10.4236, -75.5253);
        assertTrue(regla.debeGuardarPunto(null, ultimo, 0));
        assertFalse(regla.debeGuardarPunto(ultimo, new PuntoGeo(10.42365, -75.5253), 1)); // ~5,5 m
        assertTrue(regla.debeGuardarPunto(ultimo, new PuntoGeo(10.4240, -75.5253), 1));   // ~44 m
    }

    @Test
    void noSeGuardanMasPuntosQueElTope() {
        PuntoGeo ultimo = new PuntoGeo(10.4236, -75.5253);
        assertFalse(regla.debeGuardarPunto(ultimo, new PuntoGeo(10.45, -75.5253), 2000));
    }

    @Test
    void distanciaRecorridaSumaLosTramos() {
        List<PuntoGeo> puntos = List.of(new PuntoGeo(10.4236, -75.5253), new PuntoGeo(10.4326, -75.5253),
                new PuntoGeo(10.4326, -75.5163));
        double esperado = puntos.get(0).distanciaKm(puntos.get(1)) + puntos.get(1).distanciaKm(puntos.get(2));
        assertEquals(esperado, ReglaViaje.distanciaRecorridaKm(puntos), 1e-9);
        assertEquals(0, ReglaViaje.distanciaRecorridaKm(List.of(puntos.get(0))), 1e-12);
        assertEquals(0, ReglaViaje.distanciaRecorridaKm(List.of()), 1e-12);
    }

    @Test
    void factorDeCobroLaReglaDeLaMitad() {
        assertEquals(1.0, regla.factorCobro(true, 0.1, 4.0));    // llegó al destino
        assertEquals(0.5, regla.factorCobro(false, 1.99, 4.0));  // antes de la mitad
        assertEquals(1.0, regla.factorCobro(false, 2.0, 4.0));   // justo la mitad
        assertEquals(1.0, regla.factorCobro(false, 3.0, 4.0));   // pasada la mitad
        assertEquals(1.0, regla.factorCobro(false, null, 4.0));  // sin datos para medir: completo
        assertEquals(1.0, regla.factorCobro(false, 1.0, 0));     // sin distancia planeada
    }
}
