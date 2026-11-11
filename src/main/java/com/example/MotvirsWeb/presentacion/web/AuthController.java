package com.example.MotvirsWeb.presentacion.web;

import com.example.MotvirsWeb.infraestructura.seguridad.LoginFailureHandler;
import com.example.MotvirsWeb.presentacion.dto.ConductorRegistroRequest;
import com.example.MotvirsWeb.aplicacion.servicio.RegistroConductorService;
import com.example.MotvirsWeb.aplicacion.servicio.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import com.example.MotvirsWeb.dominio.regla.PoliticaPassword;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import org.springframework.web.servlet.support.RequestContextUtils;

import java.util.Map;

/**
 * Controller HTTP para autenticación y registro.
 *
 * Responsabilidad única: presentar formularios y coordinar el flujo de
 * respuesta
 * HTTP (redirects, flash messages). La lógica de negocio del registro vive en
 * {@link AuthService}.
 */
@Controller
@RequestMapping("/auth")
@RequiredArgsConstructor
@lombok.extern.slf4j.Slf4j
public class AuthController {

    private final AuthService authService;
    private final RegistroConductorService registroConductorService;

    @GetMapping("/registro")
    public String mostrarFormularioRegistro() {
        return "registros";
    }

    @GetMapping("/login")
    public String mostrarLogin(@RequestParam(required = false) String error,
            @RequestParam(required = false) String logout,
            @RequestParam(required = false) String cuenta,
            HttpServletRequest request,
            Model model) {

        if (error != null) {
            model.addAttribute("showError", true);
            model.addAttribute("errorMessage", "Email o contraseña incorrectos. Por favor, intente nuevamente.");
        }

        // Conductor con cuenta sin aprobar que acertó su contraseña (lo deja LoginFailureHandler en la sesión)
        var sesion = request.getSession(false);
        if (cuenta != null && sesion != null
                && sesion.getAttribute(LoginFailureHandler.ATRIBUTO_CUENTA) instanceof LoginFailureHandler.EstadoCuenta ec
                && ec.estado().equals(cuenta)) {
            model.addAttribute("estadoCuenta", ec.estado());
            model.addAttribute("motivoRechazo", ec.motivo());
            model.addAttribute("plazoRevision", ec.plazo() == null ? null
                    : ec.plazo().format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy")));
            sesion.removeAttribute(LoginFailureHandler.ATRIBUTO_CUENTA);
        }

        if (logout != null) {
            model.addAttribute("showSuccess", true);
            model.addAttribute("successMessage", "Has cerrado sesión correctamente");
        }

        Map<String, ?> flashMap = RequestContextUtils.getInputFlashMap(request);
        if (flashMap != null) {
            if (flashMap.containsKey("errorPasajero")) {
                model.addAttribute("showError", true);
                model.addAttribute("errorMessage", flashMap.get("errorPasajero"));
            }
            if (flashMap.containsKey("errorConductor")) {
                model.addAttribute("showError", true);
                model.addAttribute("errorMessage", flashMap.get("errorConductor"));
            }
            if (flashMap.containsKey("success")) {
                model.addAttribute("showSuccess", true);
                model.addAttribute("successMessage", flashMap.get("success"));
            }
        }

        return "inicio";
    }

    @PostMapping("/registro/pasajero")
    public String registrarPasajero(
            @RequestParam String nombre,
            @RequestParam String apellido,
            @RequestParam String email,
            @RequestParam String telefono,
            @RequestParam String password,
            @RequestParam String confirmPassword,
            RedirectAttributes redirectAttributes) {

        if (!password.equals(confirmPassword)) {
            redirectAttributes.addFlashAttribute("errorPasajero", "Las contraseñas no coinciden");
            return "redirect:/auth/registro";
        }
        if (!PoliticaPassword.esValida(password)) {
            redirectAttributes.addFlashAttribute("errorPasajero", PoliticaPassword.MENSAJE);
            return "redirect:/auth/registro";
        }
        String datos = validarDatosPasajero(nombre, apellido, email, telefono);
        if (datos != null) {
            redirectAttributes.addFlashAttribute("errorPasajero", datos);
            return "redirect:/auth/registro";
        }

        try {
            // Delegamos la creación y persistencia completa al servicio
            authService.registrarPasajero(nombre + " " + apellido, email, telefono, password);

            redirectAttributes.addFlashAttribute("success", "Registro exitoso. Por favor inicia sesión.");
            return "redirect:/auth/login";
        } catch (IllegalStateException e) {
            redirectAttributes.addFlashAttribute("errorPasajero", e.getMessage());
            return "redirect:/auth/registro";
        } catch (Exception e) {
            log.error("Error registrando pasajero", e);
            redirectAttributes.addFlashAttribute("errorPasajero", "No se pudo completar el registro. Intenta de nuevo.");
            return "redirect:/auth/registro";
        }
    }

    private static final java.util.regex.Pattern EMAIL = java.util.regex.Pattern
            .compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");

    private static String validarDatosPasajero(String nombre, String apellido, String email, String telefono) {
        if (nombre == null || nombre.isBlank() || nombre.length() > 60 || apellido == null || apellido.isBlank()
                || apellido.length() > 60) {
            return "Nombre y apellido son obligatorios (máximo 60 caracteres).";
        }
        if (email == null || email.length() > 100 || !EMAIL.matcher(email).matches()) {
            return "Formato de email inválido.";
        }
        if (telefono == null || !telefono.matches("^\\d{7,15}$")) {
            return "El teléfono debe tener entre 7 y 15 dígitos.";
        }
        return null;
    }

    @PostMapping("/registro/conductor")
    public String registrarConductor(
            @Valid @ModelAttribute ConductorRegistroRequest request,
            BindingResult bindingResult,
            RedirectAttributes redirectAttributes) {

        if (bindingResult.hasErrors()) {
            String mensajeError = bindingResult.getFieldErrors().stream()
                    .map(e -> e.getDefaultMessage())
                    .findFirst()
                    .orElse("Datos inválidos. Verifica todos los campos.");
            redirectAttributes.addFlashAttribute("errorConductor", mensajeError);
            return "redirect:/auth/registro#conductor";
        }

        try {
            registroConductorService.registrar(request.aSolicitud());

            redirectAttributes.addFlashAttribute("success",
                    "Registro recibido. Un administrador revisará tus documentos y podrás iniciar sesión cuando te aprueben.");
            return "redirect:/auth/login";
        } catch (Exception e) {
            boolean esperado = e instanceof IllegalStateException;
            if (!esperado) {
                log.error("Error registrando conductor", e);
            }
            redirectAttributes.addFlashAttribute("errorConductor",
                    esperado ? e.getMessage() : "No se pudo completar el registro. Verifica los datos e intenta de nuevo.");
            return "redirect:/auth/registro#conductor";
        }
    }

    /** Un archivo (o el conjunto) supera el límite de subida: se avisa en el formulario en vez de mostrar un error 500. */
    @ExceptionHandler(org.springframework.web.multipart.MaxUploadSizeExceededException.class)
    public String archivoMuyPesado(RedirectAttributes redirectAttributes) {
        redirectAttributes.addFlashAttribute("errorConductor", "Cada foto debe pesar máximo 5 MB.");
        return "redirect:/auth/registro#conductor";
    }
}
