package com.example.MotvirsWeb.presentacion.web;

import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.aplicacion.servicio.CotizacionService;
import com.example.MotvirsWeb.aplicacion.servicio.DeudaService;
import com.example.MotvirsWeb.aplicacion.servicio.ServicioService;
import com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.presentacion.dto.CotizacionRequest;
import com.example.MotvirsWeb.presentacion.dto.CotizacionResponse;
import com.example.MotvirsWeb.aplicacion.util.UsuarioContextHelper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import com.example.MotvirsWeb.presentacion.dto.SolicitudViajeRequest;
import com.example.MotvirsWeb.presentacion.dto.CalificacionRequest;
import jakarta.validation.Valid;

/**
 * Controller HTTP para el Pasajero.
 *
 * Responsabilidad única: mapear rutas HTTP, delegar al servicio y retornar
 * respuestas.
 * Toda la lógica de negocio vive en {@link ServicioService}.
 */
@Controller
@RequestMapping("/pasajero")
@RequiredArgsConstructor
public class ControllerPasajero {

    private final ServicioService servicioService;
    private final CotizacionService cotizacionService;
    private final DeudaService deudaService;
    private final UsuarioContextHelper usuarioContext;
    private final com.example.MotvirsWeb.aplicacion.servicio.SeguimientoPasajeroService seguimientoPasajero;
    private final ModeloNexaProperties modeloNexa;

    @GetMapping("/panel")
    public String mapeopanelpasajero(Model model) {
        Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
        model.addAttribute("pasajero", pasajero);
        return "pasajero/panel_pasajero";
    }

    /** Cargos por cancelación del pasajero: pagados, condonados y el pendiente, si lo hay. */
    @GetMapping("/historial-cargos")
    @ResponseBody
    public ResponseEntity<?> historialCargos() {
        return ResponseEntity.ok(deudaService.historialDe(usuarioContext.getPasajeroAutenticado().getId()));
    }

    /** Cargo de cancelación pendiente del pasajero (bloquea nuevos viajes hasta que se pague). */
    @GetMapping("/deuda")
    @ResponseBody
    public ResponseEntity<?> deuda() {
        Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
        return ResponseEntity.ok(deudaService.deudaDe(pasajero.getId())
                .<Map<String, Object>>map(d -> {
                    Map<String, Object> r = new java.util.HashMap<>(Map.of("tieneDeuda", true, "monto", d.getMonto(),
                            "servicioId", d.getServicioId(), "creadaEn", d.getCreadaEn().toString()));
                    String motivo = deudaService.motivoDe(d);
                    if (motivo != null) r.put("motivo", motivo);
                    return r;
                })
                .orElse(Map.of("tieneDeuda", false)));
    }


    /** Solicitud que aún espera conductor: permite retomarla (y cancelarla) tras recargar la página. */
    @GetMapping("/solicitud-activa")
    @ResponseBody
    public ResponseEntity<?> solicitudActiva() {
        Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
        return ResponseEntity.ok(servicioService.solicitudPendienteDe(pasajero)
                .<Map<String, Object>>map(s -> {
                    Map<String, Object> r = new java.util.HashMap<>(servicioService.datosDeOferta(s));
                    r.put("activa", true);
                    r.put("servicioId", s.getId());
                    r.put("estado", s.getEstado().name());
                    return r;
                })
                .orElse(Map.of("activa", false)));
    }

