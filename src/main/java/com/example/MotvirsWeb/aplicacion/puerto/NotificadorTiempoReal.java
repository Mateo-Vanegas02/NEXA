package com.example.MotvirsWeb.aplicacion.puerto;

import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.modelo.Usuario;

/**
 * Puerto de salida: avisos en tiempo real a pasajeros, conductores y administradores.
 * La implementación (STOMP/WebSocket) vive en infraestructura.
 */
public interface NotificadorTiempoReal {

    void notificarCambioEstadoServicio(Servicio servicio);

    default void notificarCambioEstadoServicio(Servicio servicio, String avisoId) {
        notificarCambioEstadoServicio(servicio);
    }

    /**
     * Avisa a los conductores que hay una solicitud nueva. Viaja solo el id: cada conductor recarga su lista, que el
     * servidor filtra por ola y cercanía.
     */
    void notificarNuevoServicioDisponible(Servicio servicio);

    /** La solicitud pasó a una ola más amplia: los conductores recargan su lista (viaja solo id y ola). */
    void notificarOlaAmpliada(String servicioId, int ola);

    /**
     * Avisa a los conductores que una solicitud ya no está disponible.
     * Solo viaja el id y el motivo ({@code TOMADO} o {@code CANCELADO}), nunca datos del pasajero ni del conductor.
     */
    void notificarSolicitudRetirada(String servicioId, String motivo);

    /** Avisa a los conductores que una solicitud subió su extra voluntario (viaja solo el id y el total). */
    void notificarOfertaSubida(String servicioId, long extraVoluntario);

    /**
     * Posición en vivo del conductor para el pasajero de ese viaje (canal privado del pasajero).
     * Solo lleva lo necesario para dibujar el mapa: nunca datos del conductor.
     */
    void notificarPosicionConductor(String pasajeroId, PosicionViaje posicion);

    /**
     * @param servicioId       viaje al que pertenece la posición
     * @param fase             {@code ACEPTADO} (yendo a recoger) o {@code EN_CURSO}
     * @param latitud          posición del conductor
     * @param longitud         posición del conductor
     * @param distanciaRestanteKm km por calle hasta la recogida (ACEPTADO) o el destino (EN_CURSO)
     * @param etaMinutos       minutos estimados hasta ese punto
     * @param en               instante de la posición (epoch ms, hora del servidor)
     */
    record PosicionViaje(String servicioId, String fase, double latitud, double longitud,
            double distanciaRestanteKm, int etaMinutos, long en) {
        @com.fasterxml.jackson.annotation.JsonProperty("avisoId")
        public String avisoId() {
            return servicioId + ":POSICION:" + en;
        }
    }

    void notificarNuevoRegistroAdmin(Usuario nuevoUsuario);

    void notificarNuevoRegistroAdmin(String email, String rol);
}
