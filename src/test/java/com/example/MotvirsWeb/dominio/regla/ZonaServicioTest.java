package com.example.MotvirsWeb.dominio.regla;

import com.example.MotvirsWeb.dominio.regla.ZonaServicio.Resultado;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.junit.jupiter.api.Assertions.*;

class ZonaServicioTest {

    private final ZonaServicio zona = new ZonaServicio(ModeloNexaPropertiesTestSupport.cargar());

    private static final PuntoGeo CENTRO = new PuntoGeo(10.4236, -75.5487);
    private static final PuntoGeo BAYUNCA = new PuntoGeo(10.5370, -75.4100);
    private static final PuntoGeo PASACABALLOS = new PuntoGeo(10.2850, -75.5180);

    @ParameterizedTest(name = "{0} está dentro")
    @CsvSource({
            "Centro histórico, 10.4236, -75.5487",
            "Bocagrande, 10.3997, -75.5580",
            "Castillogrande, 10.3920, -75.5530",
            "Manga, 10.4100, -75.5400",
            "Aeropuerto, 10.4424, -75.5130",
            "La Boquilla, 10.4740, -75.4950",
            "Manzanillo del Mar, 10.5200, -75.4700",
            "Bayunca, 10.5370, -75.4100",
            "Ternera, 10.3870, -75.4600",
            "El Pozón, 10.4150, -75.4650",
            "Olaya Herrera, 10.4170, -75.4980",
            "Mamonal, 10.3300, -75.5000",
            "Pasacaballos, 10.2850, -75.5180"
    })
    void barriosDeCartagenaEstanDentro(String nombre, double lat, double lng) {
        assertTrue(zona.contiene(new PuntoGeo(lat, lng)), nombre);
    }

    @ParameterizedTest(name = "{0} está fuera")
    @CsvSource({
            "Turbaco, 10.3325, -75.4142",
            "Tierra Bomba, 10.3600, -75.5800",
            "Playa Blanca (Barú), 10.2300, -75.6000",
            "Barranquilla, 10.9639, -74.7964",
            "Bogotá, 4.7110, -74.0721",
            "Origen 0 0, 0, 0"
    })
    void puntosLejanosQuedanFuera(String nombre, double lat, double lng) {
        assertFalse(zona.contiene(new PuntoGeo(lat, lng)), nombre);
    }

    @Test
    void elViajeUrbanoMasLargoCabeEnElLimite() {
        double recta = BAYUNCA.distanciaKm(PASACABALLOS);
        assertEquals(30.4, recta, 0.1);
        assertEquals(40, zona.distanciaMaxKm());
        assertEquals(Resultado.VALIDO, zona.evaluar(BAYUNCA, PASACABALLOS, recta * 1.3));
    }

    @Test
    void evaluarRechazaCadaCaso() {
        PuntoGeo bogota = new PuntoGeo(4.7110, -74.0721);
        assertEquals(Resultado.ORIGEN_FUERA_DE_ZONA, zona.evaluar(bogota, CENTRO, 5));
        assertEquals(Resultado.DESTINO_FUERA_DE_ZONA, zona.evaluar(CENTRO, bogota, 5));
        assertEquals(Resultado.DISTANCIA_EXCEDIDA, zona.evaluar(CENTRO, PASACABALLOS, 40.1));
        assertEquals(Resultado.VALIDO, zona.evaluar(CENTRO, PASACABALLOS, 20));
    }

    @Test
    void poligonoMalConfiguradoFallaAlArrancar() {
        assertThrows(IllegalStateException.class, () -> ZonaServicio.parsear(""));
        assertThrows(IllegalStateException.class, () -> ZonaServicio.parsear("10 -75; 11 -75"));
        assertThrows(IllegalStateException.class, () -> ZonaServicio.parsear("10 -75; 11; 12 -74"));
        assertEquals(12, zona.vertices().size());
    }
}