    /** Precio del viaje según el servidor: valida la zona de Cartagena y calcula distancia y tarifa. */
    @PostMapping("/cotizar")
    @ResponseBody
    public ResponseEntity<?> cotizar(@Valid @RequestBody CotizacionRequest solicitud) {
        try {
            Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
            var cotizacion = cotizacionService.cotizar(pasajero,
                    new PuntoGeo(solicitud.ubicacionOrigen().latitud(), solicitud.ubicacionOrigen().longitud()),
                    new PuntoGeo(solicitud.ubicacionDestino().latitud(), solicitud.ubicacionDestino().longitud()));
            long deuda = deudaService.deudaDe(pasajero.getId())
                    .map(com.example.MotvirsWeb.dominio.modelo.DeudaCancelacion::getMonto).orElse(0L);
            return ResponseEntity.ok(CotizacionResponse.de(cotizacion, deuda));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason()));
        }
    }

    @PostMapping("/solicitar-viaje")
    @ResponseBody
    public ResponseEntity<?> solicitarViaje(@Valid @RequestBody SolicitudViajeRequest solicitud) {
        try {
            Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
            return ResponseEntity.ok(servicioService.solicitarViaje(solicitud.aComando(), pasajero));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason(), "message", e.getReason()));
        } catch (Exception e) {
            String mensaje = "Error al procesar la solicitud: " + e.getMessage();
            return ResponseEntity.badRequest().body(Map.of("error", mensaje, "message", mensaje));
        }
    }

    @PostMapping("/subir-oferta/{servicioId}")
    @ResponseBody
    public ResponseEntity<?> subirOferta(@PathVariable String servicioId,
            @Valid @RequestBody com.example.MotvirsWeb.presentacion.dto.SubirOfertaRequest cuerpo) {
        try {
            Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
            return ResponseEntity.ok(servicioService.subirOferta(servicioId, cuerpo.incremento(), pasajero));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason()));
        }
    }

    /** Viaje con conductor en camino: permite retomar el seguimiento tras recargar la página. */
    @GetMapping("/viaje-en-camino")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> viajeEnCamino() {
        Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
        return ResponseEntity.ok(seguimientoPasajero.viajeEnCamino(pasajero)
                .<Map<String, Object>>map(s -> {
                    Map<String, Object> conductor = new java.util.HashMap<>();
                    if (s.getConductor() != null) {
                        conductor.put("nombre", s.getConductor().getNombre());
                        conductor.put("fotoUrl", s.getConductor().getFotoUrl());
                    }
                    ModeloNexaProperties.Espera espera = modeloNexa.getEspera();
                    return Map.<String, Object>of("activo", true, "id", s.getId(), "estado", s.getEstado().name(),
                            "conductor", conductor,
                            // Vista del pasajero del viaje (sin datos del conductor que no le corresponden)
                            "servicio", VisibilidadServicio.paraPasajero(s),
                            // Reglas de espera del servidor, solo para mostrar el cronómetro y el aviso
                            "espera", Map.of("graciaMinutos", espera.getGraciaMinutos(),
                                    "valorMinuto", espera.getValorMinuto(), "maxMinutos", espera.getMaxMinutos()));
                })
                .orElse(Map.of("activo", false)));
    }

    /** El pasajero reporta dónde está mientras su conductor va en camino; solo lo ve ese conductor. */
    @PostMapping("/ubicacion/{servicioId}")
    @ResponseBody
    public ResponseEntity<Void> reportarUbicacion(@PathVariable String servicioId,
            @Valid @RequestBody SolicitudViajeRequest.Coordenada posicion) {
        Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
        seguimientoPasajero.reportar(servicioId, pasajero, new PuntoGeo(posicion.latitud(), posicion.longitud()));
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/cancelar-viaje/{servicioId}")
    @ResponseBody
    public ResponseEntity<?> cancelarViajePasajero(@PathVariable String servicioId) {
        try {
            Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
            return ResponseEntity.ok(servicioService.cancelarViajePasajero(servicioId, pasajero));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason()));
        } catch (RuntimeException e) {
            if (e.getMessage() != null && e.getMessage().contains("Servicio no encontrado")) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(Map.of("error", e.getMessage()));
            }
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", "Error al procesar la cancelación: " + e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Error interno del servidor al procesar la cancelación"));
        }
    }

    @PostMapping("/actualizar-estado/{servicioId}")
    @ResponseBody
    public ResponseEntity<?> actualizarEstadoServicio(
            @PathVariable String servicioId,
            @RequestBody Map<String, String> request) {
        // Este endpoint delega directamente al service si existe lógica,
        // o se mantiene como stub para compatibilidad con el frontend existente.
        return ResponseEntity.ok(Map.of(
                "mensaje", "Estado del servicio actualizado",
                "servicioId", servicioId));
    }

    @PostMapping("/calificar-servicio/{servicioId}")
    @ResponseBody
    public ResponseEntity<?> calificarServicio(@PathVariable String servicioId,
            @Valid @RequestBody CalificacionRequest datosCalificacion) {
        try {
            // Verificamos que el usuario autenticado es un pasajero (autenticación)
            Pasajero pasajero = usuarioContext.getPasajeroAutenticado();

            Double calificacion = datosCalificacion.calificacion();
            String comentarios = datosCalificacion.comentarios();

            return ResponseEntity.ok(
                    servicioService.calificarServicio(servicioId, "pasajero", calificacion, comentarios,
                            datosCalificacion.factores(), pasajero.getIdString()));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(e.getReason());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error al enviar la calificación: " + e.getMessage());
        }
    }

    @GetMapping("/historial")
    @ResponseBody
    public ResponseEntity<List<Servicio>> obtenerHistorialPasajero(
            @RequestParam(required = false) String fecha,
            @RequestParam(required = false) String conductor) {
        Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
        return ResponseEntity.ok(com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraPasajero(
                servicioService.obtenerHistorialPasajero(pasajero, fecha, conductor)));
    }

    @GetMapping("/servicios/{servicioId}")
    @ResponseBody
    public ResponseEntity<Servicio> obtenerServicioPasajero(@PathVariable String servicioId) {
        Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
        return ResponseEntity.ok(com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraPasajero(
                servicioService.obtenerServicioDePasajero(servicioId, pasajero)));
    }
}