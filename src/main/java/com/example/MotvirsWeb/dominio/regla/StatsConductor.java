package com.example.MotvirsWeb.dominio.regla;

/**
 * Métricas de calidad del conductor en la ventana móvil.
 *
 * @param calificacion promedio de calificaciones recibidas; null si no hay ninguna
 * @param aceptacion   0..1
 * @param cancelacion  0..1
 */
public record StatsConductor(Double calificacion, double aceptacion, double cancelacion) {
    public static StatsConductor vacio() {
        return new StatsConductor(null, 1.0, 0.0);
    }
}
