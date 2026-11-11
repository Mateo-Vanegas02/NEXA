package com.example.MotvirsWeb.dominio.regla;

import com.example.MotvirsWeb.dominio.regla.ModeloXp.Viaje;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.junit.jupiter.api.Assertions.*;

/** Valores esperados tomados del documento del modelo v2.0 (secciones 9, 10, 11, 13 y 15). */
class ModeloXpTest {

    private final ModeloXp xp = new ModeloXp(ModeloNexaPropertiesTestSupport.cargar());
    private final ModeloTarifa tarifa = new ModeloTarifa(ModeloNexaPropertiesTestSupport.cargar());

    private static Viaje viaje(double km) {
        return new Viaje(true, 10, km, km, 1);
    }

    @ParameterizedTest(name = "{0} km → {1} XP")
    @CsvSource({ "1, 4.4", "3, 6.5", "5, 8.6", "6.5, 10.2", "10, 13.9", "15, 19.2", "20, 24.4", "35, 24.4" })
    void tablaDeXpPorDistancia(double km, double esperado) {
        assertEquals(esperado, xp.xpPasajero(viaje(km), tarifa.tarifaBase(km), 1, 2.0));
    }

    @Test
    void ejemploIntegralDeLaSeccion15() {
        Viaje v = viaje(5.0);
        long t0 = tarifa.tarifaBase(5.0);
        assertEquals(8.64, xp.xpBase(t0, 5.0), 1e-9);
        assertEquals(6.9, xp.xpPasajero(v, t0, 1, 7.0), "F(7) = 0,80");
        assertEquals(10.4, xp.xpConductor(v, t0, 5.0), "calificación 5: × 1,2");
        double antes = 1395;
        assertEquals(3, xp.nivelPasajero(antes));
        assertEquals(4, xp.nivelPasajero(antes + 6.9), "1.401,9 ≥ 1.400: sube al nivel 4");
    }

    @Test
    void validezDelViaje() {
        assertTrue(xp.valido(new Viaje(true, 2, 0.5, 0.5, 2)));
        assertFalse(xp.valido(new Viaje(false, 10, 5, 5, 1)), "no finalizado");
        assertFalse(xp.valido(new Viaje(true, 1.9, 5, 5, 1)), "menos de 2 minutos");
        assertFalse(xp.valido(new Viaje(true, 10, 0.4, 0.4, 1)), "menos de 0,5 km");
        assertFalse(xp.valido(new Viaje(true, 10, 5, 5, 3)), "tercer viaje del día con la misma pareja");
        assertEquals(0, xp.xpPasajero(new Viaje(false, 10, 5, 5, 1), 9000, 1, null));
        assertEquals(0, xp.xpConductor(new Viaje(true, 10, 5, 5, 3), 9000, 5.0));
    }

    @Test
    void losRodeosNoInflanElXp() {
        assertEquals(4.0, xp.distanciaXp(10, 2), 1e-12, "ruta 10 km con línea recta de 2 km");
        assertEquals(3.0, xp.distanciaXp(3, 2), 1e-12);
        double conRodeo = xp.xpPasajero(new Viaje(true, 20, 10, 2, 1), 9000, 1, null);
        double sinRodeo = xp.xpPasajero(new Viaje(true, 20, 4, 4, 1), 9000, 1, null);
        assertEquals(sinRodeo, conRodeo);
    }

    @ParameterizedTest(name = "espera {0} min → F = {1}")
    @CsvSource({ "0, 1.10", "1, 1.10", "2, 1.0", "3, 1.0", "7, 0.80", "13, 0.5", "30, 0.5" })
    void factorDeEspera(double minutos, double esperado) {
        assertEquals(esperado, xp.factorEspera(minutos), 1e-9);
    }

    @Test
    void sinRegistroDeLlegadaElFactorEsNeutro() {
        assertEquals(1.0, xp.factorEspera(null));
    }

    @Test
    void factorPorViajesDelDia() {
        for (int n = 1; n <= 5; n++) {
            assertEquals(1.0, xp.factorDia(n));
        }
        for (int n = 6; n <= 10; n++) {
            assertEquals(0.5, xp.factorDia(n));
        }
        assertEquals(0.0, xp.factorDia(11));
        assertEquals(0, xp.xpPasajero(viaje(5), 9000, 11, null));
        assertEquals(4.3, xp.xpPasajero(viaje(5), 9000, 6, null), "8,64 × 0,5");
    }

