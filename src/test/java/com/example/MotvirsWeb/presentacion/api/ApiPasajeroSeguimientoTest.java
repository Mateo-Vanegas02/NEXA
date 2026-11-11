package com.example.MotvirsWeb.presentacion.api;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal.PosicionViaje;
import com.example.MotvirsWeb.aplicacion.servicio.CotizacionService;
import com.example.MotvirsWeb.aplicacion.servicio.DeudaService;
import com.example.MotvirsWeb.aplicacion.servicio.SeguimientoPasajeroService;
import com.example.MotvirsWeb.aplicacion.servicio.ServicioService;
import com.example.MotvirsWeb.aplicacion.servicio.ViajeEnVivoService;
import com.example.MotvirsWeb.aplicacion.util.UsuarioContextHelper;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaPropertiesTestSupport;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Seguimiento del viaje por REST para la app móvil: viaje-en-camino y posición del conductor. */
class ApiPasajeroSeguimientoTest {

    private final SeguimientoPasajeroService seguimiento = mock(SeguimientoPasajeroService.class);
    private final ViajeEnVivoService viajeEnVivo = mock(ViajeEnVivoService.class);
    private final UsuarioContextHelper usuarioContext = mock(UsuarioContextHelper.class);
    private final Pasajero pasajero = new Pasajero();
    private MockMvc mvc;

    @BeforeEach
    void preparar() {
        pasajero.setId(new ObjectId());
        when(usuarioContext.getPasajeroAutenticado()).thenReturn(pasajero);
        mvc = MockMvcBuilders.standaloneSetup(new ApiPasajeroController(mock(ServicioService.class),
                mock(CotizacionService.class), mock(DeudaService.class), usuarioContext, seguimiento, viajeEnVivo,
                ModeloNexaPropertiesTestSupport.cargar())).build();
    }

    @Test
    void viajeEnCaminoIncluyeLaVistaDelPasajeroYLasReglasDeEspera() throws Exception {
        Servicio s = new Servicio();
        s.setId("s1");
        s.setEstado(EstadoServicio.ACEPTADO);
        s.setConductor(new Servicio.ConductorEmbedded());
        s.getConductor().setNombre("Carlos");
        when(seguimiento.viajeEnCamino(any())).thenReturn(Optional.of(s));

        mvc.perform(get("/api/pasajero/viaje-en-camino"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.activo").value(true))
                .andExpect(jsonPath("$.id").value("s1"))
                .andExpect(jsonPath("$.conductor.nombre").value("Carlos"))
                .andExpect(jsonPath("$.servicio.id").value("s1"))
                .andExpect(jsonPath("$.espera.graciaMinutos").exists());
    }

    @Test
    void sinViajeEnCaminoResponde200ConActivoFalso() throws Exception {
        when(seguimiento.viajeEnCamino(any())).thenReturn(Optional.empty());

        mvc.perform(get("/api/pasajero/viaje-en-camino"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.activo").value(false));
    }

    @Test
    void posicionDelConductorDevuelve200ConLoQueCalculaElServidor() throws Exception {
        when(viajeEnVivo.posicionDe("s1", pasajero.getIdString())).thenReturn(Optional.of(
                new PosicionViaje("s1", "ACEPTADO", 10.41, -75.52, 1.2, 4, 123L)));

        mvc.perform(get("/api/pasajero/posicion-conductor/s1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fase").value("ACEPTADO"))
                .andExpect(jsonPath("$.distanciaRestanteKm").value(1.2))
                .andExpect(jsonPath("$.etaMinutos").value(4));
    }

    @Test
    void sinPosicionVigenteOViajeAjenoResponde204() throws Exception {
        when(viajeEnVivo.posicionDe(any(), any())).thenReturn(Optional.empty());

        mvc.perform(get("/api/pasajero/posicion-conductor/s1")).andExpect(status().isNoContent());
    }
}
