package com.example.MotvirsWeb.dominio.regla;

import com.example.MotvirsWeb.dominio.regla.ModeloTarifa.Cobro;
import com.example.MotvirsWeb.dominio.regla.ModeloTarifa.SituacionCancelacion;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.junit.jupiter.api.Assertions.*;

/** Valores esperados tomados del documento del modelo v2.0 (secciones 4 a 8, 12 y 15). */
class ModeloTarifaTest {

    private final ModeloTarifa tarifa = new ModeloTarifa(ModeloNexaPropertiesTestSupport.cargar());

    @ParameterizedTest(name = "{0} km → ${1}")
    @CsvSource({
            "0, 4000",
            "0.1, 4000",
            "0.83, 4000",
            "1, 4200",
            "4.2, 8000",
            "5, 9000",
            "6.5, 10800",
            "10, 15000",
            "20, 27000"
    })
    void tarifaBaseDeLaTablaDelDocumento(double km, long esperado) {
        assertEquals(esperado, tarifa.tarifaBase(km));
    }

    @Test
    void cadaCienMetrosSumanCientoVeinteDespuesDelMinimo() {
        assertEquals(10800, tarifa.tarifaBase(6.5));
        assertEquals(10900, tarifa.tarifaBase(6.6)); // 10.920 redondeado a $100
    }

    @Test
    void distanciaInvalidaSeRechaza() {
        assertThrows(IllegalArgumentException.class, () -> tarifa.tarifaBase(-1));
        assertThrows(IllegalArgumentException.class, () -> tarifa.tarifaBase(Double.NaN));
    }

    @ParameterizedTest(name = "espera {0} min → ${1}")
    @CsvSource({ "0, 0", "2, 0", "5, 0", "6, 400", "7, 800", "10, 2000", "25, 2000" })
    void recargoPorEspera(double minutos, long esperado) {
        assertEquals(esperado, tarifa.recargoEspera(minutos));
    }

    @Test
    void sinRegistroDeLlegadaNoHayRecargo() {
        assertEquals(0, tarifa.recargoEspera(null));
    }

    @Test
    void descuentoPorNivelDel2Al5YLuegoFijo() {
        assertEquals(0.0, tarifa.descuentoNivel(1));
        assertEquals(0.02, tarifa.descuentoNivel(2), 1e-12);
        assertEquals(0.03, tarifa.descuentoNivel(3), 1e-12);
        assertEquals(0.05, tarifa.descuentoNivel(5), 1e-12);
        assertEquals(0.05, tarifa.descuentoNivel(12), 1e-12);
    }

    @Test
    void comisionPorNivelDelConductor() {
        assertEquals(0.20, tarifa.comision(1));
        assertEquals(0.19, tarifa.comision(2));
        assertEquals(0.18, tarifa.comision(3));
        assertEquals(0.16, tarifa.comision(4));
        assertEquals(0.15, tarifa.comision(5));
        assertEquals(0.15, tarifa.comision(9), "por encima del 5 se queda en la del 5");
        assertEquals(0.20, tarifa.comision(0), "por debajo del 1 se trata como 1");
        assertEquals(0.15, tarifa.comisionMinima());
    }

    @Test
    void ejemploIntegralDeLaSeccion15() {
        // Pasajero nivel 3, 5,0 km, conductor nivel 2 (19 %), esperó 7 minutos.
        Cobro c = tarifa.cobrar(5.0, 1.0, 3, tarifa.comision(2), 7.0);
        assertEquals(9000, c.tarifaBase());
        assertEquals(270, c.descuento());
        assertEquals(800, c.recargoEspera());
        assertEquals(9500, c.precio());
        assertEquals(8090, c.montoConductor());
        assertEquals(1410, c.montoPlataforma());
        assertEquals(-30, c.residuo());
        assertEquals(0.157, c.margen(), 0.001);
    }

    @Test
    void elDescuentoSeRecortaParaCuidarElMargen() {
        // Viaje de referencia 6,5 km, pasajero nivel 5 (sección 7)
        assertEquals(540, tarifa.cobrar(6.5, 1.0, 5, 0.20, null).descuento());
        assertEquals(490, tarifa.cobrar(6.5, 1.0, 5, 0.15, null).descuento());
    }

