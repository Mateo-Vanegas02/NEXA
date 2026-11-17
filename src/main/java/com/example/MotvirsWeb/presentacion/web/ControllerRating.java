package com.example.MotvirsWeb.presentacion.web;

import com.example.MotvirsWeb.aplicacion.servicio.ServicioService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.dominio.modelo.Servicio;

import com.example.MotvirsWeb.dominio.regla.FactoresCalificacion;

import java.util.List;

/**
 * Controller HTTP para calificaciones post-viaje.
 *
 * Responsabilidad única: presentar la pantalla de rating y procesar el
 * formulario.
 * La lógica de persistencia de calificaciones vive en {@link ServicioService}.
 */
@Controller
@RequestMapping("/rating")
@RequiredArgsConstructor
public class ControllerRating {

    private final ServicioService servicioService;
    private final ServicioRepository servicioRepository; // solo para cargar datos de vista

    @GetMapping
    @PreAuthorize("hasRole(#rol != null ? #rol.toUpperCase() : 'USER')")
    public String mostrarRating(@RequestParam("servicioId") String servicioId,
            @RequestParam(value = "rol", required = false) String rol,
            Model model, Authentication authentication) {

        Servicio servicio = servicioRepository.findById(servicioId)
                .orElseThrow(() -> new RuntimeException("Servicio no encontrado"));

        String usuarioId = idUsuario(authentication);
        if (usuarioId != null) {
            String duenoPasajero = servicio.getPasajero() != null && servicio.getPasajero().getId() != null
                    ? servicio.getPasajero().getId().toString() : null;
            String duenoConductor = servicio.getConductor() != null && servicio.getConductor().getId() != null
                    ? servicio.getConductor().getId().toString() : null;
            boolean esParticipante = usuarioId.equals(duenoPasajero) || usuarioId.equals(duenoConductor);
            if (!esParticipante && (duenoPasajero != null || duenoConductor != null)) {
                throw new org.springframework.security.access.AccessDeniedException("Servicio ajeno");
            }
        }
        model.addAttribute("servicioId", servicioId);
        model.addAttribute("rol", rol);

        String nombreOtro = "";
        if ("conductor".equals(rol) && servicio.getPasajero() != null) {
            nombreOtro = servicio.getPasajero().getNombre();
        } else if ("pasajero".equals(rol) && servicio.getConductor() != null) {
            nombreOtro = servicio.getConductor().getNombre();
        }
        model.addAttribute("nombreOtro", nombreOtro);
        // Factores para marcar (los del modelo de satisfacción) y a dónde vuelve con «Ahora no».
        model.addAttribute("factores", "pasajero".equals(rol) || "conductor".equals(rol)
                ? FactoresCalificacion.catalogo(rol) : List.of());
        model.addAttribute("notaSatisfecho", FactoresCalificacion.NOTA_SATISFECHO);
        model.addAttribute("urlPanel", "conductor".equals(rol) ? "/conductor/panel" : "/pasajero/panel");

        return "rating";
    }

    @PostMapping("/calificar")
    @PreAuthorize("hasRole(#rol != null ? #rol.toUpperCase() : 'USER')")
    public String calificarServicio(
            @RequestParam String servicioId,
            @RequestParam Double calificacion,
            @RequestParam(required = false) String comentarios,
            @RequestParam(required = false) List<String> factores,
            @RequestParam String rol,
            Authentication authentication) {

        // El rol sale de Spring Security, no del formulario: el parámetro solo se acepta si coincide.
        String rolReal = rolAutenticado(authentication);
        if (!rolReal.equals(rol)) {
            throw new org.springframework.security.access.AccessDeniedException(
                    "Rol no autorizado para esta calificación");
        }

        servicioService.calificarServicio(servicioId, rolReal, calificacion, comentarios, factores,
                idUsuario(authentication));

        return "pasajero".equals(rolReal)
                ? "redirect:/pasajero/panel"
                : "redirect:/conductor/panel";
    }

    /** "pasajero" o "conductor" según la autoridad autenticada; cualquier otro caso se rechaza. */
    static String rolAutenticado(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new org.springframework.security.access.AccessDeniedException("Inicia sesión para calificar");
        }
        boolean pasajero = authentication.getAuthorities().stream().anyMatch(a -> "ROLE_PASAJERO".equals(a.getAuthority()));
        boolean conductor = authentication.getAuthorities().stream().anyMatch(a -> "ROLE_CONDUCTOR".equals(a.getAuthority()));
        if (pasajero == conductor) {
            throw new org.springframework.security.access.AccessDeniedException("Rol no autorizado para esta calificación");
        }
        return pasajero ? "pasajero" : "conductor";
    }

    private static String idUsuario(Authentication authentication) {
        return authentication != null
                && authentication.getPrincipal() instanceof com.example.MotvirsWeb.infraestructura.seguridad.CustomUserDetails d
                        ? d.getId()
                        : null;
    }
}
