package com.example.MotvirsWeb.presentacion.dto;

import com.example.MotvirsWeb.aplicacion.servicio.UbicacionConductorService.PosicionFlota;

import java.util.List;

/**
 * Operación en vivo para el inicio del admin en la app: cifras del día, la flota en el mapa (sin identificar
 * a nadie) y las alertas que piden atención.
 */
public record OperacionAdminDto(
        long viajesHoy,
        long finalizadosHoy,
        long canceladosHoy,
        long enCurso,
        long yendoARecoger,
        long solicitudesAbiertas,
        long conductoresEnLinea,
        long conductoresDisponibles,
        long conductoresPendientes,
        List<PosicionFlota> flota,
        List<Alerta> alertas) {

    /** Algo que el admin debería mirar. {@code tipo}: SOLICITUD_SIN_CONDUCTOR o CONDUCTORES_POR_APROBAR. */
    public record Alerta(String tipo, String texto, String servicioId, long minutos) {
    }
}
