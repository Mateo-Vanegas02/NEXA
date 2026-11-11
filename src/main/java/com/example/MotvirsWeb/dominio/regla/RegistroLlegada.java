package com.example.MotvirsWeb.dominio.regla;

import org.springframework.stereotype.Component;

/** Regla de "llegué": el conductor debe estar a menos del radio configurado del punto de recogida. */
@Component
public class RegistroLlegada {

    private final double radioMetros;

    public RegistroLlegada(ModeloNexaProperties cfg) {
        this.radioMetros = cfg.getLlegada().getRadioMetros();
    }

    public double radioMetros() {
        return radioMetros;
    }

    /** Distancia en metros entre el conductor y el punto de recogida. */
    public double distanciaMetros(PuntoGeo conductor, PuntoGeo recogida) {
        return conductor.distanciaKm(recogida) * 1000.0;
    }

    public boolean enElPuntoDeRecogida(PuntoGeo conductor, PuntoGeo recogida) {
        return distanciaMetros(conductor, recogida) <= radioMetros;
    }
}
