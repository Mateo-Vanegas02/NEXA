package com.example.MotvirsWeb.aplicacion.verificacion;

import com.example.MotvirsWeb.dominio.modelo.AuditoriaVerificacion;
import com.example.MotvirsWeb.dominio.modelo.AuditoriaVerificacion.Accion;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.dominio.modelo.Vehiculo;
import com.example.MotvirsWeb.dominio.repositorio.AuditoriaVerificacionRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.example.MotvirsWeb.dominio.repositorio.VehiculoRepository;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificacionException.Tipo;
import com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Orquesta la verificación de un conductor y su aprobación. Reglas:
 * - la verificación (automática o manual) nunca cambia el estado del conductor;
 * - aprobar exige que la última verificación concluyente sea VERIFIED (configurable);
 * - toda verificación y decisión queda en auditoria_verificacion.
 */
@Service
public class VerificacionConductorService {

    private static final Logger log = LoggerFactory.getLogger(VerificacionConductorService.class);

    public record EstadoVerificacion(String email, String estadoValidacion, String placa, String documentoEnmascarado,
                                     String proveedor, AuditoriaVerificacion ultimaVerificacion,
                                     AuditoriaVerificacion decision, List<AuditoriaVerificacion> historial,
                                     String revisionMensaje, java.time.LocalDate revisionPlazo) {
    }

    private final UsuarioRepository usuarioRepository;
    private final VehiculoRepository vehiculoRepository;
    private final AuditoriaVerificacionRepository auditoriaRepository;
    private final DriverVerificationProvider provider;
    private final NotificadorTiempoReal notificadorTiempoReal;
    private final boolean exigirVerificado;
    /** Fuente registrada en la auditoría cuando decide un administrador (coincide con ManualVerificationProvider). */
    public static final String FUENTE_MANUAL = "MANUAL";

    private final LimitadorTasa limitador = new LimitadorTasa(20, 60_000);

    public VerificacionConductorService(UsuarioRepository usuarioRepository, VehiculoRepository vehiculoRepository,
                                        AuditoriaVerificacionRepository auditoriaRepository,
                                        DriverVerificationProvider provider, NotificadorTiempoReal notificadorTiempoReal,
                                        @Value("${verification.require-verified-to-approve:true}") boolean exigirVerificado) {
        this.usuarioRepository = usuarioRepository;
        this.vehiculoRepository = vehiculoRepository;
        this.auditoriaRepository = auditoriaRepository;
        this.provider = provider;
        this.notificadorTiempoReal = notificadorTiempoReal;
        this.exigirVerificado = exigirVerificado;
    }

    public EstadoVerificacion estado(String email) {
        Conductor c = conductor(email);
        List<AuditoriaVerificacion> hist = auditoriaRepository.findTop20ByConductorEmailOrderByFechaDesc(c.getEmail());
        AuditoriaVerificacion ultima = hist.stream().filter(VerificacionConductorService::esVerificacion).findFirst().orElse(null);
        AuditoriaVerificacion decision = hist.stream().filter(a -> !esVerificacion(a)).findFirst().orElse(null);
        return new EstadoVerificacion(c.getEmail(), c.getEstadoValidacion().name(), placaDe(c),
                ValidadorEntradas.enmascarar(String.valueOf(c.getLicencia())), provider.nombre(), ultima, decision, hist,
                c.getRevisionMensaje(), c.getRevisionPlazo());
    }

    /** Consulta la fuente configurada. Con fuente caída/manual el resultado es UNAVAILABLE y se completa a mano. */
    public AuditoriaVerificacion verificar(String email, String adminEmail, String ownerDocument) {
        if (!limitador.permitir(adminEmail)) {
            throw new VerificacionException(Tipo.LIMITE_EXCEDIDO, "Demasiadas verificaciones, intente en un minuto");
        }
        String owner = ownerDocument == null || ownerDocument.isBlank() ? null : ValidadorEntradas.documento(ownerDocument);
        Conductor c = conductor(email);
        String placaRaw = placaDe(c);
        String licencia = String.valueOf(c.getLicencia());

        VerificationResult rPlaca = ejecutar(() -> provider.verifyPlate(ValidadorEntradas.placa(placaRaw), owner),
                "Placa ausente o con formato no válido");
        VerificationResult rDoc = ejecutar(() -> provider.verifyDriver(ValidadorEntradas.documento(licencia)),
                "Licencia con formato no válido");

        AuditoriaVerificacion a = base(c, Accion.VERIFICACION_AUTOMATICA, adminEmail)
                .resultado(combinar(rPlaca, rDoc).name())
                .resultadoPlaca(rPlaca.status().name())
                .resultadoDocumento(rDoc.status().name())
                .fuente(provider.nombre())
                .motivo(rPlaca.detalle())
                .build();
        log.info("Verificación conductor={} resultado={} fuente={}", ValidadorEntradas.enmascarar(c.getEmail()),
                a.getResultado(), a.getFuente());
        return auditoriaRepository.save(a);
    }

    /** El admin revisó los documentos subidos y marca el resultado a mano. */
    public AuditoriaVerificacion marcarManual(String email, String adminEmail, VerificationStatus resultado, String nota) {
        if (resultado == null || resultado == VerificationStatus.UNAVAILABLE) {
            throw new EntradaInvalidaException("Resultado manual inválido");
        }
        String motivo = ValidadorEntradas.motivo(nota);
        Conductor c = conductor(email);
        AuditoriaVerificacion a = base(c, Accion.VERIFICACION_MANUAL, adminEmail)
                .resultado(resultado.name()).resultadoPlaca(resultado.name()).resultadoDocumento(resultado.name())
                .fuente(FUENTE_MANUAL).motivo(motivo).build();
        return auditoriaRepository.save(a);
    }

