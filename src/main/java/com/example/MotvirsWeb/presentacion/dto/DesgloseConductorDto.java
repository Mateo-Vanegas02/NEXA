package com.example.MotvirsWeb.presentacion.dto;

import com.example.MotvirsWeb.dominio.modelo.Servicio.DesgloseTarifa;

/**
 * Lo que el conductor puede ver: lo que debe cobrar y lo que gana. No lleva la comisión (ni su monto ni su porcentaje),
 * la tarifa bruta, los descuentos del pasajero ni el margen de la plataforma.
 *
 * <p>{@code cobrarAlPasajero} es el efectivo que debe recibir. Puede incluir una deuda anterior del pasajero,
 * pero el conductor no ve ese desglose (solo el administrador) y su comisión y ganancia salen de la tarifa.
 */
public record DesgloseConductorDto(
        double recargoEspera,
        double extraVoluntario,
        double gananciaConductor,
        double cobrarAlPasajero) {

    public static DesgloseConductorDto de(DesgloseTarifa d) {
        return de(d, 0);
    }

    public static DesgloseConductorDto de(DesgloseTarifa d, long deudaCobrada) {
        if (d == null) {
            return null;
        }
        return new DesgloseConductorDto(d.getRecargoEspera(), d.getExtraVoluntario(), d.getGananciaConductor(),
                d.getTotalPasajero() + Math.max(0, deudaCobrada));
    }
}
