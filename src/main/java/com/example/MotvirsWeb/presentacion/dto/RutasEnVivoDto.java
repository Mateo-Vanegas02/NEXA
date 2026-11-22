package com.example.MotvirsWeb.presentacion.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.util.List;

/** DTOs de las rutas en vivo del conductor (recalcular cuando toma otra calle). */
public final class RutasEnVivoDto {

    private RutasEnVivoDto() {
    }

    /** Desde dónde recalcular: la posición actual del conductor. */
    public record Desde(
            @NotNull(message = "Falta la latitud") @DecimalMin(value = "-90", message = "Latitud inválida")
            @DecimalMax(value = "90", message = "Latitud inválida") Double latitud,
            @NotNull(message = "Falta la longitud") @DecimalMin(value = "-180", message = "Longitud inválida")
            @DecimalMax(value = "180", message = "Longitud inválida") Double longitud) {
    }

    /** La opción que eligió el conductor (índice de la última lista que recibió). */
    public record Eleccion(@NotNull(message = "Falta la ruta") @Min(0) @Max(5) Integer indice) {
    }

    /**
     * Una ruta posible.
     *
     * @param etiqueta {@code RAPIDA}, {@code CORTA} o {@code ALTERNATIVA}; la app la traduce
     */
    public record Opcion(int indice, String geometria, double distanciaKm, double duracionMin, String etiqueta,
                         List<com.example.MotvirsWeb.dominio.regla.PasoRuta> pasos) {
    }

    /**
     * Rutas desde la posición del conductor hasta su objetivo actual (la recogida si va por el pasajero, el destino
     * si el viaje está en curso). La primera es la sugerida.
     */
    public record Alternativas(String servicioId, String fase, List<Opcion> rutas) {
    }

    /** Resultado de elegir: si quedó guardada para el pasajero (solo con el viaje en curso). */
    public record Elegida(String servicioId, String rutaGeometria, boolean compartidaConPasajero,
                          List<com.example.MotvirsWeb.dominio.regla.PasoRuta> pasos) {
    }
}
