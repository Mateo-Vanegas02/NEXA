package com.example.MotvirsWeb.presentacion.dto;

import java.time.LocalDateTime;

/** Perfil visible del usuario autenticado (pasajero o conductor). */
public record PerfilDto(
        String id,
        String rol,
        String nombre,
        String email,
        String telefono,
        /** Solo conductor: número de licencia validado por el administrador. */
        Long licencia,
        String estadoValidacion,
        LocalDateTime miembroDesde,
        boolean tieneFoto,
        /** Ruta de la foto con un parámetro de versión para que el navegador la renueve al cambiarla; null si no tiene. */
        String fotoUrl) {
}