    /** Aprueba o rechaza. Rechazar exige motivo; aprobar exige verificación VERIFIED vigente (si está activado). */
    public AuditoriaVerificacion decidir(String email, String adminEmail, boolean aprobar, String motivoRaw) {
        String motivo = aprobar ? ValidadorEntradas.motivoOpcional(motivoRaw) : ValidadorEntradas.motivo(motivoRaw);
        Conductor c = conductor(email);
        if (c.getEstadoValidacion() != EstadoValidacion.PENDIENTE && c.getEstadoValidacion() != EstadoValidacion.EN_REVISION) {
            throw new VerificacionException(Tipo.ESTADO_INVALIDO, "El conductor no está pendiente de aprobación");
        }
        String vigente = resultadoVigente(c);
        if (aprobar && exigirVerificado && !VerificationStatus.VERIFIED.name().equals(vigente)) {
            throw new VerificacionException(Tipo.NO_VERIFICADO,
                    "Se requiere una verificación exitosa (automática o manual) antes de aprobar");
        }
        c.setEstadoValidacion(aprobar ? EstadoValidacion.APROBADO : EstadoValidacion.RECHAZADO);
        c.setRevisionMensaje(null);
        c.setRevisionPlazo(null);
        usuarioRepository.save(c);
        AuditoriaVerificacion a = base(c, aprobar ? Accion.APROBADO : Accion.RECHAZADO, adminEmail)
                .resultado(vigente == null ? "SIN_VERIFICAR" : vigente)
                .fuente(provider.nombre()).motivo(motivo).build();
        a = auditoriaRepository.save(a);
        if (aprobar) {
            try {
                notificadorTiempoReal.notificarNuevoRegistroAdmin(c);
            } catch (Exception e) {
                log.warn("No se pudo notificar por socket: {}", e.getClass().getSimpleName());
            }
        }
        return a;
    }

    // ── internos ──

    private String resultadoVigente(Conductor c) {
        String placa = placaDe(c);
        return auditoriaRepository.findTop20ByConductorEmailOrderByFechaDesc(c.getEmail()).stream()
                .filter(VerificacionConductorService::esVerificacion)
                .filter(a -> !VerificationStatus.UNAVAILABLE.name().equals(a.getResultado()))
                .filter(a -> a.getPlaca() == null || a.getPlaca().equals(placa))
                .map(AuditoriaVerificacion::getResultado)
                .findFirst().orElse(null);
    }

    private static boolean esVerificacion(AuditoriaVerificacion a) {
        return a.getAccion() == Accion.VERIFICACION_AUTOMATICA || a.getAccion() == Accion.VERIFICACION_MANUAL;
    }

    static VerificationStatus combinar(VerificationResult a, VerificationResult b) {
        List<VerificationStatus> s = List.of(a.status(), b.status());
        if (s.contains(VerificationStatus.NOT_FOUND)) return VerificationStatus.NOT_FOUND;
        if (s.contains(VerificationStatus.MISMATCH)) return VerificationStatus.MISMATCH;
        if (s.stream().allMatch(x -> x == VerificationStatus.VERIFIED)) return VerificationStatus.VERIFIED;
        return VerificationStatus.UNAVAILABLE;
    }

    /** Cualquier fallo del proveedor o de validación se traduce a UNAVAILABLE: nunca se aprueba por error. */
    private VerificationResult ejecutar(java.util.function.Supplier<VerificationResult> llamada, String msgInvalido) {
        try {
            VerificationResult r = llamada.get();
            return r == null ? VerificationResult.unavailable(provider.nombre(), "Sin respuesta de la fuente") : r;
        } catch (EntradaInvalidaException e) {
            return VerificationResult.unavailable(provider.nombre(), msgInvalido);
        } catch (RuntimeException e) {
            log.warn("Proveedor de verificación falló: {}", e.getClass().getSimpleName());
            return VerificationResult.unavailable(provider.nombre(), "Fuente no disponible");
        }
    }

    private AuditoriaVerificacion.AuditoriaVerificacionBuilder base(Conductor c, Accion accion, String adminEmail) {
        return AuditoriaVerificacion.builder().conductorEmail(c.getEmail()).accion(accion).adminEmail(adminEmail)
                .placa(placaDe(c)).documentoEnmascarado(ValidadorEntradas.enmascarar(String.valueOf(c.getLicencia())))
                .fecha(LocalDateTime.now());
    }

    private Conductor conductor(String email) {
        if (email == null || email.length() > 100) {
            throw new EntradaInvalidaException("Email inválido");
        }
        return usuarioRepository.findConductorByEmail(email)
                .orElseThrow(() -> new VerificacionException(Tipo.NO_ENCONTRADO, "Conductor no encontrado"));
    }

    private String placaDe(Conductor c) {
        if (c.getId() == null) {
            return null;
        }
        return vehiculoRepository.findByConductorAsignado(c).stream()
                .filter(Vehiculo::isActivo).map(Vehiculo::getPlaca).findFirst().orElse(null);
    }
}
