package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.comando.SolicitudViaje;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Servicio;

import java.util.List;
import java.util.Map;

/**
 * Contrato de servicio para todas las operaciones de negocio sobre
 * {@link Servicio}.
 *
 * Principio DIP: los Controllers dependen de esta interfaz, no de clases
 * concretas ni
 * de repositorios. Principio SRP: toda la lógica de negocio de servicios vive
 * en la
 * implementación, liberando a los controllers de esa responsabilidad.
 */
public interface ServicioService {

    // ── Operaciones del Conductor ─────────────────────────────────────

    /**
     * Acepta un servicio SOLICITADO y lo asigna al conductor dado.
     * 
     * @return mapa con mensaje y servicioId
     */
    Map<String, Object> aceptarServicio(String servicioId, Conductor conductor);

    /**
     * El conductor confirma que llegó al punto de recogida. Se acepta solo si su ubicación está
     * dentro del radio configurado; la hora la fija el servidor y desde ahí corre la espera.
     */
    Map<String, Object> confirmarLlegada(String servicioId, Conductor conductor, double latitud, double longitud);

    /**
     * Cambia el estado de un servicio ACEPTADO a EN_CURSO.
     */
    Map<String, Object> iniciarServicio(String servicioId, Conductor conductor);

    /**
     * Finaliza un servicio EN_CURSO del conductor dado.
     */
    Map<String, Object> finalizarServicio(String servicioId, Conductor conductor);

    /**
     * Cancela un servicio activo del conductor dado.
     */
    Map<String, Object> cancelarServicioConductor(String servicioId, Conductor conductor);

    /**
     * Retorna servicios disponibles (estado SOLICITADO).
     */
    List<Servicio> obtenerServiciosDisponibles();

    /** Disponibles filtrados/ordenados por prioridad de recogida para este conductor. */
    List<Servicio> obtenerServiciosDisponibles(Conductor conductor, Double lat, Double lng);

    /**
     * Retorna servicios EN_CURSO del conductor.
     */
    List<Servicio> obtenerServiciosEnCurso(Conductor conductor);

    /** Viaje que el conductor tiene ahora (en curso o aceptado), para retomarlo tras recargar la página. */
    java.util.Optional<Servicio> obtenerViajeActivo(Conductor conductor);

    /**
     * Retorna un servicio por su ID (acceso genérico para el conductor).
     */
    Servicio obtenerServicioPorId(String servicioId);

    /**
     * Servicio visible para un conductor: el que tiene asignado o uno aún SOLICITADO.
     * Lanza 403 si pertenece a otro conductor (evita IDOR).
     */
    Servicio obtenerServicioDeConductor(String servicioId, Conductor conductor);

    /**
     * Calificación verificando que el usuario (id) participa en el servicio con
     * ese rol y que el viaje ya finalizó. Lanza 403/400 si no.
     */
    Map<String, Object> calificarServicio(String servicioId, String rol,
            Double calificacion, String comentarios, String usuarioId);

    /**
     * Retorna el historial FINALIZADO del conductor, con filtros opcionales.
     */
    List<Servicio> obtenerHistorialConductor(Conductor conductor, String fecha, String pasajero);

    /**
     * Retorna ingresos del conductor, filtrados por periodo y/o fecha exacta.
     */
    List<Map<String, Object>> obtenerIngresosConductor(Conductor conductor, String periodo, String fecha);

    // ── Operaciones del Pasajero ──────────────────────────────────────

    /**
     * Crea y persiste un nuevo servicio a partir de los datos de la solicitud.
     * 
     * @return mapa con mensaje y servicioId
     */
    Map<String, Object> solicitarViaje(SolicitudViaje solicitud, Pasajero pasajero);

    /**
     * El pasajero cancela su viaje (solo si está SOLICITADO o ACEPTADO). Si corresponde cargo,
     * queda como deuda del pasajero (una sola a la vez) y bloquea nuevos viajes hasta que se pague.
     */
    Map<String, Object> cancelarViajePasajero(String servicioId, Pasajero pasajero);

    /**
     * Solicitud del pasajero que sigue esperando conductor (SOLICITADO), si la hay. Mientras exista no
     * puede cerrar sesión ni pedir otro viaje: primero debe cancelarla.
     */
    java.util.Optional<Servicio> solicitudPendienteDe(Pasajero pasajero);

    /**
     * Suma un extra voluntario a la solicitud del pasajero mientras siga esperando conductor (SOLICITADO).
     * Solo sube, en los pasos configurados y hasta el tope por viaje; los conductores lo ven al instante.
     */
    Map<String, Object> subirOferta(String servicioId, long incremento, Pasajero pasajero);

    /** Tarifa y datos del extra voluntario de una solicitud, para pintar "Subir oferta" en el panel del pasajero. */
    Map<String, Object> datosDeOferta(Servicio servicio);

    /**
     * Retorna el historial FINALIZADO del pasajero, con filtros opcionales.
     */
    List<Servicio> obtenerHistorialPasajero(Pasajero pasajero, String fecha, String conductor);

    /**
     * Retorna un servicio verificando que pertenece al pasajero dado.
     */
    Servicio obtenerServicioDePasajero(String servicioId, Pasajero pasajero);

    // ── Calificación (usada por ControllerRating y ControllerPasajero) ──

    /**
     * Registra la calificación de un participante sobre el otro.
     * 
     * @param rol "conductor" o "pasajero"
     */
    Map<String, Object> calificarServicio(String servicioId, String rol,
            Double calificacion, String comentarios);
}
