package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorPush;
import com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import lombok.extern.slf4j.Slf4j;
import org.bson.types.ObjectId;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.FindAndModifyOptions;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.index.Index;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.Executor;
import java.util.concurrent.RejectedExecutionException;

/**
 * Bandeja persistente de avisos de transiciones del viaje.
 *
 * <ul>
 *   <li>La inscripción participa en la transacción Mongo del viaje: si la transición se revierte, no hay aviso.</li>
 *   <li>Tras el commit el envío corre en {@code avisosExecutor}, nunca en el hilo de la petición ni en el de
 *       {@code @Scheduled}. El barrido periódico solo recoge lo que falló o quedó sin enviar tras un reinicio.</li>
 *   <li>Quien envía primero reclama el aviso con un {@code lease} propio (UUID) y un vencimiento. Toda escritura
 *       posterior (ENVIADO, reprogramar, FALLIDO) exige ese mismo lease: un proceso que perdió la reclamación no
 *       puede pisar al que la tomó después.</li>
 *   <li>Entrega al menos una vez: si el proveedor aceptó el aviso y el proceso cae antes de marcarlo ENVIADO, se
 *       repite. El push lleva un id de evento estable para que la app lo deduplique. El mensaje STOMP se envía una
 *       sola vez por aviso y un fallo parcial de FCM se reintenta solo con los tokens que fallaron.</li>
 *   <li>Tras {@code nexa.avisos-pendientes.max-intentos} el aviso queda FALLIDO, sin más reintentos.</li>
 * </ul>
 */
@Slf4j
@Service
public class AvisosPendientesService {
    static final String COLECCION = "avisos_viaje_pendientes";
    static final String PENDIENTE = "PENDIENTE";
    static final String EN_ENVIO = "EN_ENVIO";
    static final String ENVIADO = "ENVIADO";
    static final String FALLIDO = "FALLIDO";

    private final MongoTemplate mongo;
    private final ServicioRepository servicios;
    private final NotificadorTiempoReal tiempoReal;
    private final AvisosService push;
    private final DeudaService deudas;
    private final Executor envios;
    private final int maxIntentos;
    private final Duration bloqueo;

    @Value("${nexa.avisos-pendientes.crear-indices:false}")
    private boolean crearIndices;
    @Value("${nexa.avisos-pendientes.retencion-dias:7}")
    private long retencionDias;

    @Autowired
    public AvisosPendientesService(MongoTemplate mongo, ServicioRepository servicios, NotificadorTiempoReal tiempoReal,
                                   AvisosService push, DeudaService deudas,
                                   @Qualifier("avisosExecutor") Executor envios,
                                   @Value("${nexa.avisos-pendientes.max-intentos:8}") int maxIntentos,
                                   @Value("${nexa.avisos-pendientes.bloqueo-segundos:600}") long bloqueoSegundos) {
        this.mongo = mongo;
        this.servicios = servicios;
        this.tiempoReal = tiempoReal;
        this.push = push;
        this.deudas = deudas;
        this.envios = envios;
        this.maxIntentos = Math.max(1, maxIntentos);
        this.bloqueo = Duration.ofSeconds(Math.max(1, bloqueoSegundos));
    }

    /** Valores por defecto: 8 intentos y bloqueo de 10 minutos. */
    public AvisosPendientesService(MongoTemplate mongo, ServicioRepository servicios, NotificadorTiempoReal tiempoReal,
                                   AvisosService push, DeudaService deudas, Executor envios) {
        this(mongo, servicios, tiempoReal, push, deudas, envios, 8, 600);
    }

    public void registrar(String servicioId, Tipo tipo) {
        String id = servicioId + ":" + tipo;
        List<ObjectId> destinatarios = tipo == Tipo.ACEPTADO || tipo == Tipo.CANCELADO
                ? push.destinatariosRetirada(servicioId) : List.of();
        mongo.insert(Pendiente.nuevo(id, servicioId, tipo, destinatarios == null ? List.of() : destinatarios),
                COLECCION);
        despuesDelCommit(() -> encolar(id));
    }

