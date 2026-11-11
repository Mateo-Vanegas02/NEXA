package com.example.MotvirsWeb.presentacion.dto;

import com.example.MotvirsWeb.aplicacion.servicio.CotizacionService.Cotizacion;

/**
 * Lo que ve el pasajero al cotizar: sin comisión ni margen de la plataforma.
 *
 * @param tarifa   tarifa del viaje antes del descuento por nivel
 * @param descuento descuento por nivel ya aplicado
 * @param precio   lo que pagará como máximo (el cobro final puede ser menor, nunca mayor)
 * @param deudaPendiente deuda de una cancelación anterior que se sumará a este viaje (0 si no debe nada)
 * @param totalAPagar    precio + deudaPendiente: el efectivo que entregará al conductor
 */
public record CotizacionResponse(
        double distanciaKm,
        long tarifa,
        long descuento,
        long precio,
        double multiplicador,
        long deudaPendiente,
        long totalAPagar) {

    public static CotizacionResponse de(Cotizacion c) {
        return de(c, 0);
    }

    public static CotizacionResponse de(Cotizacion c, long deudaPendiente) {
        double km = Math.round(c.ruta().distanciaKm() * 100.0) / 100.0;
        long deuda = Math.max(0, deudaPendiente);
        return new CotizacionResponse(km, c.cobro().tarifaAjustada(), c.cobro().descuento(), c.cobro().precio(),
                c.cobro().multiplicador(), deuda, c.cobro().precio() + deuda);
    }
}
