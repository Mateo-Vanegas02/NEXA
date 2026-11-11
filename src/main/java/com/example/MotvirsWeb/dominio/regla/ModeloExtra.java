package com.example.MotvirsWeb.dominio.regla;

import org.springframework.stereotype.Component;

import java.util.Arrays;

/**
 * Regla pura del extra voluntario (modelo v2.2, sección 12A): el pasajero solo puede subir su
 * oferta en pasos fijos y sin pasar el tope por viaje. Nunca baja.
 */
@Component
public class ModeloExtra {

    private final long tope;
    private final long[] pasos;

    public ModeloExtra(ModeloNexaProperties props) {
        this.tope = props.getExtra().getTope();
        this.pasos = props.getExtra().getPasos().clone();
    }

    public long tope() {
        return tope;
    }

    public long[] pasos() {
        return pasos.clone();
    }

    /** Total tras sumar {@code incremento} a {@code actual}; lanza si el paso no existe o se pasa del tope. */
    public long nuevoTotal(long actual, long incremento) {
        if (Arrays.stream(pasos).noneMatch(p -> p == incremento)) {
            throw new IllegalArgumentException("El extra debe ser de " + Arrays.toString(pasos) + " pesos");
        }
        long total = Math.max(0, actual) + incremento;
        if (total > tope) {
            throw new IllegalArgumentException("El extra total no puede pasar de $" + tope + " por viaje");
        }
        return total;
    }

    /** Lo máximo que aún se puede sumar a un viaje con este extra. */
    public long margen(long actual) {
        return Math.max(0, tope - Math.max(0, actual));
    }
}
