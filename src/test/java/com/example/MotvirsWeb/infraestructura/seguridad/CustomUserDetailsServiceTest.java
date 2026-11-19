package com.example.MotvirsWeb.infraestructura.seguridad;

import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
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
}