    /** Barrido de respaldo: encola lo vencido; el envío corre en {@code avisosExecutor}. */
    @Scheduled(fixedDelayString = "${nexa.avisos-pendientes.intervalo-ms:5000}")
    public void procesar() {
        Query candidatos = reclamables(LocalDateTime.now()).limit(50).with(Sort.by("proximoIntento"));
        candidatos.fields().include("_id");
        // Solo los ids (documento crudo: el record Pendiente no admite campos ausentes como intentos)
        for (org.bson.Document pendiente : mongo.find(candidatos, org.bson.Document.class, COLECCION)) {
            if (!encolar(pendiente.getString("_id"))) {
                break; // cola llena: el resto espera al próximo barrido
            }
        }
    }

    /** Reclama el aviso (si nadie más lo tiene) y lo envía. Público para el barrido y las pruebas. */
    public void despachar(String id) {
        LocalDateTime ahora = LocalDateTime.now();
        String lease = UUID.randomUUID().toString();
        Query disponible = reclamables(ahora).addCriteria(Criteria.where("_id").is(id));
        Pendiente tomado = mongo.findAndModify(disponible,
                new Update().set("estado", EN_ENVIO).set("lease", lease)
                        .set("bloqueadoHasta", ahora.plus(bloqueo)).inc("intentos", 1),
                FindAndModifyOptions.options().returnNew(true), Pendiente.class, COLECCION);
        if (tomado == null) {
            return; // otro proceso lo tiene o ya terminó
        }
        Tipo tipo = Tipo.valueOf(tomado.tipo());
        boolean stompEnviado = tomado.stompEnviado();
        List<String> tokensPendientes = tomado.tokensPendientes();
        try {
            Servicio servicio = servicios.findById(tomado.servicioId()).orElse(null);
            if (servicio != null && vigente(servicio, tipo)) {
                if (!stompEnviado) {
                    notificarTiempoReal(servicio, tipo, tomado.id());
                    stompEnviado = true;
                }
                enviarExternos(servicio, tipo, tomado.destinatarios(), tokensPendientes);
            }
            if (!cerrar(id, lease, new Update().set("estado", ENVIADO).set("enviadoEn", LocalDateTime.now())
                    .unset("bloqueadoHasta").unset("lease").unset("tokensPendientes"))) {
                log.info("La reclamación del aviso {} venció y la tomó otro proceso; no se marca", id);
            }
        } catch (NotificadorPush.EnvioIncompleto e) {
            reprogramar(tomado, lease, stompEnviado, List.copyOf(e.tokensFallidos()), e);
        } catch (RuntimeException e) {
            reprogramar(tomado, lease, stompEnviado, tokensPendientes, e);
        }
    }

    /** Crea los índices de la bandeja solo si se habilita (no se aplican en producción sin aprobación). */
    @EventListener(ApplicationReadyEvent.class)
    public void asegurarIndices() {
        if (!crearIndices) {
            return;
        }
        var indices = mongo.indexOps(COLECCION);
        indices.ensureIndex(new Index().on("estado", Sort.Direction.ASC).on("proximoIntento", Sort.Direction.ASC)
                .named("estado_proximoIntento"));
        indices.ensureIndex(new Index().on("enviadoEn", Sort.Direction.ASC)
                .expire(Duration.ofDays(Math.max(1, retencionDias))).named("ttl_enviadoEn"));
    }

    // ─────────────────────────── DETALLE ───────────────────────────

    private static Query reclamables(LocalDateTime ahora) {
        return Query.query(new Criteria().orOperator(
                Criteria.where("estado").is(PENDIENTE).and("proximoIntento").lte(ahora),
                Criteria.where("estado").is(EN_ENVIO).and("bloqueadoHasta").lt(ahora)));
    }

    /** Escritura final condicionada a la reclamación propia. false si otro proceso la tomó entretanto. */
    private boolean cerrar(String id, String lease, Update update) {
        return mongo.updateFirst(Query.query(Criteria.where("_id").is(id).and("estado").is(EN_ENVIO)
                .and("lease").is(lease)), update, COLECCION).getModifiedCount() == 1;
    }

