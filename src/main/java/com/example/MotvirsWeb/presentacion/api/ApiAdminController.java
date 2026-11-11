package com.example.MotvirsWeb.presentacion.api;

import org.springframework.web.server.ResponseStatusException;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.aplicacion.servicio.AdminService;
import com.example.MotvirsWeb.aplicacion.servicio.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;

/**
 * REST Controller para el Administrador (Mobile API).
 * 
 * Reutiliza la lógica de AdminService para exponer funcionalidades a la app
 * móvil.
 * Todas estas rutas están protegidas por JWT y el rol de ROLE_ADMIN.
 */
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@SuppressWarnings("null")
public class ApiAdminController {

    private final AdminService adminService;
    private final DashboardService dashboardService;
    private final com.example.MotvirsWeb.aplicacion.servicio.NotaAdminService notaAdminService;
    private final com.example.MotvirsWeb.aplicacion.verificacion.VerificacionConductorService verificacionService;
    private final com.example.MotvirsWeb.aplicacion.servicio.DeudaService deudaService;
    private final com.example.MotvirsWeb.aplicacion.servicio.MetricasDespachoService metricasDespacho;
    private final com.example.MotvirsWeb.aplicacion.servicio.SaldoConductorService saldoConductorService;

    /** Saldo de cada conductor con NEXA: cuánto efectivo cobró de más (comisión y deudas) o cuánto se le debe. */
    @GetMapping("/conductores/saldos")
    public List<com.example.MotvirsWeb.aplicacion.servicio.SaldoConductorService.SaldoConductor> saldosConductores(
            @RequestParam(defaultValue = "30") int dias) {
        return saldoConductorService.saldos(dias);
    }

    /** Métricas para calibrar el despacho por olas en los últimos {@code dias} (1–90). */
    @GetMapping("/despacho/metricas")
    public com.example.MotvirsWeb.aplicacion.servicio.MetricasDespachoService.MetricasDespacho metricasDespacho(
            @RequestParam(defaultValue = "30") int dias) {
        return metricasDespacho.calcular(dias);
    }

    /** Deudas por cancelación: pendientes, pagadas en los últimos 30 días y las cifras de las tarjetas. */
    @GetMapping("/deudas")
    public ResponseEntity<?> listarDeudas() {
        var ahora = java.time.LocalDateTime.now();
        var pendientes = deudaService.listarDeudores();
        var pagadas = deudaService.listarPagadas(ahora.minusDays(30));
        return ResponseEntity.ok(Map.of("resumen",
                com.example.MotvirsWeb.aplicacion.servicio.DeudaService.resumir(pendientes, pagadas, ahora),
                "pendientes", pendientes, "pagadas", pagadas,
                "condonadas", deudaService.listarCondonadas(ahora.minusDays(30))));
    }

    /** Cuerpo opcional al confirmar: método de pago (hoy solo EFECTIVO) y nota o referencia. */
    public record ConfirmarPagoRequest(
            @jakarta.validation.constraints.Size(max = 20) String metodo,
            @jakarta.validation.constraints.Size(max = 200) String nota) {
    }

