package com.example.MotvirsWeb.presentacion.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;

/** Posición que reporta el conductor en línea. {@code disponible} es false mientras está en un viaje. */
public record UbicacionConductorRequest(
        @NotNull(message = "Falta la latitud") @DecimalMin(value = "-90", message = "Latitud inválida")
        @DecimalMax(value = "90", message = "Latitud inválida") Double latitud,
        @NotNull(message = "Falta la longitud") @DecimalMin(value = "-180", message = "Longitud inválida")
        @DecimalMax(value = "180", message = "Longitud inválida") Double longitud,
        Boolean disponible) {

    public boolean estaDisponible() {
        return disponible == null || disponible;
    }
}
