package com.example.MotvirsWeb.dominio.regla;

import java.time.LocalDateTime;

/**
 * Horas que manda el teléfono para acciones hechas sin señal («llegué», iniciar, finalizar y las posiciones guardadas
 * durante el corte). El servidor sigue decidiendo: acepta la hora del teléfono solo dentro de la tolerancia y nunca
 * antes del paso anterior del viaje ni en el futuro. Sin Spring ni Mongo.
 */
public final class ReglaSinConexion {

    private ReglaSinConexion() {
    }

    /**
     * Minutos hacia atrás que se aceptan: la tolerancia base ({@code nexa.sin-conexion.tolerancia-minutos}) o, con el
     * viaje en curso, la mayor entre esa y la duración estimada de la carrera (un corte puede durar todo el trayecto).
     */
    public static long toleranciaMinutos(long base, boolean enCurso, double duracionEstimadaMin) {
        if (!enCurso || duracionEstimadaMin <= 0) {
            return base;
        }
        return Math.max(base, (long) Math.ceil(duracionEstimadaMin));
    }

    /**
     * Hora que se guarda para un evento. Sin hora del teléfono o con una hora futura, la del servidor; más atrás que
     * la tolerancia, se recorta al límite; y nunca antes de {@code minimo} (el paso anterior del viaje), si lo hay.
     */
    public static LocalDateTime horaEvento(LocalDateTime ahora, LocalDateTime informada, LocalDateTime minimo,
            long toleranciaMinutos) {
        if (informada == null || informada.isAfter(ahora)) {
            return ahora;
        }
        LocalDateTime limite = ahora.minusMinutes(Math.max(0, toleranciaMinutos));
        if (minimo != null && minimo.isAfter(limite)) {
            limite = minimo.isAfter(ahora) ? ahora : minimo;
        }
        return informada.isBefore(limite) ? limite : informada;
    }

    /** ¿Sirve una posición guardada sin señal? Solo si su hora está dentro de la tolerancia y no es futura. */
    public static boolean puntoAceptable(LocalDateTime ahora, LocalDateTime tomada, long toleranciaMinutos) {
        return tomada != null && !tomada.isAfter(ahora.plusSeconds(5))
                && !tomada.isBefore(ahora.minusMinutes(Math.max(0, toleranciaMinutos)));
    }
}
