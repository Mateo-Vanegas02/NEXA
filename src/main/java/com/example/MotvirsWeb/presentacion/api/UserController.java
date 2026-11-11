package com.example.MotvirsWeb.presentacion.api;

import com.example.MotvirsWeb.infraestructura.seguridad.CustomUserDetails;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class UserController {

    @GetMapping("/api/user-id")
    public Map<String, String> getUserId(Authentication authentication) {
        String userId = "";
        if (authentication != null && authentication.getPrincipal() instanceof CustomUserDetails details) {
            userId = details.getId(); // Obtiene el userId como String
        }
        return Map.of("userId", userId);
    }
}