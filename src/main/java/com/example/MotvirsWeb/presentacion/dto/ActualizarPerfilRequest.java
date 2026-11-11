package com.example.MotvirsWeb.presentacion.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Datos del perfil que el usuario puede cambiar; el correo y la licencia no se editan desde aquí. */
public record ActualizarPerfilRequest(
        @NotBlank(message = "El nombre es obligatorio")
        @Size(min = 3, max = 100, message = "El nombre debe tener entre 3 y 100 caracteres")
        @Pattern(regexp = "^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\\s]+$", message = "El nombre solo puede contener letras y espacios")
        String nombre,

        @NotBlank(message = "El teléfono es obligatorio")
        @Pattern(regexp = "^3\\d{9}$", message = "El teléfono debe ser un número colombiano válido de 10 dígitos que empiece con 3 (ej: 3001234567)")
        String telefono) {
}
