package com.example.MotvirsWeb.presentacion.api;

import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.aplicacion.servicio.CotizacionService;
import com.example.MotvirsWeb.aplicacion.servicio.DeudaService;
import com.example.MotvirsWeb.aplicacion.servicio.ServicioService;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.presentacion.dto.CotizacionRequest;
import com.example.MotvirsWeb.presentacion.dto.CotizacionResponse;
import com.example.MotvirsWeb.aplicacion.util.UsuarioContextHelper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import com.example.MotvirsWeb.presentacion.dto.SolicitudViajeRequest;
import com.example.MotvirsWeb.presentacion.dto.CalificacionRequest;
import jakarta.validation.Valid;

/**
 * REST Controller para el Pasajero (Mobile API).
 * 
 * Sigue el principio SOLID de Responsabilidad Única (SRP):
 * Solo maneja la capa de transporte REST y delega la lógica a ServicioService.
 */
@RestController
@RequestMapping("/api/pasajero")
@RequiredArgsConstructor
public class ApiPasajeroController {

    private final ServicioService servicioService;
    private final CotizacionService cotizacionService;
    private final DeudaService deudaService;
    private final UsuarioContextHelper usuarioContext;
    private final com.example.MotvirsWeb.aplicacion.servicio.SeguimientoPasajeroService seguimientoPasajero;
    private final com.example.MotvirsWeb.aplicacion.servicio.ViajeEnVivoService viajeEnVivo;
    private final com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties modeloNexa;

    @GetMapping("/perfil")
    public ResponseEntity<Pasajero> obtenerPerfil() {
        return ResponseEntity.ok(usuarioContext.getPasajeroAutenticado());
    }

    /** Cargos por cancelación del pasajero: pagados, condonados y el pendiente, si lo hay. */
    @GetMapping("/historial-cargos")
    public ResponseEntity<?> historialCargos() {
        return ResponseEntity.ok(deudaService.historialDe(usuarioContext.getPasajeroAutenticado().getId()));
    }

    /** Cargo de cancelación pendiente del pasajero (bloquea nuevos viajes hasta que se pague). */
    @GetMapping("/deuda")
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
    public ResponseEntity<?> solicitarViaje(@Valid @RequestBody SolicitudViajeRequest solicitud) {
        try {
            Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
            return ResponseEntity.ok(servicioService.solicitarViaje(solicitud.aComando(), pasajero));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason()));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/subir-oferta/{servicioId}")
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
    public ResponseEntity<Map<String, Object>> viajeEnCamino() {
        Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
        return ResponseEntity.ok(seguimientoPasajero.viajeEnCamino(pasajero)
                .<Map<String, Object>>map(s -> {
                    Map<String, Object> conductor = new java.util.HashMap<>();
                    if (s.getConductor() != null) {
                        conductor.put("nombre", s.getConductor().getNombre());
                        conductor.put("fotoUrl", s.getConductor().getFotoUrl());
                    }
                    var espera = modeloNexa.getEspera();
                    return Map.<String, Object>of("activo", true, "id", s.getId(), "estado", s.getEstado().name(),
                            "conductor", conductor,
                            // Vista del pasajero del viaje (sin datos del conductor que no le corresponden)
                            "servicio", com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraPasajero(s),
                            // Reglas de espera del servidor, solo para mostrar el cronómetro y el aviso
                            "espera", Map.of("graciaMinutos", espera.getGraciaMinutos(),
                                    "valorMinuto", espera.getValorMinuto(), "maxMinutos", espera.getMaxMinutos()));
                })
                .orElse(Map.of("activo", false)));
    }

    /**
     * Dónde va el conductor ahora (fase, distancia y ETA calculados por el servidor). 204 si el viaje no es de este
     * pasajero o el conductor aún no reportó posición; la app móvil lo consulta cada pocos segundos.
     */
    @GetMapping("/posicion-conductor/{servicioId}")
    public ResponseEntity<com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal.PosicionViaje> posicionConductor(
            @PathVariable String servicioId) {
        Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
        return viajeEnVivo.posicionDe(servicioId, pasajero.getIdString())
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    /** El pasajero reporta dónde está mientras su conductor va en camino; solo lo ve ese conductor. */
    @PostMapping("/ubicacion/{servicioId}")
    public ResponseEntity<Void> reportarUbicacion(@PathVariable String servicioId,
            @Valid @RequestBody SolicitudViajeRequest.Coordenada posicion) {
        Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
        seguimientoPasajero.reportar(servicioId, pasajero, new PuntoGeo(posicion.latitud(), posicion.longitud()));
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/cancelar-viaje/{servicioId}")
    public ResponseEntity<?> cancelarViaje(@PathVariable String servicioId) {
        try {
            Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
            return ResponseEntity.ok(servicioService.cancelarViajePasajero(servicioId, pasajero));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason()));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/historial")
    public ResponseEntity<List<Servicio>> obtenerHistorial(
            @RequestParam(required = false) String fecha,
            @RequestParam(required = false) String conductor) {
        Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
        return ResponseEntity.ok(com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraPasajero(
                servicioService.obtenerHistorialPasajero(pasajero, fecha, conductor)));
    }

    @GetMapping("/servicios/{servicioId}")
    public ResponseEntity<?> obtenerDetalleServicio(@PathVariable String servicioId) {
        try {
            Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
            return ResponseEntity.ok(com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraPasajero(
                servicioService.obtenerServicioDePasajero(servicioId, pasajero)));
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping("/calificar-servicio/{servicioId}")
    public ResponseEntity<?> calificarServicio(@PathVariable String servicioId,
            @Valid @RequestBody CalificacionRequest datos) {
        try {
            Pasajero pasajero = usuarioContext.getPasajeroAutenticado();
            if (datos.calificacion() == null) {
                return ResponseEntity.badRequest().body(Map.of("error", "La calificación es obligatoria"));
            }
            Double calificacion = datos.calificacion();
            String comentarios = datos.comentarios() != null ? datos.comentarios() : "";
            return ResponseEntity.ok(servicioService.calificarServicio(
                    servicioId, "pasajero", calificacion, comentarios, pasajero.getIdString()));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason()));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
