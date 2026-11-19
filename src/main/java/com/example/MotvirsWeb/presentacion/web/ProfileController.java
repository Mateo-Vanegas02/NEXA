package com.example.MotvirsWeb.presentacion.web;

import com.example.MotvirsWeb.aplicacion.servicio.PasswordResetService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/profile") // Ruta base protegida
public class ProfileController {

    @Autowired
    private PasswordResetService passwordService;

    // Muestra el formulario reutilizando tu diseño
    @GetMapping("/change-password")
    public String showChangePasswordForm(Model model) {
        return "private/change-password";
    }

    @PostMapping("/change-password")
    public String processChangePassword(
            @RequestParam String currentPassword,
            @RequestParam String newPassword,
            @RequestParam String confirmPassword,
            Authentication authentication,
            RedirectAttributes redirectAttributes) {

        if (!com.example.MotvirsWeb.dominio.regla.PoliticaPassword.esValida(newPassword)) {
            redirectAttributes.addFlashAttribute("error", com.example.MotvirsWeb.dominio.regla.PoliticaPassword.MENSAJE);
            return "redirect:/profile/change-password";
        }
        // 1. Validación básica de coincidencia
        if (!newPassword.equals(confirmPassword)) {
            redirectAttributes.addFlashAttribute("error", "Las nuevas contraseñas no coinciden.");
            return "redirect:/profile/change-password";
        }

        try {
            if (authentication.getPrincipal() instanceof com.example.MotvirsWeb.infraestructura.seguridad.CustomUserDetails usuario) {
                passwordService.changePasswordCuenta(usuario.getId(), currentPassword, newPassword);
            } else {
                passwordService.changePassword(authentication.getName(), currentPassword, newPassword);
            }

            // 3. Mensaje de éxito
            redirectAttributes.addFlashAttribute("success", "¡Contraseña actualizada correctamente!");

            // 4. Redirección según Rol
            var authorities = authentication.getAuthorities();
            if (authorities.stream().anyMatch(a -> a.getAuthority().equals("ROLE_PASAJERO"))) {
                return "redirect:/pasajero/panel";
            } else if (authorities.stream().anyMatch(a -> a.getAuthority().equals("ROLE_CONDUCTOR"))) {
                return "redirect:/conductor/panel";
            } else if (authorities.stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"))) {
                return "redirect:/admin/dashboard";
            }
            return "redirect:/";

        } catch (org.springframework.security.authentication.BadCredentialsException | IllegalArgumentException e) {
            redirectAttributes.addFlashAttribute("error", e.getMessage());
            return "redirect:/profile/change-password";
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("error", "No se pudo actualizar la contraseña. Intenta de nuevo.");
            return "redirect:/profile/change-password";
        }
    }
}
