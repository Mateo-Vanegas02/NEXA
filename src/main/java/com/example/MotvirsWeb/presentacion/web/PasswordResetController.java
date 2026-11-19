package com.example.MotvirsWeb.presentacion.web;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo;
import com.example.MotvirsWeb.aplicacion.servicio.PasswordResetService;
import com.example.MotvirsWeb.dominio.modelo.Rol;
import com.example.MotvirsWeb.dominio.regla.Correo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.UUID;

@Controller
@RequestMapping("/auth")
public class PasswordResetController {

    @Autowired
    private PasswordResetService passwordResetService;

    @Autowired
    private NotificadorCorreo notificadorCorreo;

    @GetMapping("/forgot-password")
    public String showForgotPasswordForm(Model model) {
        return "auth/forgot-password";
    }

    // CORRECCIÓN DE DISEÑO: Cambiado de ResponseEntity a String (Redirect)
    @PostMapping("/forgot-password")
    public String processForgotPassword(@RequestParam String email,
            @RequestParam(required = false) Rol rol, RedirectAttributes redirectAttributes) {
        try {
            passwordResetService.initiatePasswordReset(Correo.normalizar(email), rol);
        } catch (Exception e) {
            // No revelar si el correo existe (enumeración de cuentas): mismo mensaje siempre.
            org.slf4j.LoggerFactory.getLogger(PasswordResetController.class)
                    .warn("Recuperación de contraseña no procesada: {}", e.getClass().getSimpleName());
        }
        redirectAttributes.addFlashAttribute("success",
                "Si el correo está registrado, recibirás un enlace para restablecer tu contraseña.");
        return "redirect:/auth/forgot-password";
    }

    @GetMapping("/reset-password")
    public String showResetPasswordForm(@RequestParam String token, Model model) {
        model.addAttribute("token", token);
        return "auth/reset-password";
    }

    // CORRECCIÓN DE DISEÑO: Manejo consistente de la vista
    @PostMapping("/reset-password")
    public String processResetPassword(
            @RequestParam String token,
            @RequestParam String newPassword,
            @RequestParam String confirmPassword, // Agregamos validación simple aquí también
            RedirectAttributes redirectAttributes) {

        if (!newPassword.equals(confirmPassword)) {
            redirectAttributes.addFlashAttribute("error", "Las contraseñas no coinciden.");
            redirectAttributes.addAttribute("token", token);
            return "redirect:/auth/reset-password";
        }
        if (!com.example.MotvirsWeb.dominio.regla.PoliticaPassword.esValida(newPassword)) {
            redirectAttributes.addFlashAttribute("error", com.example.MotvirsWeb.dominio.regla.PoliticaPassword.MENSAJE);
            redirectAttributes.addAttribute("token", token);
            return "redirect:/auth/reset-password";
        }

        try {
            passwordResetService.resetPassword(token, newPassword);
            redirectAttributes.addFlashAttribute("success", "Contraseña restablecida exitosamente. Ya puedes iniciar sesión.");
            return "redirect:/auth/login"; // Redirigir al login tras éxito
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("error", "El enlace no es válido o ha expirado.");
            redirectAttributes.addAttribute("token", token);
            return "redirect:/auth/reset-password";
        }
    }

    public void initiatePasswordReset(String email) {
        // 1. Verificar si el usuario existe...

        // 2. Generar y guardar el token...
        String token = UUID.randomUUID().toString();
        // guardarTokenEnBD(usuario, token);

        // 3. DELEGAR EL ENVÍO AL EMAIL SERVICE
        // Aquí es donde ocurre la magia. Pasamos el email del usuario y el token.
        notificadorCorreo.enviarCorreoRecuperacion(Correo.normalizar(email), token);
    }
}
