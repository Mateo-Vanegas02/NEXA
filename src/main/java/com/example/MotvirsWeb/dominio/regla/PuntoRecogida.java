package com.example.MotvirsWeb.dominio.regla;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

/**
 * El pasajero elige dónde lo recogen, pero ese punto tiene que estar cerca de donde está: no se pide un viaje
 * desde el otro lado de la ciudad. El límite es {@code nexa.recogida.radio-max-metros}. Si el cliente no envía su
 * posición GPS (app antigua) no hay nada que comparar y se acepta.
 */
@Component
public class PuntoRecogida {

    private final double radioMaxMetros;

    public PuntoRecogida(ModeloNexaProperties cfg) {
        this.radioMaxMetros = cfg.getRecogida().getRadioMaxMetros();
    }

    public double radioMaxMetros() {
        return radioMaxMetros;
    }

    /** Metros entre el pasajero y el punto de recogida; -1 si falta alguno. */
    public double metrosHasta(PuntoGeo pasajero, PuntoGeo recogida) {
        return pasajero == null || recogida == null ? -1 : pasajero.distanciaKm(recogida) * 1000;
    }

    public boolean cerca(PuntoGeo pasajero, PuntoGeo recogida) {
        double metros = metrosHasta(pasajero, recogida);
        return metros < 0 || metros <= radioMaxMetros;
    }

    /** Lanza 400 si el punto de recogida está demasiado lejos del pasajero. */
    public void exigirCerca(PuntoGeo pasajero, PuntoGeo recogida) {
        if (!cerca(pasajero, recogida)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "El punto de recogida debe estar a menos de " + Math.round(radioMaxMetros)
                            + " m de donde estás. Acércalo o muévete hasta él.");
        }
    }
}
