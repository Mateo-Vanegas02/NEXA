package com.example.MotvirsWeb.presentacion.web;

import com.example.MotvirsWeb.aplicacion.servicio.ServicioService;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.infraestructura.seguridad.CustomUserDetails;
import org.junit.jupiter.api.Test;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

/** POST /rating/calificar: el rol y el usuario salen de Spring Security, no del formulario. */
class ControllerRatingCalificarTest {

    private final ServicioService servicios = mock(ServicioService.class);
    private final ControllerRating controller = new ControllerRating(servicios, mock(ServicioRepository.class));

    private static Authentication autenticado(String id, String rol) {
        var autoridad = List.of(new SimpleGrantedAuthority("ROLE_" + rol));
        var usuario = new CustomUserDetails(id, id + "@example.test", "x", autoridad, true);
        return new UsernamePasswordAuthenticationToken(usuario, null, autoridad);
    }

    @Test
    void elPasajeroCalificaConSuIdYSuRolReal() {
        String destino = controller.calificarServicio("s1", 5.0, "bien", List.of(), "pasajero",
                autenticado("p1", "PASAJERO"));

        verify(servicios).calificarServicio("s1", "pasajero", 5.0, "bien", List.of(), "p1");
        assertEquals("redirect:/pasajero/panel", destino);
    }

    @Test
    void elConductorCalificaConSuIdYSuRolReal() {
        controller.calificarServicio("s1", 3.0, null, null, "conductor", autenticado("c1", "CONDUCTOR"));

        verify(servicios).calificarServicio("s1", "conductor", 3.0, null, null, "c1");
    }

    @Test
    void cambiarElRolPorParametroSeRechazaSinLlegarAlServicio() {
        assertThrows(AccessDeniedException.class, () -> controller.calificarServicio("s1", 1.0, "x", List.of(),
                "conductor", autenticado("p1", "PASAJERO")));
        assertThrows(AccessDeniedException.class, () -> controller.calificarServicio("s1", 1.0, "x", List.of(),
                "admin", autenticado("a1", "ADMIN")));

        verify(servicios, never()).calificarServicio(anyString(), anyString(), any(), any(), any(), any());
    }

    @Test
    void sinAutenticacionNoSeCalifica() {
        assertThrows(AccessDeniedException.class,
                () -> controller.calificarServicio("s1", 5.0, "x", List.of(), "pasajero", null));
        verify(servicios, never()).calificarServicio(anyString(), anyString(), any(), any(), any(), any());
    }
}
