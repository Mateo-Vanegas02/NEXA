package com.example.MotvirsWeb.presentacion.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;

/** Cuerpo de {@code POST /pasajero/cotizar} y {@code POST /api/pasajero/cotizar}: solo los dos puntos. */
public record CotizacionRequest(
        @NotNull(message = "La ubicación de origen es obligatoria") @Valid SolicitudViajeRequest.Coordenada ubicacionOrigen,
        @NotNull(message = "La ubicación de destino es obligatoria") @Valid SolicitudViajeRequest.Coordenada ubicacionDestino) {
}