    @Test
    void elTopeDeOchocientosPesosPorViaje() {
        // 20 km = $27.000; 5 % serían $1.350
        assertEquals(800, tarifa.cobrar(20, 1.0, 8, 0.20, null).descuento());
    }

    @Test
    void unViajeCortoCuestaLaMinimaEnCualquierNivel() {
        for (int nivel = 1; nivel <= 10; nivel++) {
            Cobro c = tarifa.cobrar(0.1, 1.0, nivel, 0.15, null);
            assertEquals(4000, c.precio(), "nivel " + nivel);
            assertEquals(0, c.descuento());
        }
    }

    @Test
    void cotizarUsaLaComisionMinimaYElMultiplicadorDePrueba() {
        Cobro c = tarifa.cotizar(6.5, 5);
        assertEquals(1.0, c.multiplicador());
        assertEquals(0.15, c.comisionPct());
        assertEquals(490, c.descuento());
        assertEquals(10300, c.precio()); // 10.800 − 490 = 10.310 → 10.300
    }

    @Test
    void invariantesEnTodoElRango() {
        double[] multiplicadores = { 1.0, 1.1, 1.25, 1.5 };
        Double[] esperas = { null, 0.0, 2.0, 5.0, 12.0 };
        for (double km = 0; km <= 40; km += 0.37) {
            for (int nivel = 1; nivel <= 12; nivel++) {
                for (int nc = 1; nc <= 5; nc++) {
                    for (double m : multiplicadores) {
                        for (Double e : esperas) {
                            double phi = tarifa.comision(nc);
                            Cobro c = tarifa.cobrar(km, m, nivel, phi, e);
                            String caso = km + " km, nivel " + nivel + ", φ " + phi + ", M " + m + ", e " + e;
                            assertEquals(c.precio(), c.montoConductor() + c.montoPlataforma(), "C + I = P: " + caso);
                            assertEquals(0, c.precio() % 100, "múltiplo de $100: " + caso);
                            assertTrue(Math.abs(c.residuo()) <= 50, "residuo ±50: " + caso);
                            assertTrue(c.precio() >= 4000, "nunca menos de la mínima: " + caso);
                            assertTrue(c.precio() - c.recargoEspera() >= 4000 - 50,
                                    "el descuento no baja de la mínima: " + caso);
                            assertTrue(c.montoPlataforma() >= 0.10 * c.tarifaAjustada() - 1,
                                    "margen mínimo de 10 %: " + caso);
                            assertTrue(c.montoConductor() >= Math.round((1 - phi) * c.tarifaAjustada()) + c.recargoEspera(),
                                    "el conductor no paga el descuento: " + caso);
                        }
                    }
                }
            }
        }
    }

    @Test
    void multiplicadorFueraDeRangoSeRechaza() {
        assertThrows(IllegalArgumentException.class, () -> tarifa.cobrar(5, 0.9, 1, 0.2, null));
        assertThrows(IllegalArgumentException.class, () -> tarifa.cobrar(5, 1.6, 1, 0.2, null));
    }

    private static SituacionCancelacion aceptado(double minutosDesdeAceptacion) {
        return new SituacionCancelacion(true, minutosDesdeAceptacion, false, 0);
    }

    private static SituacionCancelacion conductorEnElPunto(double minutosDesdeAceptacion, double minutosEsperando) {
        return new SituacionCancelacion(true, minutosDesdeAceptacion, true, minutosEsperando);
    }

    @Test
    void sinConductorAsignadoOEnLaGraciaNoSeCobra() {
        assertEquals(0, tarifa.cargoCancelacion(1, 10800, new SituacionCancelacion(false, 0, false, 0)));
        assertEquals(0, tarifa.cargoCancelacion(1, 10800, aceptado(2)), "hasta 2 min después de aceptar");
        assertEquals(0, tarifa.cargoCancelacion(4, 10800, aceptado(5)), "desde el nivel 4, hasta 5 min");
        assertEquals(2160, tarifa.cargoCancelacion(3, 10800, aceptado(2.1)));
        assertEquals(2160, tarifa.cargoCancelacion(4, 10800, aceptado(5.1)));
    }

