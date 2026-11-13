package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import org.springframework.beans.BeanUtils;

import java.util.List;

/**
 * Qué parte de un {@link Servicio} puede ver cada rol. Todo viaje que sale hacia un navegador (REST o tiempo real)
 * pasa por aquí: se devuelve una copia y la entidad guardada no se toca.
 *
 * <ul>
 *   <li><b>Calificaciones:</b> cada uno ve solo la que él puso (nota, comentario y factores). El conductor no ve lo que le puso el pasajero y
 *       el pasajero no ve lo que le puso el conductor.</li>
 *   <li><b>Deuda:</b> el conductor no ve que al viaje se le suma una deuda del pasajero; ve un solo monto a
 *       cobrar. El detalle de la deuda solo lo ve el pasajero (la suya) y el administrador.</li>
 *   <li><b>Interno:</b> notas del administrador sobre cargos, XP del otro y métricas de despacho no salen.</li>
 * </ul>
 */
public final class VisibilidadServicio {

    private VisibilidadServicio() {
    }

    /** Vista del conductor: sin la calificación que le dio el pasajero y sin rastro de la deuda del pasajero. */
    public static Servicio paraConductor(Servicio original) {
        if (original == null) {
            return null;
        }
        Servicio v = copiar(original);
        v.setCalificacionConductor(null);
        v.setComentariosConductor(null);
        v.setFactoresConductor(null);
        // Un solo monto: lo que debe recibir en efectivo (tarifa + deuda cobrada con este viaje, si la hay)
        long deuda = 0;
        if (original.getEstado() == EstadoServicio.FINALIZADO) {
            deuda = original.getDeudaCobrada();
        } else if (original.getEstado() == EstadoServicio.ACEPTADO || original.getEstado() == EstadoServicio.EN_CURSO) {
            deuda = original.getDeudaPorCobrar();
        }
        v.setTarifa(original.getTarifa() + Math.max(0, deuda));
        v.setDeudaPorCobrar(0);
        v.setDeudaServicioId(null);
        v.setDeudaCobrada(0);
        v.setXpGanadoPasajero(0);
        return v;
    }

    /** Vista del pasajero: sin la calificación que le dio el conductor ni lo que el conductor gana. */
    public static Servicio paraPasajero(Servicio original) {
        if (original == null) {
            return null;
        }
        if (original.getGananciaEstimada() != null) {
            original = copiar(original);
            original.setGananciaEstimada(null);
        }
        Servicio v = copiar(original);
        v.setCalificacionPasajero(null);
        v.setComentariosPasajero(null);
        v.setFactoresPasajero(null);
        v.setXpGanadoConductor(0);
        return v;
    }

    public static List<Servicio> paraConductor(List<Servicio> originales) {
        return originales == null ? List.of() : originales.stream().map(VisibilidadServicio::paraConductor).toList();
    }

    public static List<Servicio> paraPasajero(List<Servicio> originales) {
        return originales == null ? List.of() : originales.stream().map(VisibilidadServicio::paraPasajero).toList();
    }

    private static Servicio copiar(Servicio original) {
        Servicio v = new Servicio();
        BeanUtils.copyProperties(original, v);
        // Nada de esto le sirve a ningún rol: es de administración y de la medición del despacho
        v.setDesglose(null);
        v.setCargoMetodoPago(null);
        v.setCargoNotaPago(null);
        v.setCargoCondonadoPor(null);
        v.setCargoMotivoCondonacion(null);
        v.setOlaAceptacion(0);
        v.setDistanciaRecogidaKm(null);
        // El recorrido real (miles de puntos) no viaja con cada viaje: es para auditoría del administrador
        v.setRecorrido(null);
        return v;
    }
}
