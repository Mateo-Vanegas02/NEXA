package com.example.MotvirsWeb.infraestructura.seguridad;

import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Usuario;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

/**
 * No se puede cerrar sesión con un servicio activo: el pasajero con una solicitud esperando conductor
 * o con un viaje aceptado/en curso, y el conductor con un viaje aceptado (yendo a recoger) o en curso.
 * Primero hay que cancelar (o terminar) el servicio; si no, quedaría a medias para la otra persona.
 * El panel ya lo avisa en pantalla; esto lo garantiza también en el servidor.
 */
@Component
@RequiredArgsConstructor
public class BloqueoCierreSesionFilter extends OncePerRequestFilter {

    static final String RUTA_CIERRE = "/auth/logout";
    static final String MENSAJE_SOLICITUD = "Tienes una solicitud esperando conductor. Cancélala antes de cerrar sesión.";
    static final String MENSAJE_VIAJE = "Tienes un servicio en marcha. Cancela el viaje (o termínalo) antes de cerrar sesión.";
    private static final List<EstadoServicio> EN_MARCHA = List.of(EstadoServicio.ACEPTADO, EstadoServicio.EN_CURSO);

    private final UsuarioRepository usuarioRepository;
    private final ServicioRepository servicioRepository;

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !HttpMethod.POST.matches(request.getMethod())
                || !RUTA_CIERRE.equals(request.getRequestURI().substring(request.getContextPath().length()));
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        Bloqueo bloqueo = bloqueoDelUsuario();
        if (bloqueo != null) {
            String contexto = request.getContextPath();
            String aceptaJson = request.getHeader("Accept");
            if (aceptaJson != null && aceptaJson.contains("application/json")) {
                response.setStatus(HttpServletResponse.SC_CONFLICT);
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"error\":\"" + bloqueo.mensaje() + "\"}");
            } else {
                response.sendRedirect(contexto + bloqueo.panel() + "?cierreBloqueado=" + bloqueo.motivo());
            }
            return;
        }
        chain.doFilter(request, response);
    }

    private record Bloqueo(String panel, String motivo, String mensaje) { }

    private Bloqueo bloqueoDelUsuario() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || auth instanceof AnonymousAuthenticationToken) {
            return null;
        }
        Usuario u = auth.getPrincipal() instanceof CustomUserDetails detalles
                ? usuarioRepository.findById(detalles.getId()).orElse(null)
                : usuarioRepository.findByEmail(auth.getName()).orElse(null);
        if (u instanceof Pasajero) {
            if (servicioRepository.existsByPasajeroIdAndEstado(u.getId(), EstadoServicio.SOLICITADO)) {
                return new Bloqueo("/pasajero/panel", "true", MENSAJE_SOLICITUD);
            }
            if (servicioRepository.existsByPasajeroIdAndEstadoIn(u.getId(), EN_MARCHA)) {
                return new Bloqueo("/pasajero/panel", "viaje", MENSAJE_VIAJE);
            }
        } else if (u instanceof Conductor
                && servicioRepository.existsByConductorIdAndEstadoIn(u.getId(), EN_MARCHA)) {
            return new Bloqueo("/conductor/panel", "viaje", MENSAJE_VIAJE);
        }
        return null;
    }
}
