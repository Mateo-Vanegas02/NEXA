package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import org.bson.types.ObjectId;

/** Bandeja persistente de avisos de transiciones. La inscripción participa en la transacción Mongo del viaje. */
@Slf4j
@Service
@RequiredArgsConstructor
public class AvisosPendientesService {
    private static final String COLECCION = "avisos_viaje_pendientes";
    private final MongoTemplate mongo;
    private final ServicioRepository servicios;
    private final NotificadorTiempoReal tiempoReal;
    private final AvisosService push;
    private final DeudaService deudas;

    public void registrar(String servicioId, Tipo tipo) {
        String id = servicioId + ":" + tipo;
        List<ObjectId> destinatarios = tipo == Tipo.ACEPTADO || tipo == Tipo.CANCELADO
                ? push.destinatariosRetirada(servicioId) : List.of();
        mongo.insert(new Pendiente(id, servicioId, tipo.name(), "PENDIENTE", LocalDateTime.now(), null, 0,
                        destinatarios == null ? List.of() : destinatarios),
                COLECCION);
    }

    @Scheduled(fixedDelayString = "${nexa.avisos-pendientes.intervalo-ms:5000}")
    public void procesar() {
        LocalDateTime ahora = LocalDateTime.now();
        Query candidatos = Query.query(new Criteria().orOperator(
                Criteria.where("estado").is("PENDIENTE").and("proximoIntento").lte(ahora),
                Criteria.where("estado").is("EN_ENVIO").and("bloqueadoHasta").lt(ahora))).limit(50);
        List<Pendiente> pendientes = mongo.find(candidatos, Pendiente.class, COLECCION);
        for (Pendiente pendiente : pendientes) {
            despachar(pendiente.id());
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
