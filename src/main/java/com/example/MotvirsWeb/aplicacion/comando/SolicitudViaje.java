package com.example.MotvirsWeb.aplicacion.comando;

/**
 * Datos que necesita el caso de uso "solicitar viaje". Es independiente del formato HTTP:
 * la capa de presentación lo construye a partir de su DTO ya validado.
 *
 * @param ubicacionOrigen   punto de recogida elegido por el pasajero
 * @param ubicacionPasajero donde está el pasajero según su GPS (opcional); el punto de recogida debe estar cerca
 * @param fechaHora   instante de la solicitud en ISO-8601 (opcional; si falta se usa la hora actual)
 * @param metodoPago  opcional
 * @param aceptaDeuda el pasajero vio que su deuda anterior se suma a este viaje y aceptó pagarla
 */
public record SolicitudViaje(
        String origen,
        String destino,
        Coordenada ubicacionOrigen,
        Coordenada ubicacionDestino,
        Coordenada ubicacionPasajero,
        String fechaHora,
        String metodoPago,
        boolean aceptaDeuda) {

    public record Coordenada(double latitud, double longitud) {
    }
}
