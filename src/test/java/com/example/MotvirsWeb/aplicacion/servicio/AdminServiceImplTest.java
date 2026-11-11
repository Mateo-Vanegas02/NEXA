package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.example.MotvirsWeb.infraestructura.socket.WebSocketService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.dominio.modelo.Rol;

@ExtendWith(MockitoExtension.class)
public class AdminServiceImplTest {

    @Mock
    private UsuarioRepository usuarioRepository;
    @Mock
    private WebSocketService webSocketService;

    @InjectMocks
    private AdminServiceImpl adminService;

    private Conductor testConductor;

    @BeforeEach
    void setUp() {
        testConductor = Conductor.builder()
                .email("conductor@test.com")
                .nombre_y_Apellido("Test Conductor")
                .rol(Rol.CONDUCTOR)
                .estadoValidacion(EstadoValidacion.PENDIENTE)
                .build();
    }

    @Test
    void aprobarConductor_Success() {
        when(usuarioRepository.findConductorByEmail("conductor@test.com")).thenReturn(Optional.of(testConductor));

        adminService.aprobarConductor("conductor@test.com");

        assertEquals(EstadoValidacion.APROBADO, testConductor.getEstadoValidacion());
        verify(usuarioRepository).save(testConductor);
        verify(webSocketService).notificarNuevoRegistroAdmin(testConductor);
    }

    @Test
    void aprobarConductor_NotPending_ThrowsException() {
        testConductor.setEstadoValidacion(EstadoValidacion.APROBADO);
        when(usuarioRepository.findConductorByEmail("conductor@test.com")).thenReturn(Optional.of(testConductor));

        assertThrows(RuntimeException.class, () -> adminService.aprobarConductor("conductor@test.com"));
        verify(usuarioRepository, never()).save(any());
    }

    @Test
    void rechazarConductor_Success() {
        when(usuarioRepository.findConductorByEmail("conductor@test.com")).thenReturn(Optional.of(testConductor));

        adminService.rechazarConductor("conductor@test.com");

        assertEquals(EstadoValidacion.RECHAZADO, testConductor.getEstadoValidacion());
        verify(usuarioRepository).save(testConductor);
    }
}
