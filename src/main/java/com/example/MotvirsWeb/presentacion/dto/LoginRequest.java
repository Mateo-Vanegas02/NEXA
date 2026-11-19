package com.example.MotvirsWeb.presentacion.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class LoginRequest {
    @NotBlank(message = "El email es obligatorio")
    @Size(max = 100, message = "El email no puede exceder 100 caracteres")
    private String email;

    @NotBlank(message = "La contraseña es obligatoria")
    @Size(max = 100, message = "La contraseña no puede exceder 100 caracteres")
    private String password;

    /** Opcional para correos de un solo rol; obligatorio si el correo pertenece a varios roles. */
    private com.example.MotvirsWeb.dominio.modelo.Rol rol;
}
