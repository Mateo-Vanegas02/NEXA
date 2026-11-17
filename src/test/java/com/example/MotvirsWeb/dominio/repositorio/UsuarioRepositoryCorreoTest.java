package com.example.MotvirsWeb.dominio.repositorio;

import com.example.MotvirsWeb.dominio.modelo.Rol;
import org.junit.jupiter.api.Test;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.*;

class UsuarioRepositoryCorreoTest {
    @Test
    void normalizaTodasLasBusquedasPorCorreo() {
        UsuarioRepository repo = mock(UsuarioRepository.class, CALLS_REAL_METHODS);
        doReturn(Optional.empty()).when(repo).buscarCorreoExacto("a@example.com");
        doReturn(Optional.empty()).when(repo).buscarCorreoYRolExactos("a@example.com", Rol.PASAJERO);
        doReturn(false).when(repo).existeCorreoExacto("a@example.com");
        assertTrue(repo.findByEmail(" A@EXAMPLE.COM ").isEmpty());
        assertTrue(repo.findByEmailAndRol(" A@EXAMPLE.COM ", Rol.PASAJERO).isEmpty());
        repo.existsByEmail(" A@EXAMPLE.COM ");
        verify(repo).buscarCorreoExacto("a@example.com");
        verify(repo).buscarCorreoYRolExactos("a@example.com", Rol.PASAJERO);
        verify(repo).existeCorreoExacto("a@example.com");
    }
}
