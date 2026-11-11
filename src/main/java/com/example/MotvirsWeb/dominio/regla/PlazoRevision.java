package com.example.MotvirsWeb.dominio.regla;

import java.time.DayOfWeek;
import java.time.LocalDate;

/** Regla pura del plazo de revisión: N días hábiles (lunes a viernes; no incluye festivos). */
public final class PlazoRevision {

    private PlazoRevision() {
    }

    /** Fecha límite = {@code dias} días hábiles después de {@code desde}. Con 0 o menos devuelve {@code desde}. */
    public static LocalDate sumarDiasHabiles(LocalDate desde, int dias) {
        LocalDate f = desde;
        int restantes = dias;
        while (restantes > 0) {
            f = f.plusDays(1);
            if (f.getDayOfWeek() != DayOfWeek.SATURDAY && f.getDayOfWeek() != DayOfWeek.SUNDAY) {
                restantes--;
            }
        }
        return f;
    }

    /** Vencido cuando hoy es posterior al último día del plazo. */
    public static boolean vencido(LocalDate plazo, LocalDate hoy) {
        return plazo != null && hoy.isAfter(plazo);
    }
}
