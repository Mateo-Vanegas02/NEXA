package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaPropertiesTestSupport;
import com.example.MotvirsWeb.dominio.regla.ModeloTarifa;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.regla.ZonaServicio;
import com.example.MotvirsWeb.infraestructura.rutas.RutaLineaRecta;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import static org.junit.jupiter.api.Assertions.*;

/** Cotización con las piezas reales (zona, línea recta × 1,3 y tarifa), sin Spring ni Mongo. */
class CotizacionServiceTest {

    private static final PuntoGeo CENTRO = new PuntoGeo(10.4236, -75.5487);
    private static final PuntoGeo AEROPUERTO = new PuntoGeo(10.4424, -75.5130);
    private static final PuntoGeo BAYUNCA = new PuntoGeo(10.5370, -75.4100);
    private static final PuntoGeo PASACABALLOS = new PuntoGeo(10.2850, -75.5180);
    private static final PuntoGeo BOGOTA = new PuntoGeo(4.7110, -74.0721);

    private final CotizacionService servicio;

    CotizacionServiceTest() {
        var cfg = ModeloNexaPropertiesTestSupport.cargar();
        servicio = new CotizacionService(new ZonaServicio(cfg), new RutaLineaRecta(cfg), new ModeloTarifa(cfg));
    }

    private static Pasajero pasajeroDeNivel(int nivelAnterior) {
        Pasajero p = new Pasajero();
        p.setNivel(nivelAnterior);
        return p;
    }

    private static void assertRechazo(Runnable accion, String fragmento) {
        ResponseStatusException e = assertThrows(ResponseStatusException.class, accion::run);
        assertEquals(HttpStatus.BAD_REQUEST, e.getStatusCode());
        assertTrue(e.getReason().contains(fragmento), e.getReason());
    }

    @Test
    void cotizaUnViajeUrbanoConLaDistanciaDelServidor() {
        var c = servicio.cotizar(pasajeroDeNivel(0), CENTRO, AEROPUERTO);

        double recta = CENTRO.distanciaKm(AEROPUERTO);
        assertEquals(recta * 1.3, c.ruta().distanciaKm(), 1e-9);
        assertEquals(new ModeloTarifa(ModeloNexaPropertiesTestSupport.cargar()).tarifaBase(recta * 1.3),
                c.cobro().tarifaBase());
        assertEquals(0, c.cobro().descuento(), "nivel 1: sin descuento");
        assertEquals(c.cobro().tarifaAjustada(), c.cobro().precio());
    }

    @Test
    void elNivelGuardadoEsElDelModelo() {
        // viaje largo para que el descuento llegue al tope: nivel 5 = 4 % (0 cuenta como nivel 1)
        var sinNivel = servicio.cotizar(pasajeroDeNivel(0), CENTRO, BAYUNCA);
        var maximo = servicio.cotizar(pasajeroDeNivel(5), CENTRO, BAYUNCA);

        assertEquals(0, sinNivel.cobro().descuento());
        assertEquals(5, maximo.cobro().nivelPasajero());
        assertTrue(maximo.cobro().descuento() > 0);
        assertTrue(maximo.cobro().precio() < sinNivel.cobro().precio());
    }

    @Test
    void elViajeMasLargoPosibleSeAcepta() {
        var c = servicio.cotizar(pasajeroDeNivel(0), BAYUNCA, PASACABALLOS);

        assertTrue(c.ruta().distanciaKm() < 40);
        assertTrue(c.cobro().precio() > 30000);
    }

    @Test
    void rechazaUnOrigenFueraDeCartagena() {
        assertRechazo(() -> servicio.cotizar(pasajeroDeNivel(0), BOGOTA, CENTRO), "origen");
    }

    @Test
    void rechazaUnDestinoFueraDeCartagena() {
        assertRechazo(() -> servicio.cotizar(pasajeroDeNivel(0), CENTRO, BOGOTA), "destino");
    }

    @Test
    void rechazaMismoOrigenYDestino() {
        assertRechazo(() -> servicio.cotizar(pasajeroDeNivel(0), CENTRO, CENTRO), "mismo punto");
    }

    @Test
    void rechazaUnaRutaMasLargaQueElMaximo() {
        var cfg = ModeloNexaPropertiesTestSupport.cargar();
        cfg.getZona().setDistanciaMaxKm(20);
        var corto = new CotizacionService(new ZonaServicio(cfg), new RutaLineaRecta(cfg), new ModeloTarifa(cfg));

        assertRechazo(() -> corto.cotizar(pasajeroDeNivel(0), BAYUNCA, PASACABALLOS), "20 km");
    }
}
