package com.example.MotvirsWeb.infraestructura.seguridad;

import com.example.MotvirsWeb.dominio.modelo.AuditoriaVerificacion;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.dominio.repositorio.AuditoriaVerificacionRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class LoginFailureHandlerTest {

    private final UsuarioRepository usuarios = mock(UsuarioRepository.class);
    private final AuditoriaVerificacionRepository auditoria = mock(AuditoriaVerificacionRepository.class);
    private final BCryptPasswordEncoder codificador = new BCryptPasswordEncoder();
    private LoginFailureHandler handler;

    @BeforeEach
    void preparar() {
        handler = new LoginFailureHandler(usuarios, auditoria, codificador);
    }

    private Conductor conductor(EstadoValidacion estado) {
        Conductor c = Conductor.builder().email("ana@x.com").password(codificador.encode("Clave123")).build();
        c.setEstadoValidacion(estado);
        return c;
    }

    private MockHttpServletResponse intentar(String clave, Exception e) throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest();
        req.setParameter("username", "ana@x.com");
        req.setParameter("password", clave);
        MockHttpServletResponse res = new MockHttpServletResponse();
        handler.onAuthenticationFailure(req, res, e instanceof DisabledException d ? d : new BadCredentialsException("x"));
        return res;
    }

    @Test
    void conductorPendienteConClaveCorrectaVeSuEstado() throws Exception {
        when(usuarios.findByEmail("ana@x.com")).thenReturn(Optional.of(conductor(EstadoValidacion.PENDIENTE)));

        assertEquals("/auth/login?cuenta=PENDIENTE", intentar("Clave123", new DisabledException("x")).getRedirectedUrl());
    }

    @Test
    void conductorRechazadoVeElMotivoDelAdministrador() throws Exception {
        when(usuarios.findByEmail("ana@x.com")).thenReturn(Optional.of(conductor(EstadoValidacion.RECHAZADO)));
        AuditoriaVerificacion rechazo = AuditoriaVerificacion.builder()
                .accion(AuditoriaVerificacion.Accion.RECHAZADO).motivo("documentos ilegibles").build();
        when(auditoria.findTop20ByConductorEmailOrderByFechaDesc("ana@x.com")).thenReturn(List.of(rechazo));

        var cuenta = handler.estadoSiCredencialesValidas("ana@x.com", "Clave123").orElseThrow();

        assertEquals("RECHAZADO", cuenta.estado());
        assertEquals("documentos ilegibles", cuenta.motivo());
    }

    @Test
    void conClaveIncorrectaNoSeRevelaElEstado() throws Exception {
        when(usuarios.findByEmail("ana@x.com")).thenReturn(Optional.of(conductor(EstadoValidacion.PENDIENTE)));

        assertEquals("/auth/login?error=true", intentar("otra", new DisabledException("x")).getRedirectedUrl());
    }

    @Test
    void unFalloComunSigueSiendoElMensajeGenerico() throws Exception {
        assertEquals("/auth/login?error=true", intentar("Clave123", new BadCredentialsException("x")).getRedirectedUrl());
        verifyNoInteractions(usuarios);
    }

    @Test
    void conductorEnRevisionVeLoQueFaltaYElPlazo() throws Exception {
        Conductor c = conductor(EstadoValidacion.EN_REVISION);
        c.setRevisionMensaje("Foto del SOAT más clara");
        c.setRevisionPlazo(java.time.LocalDate.of(2026, 11, 12));
        when(usuarios.findByEmail("ana@x.com")).thenReturn(Optional.of(c));

        var cuenta = handler.estadoSiCredencialesValidas("ana@x.com", "Clave123").orElseThrow();

        assertEquals("EN_REVISION", cuenta.estado());
        assertEquals("Foto del SOAT más clara", cuenta.motivo());
        assertEquals(java.time.LocalDate.of(2026, 11, 12), cuenta.plazo());
    }
}
