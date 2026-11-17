package com.example.MotvirsWeb.dominio.repositorio;

import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.dominio.modelo.Rol;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.*;

class UsuarioRepositoryConteoTest {
    @Test
    void cuentaEnMongoSinCargarConductores() {
        UsuarioRepository repo = mock(UsuarioRepository.class, CALLS_REAL_METHODS);
        when(repo.countByRolAndEstadoValidacionIn(Rol.CONDUCTOR,
                List.of(EstadoValidacion.PENDIENTE, EstadoValidacion.APROBADO))).thenReturn(7L);

        assertEquals(7, repo.countConductoresByEstados(EstadoValidacion.PENDIENTE, EstadoValidacion.APROBADO));
        verify(repo, never()).findByRol(Rol.CONDUCTOR);
    }

    @Test
    void listaVaciaDevuelveCeroSinConsultarMongo() {
        UsuarioRepository repo = mock(UsuarioRepository.class, CALLS_REAL_METHODS);
        assertEquals(0, repo.countConductoresByEstados());
        verify(repo, never()).countByRolAndEstadoValidacionIn(any(), any());
    }

    @Test
    void unEstadoSinResultadosDevuelveCero() {
        UsuarioRepository repo = mock(UsuarioRepository.class, CALLS_REAL_METHODS);
        assertEquals(0, repo.countConductoresByEstados(EstadoValidacion.RECHAZADO));
        verify(repo).countByRolAndEstadoValidacionIn(Rol.CONDUCTOR, List.of(EstadoValidacion.RECHAZADO));
    }
}
