package com.example.MotvirsWeb.presentacion.dto;

import com.example.MotvirsWeb.aplicacion.comando.SolicitudViaje;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Cuerpo de {@code POST /pasajero/solicitar-viaje} y {@code POST /api/pasajero/solicitar-viaje}.
 * No lleva tarifa ni distancia: las calcula el servidor a partir de los dos puntos. Si un cliente
 * antiguo las envía, se ignoran.
 */
public record SolicitudViajeRequest(
        @NotBlank(message = "El origen es obligatorio")
        @Size(max = 500, message = "El origen no puede exceder 500 caracteres") String origen,

        @NotBlank(message = "El destino es obligatorio")
        @Size(max = 500, message = "El destino no puede exceder 500 caracteres") String destino,

        @NotNull(message = "La ubicación de origen es obligatoria") @Valid Coordenada ubicacionOrigen,

        @NotNull(message = "La ubicación de destino es obligatoria") @Valid Coordenada ubicacionDestino,

        @Size(max = 64, message = "La fecha no es válida") String fechaHora,

        @Size(max = 50, message = "El método de pago no puede exceder 50 caracteres") String metodoPago,

        /** Dónde está el pasajero según su GPS; el punto de recogida debe estar cerca. */
        @Valid Coordenada ubicacionPasajero,

        /** El pasajero vio que su deuda anterior se suma a este viaje y aceptó pagarla. */
        boolean aceptaDeuda) {

    public record Coordenada(
            @NotNull(message = "La latitud es obligatoria")
            @DecimalMin(value = "-90.0", message = "Latitud fuera de rango")
            @DecimalMax(value = "90.0", message = "Latitud fuera de rango") Double latitud,

            @NotNull(message = "La longitud es obligatoria")
            @DecimalMin(value = "-180.0", message = "Longitud fuera de rango")
            @DecimalMax(value = "180.0", message = "Longitud fuera de rango") Double longitud) {
    }

    /** Convierte el DTO (ya validado) en el comando de la capa de aplicación. */
    public SolicitudViaje aComando() {
        return new SolicitudViaje(
                origen, destino,
                new SolicitudViaje.Coordenada(ubicacionOrigen.latitud(), ubicacionOrigen.longitud()),
                new SolicitudViaje.Coordenada(ubicacionDestino.latitud(), ubicacionDestino.longitud()),
                ubicacionPasajero == null ? null
                        : new SolicitudViaje.Coordenada(ubicacionPasajero.latitud(), ubicacionPasajero.longitud()),
                fechaHora, metodoPago, aceptaDeuda);
    }
}
