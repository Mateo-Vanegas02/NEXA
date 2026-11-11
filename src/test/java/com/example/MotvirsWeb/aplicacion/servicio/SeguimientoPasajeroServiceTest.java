package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.servicio.UbicacionConductorServiceTest.RelojManual;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaPropertiesTestSupport;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class SeguimientoPasajeroServiceTest {

    private static final PuntoGeo RECOGIDA = new PuntoGeo(10.4236, -75.5253);
    /** ~110 m al norte de la recogida. */
    private static final PuntoGeo CERCA = new PuntoGeo(10.4246, -75.5253);

    private final ServicioRepository repo = mock(ServicioRepository.class);
    private RelojManual reloj;
    private SeguimientoPasajeroService servicio;
    private Pasajero pasajero;
    private Conductor conductor;
    private Servicio viaje;

    @BeforeEach
    void preparar() {
        reloj = new RelojManual();
        servicio = new SeguimientoPasajeroService(repo, ModeloNexaPropertiesTestSupport.cargar(), reloj);
        pasajero = new Pasajero();
        pasajero.setId(new ObjectId());
        conductor = new Conductor();
        conductor.setId(new ObjectId());
        viaje = new Servicio();
        viaje.setId("s1");
        viaje.setEstado(EstadoServicio.ACEPTADO);
        viaje.setPasajero(new Servicio.PasajeroEmbedded(pasajero.getId(), "Ana", "ana@x.co"));
        Servicio.ConductorEmbedded c = new Servicio.ConductorEmbedded();
        c.setId(conductor.getId());
        viaje.setConductor(c);
        viaje.setUbicacionOrigen(new Servicio.Coordenada(RECOGIDA.latitud(), RECOGIDA.longitud()));
        when(repo.findById("s1")).thenReturn(Optional.of(viaje));
    }

    private static int estado(ResponseStatusException e) {
        return e.getStatusCode().value();
    }

    @Test
    void elConductorVeAlPasajeroYSuDistanciaALaRecogida() {
        servicio.reportar("s1", pasajero, CERCA);
        reloj.ahora = reloj.ahora.plusSeconds(4);

        var pos = servicio.consultar("s1", conductor).orElseThrow();
        assertEquals(CERCA.latitud(), pos.latitud());
        assertEquals(4, pos.haceSegundos());
        assertTrue(pos.distanciaRecogidaMetros() > 90 && pos.distanciaRecogidaMetros() < 130,
                "distancia real: " + pos.distanciaRecogidaMetros());
    }

    @Test
    void sinReportesOConUnaPosicionVencidaNoSeMuestraNada() {
        assertTrue(servicio.consultar("s1", conductor).isEmpty());
        servicio.reportar("s1", pasajero, CERCA);
        reloj.ahora = reloj.ahora.plusSeconds(31);
        assertTrue(servicio.consultar("s1", conductor).isEmpty(), "pasados 30 s se oculta");
    }

    @Test
    void soloElDuenoDelViajePuedeReportar() {
        Pasajero otro = new Pasajero();
        otro.setId(new ObjectId());
        var e = assertThrows(ResponseStatusException.class, () -> servicio.reportar("s1", otro, CERCA));
        assertEquals(HttpStatus.FORBIDDEN.value(), estado(e));
    }

    @Test
    void soloElConductorAsignadoPuedeVerlo() {
        servicio.reportar("s1", pasajero, CERCA);
        Conductor otro = new Conductor();
        otro.setId(new ObjectId());
        var e = assertThrows(ResponseStatusException.class, () -> servicio.consultar("s1", otro));
        assertEquals(HttpStatus.FORBIDDEN.value(), estado(e));
    }

    @Test
    void noSeReportaNiSeVeUnaVezIniciadoOCancelado() {
        servicio.reportar("s1", pasajero, CERCA);
        viaje.setEstado(EstadoServicio.EN_CURSO);

        assertTrue(servicio.consultar("s1", conductor).isEmpty(), "con el viaje en curso ya no se comparte");
        var e = assertThrows(ResponseStatusException.class, () -> servicio.reportar("s1", pasajero, CERCA));
        assertEquals(HttpStatus.CONFLICT.value(), estado(e));

        viaje.setEstado(EstadoServicio.ACEPTADO);
        assertTrue(servicio.consultar("s1", conductor).isEmpty(), "lo guardado antes se borró al iniciar");
    }

    @Test
    void unViajeInexistenteDa404() {
        when(repo.findById("zz")).thenReturn(Optional.empty());
        var e = assertThrows(ResponseStatusException.class, () -> servicio.consultar("zz", conductor));
        assertEquals(HttpStatus.NOT_FOUND.value(), estado(e));
    }

    @Test
    void purgarDescartaLasPosicionesAbandonadas() {
        servicio.reportar("s1", pasajero, CERCA);
        assertEquals(0, servicio.purgar());
        reloj.ahora = reloj.ahora.plusSeconds(200);
        assertEquals(1, servicio.purgar());
    }

    @Test
    void retomaElViajeAceptadoDelPasajeroTrasRecargar() {
        when(repo.findByPasajeroIdAndEstado(pasajero.getId(), EstadoServicio.ACEPTADO)).thenReturn(List.of(viaje));
        assertSame(viaje, servicio.viajeEnCamino(pasajero).orElseThrow());

        when(repo.findByPasajeroIdAndEstado(pasajero.getId(), EstadoServicio.ACEPTADO)).thenReturn(List.of());
        assertTrue(servicio.viajeEnCamino(pasajero).isEmpty());
    }
}
