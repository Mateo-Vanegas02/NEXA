package com.example.MotvirsWeb.infraestructura.seguridad;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.util.Optional;

import org.bson.types.ObjectId;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;

class BloqueoCierreSesionFilterTest {

    private final UsuarioRepository usuarios = mock(UsuarioRepository.class);
    private final ServicioRepository servicios = mock(ServicioRepository.class);
    private final BloqueoCierreSesionFilter filtro = new BloqueoCierreSesionFilter(usuarios, servicios);
    private final ObjectId pasajeroId = new ObjectId();

    @BeforeEach
    void autenticar() {
        SecurityContextHolder.getContext().setAuthentication(new TestingAuthenticationToken("p@x.com", "n", "ROLE_PASAJERO"));
        when(usuarios.findByEmail("p@x.com"))
                .thenReturn(Optional.of(Pasajero.builder().id(pasajeroId).email("p@x.com").build()));
    }

    @AfterEach
    void limpiar() {
        SecurityContextHolder.clearContext();
    }

    private MockHttpServletRequest cierre() {
        MockHttpServletRequest r = new MockHttpServletRequest("POST", "/auth/logout");
        r.setServletPath("/auth/logout");
        return r;
    }

    @Test
    void conSolicitudEsperandoNoDejaCerrarSesionYVuelveAlPanel() throws Exception {
        when(servicios.existsByPasajeroIdAndEstado(pasajeroId, EstadoServicio.SOLICITADO)).thenReturn(true);
        MockHttpServletResponse res = new MockHttpServletResponse();
        MockFilterChain cadena = new MockFilterChain();

        filtro.doFilter(cierre(), res, cadena);

        assertEquals("/pasajero/panel?cierreBloqueado=true", res.getRedirectedUrl());
        assertNull(cadena.getRequest(), "no debe llegar al cierre de sesión");
    }

    @Test
    void siPideJsonResponde409() throws Exception {
        when(servicios.existsByPasajeroIdAndEstado(pasajeroId, EstadoServicio.SOLICITADO)).thenReturn(true);
        MockHttpServletRequest req = cierre();
        req.addHeader("Accept", "application/json");
        MockHttpServletResponse res = new MockHttpServletResponse();

        filtro.doFilter(req, res, new MockFilterChain());

        assertEquals(409, res.getStatus());
        assertTrue(res.getContentAsString().contains("Cancélala"));
    }

    @Test
    void sinSolicitudEsperandoDejaCerrarSesion() throws Exception {
        when(servicios.existsByPasajeroIdAndEstado(pasajeroId, EstadoServicio.SOLICITADO)).thenReturn(false);
        MockFilterChain cadena = new MockFilterChain();

        filtro.doFilter(cierre(), new MockHttpServletResponse(), cadena);

        assertNotNull(cadena.getRequest());
    }

    @Test
    void pasajeroConViajeAceptadoOEnCursoNoDejaCerrarSesion() throws Exception {
        when(servicios.existsByPasajeroIdAndEstadoIn(pasajeroId,
                java.util.List.of(EstadoServicio.ACEPTADO, EstadoServicio.EN_CURSO))).thenReturn(true);
        MockHttpServletResponse res = new MockHttpServletResponse();
        MockFilterChain cadena = new MockFilterChain();

        filtro.doFilter(cierre(), res, cadena);

        assertEquals("/pasajero/panel?cierreBloqueado=viaje", res.getRedirectedUrl());
        assertNull(cadena.getRequest());
    }

    private ObjectId autenticarConductor() {
        ObjectId id = new ObjectId();
        SecurityContextHolder.getContext().setAuthentication(new TestingAuthenticationToken("c@x.com", "n", "ROLE_CONDUCTOR"));
        when(usuarios.findByEmail("c@x.com"))
                .thenReturn(Optional.of(Conductor.builder().id(id).email("c@x.com").build()));
        return id;
    }

    @Test
    void conductorConViajeEnMarchaNoDejaCerrarSesion() throws Exception {
        ObjectId id = autenticarConductor();
        when(servicios.existsByConductorIdAndEstadoIn(id,
                java.util.List.of(EstadoServicio.ACEPTADO, EstadoServicio.EN_CURSO))).thenReturn(true);
        MockHttpServletResponse res = new MockHttpServletResponse();
        MockFilterChain cadena = new MockFilterChain();

        filtro.doFilter(cierre(), res, cadena);

        assertEquals("/conductor/panel?cierreBloqueado=viaje", res.getRedirectedUrl());
        assertNull(cadena.getRequest());
    }

    @Test
    void conductorConViajeEnMarchaYJsonResponde409() throws Exception {
        ObjectId id = autenticarConductor();
        when(servicios.existsByConductorIdAndEstadoIn(id,
                java.util.List.of(EstadoServicio.ACEPTADO, EstadoServicio.EN_CURSO))).thenReturn(true);
        MockHttpServletRequest req = cierre();
        req.addHeader("Accept", "application/json");
        MockHttpServletResponse res = new MockHttpServletResponse();

        filtro.doFilter(req, res, new MockFilterChain());

        assertEquals(409, res.getStatus());
        assertTrue(res.getContentAsString().contains("Cancela el viaje"));
    }

    @Test
    void conductorSinViajeDejaCerrarSesion() throws Exception {
        autenticarConductor();
        MockFilterChain cadena = new MockFilterChain();

        filtro.doFilter(cierre(), new MockHttpServletResponse(), cadena);

        assertNotNull(cadena.getRequest());
    }

    @Test
    void otrasRutasNoSeTocan() throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/pasajero/panel");
        req.setServletPath("/pasajero/panel");
        MockFilterChain cadena = new MockFilterChain();

        filtro.doFilter(req, new MockHttpServletResponse(), cadena);

        assertNotNull(cadena.getRequest());
        verifyNoInteractions(usuarios, servicios);
    }
}
