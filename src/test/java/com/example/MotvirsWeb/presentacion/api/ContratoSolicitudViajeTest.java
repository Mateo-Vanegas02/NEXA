package com.example.MotvirsWeb.presentacion.api;

import com.example.MotvirsWeb.aplicacion.comando.SolicitudViaje;
import com.example.MotvirsWeb.aplicacion.servicio.CotizacionService;
import com.example.MotvirsWeb.aplicacion.servicio.ServicioService;
import com.example.MotvirsWeb.dominio.regla.ModeloTarifa;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaPropertiesTestSupport;
import com.example.MotvirsWeb.dominio.regla.Ruta;
import com.example.MotvirsWeb.aplicacion.util.UsuarioContextHelper;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Fija el contrato JSON que usa el front (Dashboard_P_v2.js) contra los DTOs validados:
 * mismos nombres de campo y errores en formato {error, message}.
 */
class ContratoSolicitudViajeTest {

    private ServicioService servicioService;
    private CotizacionService cotizacionService;
    private UsuarioContextHelper usuarioContext;
    private MockMvc mvc;

    @BeforeEach
    void preparar() {
        servicioService = mock(ServicioService.class);
        cotizacionService = mock(CotizacionService.class);
        usuarioContext = mock(UsuarioContextHelper.class);
        when(usuarioContext.getPasajeroAutenticado()).thenReturn(new Pasajero());
        mvc = MockMvcBuilders.standaloneSetup(new ApiPasajeroController(servicioService, cotizacionService,
                mock(com.example.MotvirsWeb.aplicacion.servicio.DeudaService.class), usuarioContext,
                mock(com.example.MotvirsWeb.aplicacion.servicio.SeguimientoPasajeroService.class),
                mock(com.example.MotvirsWeb.aplicacion.servicio.ViajeEnVivoService.class),
                mock(com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties.class)))
                .setControllerAdvice(new ManejadorErroresValidacion())
                .build();
    }

    private static final String JSON_FRONT = """
            {"origen":"Calle 1","destino":"Calle 2",
             "ubicacionOrigen":{"latitud":4.6,"longitud":-74.1},
             "ubicacionDestino":{"latitud":4.7,"longitud":-74.0},
             "distanciaKM":10.5,"tarifa":15000,
             "fechaHora":"2026-10-13T22:00:00.000Z","metodoPago":"Efectivo"}""";

    @Test
    void elJsonDelFrontLlegaComoComando() throws Exception {
        when(servicioService.solicitarViaje(any(), any())).thenReturn(Map.of("servicioId", "abc"));

        mvc.perform(post("/api/pasajero/solicitar-viaje").contentType(MediaType.APPLICATION_JSON).content(JSON_FRONT))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.servicioId").value("abc"));

        ArgumentCaptor<SolicitudViaje> c = ArgumentCaptor.forClass(SolicitudViaje.class);
        verify(servicioService).solicitarViaje(c.capture(), any());
        assertEquals("Calle 1", c.getValue().origen());
        assertEquals(-74.0, c.getValue().ubicacionDestino().longitud());
        assertEquals("Efectivo", c.getValue().metodoPago());
        // "distanciaKM" y "tarifa" del JSON viejo se ignoran: el servidor calcula ambos.
    }

    @Test
    void cotizarDevuelveElPrecioSinComisionNiMargen() throws Exception {
        var tarifa = new ModeloTarifa(ModeloNexaPropertiesTestSupport.cargar());
        when(cotizacionService.cotizar(any(), any(), any())).thenReturn(
                new CotizacionService.Cotizacion(new Ruta(6.5, 5.0, "recta"), tarifa.cotizar(6.5, 5)));

        String cuerpo = """
                {"ubicacionOrigen":{"latitud":10.4236,"longitud":-75.5487},
                 "ubicacionDestino":{"latitud":10.5370,"longitud":-75.4100}}""";
        mvc.perform(post("/api/pasajero/cotizar").contentType(MediaType.APPLICATION_JSON).content(cuerpo))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.distanciaKm").value(6.5))
                .andExpect(jsonPath("$.tarifa").value(10800))
                .andExpect(jsonPath("$.descuento").value(490))
                .andExpect(jsonPath("$.precio").value(10300))
                .andExpect(jsonPath("$.comisionPct").doesNotExist())
                .andExpect(jsonPath("$.ingresoPlataforma").doesNotExist());
    }

    @Test
    void cotizarFueraDeLaZonaResponde400ConElMotivo() throws Exception {
        when(cotizacionService.cotizar(any(), any(), any())).thenThrow(new org.springframework.web.server.ResponseStatusException(
                org.springframework.http.HttpStatus.BAD_REQUEST, "El origen está fuera de la zona de servicio de Cartagena"));

        String cuerpo = """
                {"ubicacionOrigen":{"latitud":4.6,"longitud":-74.1},
                 "ubicacionDestino":{"latitud":10.4,"longitud":-75.5}}""";
        mvc.perform(post("/api/pasajero/cotizar").contentType(MediaType.APPLICATION_JSON).content(cuerpo))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("El origen está fuera de la zona de servicio de Cartagena"));
    }

    @Test
    void cotizarSinDestinoResponde400() throws Exception {
        mvc.perform(post("/api/pasajero/cotizar").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"ubicacionOrigen\":{\"latitud\":10.4,\"longitud\":-75.5}}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("La ubicación de destino es obligatoria"));
        verify(cotizacionService, never()).cotizar(any(), any(), any());
    }

    @Test
    void faltaUnCampoResponde400ConMensaje() throws Exception {
        String sinDestino = JSON_FRONT.replace("\"destino\":\"Calle 2\",", "");

        mvc.perform(post("/api/pasajero/solicitar-viaje").contentType(MediaType.APPLICATION_JSON).content(sinDestino))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("El destino es obligatorio"))
                .andExpect(jsonPath("$.message").value("El destino es obligatorio"));

        verify(servicioService, never()).solicitarViaje(any(), any());
    }

    @Test
    void jsonMalFormadoResponde400() throws Exception {
        mvc.perform(post("/api/pasajero/solicitar-viaje").contentType(MediaType.APPLICATION_JSON).content("{no es json"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").exists());
    }

    @Test
    void calificacionFueraDeRangoResponde400() throws Exception {
        mvc.perform(post("/api/pasajero/calificar-servicio/s1").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"calificacion\":9,\"comentarios\":\"x\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("La calificación debe estar entre 0 y 5"));
    }
}
