package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.DespachoOlas;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaPropertiesTestSupport;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class DespachoServiceTest {

    private static final LocalDateTime AHORA = LocalDateTime.of(2026, 10, 24, 12, 0, 0);
    private static final PuntoGeo RECOGIDA = new PuntoGeo(10.4236, -75.5253);

    private DespachoService despacho;
    private UbicacionConductorService ubicaciones;

    @BeforeEach
    void preparar() {
        ModeloNexaProperties cfg = ModeloNexaPropertiesTestSupport.cargar();
        Clock reloj = Clock.fixed(AHORA.toInstant(ZoneOffset.UTC), ZoneOffset.UTC);
        ubicaciones = new UbicacionConductorService(cfg, reloj);
        despacho = new DespachoService(new DespachoOlas(cfg), ubicaciones, reloj, cfg);
    }

    private Servicio solicitud(long segundosEsperando) {
        Servicio s = new Servicio();
        s.setId(new ObjectId().toHexString());
        s.setSolicitadoEn(AHORA.minusSeconds(segundosEsperando));
        Servicio.Coordenada o = new Servicio.Coordenada();
        o.setLatitud(RECOGIDA.latitud());
        o.setLongitud(RECOGIDA.longitud());
        s.setUbicacionOrigen(o);
        return s;
    }

    private Conductor conductor() {
        Conductor c = new Conductor();
        c.setId(new ObjectId());
        return c;
    }

    @Test
    void elConductorCercanoVeLaSolicitudDesdeLaPrimeraOla() {
        Conductor c = conductor();
        ubicaciones.registrar(c.getId(), new PuntoGeo(10.4300, -75.5253), true); // ~0,7 km
        assertEquals(1, despacho.filtrarPorOla(List.of(solicitud(5)), c, null, null).size());
    }

    @Test
    void elLejanoLaVeCuandoLaOlaLlegaASuDistancia() {
        Conductor c = conductor();
        ubicaciones.registrar(c.getId(), new PuntoGeo(10.4560, -75.5253), true); // ~3,6 km
        assertTrue(despacho.filtrarPorOla(List.of(solicitud(10)), c, null, null).isEmpty());
        assertTrue(despacho.filtrarPorOla(List.of(solicitud(30)), c, null, null).isEmpty());
        assertEquals(1, despacho.filtrarPorOla(List.of(solicitud(55)), c, null, null).size());
    }

    @Test
    void masAllaDelTopeNuncaLaVe() {
        Conductor c = conductor();
        ubicaciones.registrar(c.getId(), new PuntoGeo(10.5000, -75.5253), true); // ~8,5 km
        assertTrue(despacho.filtrarPorOla(List.of(solicitud(600)), c, null, null).isEmpty());
    }

    @Test
    void sinPosicionSoloVeLaUltimaOla() {
        Conductor c = conductor();
        assertTrue(despacho.filtrarPorOla(List.of(solicitud(30)), c, null, null).isEmpty());
        assertEquals(1, despacho.filtrarPorOla(List.of(solicitud(95)), c, null, null).size());
    }

    @Test
    void laPosicionDeLaPeticionTienePrioridadSobreLaGuardada() {
        Conductor c = conductor();
        ubicaciones.registrar(c.getId(), new PuntoGeo(10.5000, -75.5253), true); // lejos
        assertEquals(1, despacho.filtrarPorOla(List.of(solicitud(5)), c, 10.4300, -75.5253).size());
        // coordenadas inválidas: se usa la guardada
        assertTrue(despacho.filtrarPorOla(List.of(solicitud(5)), c, 999.0, 0.0).isEmpty());
    }

    @Test
    void noSePuedeAceptarUnaSolicitudQueTodaviaNoLlega() {
        Conductor c = conductor();
        ubicaciones.registrar(c.getId(), new PuntoGeo(10.4560, -75.5253), true); // ~3,6 km
        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> despacho.verificarPuedeAceptar(solicitud(5), c));
        assertEquals(403, e.getStatusCode().value());
        assertDoesNotThrow(() -> despacho.verificarPuedeAceptar(solicitud(100), c));
    }

    @Test
    void elAvisoCuentaLosConductoresDeLaOlaActual() {
        ubicaciones.registrar(new ObjectId(), new PuntoGeo(10.4300, -75.5253), true); // ~0,7 km
        ubicaciones.registrar(new ObjectId(), new PuntoGeo(10.4560, -75.5253), true); // ~3,6 km
        ubicaciones.registrar(new ObjectId(), new PuntoGeo(10.5000, -75.5253), true); // ~8,5 km

        var primera = despacho.avisoDe(solicitud(5));
        assertEquals(1, primera.ola());
        assertEquals(1, primera.conductoresAvisados());
        assertEquals(1.5, primera.radioKm());
        assertEquals(20L, primera.segundosSiguienteOla());

        var tercera = despacho.avisoDe(solicitud(65));
        assertEquals(3, tercera.ola());
        assertEquals(2, tercera.conductoresAvisados());

        var ultima = despacho.avisoDe(solicitud(200));
        assertEquals(4, ultima.ola());
        assertEquals(2, ultima.conductoresAvisados()); // el de ~8,5 km queda fuera del tope
        assertEquals(6.0, ultima.radioKm());
        assertNull(ultima.segundosSiguienteOla());
    }

    @Test
    void alAceptarSeGuardanLaOlaYLaDistancia() {
        Conductor c = conductor();
        ubicaciones.registrar(c.getId(), new PuntoGeo(10.4300, -75.5253), true); // ~0,7 km
        var datos = despacho.datosAceptacion(solicitud(30), c);
        assertEquals(2, datos.ola());
        assertEquals(0.71, datos.distanciaKm(), 0.02);

        var sinPosicion = despacho.datosAceptacion(solicitud(90), conductor());
        assertEquals(4, sinPosicion.ola());
        assertNull(sinPosicion.distanciaKm());
    }

    @Test
    void elExtraVoluntarioAdelantaLaOlaDeLaSolicitud() {
        Conductor c = conductor();
        ubicaciones.registrar(c.getId(), new PuntoGeo(10.4440, -75.5253), true); // ~2,3 km
        Servicio sinExtra = solicitud(5);
        assertTrue(despacho.filtrarPorOla(List.of(sinExtra), c, null, null).isEmpty());

        Servicio conExtra = solicitud(5);
        conExtra.setExtraVoluntario(1000);
        assertEquals(1, despacho.filtrarPorOla(List.of(conExtra), c, null, null).size());
        assertEquals(2, despacho.olaDe(conExtra));
        assertTrue(despacho.avisoDe(conExtra).adelantadaPorExtra());
        assertFalse(despacho.avisoDe(sinExtra).adelantadaPorExtra());
    }

}