    private void reprogramar(Pendiente tomado, String lease, boolean stompEnviado, List<String> tokensPendientes,
                             RuntimeException e) {
        String error = e.getClass().getSimpleName() + (e.getMessage() == null ? ""
                : ": " + e.getMessage().substring(0, Math.min(200, e.getMessage().length())));
        Update update = new Update().set("stompEnviado", stompEnviado).set("ultimoError", error)
                .unset("bloqueadoHasta").unset("lease");
        if (tokensPendientes == null || tokensPendientes.isEmpty()) {
            update.unset("tokensPendientes");
        } else {
            update.set("tokensPendientes", tokensPendientes);
        }
        boolean agotado = tomado.intentos() >= maxIntentos;
        if (agotado) {
            update.set("estado", FALLIDO);
        } else {
            long segundos = Math.min(300, 1L << Math.min(8, tomado.intentos()));
            update.set("estado", PENDIENTE).set("proximoIntento", LocalDateTime.now().plusSeconds(segundos));
        }
        if (!cerrar(tomado.id(), lease, update)) {
            log.info("La reclamación del aviso {} venció y la tomó otro proceso; no se reprograma", tomado.id());
        } else if (agotado) {
            log.error("Aviso {} FALLIDO tras {} intentos: {}", tomado.id(), tomado.intentos(), error);
        } else {
            log.warn("Se reintentará el aviso {} (intento {} de {}): {}", tomado.id(), tomado.intentos(),
                    maxIntentos, error);
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

    private static boolean vigente(Servicio s, Tipo tipo) {
        return switch (tipo) {
            case ACEPTADO, LLEGADA -> s.getEstado() == EstadoServicio.ACEPTADO;
            case INICIADO -> s.getEstado() == EstadoServicio.EN_CURSO;
            case FINALIZADO -> s.getEstado() == EstadoServicio.FINALIZADO;
            case CANCELADO -> s.getEstado() == EstadoServicio.CANCELADO;
            case DEUDA -> s.getEstado() == EstadoServicio.CANCELADO && s.getCargoCancelacion() > 0;
        };
    }

    /** STOMP: una sola vez por aviso. */
    private void notificarTiempoReal(Servicio s, Tipo tipo, String avisoId) {
        if (tipo == Tipo.DEUDA) {
            return;
        }
        tiempoReal.notificarCambioEstadoServicio(s, avisoId);
        if (tipo == Tipo.ACEPTADO) {
            tiempoReal.notificarSolicitudRetirada(s.getId(), "TOMADO");
        } else if (tipo == Tipo.CANCELADO && s.getConductor() == null) {
            tiempoReal.notificarSolicitudRetirada(s.getId(), "CANCELADO");
        }
    }

    /** Push y correo, con confirmación del proveedor; en un reintento parcial, solo a los tokens que fallaron. */
    private void enviarExternos(Servicio s, Tipo tipo, List<ObjectId> destinatarios, Collection<String> soloTokens) {
        switch (tipo) {
            case ACEPTADO -> push.ejecutarConfirmado(soloTokens, () -> {
                push.viajeAceptado(s);
                push.solicitudRetiradaA(s, "TOMADO", destinatarios);
            });
            case LLEGADA -> push.ejecutarConfirmado(soloTokens, () -> push.conductorLlego(s));
            case INICIADO -> push.ejecutarConfirmado(soloTokens, () -> push.viajeIniciado(s));
            case FINALIZADO -> push.ejecutarConfirmado(soloTokens, () -> push.viajeFinalizado(s));
            case CANCELADO -> push.ejecutarConfirmado(soloTokens, () -> {
                push.viajeCancelado(s);
                if (s.getConductor() == null) push.solicitudRetiradaA(s, "CANCELADO", destinatarios);
            });
            case DEUDA -> deudas.enviarAvisoDeuda(s);
        }
    }

    public enum Tipo { ACEPTADO, LLEGADA, INICIADO, FINALIZADO, CANCELADO, DEUDA }

    public record Pendiente(@org.springframework.data.annotation.Id String id, String servicioId, String tipo,
                            String estado, LocalDateTime proximoIntento, LocalDateTime bloqueadoHasta, int intentos,
                            List<ObjectId> destinatarios, String lease, boolean stompEnviado,
                            List<String> tokensPendientes, String ultimoError, LocalDateTime enviadoEn) {

        static Pendiente nuevo(String id, String servicioId, Tipo tipo, List<ObjectId> destinatarios) {
            return new Pendiente(id, servicioId, tipo.name(), PENDIENTE, LocalDateTime.now(), null, 0, destinatarios,
                    null, false, null, null, null);
        }
    }
}
