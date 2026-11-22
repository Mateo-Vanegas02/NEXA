package com.example.MotvirsWeb.infraestructura.rutas;

import com.example.MotvirsWeb.dominio.regla.ModeloNexaPropertiesTestSupport;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.regla.Ruta;
import org.junit.jupiter.api.Test;

import java.net.URI;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.Function;

import static org.junit.jupiter.api.Assertions.*;

class RutaOsrmTest {

    private static final PuntoGeo A = new PuntoGeo(10.4236, -75.5487);
    private static final PuntoGeo B = new PuntoGeo(10.4000, -75.5200);

    private static final String OK = """
            {"code":"Ok","routes":[{"distance":5200.5,"duration":600,"geometry":"_p~iF~ps|U_ulLnnqC_mqNvxq`@"}]}""";

    private final RutaLineaRecta respaldo = new RutaLineaRecta(ModeloNexaPropertiesTestSupport.cargar());

    @Test
    void usaDistanciaDuracionYTrazadoDeOsrm() {
        RutaOsrm osrm = new RutaOsrm("https://osrm.test/", uri -> OK, respaldo);
        Ruta r = osrm.calcular(A, B);
        assertEquals("osrm", r.fuente());
        assertEquals(5.2005, r.distanciaKm(), 1e-9);
        assertEquals(10.0, r.duracionMin(), 1e-9);
        assertTrue(r.tieneTrazado());
        assertEquals(A.distanciaKm(B), r.distanciaRectaKm(), 1e-9);
    }

    @Test
    void pideLongitudPrimeroComoExigeOsrm() {
        AtomicReference<URI> pedida = new AtomicReference<>();
        RutaOsrm osrm = new RutaOsrm("https://osrm.test", uri -> {
            pedida.set(uri);
            return OK;
        }, respaldo);
        osrm.calcular(A, B);
        assertEquals("https://osrm.test/route/v1/driving/-75.548700,10.423600;-75.520000,10.400000",
                pedida.get().toString().split("\\?")[0]);
        assertTrue(pedida.get().getQuery().contains("overview=full"));
        assertTrue(pedida.get().getQuery().contains("geometries=polyline"));
    }

    @Test
    void sinRespuestaCaeALaLineaRecta() {
        Function<URI, String> caido = uri -> {
            throw new IllegalStateException("timeout");
        };
        Ruta r = new RutaOsrm("https://osrm.test", caido, respaldo).calcular(A, B);
        assertEquals("recta", r.fuente());
        assertFalse(r.tieneTrazado());
        assertEquals(A.distanciaKm(B) * 1.3, r.distanciaKm(), 1e-9);
    }

    @Test
    void respuestasInvalidasCaenALaLineaRecta() {
        for (String malo : new String[] { "no es json", "{\"code\":\"NoRoute\"}",
                "{\"code\":\"Ok\",\"routes\":[]}", "{\"code\":\"Ok\",\"routes\":[{\"distance\":0}]}" }) {
            Ruta r = new RutaOsrm("https://osrm.test", uri -> malo, respaldo).calcular(A, B);
            assertEquals("recta", r.fuente(), malo);
        }
    }

    @Test
    void sinUrlConfiguradaCaeALaLineaRecta() {
        assertEquals("recta", new RutaOsrm(null, uri -> OK, respaldo).calcular(A, B).fuente());
    }

    @Test
    void porCalleNuncaEsMenosQueLaRecta() {
        String corta = "{\"code\":\"Ok\",\"routes\":[{\"distance\":10,\"duration\":5,\"geometry\":\"x\"}]}";
        Ruta r = new RutaOsrm("https://osrm.test", uri -> corta, respaldo).calcular(A, B);
        assertEquals(A.distanciaKm(B), r.distanciaKm(), 1e-9);
    }

    @Test
    void repetirLaMismaConsultaNoVuelveAPreguntar() {
        AtomicInteger llamadas = new AtomicInteger();
        RutaOsrm osrm = new RutaOsrm("https://osrm.test", uri -> {
            llamadas.incrementAndGet();
            return OK;
        }, respaldo);
        osrm.calcular(A, B);
        osrm.calcular(A, B);
        assertEquals(1, llamadas.get());
        osrm.calcular(B, A);
        assertEquals(2, llamadas.get());
    }

    @Test
    void laFallaNoSeGuardaEnCache() {
        AtomicInteger llamadas = new AtomicInteger();
        RutaOsrm osrm = new RutaOsrm("https://osrm.test", uri -> {
            if (llamadas.incrementAndGet() == 1) {
                throw new IllegalStateException("caído");
            }
            return OK;
        }, respaldo);
        assertEquals("recta", osrm.calcular(A, B).fuente());
        assertEquals("osrm", osrm.calcular(A, B).fuente());
    }

    @Test
    void alternativasDevuelveTodasLasRutasYPideAlternativasAOsrm() {
        AtomicReference<URI> pedida = new AtomicReference<>();
        String tres = "{\"code\":\"Ok\",\"routes\":[{\"distance\":5200,\"duration\":600,\"geometry\":\"a\"},"
                + "{\"distance\":4800,\"duration\":660,\"geometry\":\"b\"},{\"distance\":0,\"duration\":1}]}";
        java.util.List<Ruta> rutas = new RutaOsrm("https://osrm.test", uri -> {
            pedida.set(uri);
            return tres;
        }, respaldo).alternativas(A, B);
        assertTrue(pedida.get().getQuery().contains("alternatives=2"));
        assertEquals(2, rutas.size());
        assertEquals("a", rutas.get(0).geometria());
        assertEquals(11.0, rutas.get(1).duracionMin(), 1e-9);
    }

    @Test
    void alternativasSinOsrmCaeALaLineaRecta() {
        java.util.List<Ruta> rutas = new RutaOsrm("https://osrm.test", uri -> {
            throw new IllegalStateException("timeout");
        }, respaldo).alternativas(A, B);
        assertEquals(1, rutas.size());
        assertEquals("recta", rutas.get(0).fuente());
    }

    @Test
    void leeLasManiobrasConElNombreDeLaCalle() {
        String cuerpo = """
                {"code":"Ok","routes":[{"distance":1200,"duration":240,"geometry":"_p~iF~ps|U",
                 "legs":[{"steps":[
                   {"name":"Carrera 2","distance":300,"maneuver":{"type":"depart","location":[-75.55,10.42]}},
                   {"name":"Calle 30","distance":900,"maneuver":{"type":"turn","modifier":"right","location":[-75.548,10.421]}},
                   {"name":"","distance":0,"maneuver":{"type":"arrive","location":[-75.54,10.43]}},
                   {"name":"rota","maneuver":{"type":"turn"}}
                 ]}]}]}""";
        Ruta r = new RutaOsrm("https://osrm.test", uri -> cuerpo, respaldo).calcular(A, B);
        assertEquals(3, r.pasos().size());
        var giro = r.pasos().get(1);
        assertEquals("turn", giro.maniobra());
        assertEquals("right", giro.modificador());
        assertEquals("Calle 30", giro.calle());
        assertEquals(10.421, giro.latitud(), 1e-9);
        assertEquals(-75.548, giro.longitud(), 1e-9);
        assertEquals(900, giro.metros(), 1e-9);
    }

    @Test
    void pideLosPasosAOsrm() {
        java.util.List<java.net.URI> pedidas = new java.util.ArrayList<>();
        new RutaOsrm("https://osrm.test", uri -> {
            pedidas.add(uri);
            return OK;
        }, respaldo).calcular(A, B);
        assertTrue(pedidas.get(0).toString().contains("steps=true"));
    }
}
