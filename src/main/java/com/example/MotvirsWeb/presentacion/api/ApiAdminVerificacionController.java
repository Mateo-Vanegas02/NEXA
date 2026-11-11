package com.example.MotvirsWeb.presentacion.api;

import com.example.MotvirsWeb.dominio.modelo.AuditoriaVerificacion;
import com.example.MotvirsWeb.aplicacion.verificacion.EntradaInvalidaException;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificacionConductorService;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificacionConductorService.EstadoVerificacion;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificacionException;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificationStatus;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import com.example.MotvirsWeb.aplicacion.servicio.DocumentosConductorService;
import com.example.MotvirsWeb.dominio.modelo.DocumentoConductor;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * Verificación de conductores para el dashboard de admin. La ruta /api/admin/** ya exige ROLE_ADMIN en SecurityConfig;
 * @PreAuthorize es una segunda barrera. Los errores no exponen detalles internos.
 */
@RestController
@RequestMapping("/api/admin/verificacion")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class ApiAdminVerificacionController {

    private static final Logger log = LoggerFactory.getLogger(ApiAdminVerificacionController.class);

    private final VerificacionConductorService service;
    private final DocumentosConductorService documentosService;
    private final com.example.MotvirsWeb.aplicacion.verificacion.RevisionConductorService revision;
    private final com.example.MotvirsWeb.aplicacion.servicio.LecturaDocumentosService lecturaDocumentos;
    private final com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository usuarios;
    private final com.example.MotvirsWeb.dominio.repositorio.VehiculoRepository vehiculos;
    private final com.example.MotvirsWeb.aplicacion.servicio.VehiculoConductorService vehiculosConductor;

    public record VerificarRequest(@NotNull @Size(max = 100) String email, @Size(max = 12) String ownerDocument) {
    }

    public record ManualRequest(@NotNull @Size(max = 100) String email, @NotNull VerificationStatus resultado,
                                @NotNull @Size(max = 300) String nota) {
    }

    public record DecisionRequest(@NotNull @Size(max = 100) String email, boolean aprobar,
                                  @Size(max = 300) String motivo) {
    }

    public record InfoRequest(@NotNull @Size(max = 100) String email, @Size(max = 300) String mensaje) {
    }

    /** Foto de documento subida por el conductor, con el número que declaró para contrastarlos. */
    public record DocumentoResumen(String id, String tipo, String numeroDeclarado, String vehiculoId,
                                   String contentType, long tamano, LocalDateTime subidoEn) {
        static DocumentoResumen de(DocumentoConductor d) {
            return new DocumentoResumen(d.getId(), d.getTipo().name(), d.getNumeroDeclarado(), d.getVehiculoId(),
                    d.getContentType(), d.getTamano(), d.getSubidoEn());
        }
    }

    @GetMapping("/documentos")
    public List<DocumentoResumen> documentos(@RequestParam String email) {
        return documentosService.listarPorEmail(email).stream().map(DocumentoResumen::de).toList();
    }

    /** Lee con IA el número de la foto y lo contrasta con el declarado (a pedido, una foto a la vez). */
    @PostMapping("/documentos/{id}/leer")
    public com.example.MotvirsWeb.aplicacion.servicio.LecturaDocumentosService.Lectura leer(@PathVariable String id, Principal admin) {
        return lecturaDocumentos.leer(id, admin.getName());
    }

    public record VehiculoResumen(String id, String placa, String marca, String modelo, String color, boolean activo,
                                  boolean verificado, java.time.LocalDate fechaRegistro) {
    }

    @PostMapping("/vehiculos/{id}/aprobar")
    public Map<String, String> aprobarVehiculo(@PathVariable String id) {
        vehiculosConductor.aprobar(id);
        return Map.of("message", "Vehículo aprobado");
    }

    @GetMapping("/vehiculos")
    public List<VehiculoResumen> vehiculos(@RequestParam String email) {
        return usuarios.findConductorByEmail(email)
                .map(c -> vehiculos.findByConductorAsignado(c).stream()
                        .map(v -> new VehiculoResumen(v.getId(), v.getPlaca(), v.getMarca(), v.getModelo(), v.getColor(), v.isActivo(), v.estaVerificado(), v.getFechaRegistro()))
                        .toList())
                .orElse(List.of());
    }

    @GetMapping("/documentos/{id}/archivo")
    public ResponseEntity<InputStreamResource> archivo(@PathVariable String id) {
        return documentosService.abrir(id)
                .map(c -> ResponseEntity.ok()
                        .contentType(MediaType.parseMediaType(c.documento().getContentType()))
                        .contentLength(c.documento().getTamano())
                        .cacheControl(CacheControl.noStore().cachePrivate())
                        .header("X-Content-Type-Options", "nosniff")
                        .header("Content-Disposition", "inline")
                        .body(new InputStreamResource(c.flujo())))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping("/estado")
    public EstadoVerificacion estado(@RequestParam String email) {
        return service.estado(email);
    }

    @PostMapping("/verificar")
    public AuditoriaVerificacion verificar(@jakarta.validation.Valid @RequestBody VerificarRequest req, Principal admin) {
        return service.verificar(req.email(), admin.getName(), req.ownerDocument());
    }

    @PostMapping("/manual")
    public AuditoriaVerificacion manual(@jakarta.validation.Valid @RequestBody ManualRequest req, Principal admin) {
        return service.marcarManual(req.email(), admin.getName(), req.resultado(), req.nota());
    }

    @PostMapping("/decision")
    public AuditoriaVerificacion decision(@jakarta.validation.Valid @RequestBody DecisionRequest req, Principal admin) {
        return service.decidir(req.email(), admin.getName(), req.aprobar(), req.motivo());
    }

    @PostMapping("/solicitar-info")
    public AuditoriaVerificacion solicitarInfo(@jakarta.validation.Valid @RequestBody InfoRequest req, Principal admin) {
        return revision.solicitarInformacion(req.email(), admin.getName(), req.mensaje());
    }

    @PostMapping("/info-recibida")
    public AuditoriaVerificacion infoRecibida(@jakarta.validation.Valid @RequestBody InfoRequest req, Principal admin) {
        return revision.registrarRespuesta(req.email(), admin.getName(), req.mensaje());
    }

    @ExceptionHandler(EntradaInvalidaException.class)
    public ResponseEntity<Map<String, String>> invalida(EntradaInvalidaException e) {
        return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
    }

    @ExceptionHandler({org.springframework.web.bind.MethodArgumentNotValidException.class,
            org.springframework.http.converter.HttpMessageNotReadableException.class})
    public ResponseEntity<Map<String, String>> malFormada(Exception e) {
        return ResponseEntity.badRequest().body(Map.of("error", "Solicitud inválida"));
    }

    @ExceptionHandler(VerificacionException.class)
    public ResponseEntity<Map<String, String>> negocio(VerificacionException e) {
        HttpStatus st = switch (e.getTipo()) {
            case NO_ENCONTRADO -> HttpStatus.NOT_FOUND;
            case LIMITE_EXCEDIDO -> HttpStatus.TOO_MANY_REQUESTS;
            default -> HttpStatus.CONFLICT;
        };
        return ResponseEntity.status(st).body(Map.of("error", e.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> generico(Exception e) {
        if (e instanceof org.springframework.security.access.AccessDeniedException ade) {
            throw ade;
        }
        log.error("Error en verificación: {}", e.getClass().getSimpleName());
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", "Error interno"));
    }
}
