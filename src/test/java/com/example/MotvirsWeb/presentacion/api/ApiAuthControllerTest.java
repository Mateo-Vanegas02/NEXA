package com.example.MotvirsWeb.presentacion.api;

import com.example.MotvirsWeb.aplicacion.puerto.EmisorTokens;
import com.example.MotvirsWeb.infraestructura.seguridad.LoginFailureHandler;
import com.example.MotvirsWeb.presentacion.dto.LoginRequest;
import com.example.MotvirsWeb.presentacion.dto.LoginResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/** Login JWT de la app móvil: pasajeros, conductores aprobados y administradores. Sin Mongo ni contexto de Spring. */
class ApiAuthControllerTest {

    private final AuthenticationManager autenticador = mock(AuthenticationManager.class);
    private final EmisorTokens emisor = mock(EmisorTokens.class);
    private final LoginFailureHandler fallos = mock(LoginFailureHandler.class);
    private ApiAuthController controlador;

    @BeforeEach
    void preparar() {
        controlador = new ApiAuthController(autenticador, emisor, fallos);
    }

    private static LoginRequest credenciales() {
        LoginRequest r = new LoginRequest();
        r.setEmail("ana@x.com");
        r.setPassword("Clave123");
        return r;
    }

    private void autenticaComo(String rol) {
        User usuario = new User("ana@x.com", "x", List.of(new SimpleGrantedAuthority(rol)));
        when(autenticador.authenticate(any()))
                .thenReturn(new UsernamePasswordAuthenticationToken(usuario, null, usuario.getAuthorities()));
        when(emisor.generateToken(usuario)).thenReturn("jwt-de-prueba");
    }

    @Test
    void pasajeroRecibeToken() {
        autenticaComo("ROLE_PASAJERO");

        ResponseEntity<?> res = controlador.login(credenciales());

        assertEquals(200, res.getStatusCode().value());
        assertEquals("jwt-de-prueba", ((LoginResponse) res.getBody()).getToken());
    }

    @Test
    void conductorAprobadoRecibeToken() {
        autenticaComo("ROLE_CONDUCTOR");

        ResponseEntity<?> res = controlador.login(credenciales());

        assertEquals(200, res.getStatusCode().value());
        assertEquals("jwt-de-prueba", ((LoginResponse) res.getBody()).getToken());
    }

    @Test
    void administradorRecibeToken() {
        autenticaComo("ROLE_ADMIN");

        ResponseEntity<?> res = controlador.login(credenciales());

        assertEquals(200, res.getStatusCode().value());
    }

    @Test
    void otroRolNoUsaLaApp() {
        autenticaComo("ROLE_OTRO");

        ResponseEntity<?> res = controlador.login(credenciales());

        assertEquals(403, res.getStatusCode().value());
        verify(emisor, never()).generateToken(any());
    }

    @Test
    @SuppressWarnings("unchecked")
    void conductorPendienteConClaveCorrectaVeSuEstado() {
        when(autenticador.authenticate(any())).thenThrow(new DisabledException("no aprobada"));
        when(fallos.estadoSiCredencialesValidas("ana@x.com", "Clave123")).thenReturn(Optional.of(
                new LoginFailureHandler.EstadoCuenta("RECHAZADO", "documentos ilegibles", LocalDate.of(2026, 11, 1))));

        ResponseEntity<?> res = controlador.login(credenciales());

        assertEquals(403, res.getStatusCode().value());
        Map<String, Object> cuerpo = (Map<String, Object>) res.getBody();
        assertEquals("RECHAZADO", cuerpo.get("estadoValidacion"));
        assertEquals("documentos ilegibles", cuerpo.get("motivo"));
        assertEquals("2026-11-01", cuerpo.get("plazoRevision"));
        verify(emisor, never()).generateToken(any());
    }

    @Test
    @SuppressWarnings("unchecked")
    void conductorPendienteSinMotivoNoLoIncluye() {
        when(autenticador.authenticate(any())).thenThrow(new DisabledException("no aprobada"));
        when(fallos.estadoSiCredencialesValidas(any(), any()))
                .thenReturn(Optional.of(new LoginFailureHandler.EstadoCuenta("PENDIENTE", null, null)));

        Map<String, Object> cuerpo = (Map<String, Object>) controlador.login(credenciales()).getBody();

        assertEquals("PENDIENTE", cuerpo.get("estadoValidacion"));
        assertFalse(cuerpo.containsKey("motivo"));
        assertFalse(cuerpo.containsKey("plazoRevision"));
    }

    @Test
    void cuentaSinAprobarConClaveIncorrectaNoRevelaNada() {
        when(autenticador.authenticate(any())).thenThrow(new DisabledException("no aprobada"));
        when(fallos.estadoSiCredencialesValidas(any(), any())).thenReturn(Optional.empty());

        // Se trata como credenciales inválidas (401 por el entry point de Spring Security)
        assertThrows(BadCredentialsException.class, () -> controlador.login(credenciales()));
    }
}
