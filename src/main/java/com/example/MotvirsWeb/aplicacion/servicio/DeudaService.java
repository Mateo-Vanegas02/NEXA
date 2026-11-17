package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.DeudaCancelacion;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.modelo.Usuario;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.bson.types.ObjectId;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.text.NumberFormat;
import java.time.LocalDateTime;
import java.util.Locale;
import java.util.Optional;

/**
 * Deuda del pasajero por cargos de cancelación. NEXA es solo efectivo, así que la deuda se cobra junto con el
 * próximo viaje: el pasajero la ve y la acepta antes de pedirlo, y al finalizar paga tarifa + deuda en un solo
 * monto. El conductor solo ve el total a cobrar; el desglose lo ve el administrador. También puede pagarla aparte
 * (un administrador confirma) o condonarse. Solo puede existir una deuda por pasajero a la vez.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DeudaService {

    private final UsuarioRepository usuarioRepository;
    private final ServicioRepository servicioRepository;
    private final MongoTemplate mongoTemplate;
    private final com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo correo;

    public static final String METODO_EFECTIVO = "EFECTIVO";
    /** Se cobró en efectivo junto con el siguiente viaje del pasajero. */
    public static final String METODO_EN_VIAJE = "COBRADO_EN_VIAJE";
    static final int MOTIVO_MIN = 5;
    static final int MOTIVO_MAX = 300;

    /** Deuda vigente del pasajero, leída de la base (no del objeto de la sesión). */
    public Optional<DeudaCancelacion> deudaDe(ObjectId pasajeroId) {
        return usuarioRepository.findById(pasajeroId.toString())
                .filter(Pasajero.class::isInstance)
                .map(u -> ((Pasajero) u).getDeuda());
    }

    /** Por qué se generó el cargo, en palabras para el pasajero (según si el conductor ya había llegado). */
    public String motivoDe(DeudaCancelacion deuda) {
        boolean conductorYaLlego = deuda != null && deuda.getServicioId() != null
                && servicioRepository.findById(deuda.getServicioId()).map(s -> s.getFechaLlegada() != null).orElse(false);
        return conductorYaLlego
                ? "Cancelaste cuando el conductor ya había llegado al punto de recogida"
                : "Cancelaste después de que un conductor aceptó tu viaje";
    }

    /**
     * Deuda que se sumará al viaje que el pasajero está pidiendo. Si debe algo y todavía no lo aceptó, se responde
     * 402 con el monto para que la app se lo muestre y vuelva a pedir el viaje con {@code aceptaDeuda}.
     */
    public Optional<DeudaCancelacion> deudaACobrarEnViaje(Pasajero pasajero, boolean aceptada) {
        Optional<DeudaCancelacion> deuda = deudaDe(pasajero.getId());
        if (deuda.isPresent() && !aceptada) {
            throw new ResponseStatusException(HttpStatus.PAYMENT_REQUIRED,
                    "Tienes una deuda de " + pesos(deuda.get().getMonto())
                            + " por la cancelación de un viaje anterior. Se sumará al pago en efectivo de este viaje.");
        }
        return deuda;
    }

    /**
     * Cobra con el viaje que acaba de terminar la deuda que el pasajero aceptó al pedirlo. El descuento de la
     * deuda es atómico y condicional a que siga siendo la misma: si un administrador la cobró o la condonó entre
     * tanto, no se cobra dos veces y se devuelve 0.
     *
     * @return lo que se cobró de la deuda (0 si no había o ya estaba resuelta)
     */
    public long cobrarEnViaje(Servicio viaje, LocalDateTime ahora) {
        if (viaje == null || viaje.getDeudaPorCobrar() <= 0 || viaje.getDeudaServicioId() == null
                || viaje.getPasajero() == null || viaje.getPasajero().getId() == null) {
            return 0;
        }
        Query esaDeuda = Query.query(Criteria.where("_id").is(viaje.getPasajero().getId())
                .and("deuda.servicioId").is(viaje.getDeudaServicioId()));
        if (mongoTemplate.updateFirst(esaDeuda, new Update().unset("deuda"), Usuario.class).getModifiedCount() == 0) {
            log.info("La deuda del servicio {} ya no estaba pendiente: no se cobra con el viaje {}",
                    viaje.getDeudaServicioId(), viaje.getId());
            return 0;
        }
        servicioRepository.findById(viaje.getDeudaServicioId())
                .ifPresent(s -> marcarPagado(s, ahora, METODO_EN_VIAJE, "Cobrado en efectivo con el viaje " + viaje.getId()));
        return viaje.getDeudaPorCobrar();
    }

    /**
     * Registra la deuda de forma atómica: solo se crea si el pasajero no tiene otra.
     *
     * @return false si ya había una deuda (no se registra la nueva)
     */
    public boolean registrar(ObjectId pasajeroId, String servicioId, long monto, LocalDateTime ahora) {
        Query sinDeuda = Query.query(Criteria.where("_id").is(pasajeroId).and("deuda").exists(false));
        Update poner = new Update().set("deuda", new DeudaCancelacion(servicioId, monto, ahora));
        boolean creada = mongoTemplate.updateFirst(sinDeuda, poner, Usuario.class).getModifiedCount() > 0;
        if (!creada) {
            log.warn("El pasajero {} ya tiene una deuda: no se registra el cargo de {} del servicio {}",
                    pasajeroId, monto, servicioId);
            return false;
        }
        return true;
    }

    /** Lo llama la bandeja persistente después de confirmar la cancelación. */
    public void enviarAvisoDeuda(Servicio servicio) {
        if (servicio.getPasajero() == null || servicio.getPasajero().getId() == null) return;
        usuarioRepository.findById(servicio.getPasajero().getId().toString())
                .filter(Pasajero.class::isInstance).map(Pasajero.class::cast)
                .ifPresent(p -> correo.enviarDeudaSeCobraEnProximoViaje(
                        p.getEmail(), p.getNombreCompleto(), servicio.getCargoCancelacion()));
    }

    /**
     * Un administrador confirma el pago: se libera al pasajero y, si la plataforma aún no se lo
     * había reconocido al conductor (no hubo llegada verificada), se le acredita ahora.
     */
    public DeudaCancelacion confirmarPago(String pasajeroId, LocalDateTime ahora) {
        return confirmarPago(pasajeroId, ahora, METODO_EFECTIVO, null);
    }

    /** Igual que {@link #confirmarPago(String, LocalDateTime)} dejando el método de pago y una nota opcional. */
    public DeudaCancelacion confirmarPago(String pasajeroId, LocalDateTime ahora, String metodo, String nota) {
        if (!METODO_EFECTIVO.equals(metodo)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Por ahora solo se recibe pago en efectivo");
        }
        String notaLimpia = nota == null || nota.isBlank() ? null : nota.strip();
        Pasajero pasajero = usuarioRepository.findById(pasajeroId)
                .filter(Pasajero.class::isInstance).map(Pasajero.class::cast)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Pasajero no encontrado"));
        DeudaCancelacion deuda = pasajero.getDeuda();
        if (deuda == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El pasajero no tiene deuda pendiente");
        }
        mongoTemplate.updateFirst(Query.query(Criteria.where("_id").is(pasajero.getId())),
                new Update().unset("deuda"), Usuario.class);
        servicioRepository.findById(deuda.getServicioId()).ifPresent(s -> marcarPagado(s, ahora, metodo, notaLimpia));
        return deuda;
    }

    /**
     * Un administrador perdona la deuda (p. ej. la cancelación fue por culpa del conductor o de la app). El
     * pasajero queda libre y el motivo queda registrado en el servicio junto con quién lo autorizó. Lo que ya se le
     * reconoció al conductor no se toca: lo absorbe la plataforma.
     */
    public DeudaCancelacion condonar(String pasajeroId, String adminEmail, String motivo, LocalDateTime ahora) {
        String motivoLimpio = motivo == null ? "" : motivo.strip();
        if (motivoLimpio.length() < MOTIVO_MIN || motivoLimpio.length() > MOTIVO_MAX) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Escribe el motivo de la condonación (entre " + MOTIVO_MIN + " y " + MOTIVO_MAX + " caracteres)");
        }
        Pasajero pasajero = usuarioRepository.findById(pasajeroId)
                .filter(Pasajero.class::isInstance).map(Pasajero.class::cast)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Pasajero no encontrado"));
        DeudaCancelacion deuda = pasajero.getDeuda();
        if (deuda == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El pasajero no tiene deuda pendiente");
        }
        // Solo si sigue siendo esa misma deuda: si otro administrador la cerró entre tanto, no se repite
        Query esaDeuda = Query.query(Criteria.where("_id").is(pasajero.getId())
                .and("deuda.servicioId").is(deuda.getServicioId()));
        var resultado = mongoTemplate.updateFirst(esaDeuda, new Update().unset("deuda"), Usuario.class);
        if (resultado.getModifiedCount() == 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "La deuda ya fue resuelta por otro administrador");
        }
        servicioRepository.findById(deuda.getServicioId()).ifPresent(s -> {
            s.setCargoCondonadoEn(ahora);
            s.setCargoCondonadoPor(adminEmail);
            s.setCargoMotivoCondonacion(motivoLimpio);
            servicioRepository.save(s);
        });
        log.info("Deuda de {} del servicio {} condonada por {}", deuda.getMonto(), deuda.getServicioId(), adminEmail);
        avisar(() -> correo.enviarDeudaCondonada(pasajero.getEmail(), pasajero.getNombreCompleto(),
                deuda.getMonto(), motivoLimpio));
        return deuda;
    }

    /** Deudas condonadas desde {@code desde} (más recientes primero, máx. 100). */
    public java.util.List<CondonadaResumen> listarCondonadas(LocalDateTime desde) {
        Query q = Query.query(Criteria.where("cargoCondonadoEn").gte(desde))
                .with(org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "cargoCondonadoEn"))
                .limit(100);
        return mongoTemplate.find(q, Servicio.class).stream()
                .filter(s -> s.getPasajero() != null)
                .map(s -> new CondonadaResumen(s.getPasajero().getIdString(), s.getPasajero().getNombre(),
                        s.getPasajero().getEmail(), s.getId(), s.getCargoCancelacion(), s.getFechaCancelacion(),
                        s.getCargoCondonadoEn(), s.getCargoCondonadoPor(), s.getCargoMotivoCondonacion()))
                .toList();
    }

    /** Cargos por cancelación del pasajero, del más reciente al más antiguo (máx. 50). */
    public java.util.List<CargoHistorial> historialDe(ObjectId pasajeroId) {
        String pendiente = deudaDe(pasajeroId).map(DeudaCancelacion::getServicioId).orElse(null);
        var pagina = org.springframework.data.domain.PageRequest.of(0, 50,
                org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "fechaCancelacion"));
        return servicioRepository.findByPasajeroIdAndCargoCancelacionGreaterThan(pasajeroId, 0, pagina).stream()
                .map(s -> {
                    if (s.getCargoPagadoEn() != null) {
                        return new CargoHistorial(s.getId(), s.getCargoCancelacion(), s.getFechaCancelacion(), "PAGADO",
                                s.getCargoPagadoEn(), s.getCargoMetodoPago());
                    }
                    if (s.getCargoCondonadoEn() != null) {
                        return new CargoHistorial(s.getId(), s.getCargoCancelacion(), s.getFechaCancelacion(), "CONDONADO",
                                s.getCargoCondonadoEn(), s.getCargoMotivoCondonacion());
                    }
                    String estado = s.getId() != null && s.getId().equals(pendiente) ? "PENDIENTE" : "REGISTRADO";
                    return new CargoHistorial(s.getId(), s.getCargoCancelacion(), s.getFechaCancelacion(), estado, null, null);
                })
                .toList();
    }

    /** Pasajeros con deuda pendiente, para que el administrador confirme los pagos. */
    public java.util.List<DeudorResumen> listarDeudores() {
        return mongoTemplate.find(Query.query(Criteria.where("deuda").exists(true)), Pasajero.class).stream()
                .map(p -> new DeudorResumen(p.getId().toString(), p.getNombreCompleto(), p.getEmail(),
                        p.getTelefono(), p.getDeuda().getServicioId(), p.getDeuda().getMonto(),
                        p.getDeuda().getCreadaEn()))
                .toList();
    }

    /** Deudas ya pagadas desde {@code desde} (más recientes primero, máx. 100). */
    public java.util.List<PagadaResumen> listarPagadas(LocalDateTime desde) {
        Query q = Query.query(Criteria.where("cargoPagadoEn").gte(desde))
                .with(org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "cargoPagadoEn"))
                .limit(100);
        return mongoTemplate.find(q, Servicio.class).stream()
                .filter(s -> s.getPasajero() != null)
                .map(s -> new PagadaResumen(s.getPasajero().getIdString(), s.getPasajero().getNombre(),
                        s.getPasajero().getEmail(), s.getId(), s.getCargoCancelacion(),
                        s.getFechaCancelacion(), s.getCargoPagadoEn()))
                .toList();
    }

    /** Cifras de las tarjetas del panel: lo pendiente y lo cobrado en los últimos 30 días. */
    public static ResumenDeudas resumir(java.util.List<DeudorResumen> pendientes,
            java.util.List<PagadaResumen> pagadas, LocalDateTime ahora) {
        long total = pendientes.stream().mapToLong(DeudorResumen::monto).sum();
        long nuevas = pendientes.stream().filter(d -> d.creadaEn() != null && d.creadaEn().isAfter(ahora.minusDays(7))).count();
        long recaudado = pagadas.stream().mapToLong(PagadaResumen::monto).sum();
        return new ResumenDeudas(pendientes.size(), total, nuevas, pagadas.size(), recaudado);
    }

    /** Fila del historial de cargos del pasajero. {@code estado}: PENDIENTE, PAGADO, CONDONADO o REGISTRADO. */
    public record CargoHistorial(String servicioId, long monto, LocalDateTime canceladoEn, String estado,
            LocalDateTime resueltoEn, String detalle) {
    }

    public record CondonadaResumen(String pasajeroId, String nombre, String email, String servicioId, long monto,
            LocalDateTime canceladoEn, LocalDateTime condonadaEn, String condonadaPor, String motivo) {
    }

    public record PagadaResumen(String pasajeroId, String nombre, String email, String servicioId, long monto,
            LocalDateTime canceladoEn, LocalDateTime pagadaEn) {
    }

    public record ResumenDeudas(long pasajerosConDeuda, long totalPorCobrar, long nuevasSemana,
            long pagadas30Dias, long recaudado30Dias) {
    }

    /** Fila del listado de deudores (sin datos sensibles). */
    public record DeudorResumen(String pasajeroId, String nombre, String email, String telefono,
            String servicioId, long monto, LocalDateTime creadaEn) {
    }

    private void marcarPagado(Servicio s, LocalDateTime ahora, String metodo, String nota) {
        s.setCargoPagadoEn(ahora);
        s.setCargoMetodoPago(metodo);
        s.setCargoNotaPago(nota);
        s.setCargoAcreditadoConductor(true);
        servicioRepository.save(s);
    }

    /** Un correo que no sale nunca debe tumbar la operación que lo dispara. */
    private void avisar(Runnable envio) {
        try {
            envio.run();
        } catch (RuntimeException e) {
            log.warn("No se pudo enviar el correo de la deuda", e);
        }
    }

    private static String pesos(long monto) {
        return "$" + NumberFormat.getIntegerInstance(Locale.forLanguageTag("es-CO")).format(monto);
    }
}
