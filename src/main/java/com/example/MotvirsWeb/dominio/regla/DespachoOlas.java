package com.example.MotvirsWeb.dominio.regla;

import org.springframework.stereotype.Component;

/**
 * Despacho por olas: una solicitud se avisa primero a los conductores cercanos y, mientras nadie la toma, el
 * radio de recogida crece (nexa.despacho.*). La ola es función del tiempo transcurrido desde la solicitud, así que
 * no hay estado que guardar ni avanzar. Un conductor sin posición vigente solo la ve en la última ola.
 */
@Component
public class DespachoOlas {

    private final int[] inicios;
    private final double[] radios;
    private final int olasPorExtra;

    public DespachoOlas(ModeloNexaProperties cfg) {
        ModeloNexaProperties.Despacho d = cfg.getDespacho();
        this.inicios = d.getOlaSegundos();
        this.radios = d.getOlaRadioKm();
        this.olasPorExtra = Math.max(0, d.getOlasPorExtra());
        if (inicios == null || radios == null || inicios.length == 0 || inicios.length != radios.length) {
            throw new IllegalStateException("nexa.despacho: ola-segundos y ola-radio-km deben tener el mismo largo (≥ 1)");
        }
        if (inicios[0] != 0) {
            throw new IllegalStateException("nexa.despacho.ola-segundos debe empezar en 0");
        }
        for (int i = 1; i < inicios.length; i++) {
            if (inicios[i] <= inicios[i - 1]) {
                throw new IllegalStateException("nexa.despacho.ola-segundos debe ser creciente");
            }
        }
    }

    public int totalOlas() {
        return inicios.length;
    }

    /** Ola (desde 1) en que está una solicitud con esos segundos de espera. */
    public int ola(long segundos) {
        int ola = 1;
        for (int i = 1; i < inicios.length; i++) {
            if (segundos >= inicios[i]) {
                ola = i + 1;
            }
        }
        return ola;
    }

    /**
     * Ola de una solicitud que puede llevar extra voluntario: pagar de más la adelanta
     * {@code nexa.despacho.olas-por-extra} olas, así la ven más conductores sin esperar.
     */
    public int ola(long segundos, boolean conExtra) {
        int ola = ola(segundos) + (conExtra ? olasPorExtra : 0);
        return Math.min(ola, inicios.length);
    }

    public int olasPorExtra() {
        return olasPorExtra;
    }

    /** Segundo (desde la solicitud) en que empieza la ola (desde 1). */
    public int inicioSegundos(int ola) {
        return inicios[Math.max(1, Math.min(ola, inicios.length)) - 1];
    }

    public boolean esUltima(int ola) {
        return ola >= inicios.length;
    }

    /** Radio de la ola en km; infinito en la ola abierta a toda la zona. */
    public double radioKm(int ola) {
        double r = radios[Math.max(1, Math.min(ola, radios.length)) - 1];
        return r <= 0 ? Double.POSITIVE_INFINITY : r;
    }

    /**
     * ¿Ve el conductor la solicitud? {@code distanciaKm} es la de la recogida; null si no hay posición vigente
     * (opción B: entonces solo la ve en la última ola).
     */
    public boolean visible(long segundos, Double distanciaKm) {
        return visible(segundos, distanciaKm, false);
    }

    /** Igual que {@link #visible(long, Double)} teniendo en cuenta el extra voluntario. */
    public boolean visible(long segundos, Double distanciaKm, boolean conExtra) {
        int ola = ola(segundos, conExtra);
        if (distanciaKm == null) {
            return esUltima(ola);
        }
        return distanciaKm <= radioKm(ola);
    }

    /** Segundos que faltan para la siguiente ola; null si ya es la última. */
    public Long segundosParaSiguiente(long segundos) {
        return segundosParaSiguiente(segundos, false);
    }

    /** Igual que {@link #segundosParaSiguiente(long)} teniendo en cuenta el extra voluntario. */
    public Long segundosParaSiguiente(long segundos, boolean conExtra) {
        if (esUltima(ola(segundos, conExtra))) {
            return null;
        }
        return Math.max(0, inicios[ola(segundos)] - segundos);
    }
}
