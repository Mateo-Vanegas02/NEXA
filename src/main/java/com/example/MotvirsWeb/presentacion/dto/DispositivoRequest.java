package com.example.MotvirsWeb.presentacion.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Token de FCM del teléfono. {@code plataforma} es ANDROID (por omisión) o IOS.
 * Al cerrar sesión se envía solo el token, para dejar de recibir avisos en ese teléfono.
 */
public record DispositivoRequest(
        @NotBlank @Size(max = 4096) String token,
        @Pattern(regexp = "ANDROID|IOS", message = "plataforma debe ser ANDROID o IOS") String plataforma) {
}
