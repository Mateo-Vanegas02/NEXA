package com.example.MotvirsWeb.presentacion.api;

import com.example.MotvirsWeb.aplicacion.servicio.IdempotenciaService;
import com.example.MotvirsWeb.aplicacion.servicio.NivelesService;
import com.example.MotvirsWeb.aplicacion.servicio.OptimizerService;
import com.example.MotvirsWeb.aplicacion.servicio.SaldoConductorService;
import com.example.MotvirsWeb.aplicacion.servicio.SeguimientoPasajeroService;
import com.example.MotvirsWeb.aplicacion.servicio.ServicioService;
import com.example.MotvirsWeb.aplicacion.servicio.UbicacionConductorService;
import com.example.MotvirsWeb.aplicacion.servicio.UbicacionLoteService;
import com.example.MotvirsWeb.aplicacion.servicio.ViajeEnVivoService;
import com.example.MotvirsWeb.aplicacion.util.UsuarioContextHelper;
import com.example.MotvirsWeb.aplicacion.puerto.CanalPeticion;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.presentacion.dto.CalificacionRequest;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.ResponseEntity;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/** La app del conductor: «Ganas $X» en cada solicitud y calificar al pasajero con factores. */
class ApiConductorCalificacionTest {

    private ServicioService servicios;
    private NivelesService niveles;
    private ApiConductorController api;
    private final Conductor conductor = new Conductor();

    @BeforeEach
    void preparar() {
        servicios = mock(ServicioService.class);
        niveles = mock(NivelesService.class);
        UsuarioContextHelper contexto = mock(UsuarioContextHelper.class);
        conductor.setId(new ObjectId());
        when(contexto.getConductorAutenticado()).thenReturn(conductor);
        api = new ApiConductorController(servicios, mock(OptimizerService.class), contexto,
                mock(SeguimientoPasajeroService.class), mock(UbicacionConductorService.class),
                mock(CanalPeticion.class), mock(ViajeEnVivoService.class), mock(SaldoConductorService.class),
                mock(IdempotenciaService.class), mock(UbicacionLoteService.class), niveles,
                mock(com.example.MotvirsWeb.aplicacion.servicio.RutaEnVivoService.class));
    }

    @Test
    void cadaSolicitudTraeLoQueGanaria() {
        Servicio s = new Servicio();
        s.setId("s1");
        s.setEstado(EstadoServicio.SOLICITADO);
        s.setTarifa(7000);
        when(servicios.obtenerServiciosDisponibles(eq(conductor), any(), any())).thenReturn(List.of(s));
        when(niveles.gananciaEstimada(s, conductor)).thenReturn(5600L);

        List<Servicio> lista = api.obtenerServiciosDisponibles(10.4, -75.5).getBody();

        assertNotNull(lista);
        assertEquals(5600L, lista.get(0).getGananciaEstimada());
        assertNull(s.getGananciaEstimada(), "la entidad no se toca");
    }

    @Test
    void calificaComoConductorConSusFactores() {
        when(servicios.calificarServicio(eq("s1"), eq("conductor"), eq(2.0), eq(""),
                eq(List.of("ESPERA_EN_EL_PUNTO")), anyString()))
                .thenReturn(Map.of("mensaje", "ok", "servicioId", "s1"));

        ResponseEntity<?> r = api.calificarServicio("s1",
                new CalificacionRequest(2.0, null, List.of("ESPERA_EN_EL_PUNTO")));

        assertEquals(200, r.getStatusCode().value());
        verify(servicios).calificarServicio("s1", "conductor", 2.0, "", List.of("ESPERA_EN_EL_PUNTO"),
                conductor.getIdString());
    }

    @Test
    void sinNotaResponde400() {
        ResponseEntity<?> r = api.calificarServicio("s1", new CalificacionRequest(null, "x", List.of()));
        assertEquals(400, r.getStatusCode().value());
        verifyNoInteractions(servicios);
    }
}
