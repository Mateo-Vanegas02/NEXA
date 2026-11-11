package com.example.MotvirsWeb.presentacion.dto;

import com.example.MotvirsWeb.dominio.modelo.Servicio.DesgloseTarifa;

/**
 * Lo que el pasajero puede ver del cobro: sin comisión ni margen de la plataforma. Si traía una deuda de una
 * cancelación anterior, la ve aparte y sumada al total que paga en efectivo.
 */
public record DesglosePasajeroDto(
        double tarifa,
        double descuentoNivel,
        double recargoEspera,
        double extraVoluntario,
        double totalPasajero,
        long deudaAnterior,
        double totalAPagar) {

    public static DesglosePasajeroDto de(DesgloseTarifa d) {
        return de(d, 0);
    }

    public static DesglosePasajeroDto de(DesgloseTarifa d, long deudaAnterior) {
        if (d == null) {
            return null;
        }
        long deuda = Math.max(0, deudaAnterior);
        return new DesglosePasajeroDto(d.getTarifaBruta(), d.getDescuentoNivel(), d.getRecargoEspera(),
                d.getExtraVoluntario(), d.getTotalPasajero(), deuda, d.getTotalPasajero() + deuda);
    }
}
