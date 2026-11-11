package com.example.MotvirsWeb.presentacion.dto;

import com.example.MotvirsWeb.dominio.regla.PoliticaPassword;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Registro de un pasajero desde la app móvil (JSON). Las mismas reglas que el formulario web. */
public record RegistroPasajeroRequest(
        @NotBlank(message = "El nombre es obligatorio")
        @Size(min = 3, max = 120, message = "El nombre debe tener entre 3 y 120 caracteres")
        @Pattern(regexp = "^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\\s]+$", message = "El nombre solo puede contener letras y espacios") String nombre,
        @NotBlank(message = "El email es obligatorio")
        @Email(message = "Formato de email inválido")
        @Size(max = 100, message = "El email no puede exceder 100 caracteres") String email,
        @NotBlank(message = "El teléfono es obligatorio")
        @Pattern(regexp = "^\\d{7,15}$", message = "El teléfono debe tener entre 7 y 15 dígitos") String telefono,
        @NotBlank(message = "La contraseña es obligatoria") String password) {

    @AssertTrue(message = PoliticaPassword.MENSAJE)
    public boolean isPasswordValida() {
        return password == null || password.isBlank() || PoliticaPassword.esValida(password);
    }
}