    /** El administrador confirma que el pasajero pagó su deuda: se libera y se acredita al conductor. */
    @PostMapping("/deudas/{pasajeroId}/confirmar-pago")
    public ResponseEntity<?> confirmarPagoDeuda(@PathVariable String pasajeroId,
            @jakarta.validation.Valid @RequestBody(required = false) ConfirmarPagoRequest cuerpo) {
        try {
            String metodo = cuerpo == null || cuerpo.metodo() == null
                    ? com.example.MotvirsWeb.aplicacion.servicio.DeudaService.METODO_EFECTIVO : cuerpo.metodo();
            var deuda = deudaService.confirmarPago(pasajeroId, java.time.LocalDateTime.now(), metodo,
                    cuerpo == null ? null : cuerpo.nota());
            return ResponseEntity.ok(Map.of("message", "Pago confirmado", "monto", deuda.getMonto(),
                    "servicioId", deuda.getServicioId()));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason()));
        }
    }

    /** Motivo obligatorio de la condonación; queda registrado junto con el correo del administrador. */
    public record CondonarRequest(
            @jakarta.validation.constraints.NotBlank(message = "Escribe el motivo de la condonación")
            @jakarta.validation.constraints.Size(max = 300, message = "El motivo no puede pasar de 300 caracteres")
            String motivo) {
    }

    /** El administrador perdona la deuda del pasajero (no hubo pago): se libera y queda el motivo registrado. */
    @PostMapping("/deudas/{pasajeroId}/condonar")
    public ResponseEntity<?> condonarDeuda(@PathVariable String pasajeroId,
            @jakarta.validation.Valid @RequestBody CondonarRequest cuerpo, Principal admin) {
        try {
            var deuda = deudaService.condonar(pasajeroId, admin.getName(), cuerpo.motivo(),
                    java.time.LocalDateTime.now());
            return ResponseEntity.ok(Map.of("message", "Deuda condonada", "monto", deuda.getMonto(),
                    "servicioId", deuda.getServicioId()));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason()));
        }
    }

    @GetMapping("/dashboard-stats")
    public ResponseEntity<Map<String, Object>> obtenerResumen() {
        return ResponseEntity.ok(adminService.obtenerResumenDashboard());
    }

    @GetMapping("/conductores")
    public ResponseEntity<List<Conductor>> obtenerConductores(@RequestParam EstadoValidacion estado) {
        return ResponseEntity.ok(adminService.obtenerConductoresPorEstado(estado));
    }

    @PostMapping("/aprobar-conductor")
    public ResponseEntity<Map<String, String>> aprobarConductor(@RequestParam String email, Principal admin) {
        try {
            // Pasa por el flujo con verificación y auditoría (no aprueba sin verificación vigente).
            verificacionService.decidir(email, admin.getName(), true, null);
            return ResponseEntity.ok(Map.of("message", "Conductor aprobado exitosamente"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", mensajeSeguro(e)));
        }
    }

    @PostMapping("/rechazar-conductor")
    public ResponseEntity<Map<String, String>> rechazarConductor(@RequestParam String email,
            @RequestParam(required = false) String motivo, Principal admin) {
        try {
            verificacionService.decidir(email, admin.getName(), false,
                    motivo == null || motivo.isBlank() ? "Rechazado sin motivo indicado" : motivo);
            return ResponseEntity.ok(Map.of("message", "Conductor rechazado exitosamente"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", mensajeSeguro(e)));
        }
    }

    /** Solo se expone el mensaje de errores de negocio/validación conocidos; el resto, genérico. */
    private static String mensajeSeguro(Exception e) {
        return (e instanceof com.example.MotvirsWeb.aplicacion.verificacion.VerificacionException
                || e instanceof com.example.MotvirsWeb.aplicacion.verificacion.EntradaInvalidaException)
                        ? e.getMessage() : "No se pudo completar la operación";
    }

    @GetMapping("/estadisticas-mensuales")
    public ResponseEntity<Map<String, Object>> obtenerStatsMensuales() {
        return ResponseEntity.ok(dashboardService.obtenerEstadisticasMensuales());
    }

    @PostMapping("/config/notificaciones")
    public ResponseEntity<Map<String, Object>> toggleNotificaciones(
            @RequestParam boolean habilitado,
            Principal principal) {
        try {
            adminService.actualizarPreferenciaNotificaciones(principal.getName(), habilitado);
            return ResponseEntity.ok(Map.of("success", true, "enabled", habilitado));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "error", e.getMessage()));
        }
    }

    // --- Endpoints para CRUD de Notas ---
    @GetMapping("/notas")
    public ResponseEntity<List<com.example.MotvirsWeb.dominio.modelo.NotaAdmin>> obtenerNotas() {
        return ResponseEntity.ok(notaAdminService.listarTodasLasNotas());
    }

    @PostMapping("/notas")
    public ResponseEntity<com.example.MotvirsWeb.dominio.modelo.NotaAdmin> crearNota(@RequestBody Map<String, String> body) {
        return ResponseEntity.ok(notaAdminService.crearNota(body.get("titulo"), body.get("contenido")));
    }

    @PutMapping("/notas/{id}")
    public ResponseEntity<com.example.MotvirsWeb.dominio.modelo.NotaAdmin> actualizarNota(@PathVariable String id,
            @RequestBody Map<String, String> body) {
        return ResponseEntity.ok(notaAdminService.actualizarNota(id, body.get("titulo"), body.get("contenido")));
    }

    @DeleteMapping("/notas/{id}")
    public ResponseEntity<Map<String, Boolean>> eliminarNota(@PathVariable String id) {
        notaAdminService.eliminarNota(id);
        return ResponseEntity.ok(Map.of("success", true));
    }
}