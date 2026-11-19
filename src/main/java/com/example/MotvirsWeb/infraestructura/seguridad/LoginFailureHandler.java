package com.example.MotvirsWeb.infraestructura.seguridad;

import com.example.MotvirsWeb.dominio.modelo.AuditoriaVerificacion;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.dominio.repositorio.AuditoriaVerificacionRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.example.MotvirsWeb.dominio.regla.Correo;
import com.example.MotvirsWeb.dominio.modelo.Rol;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.authentication.AuthenticationFailureHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.Optional;

/**
 * Fallo de inicio de sesión. Un conductor cuya cuenta aún no está aprobada recibe un mensaje
 * propio (pendiente / rechazado, con el motivo), pero SOLO si su contraseña es correcta: así no
 * se revela a un tercero qué correos son de conductores ni en qué estado están.
 */
@Component
@RequiredArgsConstructor
public class LoginFailureHandler implements AuthenticationFailureHandler {

    /** Atributo de sesión que lee {@code AuthController.mostrarLogin} (una sola vez). */
    public static final String ATRIBUTO_CUENTA = "nexa.cuentaConductor";

    /** Estado de la cuenta que se le muestra al conductor en el login. */
    public record EstadoCuenta(String estado, String motivo, java.time.LocalDate plazo) {
    }

    private final UsuarioRepository usuarioRepository;
    private final AuditoriaVerificacionRepository auditoriaRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void onAuthenticationFailure(HttpServletRequest request, HttpServletResponse response,
            AuthenticationException exception) throws IOException {
        if (exception instanceof DisabledException) {
            Optional<EstadoCuenta> cuenta = estadoSiCredencialesValidas(
                    request.getParameter("username"), request.getParameter("password"));
            if (cuenta.isPresent()) {
                request.getSession().setAttribute(ATRIBUTO_CUENTA, cuenta.get());
                response.sendRedirect(request.getContextPath() + "/auth/login?cuenta=" + cuenta.get().estado());
                return;
            }
        }
        response.sendRedirect(request.getContextPath() + "/auth/login?error=true");
    }

    public Optional<EstadoCuenta> estadoSiCredencialesValidas(String email, String password) {
        if (email == null || password == null) {
            return Optional.empty();
        }
        int separador = email.lastIndexOf('|');
        Rol rol;
        try {
            rol = separador < 0 ? null : Rol.valueOf(email.substring(separador + 1));
        } catch (IllegalArgumentException e) {
            return Optional.empty();
        }
        String correo = Correo.normalizar(separador < 0 ? email : email.substring(0, separador));
        return (rol == null ? usuarioRepository.findByEmail(correo)
                : usuarioRepository.findByEmailAndRol(correo, rol))
                .filter(Conductor.class::isInstance).map(Conductor.class::cast)
                .filter(c -> c.getEstadoValidacion() != EstadoValidacion.APROBADO)
                .filter(c -> c.getPassword() != null && passwordEncoder.matches(password, c.getPassword()))
                .map(c -> new EstadoCuenta(c.getEstadoValidacion().name(), motivoDe(c), c.getRevisionPlazo()));
    }

    private String motivoDe(Conductor c) {
        if (c.getEstadoValidacion() == EstadoValidacion.EN_REVISION) {
            return c.getRevisionMensaje();
        }
        if (c.getEstadoValidacion() != EstadoValidacion.RECHAZADO) {
            return null;
        }
        return auditoriaRepository.findTop20ByConductorEmailOrderByFechaDesc(c.getEmail()).stream()
                .filter(a -> a.getAccion() == AuditoriaVerificacion.Accion.RECHAZADO)
                .map(AuditoriaVerificacion::getMotivo).findFirst().orElse(null);
    }
}
