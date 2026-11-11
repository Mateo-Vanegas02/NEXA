package com.example.MotvirsWeb.aplicacion.verificacion;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificacionException.Tipo;
import com.example.MotvirsWeb.dominio.modelo.AuditoriaVerificacion;
import com.example.MotvirsWeb.dominio.modelo.AuditoriaVerificacion.Accion;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.dominio.modelo.Rol;
import com.example.MotvirsWeb.dominio.regla.PlazoRevision;
import com.example.MotvirsWeb.dominio.repositorio.AuditoriaVerificacionRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;

/**
 * Estado EN_REVISION: el admin pide información adicional al conductor, que tiene N días hábiles
 * para responder. Si el plazo vence sin respuesta, la solicitud se rechaza sola. Todo queda en auditoría.
 */
@Service
public class RevisionConductorService {

    private static final Logger log = LoggerFactory.getLogger(RevisionConductorService.class);
    static final String SISTEMA = "sistema";

    private final UsuarioRepository usuarioRepository;
    private final AuditoriaVerificacionRepository auditoriaRepository;
    private final NotificadorCorreo correo;
    private final int diasHabiles;
    private final ZoneId zona;

    public RevisionConductorService(UsuarioRepository usuarioRepository, AuditoriaVerificacionRepository auditoriaRepository,
                                    NotificadorCorreo correo,
                                    @Value("${verification.review-business-days:15}") int diasHabiles,
                                    @Value("${nexa.zona-horaria:America/Bogota}") String zona) {
        this.usuarioRepository = usuarioRepository;
        this.auditoriaRepository = auditoriaRepository;
        this.correo = correo;
        this.diasHabiles = diasHabiles;
        this.zona = ZoneId.of(zona);
    }

    /** Pasa a EN_REVISION (o actualiza lo pedido) y avisa por correo. El plazo cuenta desde esta solicitud. */
    public AuditoriaVerificacion solicitarInformacion(String email, String adminEmail, String mensajeRaw) {
        String mensaje = ValidadorEntradas.motivo(mensajeRaw);
        Conductor c = conductor(email);
        if (c.getEstadoValidacion() != EstadoValidacion.PENDIENTE && c.getEstadoValidacion() != EstadoValidacion.EN_REVISION) {
            throw new VerificacionException(Tipo.ESTADO_INVALIDO, "Solo se puede pedir información a una solicitud en trámite");
        }
        LocalDate plazo = PlazoRevision.sumarDiasHabiles(hoy(), diasHabiles);
        c.setEstadoValidacion(EstadoValidacion.EN_REVISION);
        c.setRevisionMensaje(mensaje);
        c.setRevisionPlazo(plazo);
        usuarioRepository.save(c);
        AuditoriaVerificacion a = auditoriaRepository.save(base(c, Accion.SOLICITUD_INFO, adminEmail)
                .resultado("EN_REVISION").motivo(mensaje).build());
        correo.enviarSolicitudInformacion(c.getEmail(), c.getNombre_y_Apellido(), mensaje, plazo);
        return a;
    }

    /** El conductor respondió (por correo): vuelve a la cola de pendientes para decidir. */
    public AuditoriaVerificacion registrarRespuesta(String email, String adminEmail, String notaRaw) {
        String nota = ValidadorEntradas.motivoOpcional(notaRaw);
        Conductor c = conductor(email);
        if (c.getEstadoValidacion() != EstadoValidacion.EN_REVISION) {
            throw new VerificacionException(Tipo.ESTADO_INVALIDO, "El conductor no está en revisión");
        }
        c.setEstadoValidacion(EstadoValidacion.PENDIENTE);
        c.setRevisionMensaje(null);
        c.setRevisionPlazo(null);
        usuarioRepository.save(c);
        return auditoriaRepository.save(base(c, Accion.INFO_RECIBIDA, adminEmail).resultado("PENDIENTE").motivo(nota).build());
    }

    /** Rechaza las solicitudes EN_REVISION cuyo plazo ya venció. Devuelve cuántas rechazó. */
    public int vencerPlazos() {
        LocalDate hoy = hoy();
        int n = 0;
        for (var u : usuarioRepository.findByRolAndEstadoValidacion(Rol.CONDUCTOR, EstadoValidacion.EN_REVISION)) {
            if (!(u instanceof Conductor c) || !PlazoRevision.vencido(c.getRevisionPlazo(), hoy)) {
                continue;
            }
            try {
                c.setEstadoValidacion(EstadoValidacion.RECHAZADO);
                c.setRevisionMensaje(null);
                c.setRevisionPlazo(null);
                usuarioRepository.save(c);
                auditoriaRepository.save(base(c, Accion.RECHAZADO, SISTEMA).resultado("PLAZO_VENCIDO")
                        .motivo("No se recibió la información solicitada dentro del plazo").build());
                correo.enviarRechazoPorPlazo(c.getEmail(), c.getNombre_y_Apellido());
                n++;
            } catch (RuntimeException e) {
                log.error("No se pudo vencer el plazo de un conductor: {}", e.getClass().getSimpleName());
            }
        }
        return n;
    }

    private LocalDate hoy() {
        return LocalDate.now(zona);
    }

    private AuditoriaVerificacion.AuditoriaVerificacionBuilder base(Conductor c, Accion accion, String adminEmail) {
        return AuditoriaVerificacion.builder().conductorEmail(c.getEmail()).accion(accion).adminEmail(adminEmail)
                .documentoEnmascarado(ValidadorEntradas.enmascarar(String.valueOf(c.getLicencia())))
                .fuente("MANUAL").fecha(LocalDateTime.now());
    }

    private Conductor conductor(String email) {
        if (email == null || email.length() > 100) {
            throw new EntradaInvalidaException("Email inválido");
        }
        return usuarioRepository.findConductorByEmail(email)
                .orElseThrow(() -> new VerificacionException(Tipo.NO_ENCONTRADO, "Conductor no encontrado"));
    }
}
