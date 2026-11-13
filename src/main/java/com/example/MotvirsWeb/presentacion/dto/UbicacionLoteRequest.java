package com.example.MotvirsWeb.presentacion.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.util.List;

/** Posiciones que el teléfono guardó sin señal, cada una con la hora en que se tomó. */
public record UbicacionLoteRequest(@NotEmpty(message = "Faltan las posiciones") List<@Valid Punto> puntos) {

    public record Punto(
            @NotNull(message = "Falta la latitud") @DecimalMin(value = "-90", message = "Latitud inválida")
            @DecimalMax(value = "90", message = "Latitud inválida") Double latitud,
            @NotNull(message = "Falta la longitud") @DecimalMin(value = "-180", message = "Longitud inválida")
            @DecimalMax(value = "180", message = "Longitud inválida") Double longitud,
            @NotNull(message = "Falta la hora de la posición") Instant ocurridoEn) {
    }
}
