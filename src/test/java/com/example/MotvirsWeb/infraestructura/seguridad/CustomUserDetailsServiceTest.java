package com.example.MotvirsWeb.infraestructura.seguridad;

import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.Rol;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import org.junit.jupiter.api.Test;
import org.springframework.dao.IncorrectResultSizeDataAccessException;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class CustomUserDetailsServiceTest {
    @Test
    void correoUnicoSeAutentica() {
        UsuarioRepository repo = mock(UsuarioRepository.class);
        when(repo.findByEmail("unico@example.com")).thenReturn(Optional.of(Pasajero.builder()
                .email("unico@example.com").password("hash").rol(Rol.PASAJERO)
                .estadoValidacion(EstadoValidacion.APROBADO).build()));
        assertEquals("unico@example.com", new CustomUserDetailsService(repo)
                .loadUserByUsername("unico@example.com").getUsername());
    }

    @Test
    void correoCompartidoFallaCerradoParaLoginWebYMovil() {
        UsuarioRepository repo = mock(UsuarioRepository.class);
        when(repo.findByEmail("compartido@example.com"))
                .thenThrow(new IncorrectResultSizeDataAccessException(1, 2));
        assertThrows(UsernameNotFoundException.class,
                () -> new CustomUserDetailsService(repo).loadUserByUsername("compartido@example.com"));
        verify(repo, times(1)).findByEmail("compartido@example.com");
    }

    @Test
    void correoConMayusculasEspaciosYAmbosSeNormaliza() {
        UsuarioRepository repo = mock(UsuarioRepository.class);
        when(repo.findByEmail("unico@example.com")).thenReturn(Optional.of(Pasajero.builder()
                .email("unico@example.com").password("hash").rol(Rol.PASAJERO)
                .estadoValidacion(EstadoValidacion.APROBADO).build()));
        CustomUserDetailsService servicio = new CustomUserDetailsService(repo);
        for (String correo : new String[]{"UNICO@EXAMPLE.COM", " unico@example.com ", " UNICO@EXAMPLE.COM "}) {
            assertEquals("unico@example.com", servicio.loadUserByUsername(correo).getUsername());
        }
        verify(repo, times(3)).findByEmail("unico@example.com");
    }

    @Test
    void correoCompartidoSeleccionaRolDeFormaExplicita() {
        UsuarioRepository repo = mock(UsuarioRepository.class);
        when(repo.findByEmailAndRol("compartido@example.com", Rol.PASAJERO))
                .thenReturn(Optional.of(Pasajero.builder().email("compartido@example.com")
                        .password("hash-p").rol(Rol.PASAJERO)
                        .estadoValidacion(EstadoValidacion.APROBADO).build()));
        when(repo.findByEmailAndRol("compartido@example.com", Rol.CONDUCTOR))
                .thenReturn(Optional.of(Conductor.builder().email("compartido@example.com")
                        .password("hash-c").rol(Rol.CONDUCTOR)
                        .estadoValidacion(EstadoValidacion.APROBADO).build()));
        CustomUserDetailsService servicio = new CustomUserDetailsService(repo);
        assertEquals("hash-p", servicio.loadUserByUsername(" COMPARTIDO@EXAMPLE.COM |PASAJERO").getPassword());
        assertEquals("hash-c", servicio.loadUserByUsername("compartido@example.com|CONDUCTOR").getPassword());
        verify(repo, never()).findByEmail(anyString());
    }
}