    @Test
    void factorDelConductorPorCalificacion() {
        assertEquals(1.2, xp.factorCalificacion(5.0));
        assertEquals(1.2, xp.factorCalificacion(4.5));
        assertEquals(1.0, xp.factorCalificacion(4.0));
        assertEquals(1.0, xp.factorCalificacion(null));
        assertEquals(0.5, xp.factorCalificacion(3.0));
    }

    @ParameterizedTest(name = "nivel {0} → {1} XP")
    @CsvSource({ "1, 0", "2, 270", "3, 760", "4, 1400", "5, 2160", "6, 3020", "7, 3970", "8, 5000", "9, 6110",
            "10, 7290" })
    void umbralesDeNivelDelPasajero(int nivel, double esperado) {
        assertEquals(esperado, xp.xpParaNivel(nivel));
    }

    @Test
    void nivelDelPasajeroSinTecho() {
        assertEquals(1, xp.nivelPasajero(0));
        assertEquals(1, xp.nivelPasajero(269.9));
        assertEquals(2, xp.nivelPasajero(270));
        assertEquals(10, xp.nivelPasajero(7290));
        int anterior = 1;
        for (double x = 0; x <= 200_000; x += 97.3) {
            int n = xp.nivelPasajero(x);
            assertTrue(n >= anterior, "el nivel nunca baja al sumar XP");
            assertTrue(x >= xp.xpParaNivel(n) && x < xp.xpParaNivel(n + 1), "X dentro de su nivel");
            anterior = n;
        }
        assertTrue(anterior > 50, "siempre hay un nivel siguiente");
        assertThrows(IllegalArgumentException.class, () -> xp.nivelPasajero(Double.POSITIVE_INFINITY));
    }

    @Test
    void elNivel2PideMasDe25ViajesDeReferencia() {
        double referencia = xp.xpPasajero(viaje(6.5), tarifa.tarifaBase(6.5), 1, 2.0);
        assertTrue(xp.xpParaNivel(2) / referencia > 25);
    }

    @Test
    void perdidaDeNivelPorInactividad() {
        assertEquals(760, xp.xpTrasInactividad(1401.9), "nivel 4 → inicio del nivel 3");
        assertEquals(270, xp.xpTrasInactividad(760), "nivel 3 → inicio del nivel 2");
        assertEquals(100, xp.xpTrasInactividad(100), "el nivel 1 no baja");
    }

    @Test
    void umbralesDelConductor() {
        assertEquals(0, xp.xpConductorParaNivel(1));
        assertEquals(400, xp.xpConductorParaNivel(2));
        assertEquals(1600, xp.xpConductorParaNivel(3));
        assertEquals(3600, xp.xpConductorParaNivel(4));
        assertEquals(6400, xp.xpConductorParaNivel(5));
        assertEquals(5, xp.nivelConductorPorXp(1_000_000), "el conductor llega como máximo al nivel 5");
        assertEquals(1, xp.nivelConductorPorXp(399));
    }

    @Test
    void nivelDelConductorExigeCalidad() {
        assertEquals(5, xp.nivelConductor(7000, new StatsConductor(4.85, 0.65, 0.05)));
        assertEquals(4, xp.nivelConductor(7000, new StatsConductor(4.75, 0.50, 0.09)), "aceptación < 60 %");
        assertEquals(3, xp.nivelConductor(7000, new StatsConductor(4.65, 0.90, 0.12)), "calificación < 4,70");
        assertEquals(2, xp.nivelConductor(7000, new StatsConductor(null, 1.0, 0.0)), "sin calificaciones no pasa del 2");
        assertEquals(2, xp.nivelConductor(500, new StatsConductor(5.0, 1.0, 0.0)), "le falta XP para el 3");
        assertEquals(1, xp.nivelConductor(0, StatsConductor.vacio()));
        assertEquals(java.util.List.of("Calificación ≥ 4.80", "Aceptación ≥ 60%", "Cancelación ≤ 8%"),
                xp.requisitosFaltantes(5, new StatsConductor(4.5, 0.3, 0.2)));
    }
}
