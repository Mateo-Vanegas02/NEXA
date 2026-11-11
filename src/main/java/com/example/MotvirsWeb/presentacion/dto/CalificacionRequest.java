package com.example.MotvirsWeb.presentacion.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * Cuerpo de {@code POST .../calificar-servicio/{id}}. Los comentarios se recortan a 500
 * caracteres en el servicio. {@code factores} son códigos de {@code FactoresCalificacion} (opcional).
 */
public record CalificacionRequest(
        @DecimalMin(value = "0.0", message = "La calificación debe estar entre 0 y 5")
        @DecimalMax(value = "5.0", message = "La calificación debe estar entre 0 y 5") Double calificacion,
        String comentarios,
        @Size(max = 20, message = "Demasiados factores") List<String> factores) {
}
