package com.example.MotvirsWeb.presentacion.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

/** Cuánto suma el pasajero a su oferta (pesos); los pasos permitidos los valida el servidor. */
public record SubirOfertaRequest(@NotNull @Positive Long incremento) {
}
