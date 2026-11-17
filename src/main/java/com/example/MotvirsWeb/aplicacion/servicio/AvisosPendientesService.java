package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.Executor;
import java.util.concurrent.RejectedExecutionException;
import org.bson.types.ObjectId;

/**
 * Bandeja persistente de avisos de transiciones. La inscripción participa en la transacción Mongo del viaje;
 * el envío ocurre después del commit, en {@code avisosExecutor}, nunca en el hilo de la petición ni en el hilo
 * compartido de {@code @Scheduled}. El barrido periódico solo recoge lo que quedó sin enviar (fallos, reinicios).
 */
@Slf4j
@Service
public class AvisosPendientesService {
    private static final String COLECCION = "avisos_viaje_pendientes";
    private final MongoTemplate mongo;
    private final ServicioRepository servicios;
    private final NotificadorTiempoReal tiempoReal;
    private final AvisosService push;
    private final DeudaService deudas;
    private final Executor envios;

    public AvisosPendientesService(MongoTemplate mongo, ServicioRepository servicios, NotificadorTiempoReal tiempoReal,
                                   AvisosService push, DeudaService deudas,
                                   @Qualifier("avisosExecutor") Executor envios) {
        this.mongo = mongo;
        this.servicios = servicios;
        this.tiempoReal = tiempoReal;
        this.push = push;
        this.deudas = deudas;
        this.envios = envios;
    }

    public void registrar(String servicioId, Tipo tipo) {
        String id = servicioId + ":" + tipo;
        List<ObjectId> destinatarios = tipo == Tipo.ACEPTADO || tipo == Tipo.CANCELADO
                ? push.destinatariosRetirada(servicioId) : List.of();
        mongo.insert(new Pendiente(id, servicioId, tipo.name(), "PENDIENTE", LocalDateTime.now(), null, 0,
                        destinatarios == null ? List.of() : destinatarios),
                COLECCION);
        despuesDelCommit(() -> encolar(id));
    }

    /** Barrido de respaldo: encola lo vencido; el envío corre en {@code avisosExecutor}. */
    @Scheduled(fixedDelayString = "${nexa.avisos-pendientes.intervalo-ms:5000}")
    public void procesar() {
        LocalDateTime ahora = LocalDateTime.now();
        Query candidatos = Query.query(new Criteria().orOperator(
                Criteria.where("estado").is("PENDIENTE").and("proximoIntento").lte(ahora),
                Criteria.where("estado").is("EN_ENVIO").and("bloqueadoHasta").lt(ahora))).limit(50);
        candidatos.fields().include("_id");
        List<Pendiente> pendientes = mongo.find(candidatos, Pendiente.class, COLECCION);
        for (Pendiente pendiente : pendientes) {
            if (!encolar(pendiente.id())) {
                break; // cola llena: el resto espera al próximo barrido
            }
        }
    }

    /** false si la cola de envíos está llena; el aviso sigue PENDIENTE y lo recoge el barrido. */
    private boolean encolar(String id) {
        try {
            envios.execute(() -> despachar(id));
            return true;
        } catch (RejectedExecutionException e) {
            log.warn("Cola de avisos llena; {} queda para el próximo barrido", id);
            return false;
        }
    }

    private static void despuesDelCommit(Runnable accion) {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    accion.run();
                }
            });
        } else {
            accion.run();
        }
    }

    public void despachar(String id) {
        LocalDateTime ahora = LocalDateTime.now();
        Query disponible = Query.query(new Criteria().andOperator(Criteria.where("_id").is(id),
                new Criteria().orOperator(Criteria.where("estado").is("PENDIENTE")
                                .and("proximoIntento").lte(ahora),
                        Criteria.where("estado").is("EN_ENVIO").and("bloqueadoHasta").lt(ahora))));
        Pendiente tomado = mongo.findAndModify(disponible,
                new Update().set("estado", "EN_ENVIO").set("bloqueadoHasta", ahora.plusMinutes(10))
                        .inc("intentos", 1),
                org.springframework.data.mongodb.core.FindAndModifyOptions.options().returnNew(true),
                Pendiente.class, COLECCION);
        if (tomado == null) return;
        try {
            Servicio servicio = servicios.findById(tomado.servicioId()).orElse(null);
            if (servicio != null && vigente(servicio, Tipo.valueOf(tomado.tipo()))) {
                enviar(servicio, Tipo.valueOf(tomado.tipo()), tomado.destinatarios());
            }
            mongo.updateFirst(Query.query(Criteria.where("_id").is(id).and("estado").is("EN_ENVIO")),
                    new Update().set("estado", "ENVIADO").unset("bloqueadoHasta"), COLECCION);
        } catch (RuntimeException e) {
            log.warn("Se reintentará el aviso {}", id, e);
            long segundos = Math.min(300, 1L << Math.min(8, tomado.intentos()));
            mongo.updateFirst(Query.query(Criteria.where("_id").is(id).and("estado").is("EN_ENVIO")),
                    new Update().set("estado", "PENDIENTE")
                            .set("proximoIntento", LocalDateTime.now().plusSeconds(segundos))
                            .unset("bloqueadoHasta"), COLECCION);
        }
    }

    private static boolean vigente(Servicio s, Tipo tipo) {
        return switch (tipo) {
            case ACEPTADO, LLEGADA -> s.getEstado() == EstadoServicio.ACEPTADO;
            case INICIADO -> s.getEstado() == EstadoServicio.EN_CURSO;
            case FINALIZADO -> s.getEstado() == EstadoServicio.FINALIZADO;
            case CANCELADO -> s.getEstado() == EstadoServicio.CANCELADO;
            case DEUDA -> s.getEstado() == EstadoServicio.CANCELADO && s.getCargoCancelacion() > 0;
        };
    }

    private void enviar(Servicio s, Tipo tipo, List<ObjectId> destinatarios) {
        if (tipo != Tipo.DEUDA) tiempoReal.notificarCambioEstadoServicio(s);
        switch (tipo) {
            case ACEPTADO -> {
                tiempoReal.notificarSolicitudRetirada(s.getId(), "TOMADO");
                push.ejecutarConfirmado(() -> {
                    push.viajeAceptado(s);
                    push.solicitudRetiradaA(s, "TOMADO", destinatarios);
                });
            }
            case LLEGADA -> push.ejecutarConfirmado(() -> push.conductorLlego(s));
            case INICIADO -> { }
            case FINALIZADO -> push.ejecutarConfirmado(() -> push.viajeFinalizado(s));
            case CANCELADO -> {
                if (s.getConductor() == null) tiempoReal.notificarSolicitudRetirada(s.getId(), "CANCELADO");
                push.ejecutarConfirmado(() -> {
                    push.viajeCancelado(s);
                    if (s.getConductor() == null) push.solicitudRetiradaA(s, "CANCELADO", destinatarios);
                });
            }
            case DEUDA -> deudas.enviarAvisoDeuda(s);
        }
    }

    public enum Tipo { ACEPTADO, LLEGADA, INICIADO, FINALIZADO, CANCELADO, DEUDA }

    public record Pendiente(@org.springframework.data.annotation.Id String id, String servicioId, String tipo, String estado,
                           LocalDateTime proximoIntento, LocalDateTime bloqueadoHasta, int intentos,
                           List<ObjectId> destinatarios) { }
}
