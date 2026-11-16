package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.example.MotvirsWeb.infraestructura.seguridad.CustomUserDetailsService;
import com.example.MotvirsWeb.infraestructura.socket.WebSocketService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Rol;

@SuppressWarnings("null")
@ExtendWith(MockitoExtension.class)
public class AuthServiceTest {

    @Mock
    private UsuarioRepository usuarioRepository;
    @Mock
    private PasswordEncoder passwordEncoder;
    @Mock
    private CustomUserDetailsService customUserDetailsService;
    @Mock
    private WebSocketService webSocketService;

    @InjectMocks
    private AuthService authService;

    private Pasajero testPasajero;
    private Conductor testConductor;

    @BeforeEach
    void setUp() {
        testPasajero = Pasajero.builder()
                .email("pasajero@test.com")
                .password("encoded_pass")
                .rol(Rol.PASAJERO)
                .estadoValidacion(EstadoValidacion.APROBADO)
                .build();

        testConductor = Conductor.builder()
                .email("conductor@test.com")
                .password("encoded_pass")
                .rol(Rol.CONDUCTOR)
                .estadoValidacion(EstadoValidacion.PENDIENTE)
                .build();
    }

    @Test
    void registrarPasajero_Success() {
        when(usuarioRepository.findByEmailAndRol(anyString(), eq(Rol.PASAJERO))).thenReturn(Optional.empty());
        when(passwordEncoder.encode(anyString())).thenReturn("encoded_pass");
        when(usuarioRepository.save(any(Pasajero.class))).thenReturn(testPasajero);

        Pasajero result = authService.registrarPasajero("Test Name", "pasajero@test.com", "123456", "password");

        assertNotNull(result);
        assertEquals("pasajero@test.com", result.getEmail());
        verify(usuarioRepository).save(any(Pasajero.class));
        verify(webSocketService).notificarNuevoRegistroAdmin(any());
    }

    @Test
    void registrarPasajero_DuplicateEmail_ThrowsException() {
        when(usuarioRepository.findByEmailAndRol("pasajero@test.com", Rol.PASAJERO))
                .thenReturn(Optional.of(testPasajero));

        assertThrows(IllegalStateException.class,
                () -> authService.registrarPasajero("Test Name", "pasajero@test.com", "123456", "password"));
    }

    @Test
    void registrarConductorUsaConsultasSelectivas() {
        when(usuarioRepository.findByEmailAndRol("conductor@test.com", Rol.CONDUCTOR)).thenReturn(Optional.empty());
        when(passwordEncoder.encode("password")).thenReturn("encoded_pass");
        when(usuarioRepository.save(any(Conductor.class))).thenAnswer(inv -> inv.getArgument(0));

        Conductor result = authService.registrarConductor("Test", "conductor@test.com", "password",
                "3001234567", 12345L, 67890L, 111L);

        assertEquals(12345L, result.getLicencia());
        verify(usuarioRepository).existsByRolAndLicencia(Rol.CONDUCTOR, 12345L);
        verify(usuarioRepository).existsByRolAndSoat(Rol.CONDUCTOR, 67890L);
        verify(usuarioRepository, never()).findByRol(Rol.CONDUCTOR);
    }

    @Test
    void registrarConductorRechazaLicenciaRepetidaAntesDeGuardar() {
        when(usuarioRepository.findByEmailAndRol("conductor@test.com", Rol.CONDUCTOR)).thenReturn(Optional.empty());
        when(usuarioRepository.existsByRolAndLicencia(Rol.CONDUCTOR, 12345L)).thenReturn(true);

        assertThrows(IllegalStateException.class, () -> authService.registrarConductor("Test",
                "conductor@test.com", "password", "3001234567", 12345L, 67890L, 111L));
        verify(usuarioRepository, never()).save(any());
    }

    @Test
    void autenticarUsuario_Success() {
        UserDetails mockDetails = mock(UserDetails.class);
        when(mockDetails.getPassword()).thenReturn("encoded_pass");
        when(customUserDetailsService.loadUserByUsername("pasajero@test.com")).thenReturn(mockDetails);
        when(passwordEncoder.matches("password", "encoded_pass")).thenReturn(true);
        when(usuarioRepository.findByEmail("pasajero@test.com")).thenReturn(Optional.of(testPasajero));

        UserDetails result = authService.autenticarUsuario("pasajero@test.com", "password");

        assertNotNull(result);
        verify(passwordEncoder).matches("password", "encoded_pass");
    }

    @Test
    void autenticarUsuario_BadCredentials_ThrowsException() {
        UserDetails mockDetails = mock(UserDetails.class);
        when(mockDetails.getPassword()).thenReturn("encoded_pass");
        when(customUserDetailsService.loadUserByUsername("pasajero@test.com")).thenReturn(mockDetails);
        when(passwordEncoder.matches("wrong_pass", "encoded_pass")).thenReturn(false);

        assertThrows(BadCredentialsException.class,
                () -> authService.autenticarUsuario("pasajero@test.com", "wrong_pass"));
    }

    @Test
    void autenticarUsuario_ConductorNotApproved_ThrowsException() {
        UserDetails mockDetails = mock(UserDetails.class);
        when(mockDetails.getPassword()).thenReturn("encoded_pass");
        when(customUserDetailsService.loadUserByUsername("conductor@test.com")).thenReturn(mockDetails);
        when(passwordEncoder.matches("password", "encoded_pass")).thenReturn(true);
        when(usuarioRepository.findByEmail("conductor@test.com")).thenReturn(Optional.of(testConductor));

        assertThrows(DisabledException.class, () -> authService.autenticarUsuario("conductor@test.com", "password"));
    }
}