    @Test
    void antesDeQueLlegueElConductorSeCobraElVeintePorCiento() {
        assertEquals(800, tarifa.cargoCancelacion(1, 4000, aceptado(3)));
        assertEquals(1320, tarifa.cargoCancelacion(1, 6600, aceptado(3)));
        assertEquals(2160, tarifa.cargoCancelacion(1, 10800, aceptado(3)));
    }

    @ParameterizedTest(name = "T0 ${0}: al llegar ${1}, a los 7 min ${2}, 10 min ${3}")
    @CsvSource({
            "4000, 800, 800, 2000",
            "6600, 1320, 1320, 2000",
            "10800, 2160, 2160, 2160",
            "15000, 3000, 3000, 3000",
            "27000, 5400, 5400, 5400"
    })
    void tablaDeLaSeccion12(long t0, long alLlegar, long a7Min, long a10Min) {
        assertEquals(alLlegar, tarifa.cargoCancelacion(1, t0, conductorEnElPunto(6, 0)));
        assertEquals(alLlegar, tarifa.cargoCancelacion(1, t0, conductorEnElPunto(8, 5)), "hasta 5 min no hay recargo");
        assertEquals(a7Min, tarifa.cargoCancelacion(1, t0, conductorEnElPunto(12, 7)));
        assertEquals(a10Min, tarifa.cargoCancelacion(1, t0, conductorEnElPunto(15, 10)));
        assertEquals(a10Min, tarifa.cargoCancelacion(1, t0, conductorEnElPunto(25, 20)), "la espera se acota a 10 min");
    }

    @Test
    void noHayTopeElCargoDependeDelServicio() {
        assertEquals(5400, tarifa.cargoCancelacion(1, 27000, aceptado(3)));
        assertEquals(10000, tarifa.cargoCancelacion(1, 50000, aceptado(3)));
    }

    @Test
    void sePagaElCargoOLaEsperaNuncaLosDos() {
        // Viaje mínimo, 10 min esperando: la espera ($2.000) supera al 20 % ($800), no se suman.
        assertEquals(2000, tarifa.cargoCancelacion(1, 4000, conductorEnElPunto(15, 10)));
        // Viaje de $10.800: el 20 % ($2.160) supera a la espera ($2.000), tampoco se suman.
        assertEquals(2160, tarifa.cargoCancelacion(1, 10800, conductorEnElPunto(15, 10)));
    }

    @Test
    void propiedadesDelCargo() {
        long[] tarifas = { 4000, 4200, 6600, 8000, 10800, 15000, 21000, 27000, 40000 };
        for (long t0 : tarifas) {
            for (int nivel = 1; nivel <= 8; nivel++) {
                long anterior = 0;
                for (double espera = 0; espera <= 14; espera += 0.5) {
                    var s = conductorEnElPunto(20, espera);
                    long q = tarifa.cargoCancelacion(nivel, t0, s);
                    String caso = "T0 " + t0 + ", nivel " + nivel + ", espera " + espera;
                    assertTrue(q >= Math.round(0.20 * t0), "nunca menos del 20 %: " + caso);
                    assertTrue(q >= tarifa.recargoEspera(espera), "nunca menos que la espera: " + caso);
                    assertEquals(Math.max(Math.round(0.20 * t0), tarifa.recargoEspera(espera)), q, caso);
                    assertTrue(q >= anterior, "no baja al esperar más: " + caso);
                    anterior = q;
                }
            }
        }
    }

    @Test
    void tarifaNegativaSeRechaza() {
        assertThrows(IllegalArgumentException.class, () -> tarifa.cargoCancelacion(1, -1, aceptado(3)));
    }

    @Test
    void elDescuentoDelNivelSeCalculaSobreT0ComoDiceLaEcuacion7() {
        // M = 1,2: T0 = 10.800, M·T0 = 12.960; nivel 3 (3 %) → 0,03 · T0 = 324 (no 0,03 · M·T0 = 389)
        ModeloTarifa.Cobro c = tarifa.cobrar(6.5, 1.2, 3, 0.15, null);
        assertEquals(10800, c.tarifaBase());
        assertEquals(12960, c.tarifaAjustada());
        assertEquals(324, c.descuento());
    }
}
