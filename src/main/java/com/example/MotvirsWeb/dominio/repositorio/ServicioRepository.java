package com.example.MotvirsWeb.dominio.repositorio;

import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import org.bson.types.ObjectId;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface ServicioRepository extends MongoRepository<Servicio, String> {
    List<Servicio> findByEstado(EstadoServicio estado);

    long countByEstado(EstadoServicio estado);

    long countByFechaHoraGreaterThanEqual(java.time.LocalDateTime desde);

    long countByFechaHoraGreaterThanEqualAndEstado(java.time.LocalDateTime desde, EstadoServicio estado);

    /**
     * Viajes finalizados después del despliegue de niveles (solicitadoEn presente) cuyo
     * procesamiento no llegó a marcarse como definitivo.
     */
    @org.springframework.data.mongodb.repository.Query("{ 'estado': 'FINALIZADO', 'solicitadoEn': { $ne: null }, "
            + "'desglose.definitivo': { $ne: true }, 'fechaFinalizacion': { $gt: ?0, $lt: ?1 } }")
    List<Servicio> findPendientesDeNiveles(java.time.LocalDateTime desde, java.time.LocalDateTime hasta);

    /** Solo los campos necesarios para las métricas de calidad (no materializa viajes completos). */
    @org.springframework.data.mongodb.repository.Query(value = "{ 'conductor._id': ?0, 'fechaHora': { $gt: ?1 } }",
            fields = "{ 'estado': 1, 'canceladoPor': 1, 'calificacionConductor': 1 }")
    List<Servicio> findResumenDeCalidad(ObjectId conductorId, java.time.LocalDateTime desde);

    /** Viajes finalizados entre el mismo pasajero y conductor en un rango (antifraude de XP: máx. 2 por día). */
    @org.springframework.data.mongodb.repository.Query(value = "{ 'pasajero._id': ?0, 'conductor._id': ?1, "
            + "'estado': 'FINALIZADO', 'fechaFinalizacion': { $gte: ?2, $lt: ?3 } }", count = true)
    long contarFinalizadosDeLaPareja(ObjectId pasajeroId, ObjectId conductorId,
            java.time.LocalDateTime desde, java.time.LocalDateTime hasta);

    List<Servicio> findByPasajeroIdAndFechaHoraBetween(ObjectId pasajeroId,
            java.time.LocalDateTime desde, java.time.LocalDateTime hasta);
    List<Servicio> findByConductorIdAndEstado(ObjectId conductorId, EstadoServicio estado);
    List<Servicio> findByPasajeroIdAndEstado(ObjectId pasajeroId, EstadoServicio estado);
    boolean existsByPasajeroIdAndEstado(ObjectId pasajeroId, EstadoServicio estado);
    boolean existsByPasajeroIdAndEstadoIn(ObjectId pasajeroId, java.util.Collection<EstadoServicio> estados);
    boolean existsByConductorIdAndEstadoIn(ObjectId conductorId, java.util.Collection<EstadoServicio> estados);

    /** Servicios del pasajero con cargo por cancelación (pagados, condonados o pendientes). */
    List<Servicio> findByPasajeroIdAndCargoCancelacionGreaterThan(ObjectId pasajeroId, long minimo,
            org.springframework.data.domain.Pageable pagina);

    /**
     * Asigna el viaje al conductor solo si sigue SOLICITADO, en una sola operación atómica:
     * si dos conductores aceptan a la vez, solo uno obtiene 1 y el otro 0.
     */
    @org.springframework.data.mongodb.repository.Query("{ '_id': ?0, 'estado': 'SOLICITADO' }")
    @org.springframework.data.mongodb.repository.Update("{ '$set': { 'estado': 'ACEPTADO', 'conductor': ?1, 'fechaAceptacion': ?2 } }")
    long tomarSiDisponible(String servicioId, Servicio.ConductorEmbedded conductor, java.time.LocalDateTime fechaAceptacion);

    /**
     * Cancela una solicitud que esperó demasiado, solo si sigue SOLICITADO (atómico: si un conductor la tomó en ese
     * instante, devuelve 0 y no la toca). Sin cargo para el pasajero.
     */
    @org.springframework.data.mongodb.repository.Query("{ '_id': ?0, 'estado': 'SOLICITADO' }")
    @org.springframework.data.mongodb.repository.Update("{ '$set': { 'estado': 'CANCELADO', 'canceladoPor': 'SISTEMA', "
            + "'fechaCancelacion': ?1, 'cargoCancelacion': 0 } }")
    long vencerSiSigueSolicitado(String servicioId, java.time.LocalDateTime fecha);

    @org.springframework.data.mongodb.repository.Query("{ '_id': ?0, 'estado': 'ACEPTADO', 'conductor._id': ?1, 'fechaLlegada': { '$ne': null } }")
    @org.springframework.data.mongodb.repository.Update("{ '$set': { 'estado': 'EN_CURSO', 'fechaInicio': ?2, 'minutosEspera': ?3 } }")
    long iniciarSiAceptado(String servicioId, ObjectId conductorId, java.time.LocalDateTime fecha, double espera);

    @org.springframework.data.mongodb.repository.Query("{ '_id': ?0, 'estado': 'ACEPTADO', 'conductor._id': ?1, 'fechaLlegada': null }")
    @org.springframework.data.mongodb.repository.Update("{ '$set': { 'fechaLlegada': ?2, 'ubicacionLlegada': ?3 } }")
    long registrarLlegadaSiAceptado(String servicioId, ObjectId conductorId,
                                   java.time.LocalDateTime fecha, Servicio.Coordenada ubicacion);

    @org.springframework.data.mongodb.repository.Query("{ '_id': ?0, 'estado': 'EN_CURSO', 'conductor._id': ?1 }")
    @org.springframework.data.mongodb.repository.Update("{ '$set': { 'estado': 'FINALIZADO', 'fechaFinalizacion': ?2, 'finalizadoAntesDelDestino': ?3, 'fraccionCobrada': ?4 } }")
    long finalizarSiEnCurso(String servicioId, ObjectId conductorId, java.time.LocalDateTime fecha,
                            boolean antesDelDestino, double fraccion);

    @org.springframework.data.mongodb.repository.Query("{ '_id': ?0, 'estado': { '$in': ['ACEPTADO', 'EN_CURSO'] }, 'conductor._id': ?1 }")
    @org.springframework.data.mongodb.repository.Update("{ '$set': { 'estado': 'CANCELADO', 'canceladoPor': 'CONDUCTOR', 'fechaCancelacion': ?2 } }")
    long cancelarSiAsignado(String servicioId, ObjectId conductorId, java.time.LocalDateTime fecha);

    @org.springframework.data.mongodb.repository.Query("{ '_id': ?0, 'estado': ?2, 'pasajero._id': ?1 }")
    @org.springframework.data.mongodb.repository.Update("{ '$set': { 'estado': 'CANCELADO', 'canceladoPor': 'PASAJERO', 'fechaCancelacion': ?3, 'cargoCancelacion': ?4, 'cargoAcreditadoConductor': ?5, 'minutosEspera': ?6 } }")
    long cancelarSiVigente(String servicioId, ObjectId pasajeroId, EstadoServicio estado,
                           java.time.LocalDateTime fecha, long cargo, boolean acreditado, Double espera);

    @org.springframework.data.mongodb.repository.Query("{ '_id': ?0, 'estado': 'FINALIZADO', 'pasajero._id': ?1, 'calificacionConductor': null, 'calificacionConductorRegistrada': { '$ne': true } }")
    @org.springframework.data.mongodb.repository.Update("{ '$set': { 'calificacionConductor': ?2, 'comentariosConductor': ?3, 'factoresConductor': ?4, 'calificacionConductorRegistrada': true } }")
    long calificarConductorUnaVez(String servicioId, ObjectId pasajeroId, Double nota, String comentario, List<String> factores);

    @org.springframework.data.mongodb.repository.Query("{ '_id': ?0, 'estado': 'FINALIZADO', 'conductor._id': ?1, 'calificacionPasajero': null, 'calificacionPasajeroRegistrada': { '$ne': true } }")
    @org.springframework.data.mongodb.repository.Update("{ '$set': { 'calificacionPasajero': ?2, 'comentariosPasajero': ?3, 'factoresPasajero': ?4, 'calificacionPasajeroRegistrada': true } }")
    long calificarPasajeroUnaVez(String servicioId, ObjectId conductorId, Double nota, String comentario, List<String> factores);

    @org.springframework.data.mongodb.repository.Query("{ '_id': ?0, 'estado': 'FINALIZADO' }")
    @org.springframework.data.mongodb.repository.Update("{ '$set': { 'distanciaRecorridaKm': ?1, 'recorrido': ?2 } }")
    long guardarRecorridoFinal(String servicioId, Double km, List<Servicio.Coordenada> puntos);

    @org.springframework.data.mongodb.repository.Query("{ '_id': ?0, 'estado': 'FINALIZADO' }")
    @org.springframework.data.mongodb.repository.Update("{ '$set': { 'deudaCobrada': ?1 } }")
    long guardarDeudaCobrada(String servicioId, long deuda);

    @org.springframework.data.mongodb.repository.Query("{ '_id': ?0, 'estado': 'FINALIZADO' }")
    @org.springframework.data.mongodb.repository.Update("{ '$set': { 'desglose': ?1, 'xpGanadoPasajero': ?2, 'xpGanadoConductor': ?3, 'tarifa': ?4 } }")
    long guardarResultadoNiveles(String servicioId, Servicio.DesgloseTarifa desglose, double pasajero, double conductor,
                                 double tarifa);

    @org.springframework.data.mongodb.repository.Query("{ '_id': ?0, 'estado': 'FINALIZADO' }")
    @org.springframework.data.mongodb.repository.Update("{ '$set': { 'xpGanadoConductor': ?1 } }")
    long guardarXpConductor(String servicioId, double xp);

    @org.springframework.data.mongodb.repository.Query("{ '_id': ?0, 'estado': 'CANCELADO', 'canceladoPor': 'PASAJERO' }")
    @org.springframework.data.mongodb.repository.Update("{ '$set': { 'cargoCancelacion': 0, 'cargoAcreditadoConductor': false } }")
    long retirarCargoNoRegistrado(String servicioId);

    /** Guarda en qué ola y a qué distancia se aceptó (métricas del despacho). */
    @org.springframework.data.mongodb.repository.Query("{ '_id': ?0 }")
    @org.springframework.data.mongodb.repository.Update("{ '$set': { 'olaAceptacion': ?1, 'distanciaRecogidaKm': ?2 } }")
    long registrarDespacho(String servicioId, int ola, Double distanciaKm);

    /** Solicitudes desde una fecha, solo con los campos que usan las métricas del despacho. */
    @org.springframework.data.mongodb.repository.Query(value = "{ 'solicitadoEn': { '$gte': ?0 } }",
            fields = "{ 'estado': 1, 'solicitadoEn': 1, 'fechaAceptacion': 1, 'olaAceptacion': 1, 'distanciaRecogidaKm': 1 }")
    java.util.List<Servicio> metricasDespachoDesde(java.time.LocalDateTime desde);

    /**
     * Suma el extra voluntario solo si la solicitud sigue SOLICITADO, es del pasajero y el total
     * no pasa del tope ({@code maximoActual} = tope − incremento). Atómico: devuelve 0 si no aplicó.
     */
    @org.springframework.data.mongodb.repository.Query("{ '_id': ?0, 'estado': 'SOLICITADO', 'pasajero._id': ?1, "
            + "'extraVoluntario': { '$not': { '$gt': ?2 } } }")
    @org.springframework.data.mongodb.repository.Update("{ '$inc': { 'extraVoluntario': ?3 }, '$push': { 'historialExtra': ?4 } }")
    long subirExtra(String servicioId, ObjectId pasajeroId, long maximoActual, long incremento,
            Servicio.OfertaExtra oferta);

    List<Servicio> findByConductorIdAndCalificacionPasajeroIsNotNull(ObjectId conductorId);
    List<Servicio> findByPasajeroIdAndCalificacionConductorIsNotNull(ObjectId pasajeroId);
}
