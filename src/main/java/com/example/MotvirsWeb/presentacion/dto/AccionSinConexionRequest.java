package com.example.MotvirsWeb.presentacion.dto;

import java.time.Instant;

/**
 * Cuerpo opcional de iniciar y finalizar desde la app: la hora en que el conductor tocó el botón, si lo hizo sin señal
 * y la acción se envió después. El servidor la acepta solo dentro de la tolerancia sin conexión.
 */
public record AccionSinConexionRequest(Instant ocurridoEn) {
}
