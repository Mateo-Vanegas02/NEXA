package com.example.MotvirsWeb.presentacion.api;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.http.MediaType;

import java.security.Principal;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import com.example.MotvirsWeb.aplicacion.servicio.DocumentosConductorService;
import com.example.MotvirsWeb.aplicacion.verificacion.EntradaInvalidaException;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificacionConductorService;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificacionException;

/** Contexto mínimo (sin Mongo ni red): seguridad por método + controlador con servicio mockeado. */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = ApiAdminVerificacionControllerTest.Cfg.class)
class ApiAdminVerificacionControllerTest {

    @Configuration
    @EnableMethodSecurity
    static class Cfg {
        @Bean
        VerificacionConductorService servicio() {
            return mock(VerificacionConductorService.class);
        }

        @Bean
        DocumentosConductorService documentos() {
            return mock(DocumentosConductorService.class);
        }

        @Bean
        ApiAdminVerificacionController controller(VerificacionConductorService s, DocumentosConductorService d) {
            return new ApiAdminVerificacionController(s, d, mock(com.example.MotvirsWeb.aplicacion.verificacion.RevisionConductorService.class),
                    mock(com.example.MotvirsWeb.aplicacion.servicio.LecturaDocumentosService.class),
                    mock(com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository.class),
                    mock(com.example.MotvirsWeb.dominio.repositorio.VehiculoRepository.class),
                    mock(com.example.MotvirsWeb.aplicacion.servicio.VehiculoConductorService.class));
        }
    }

    @Autowired
    ApiAdminVerificacionController controller;
    @Autowired
    VerificacionConductorService servicio;

    private final Principal p = () -> "admin@test.com";

    @Test
    @WithMockUser(roles = "PASAJERO")
    void pasajeroNoPuedeDecidirNiVerificar() {
        var dec = new ApiAdminVerificacionController.DecisionRequest("c@test.com", true, null);
        var ver = new ApiAdminVerificacionController.VerificarRequest("c@test.com", null);
        assertThrows(AccessDeniedException.class, () -> controller.decision(dec, p));
        assertThrows(AccessDeniedException.class, () -> controller.verificar(ver, p));
        assertThrows(AccessDeniedException.class, () -> controller.estado("c@test.com"));
    }

    @Test
    @WithMockUser(roles = "CONDUCTOR")
    void conductorNoPuedeAprobarse() {
        var dec = new ApiAdminVerificacionController.DecisionRequest("c@test.com", true, null);
        assertThrows(AccessDeniedException.class, () -> controller.decision(dec, p));
        verifyNoInteractions(servicio);
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void adminPuedeYSeMapeanErrores() throws Exception {
        MockMvc mvc = MockMvcBuilders.standaloneSetup(controller).build();
        mvc.perform(post("/api/admin/verificacion/decision").principal(p).contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"c@test.com\",\"aprobar\":true}")).andExpect(status().isOk());
        verify(servicio).decidir("c@test.com", "admin@test.com", true, null);

        doThrow(new VerificacionException(VerificacionException.Tipo.NO_VERIFICADO, "falta verificacion"))
                .when(servicio).decidir(any(), any(), anyBoolean(), any());
        mvc.perform(post("/api/admin/verificacion/decision").principal(p).contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"c@test.com\",\"aprobar\":true}")).andExpect(status().isConflict());

        doThrow(new EntradaInvalidaException("Documento inválido")).when(servicio).verificar(any(), any(), any());
        mvc.perform(post("/api/admin/verificacion/verificar").principal(p).contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"c@test.com\",\"ownerDocument\":\"abc\"}")).andExpect(status().isBadRequest());

        doThrow(new IllegalStateException("detalle interno")).when(servicio).verificar(any(), any(), any());
        mvc.perform(post("/api/admin/verificacion/verificar").principal(p).contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"c@test.com\"}")).andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.error").value("Error interno"));

        mvc.perform(post("/api/admin/verificacion/decision").principal(p).contentType(MediaType.APPLICATION_JSON)
                .content("no-es-json")).andExpect(status().isBadRequest());
    }
}
