package com.example.MotvirsWeb.presentacion.api;

import jakarta.validation.Valid;
import com.example.MotvirsWeb.presentacion.dto.SolicitudViajeRequest;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.presentacion.dto.UbicacionConductorRequest;
import com.example.MotvirsWeb.aplicacion.servicio.UbicacionConductorService;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.presentacion.dto.OptimizerResponseDto;
import com.example.MotvirsWeb.aplicacion.servicio.ServicioService;
import com.example.MotvirsWeb.aplicacion.servicio.OptimizerService;
import com.example.MotvirsWeb.aplicacion.util.UsuarioContextHelper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

/**
 * REST Controller para el Conductor (Mobile API).
 * 
 * Sigue el principio SOLID de Responsabilidad Única (SRP):
 * Solo maneja la capa de transporte REST y delega la lógica a ServicioService.
 */
@RestController
@RequestMapping("/api/conductor")
@RequiredArgsConstructor
public class ApiConductorController {

    private final ServicioService servicioService;
    private final OptimizerService optimizerService;
    private final UsuarioContextHelper usuarioContext;
    private final com.example.MotvirsWeb.aplicacion.servicio.SeguimientoPasajeroService seguimientoPasajero;
    private final UbicacionConductorService ubicacionConductorService;
    private final com.example.MotvirsWeb.aplicacion.servicio.ViajeEnVivoService viajeEnVivoService;
    private final com.example.MotvirsWeb.aplicacion.servicio.SaldoConductorService saldoConductorService;

    @GetMapping("/perfil")
    public ResponseEntity<Conductor> obtenerPerfil() {
        return ResponseEntity.ok(usuarioContext.getConductorAutenticado());
    }

    @GetMapping("/servicios-disponibles")
    public ResponseEntity<List<Servicio>> obtenerServiciosDisponibles(
            @RequestParam(required = false) Double lat, @RequestParam(required = false) Double lng) {
        return ResponseEntity.ok(com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraConductor(servicioService.obtenerServiciosDisponibles(
                usuarioContext.getConductorAutenticado(), lat, lng)));
    }

    @PostMapping("/aceptar-servicio/{servicioId}")
    public ResponseEntity<?> aceptarServicio(@PathVariable String servicioId) {
        try {
            Conductor conductor = usuarioContext.getConductorAutenticado();
            return ResponseEntity.ok(servicioService.aceptarServicio(servicioId, conductor));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason()));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /** Saldo del conductor con NEXA en los últimos días (efectivo cobrado − lo que le corresponde). */
    @GetMapping("/saldo")
    public com.example.MotvirsWeb.aplicacion.servicio.SaldoConductorService.VistaConductor saldo(
            @RequestParam(defaultValue = "30") int dias) {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        return com.example.MotvirsWeb.aplicacion.servicio.SaldoConductorService.VistaConductor.de(
                saldoConductorService.saldoDe(conductor.getId(), conductor.getNombre_y_Apellido(), dias));
    }

    /** El conductor en línea reporta su posición (cada pocos segundos); alimenta el despacho por olas. */
    @PostMapping("/ubicacion")
    public ResponseEntity<com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal.PosicionViaje> reportarUbicacion(
            @Valid @RequestBody UbicacionConductorRequest posicion) {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        PuntoGeo punto = new PuntoGeo(posicion.latitud(), posicion.longitud());
        ubicacionConductorService.registrar(conductor.getId(), punto, posicion.estaDisponible());
        // Con un viaje aceptado o en curso, la misma posición le llega en vivo al pasajero
        // Con viaje responde 200 con fase, distancia y ETA calculados por el servidor; sin viaje, 204
        return viajeEnVivoService.reportar(conductor.getId(), punto)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    /** Viaje que el conductor tiene ahora (aceptado o en curso); 204 si no tiene. Sirve para retomarlo al recargar. */
    @GetMapping("/viaje-activo")
    public ResponseEntity<Servicio> viajeActivo() {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        return servicioService.obtenerViajeActivo(conductor)
                .map(s -> ResponseEntity.ok(com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraConductor(s)))
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    /** Dónde está el pasajero ahora (204 si no hay una posición reciente); solo para el conductor de ese viaje. */
    @GetMapping("/pasajero-ubicacion/{servicioId}")
    public ResponseEntity<com.example.MotvirsWeb.aplicacion.servicio.SeguimientoPasajeroService.PosicionPasajero> ubicacionPasajero(@PathVariable String servicioId) {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        return seguimientoPasajero.consultar(servicioId, conductor)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    /** El conductor confirma que llegó al punto de recogida (la ubicación se verifica en el servidor). */
    @PostMapping("/llegue/{servicioId}")
    public ResponseEntity<?> confirmarLlegada(@PathVariable String servicioId,
            @Valid @RequestBody SolicitudViajeRequest.Coordenada posicion) {
        try {
            Conductor conductor = usuarioContext.getConductorAutenticado();
            return ResponseEntity.ok(servicioService.confirmarLlegada(servicioId, conductor,
                    posicion.latitud(), posicion.longitud()));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason(), "message", e.getReason()));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/iniciar-servicio/{servicioId}")
    public ResponseEntity<?> iniciarServicio(@PathVariable String servicioId) {
        try {
            Conductor conductor = usuarioContext.getConductorAutenticado();
            return ResponseEntity.ok(servicioService.iniciarServicio(servicioId, conductor));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason()));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/finalizar-servicio/{servicioId}")
    public ResponseEntity<?> finalizarServicio(@PathVariable String servicioId) {
        try {
            Conductor conductor = usuarioContext.getConductorAutenticado();
            return ResponseEntity.ok(servicioService.finalizarServicio(servicioId, conductor));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason()));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/cancelar-servicio/{servicioId}")
    public ResponseEntity<?> cancelarServicio(@PathVariable String servicioId) {
        try {
            Conductor conductor = usuarioContext.getConductorAutenticado();
            return ResponseEntity.ok(servicioService.cancelarServicioConductor(servicioId, conductor));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason()));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/servicios-en-curso")
    public ResponseEntity<List<Servicio>> obtenerServiciosEnCurso() {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        return ResponseEntity.ok(com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraConductor(servicioService.obtenerServiciosEnCurso(conductor)));
    }

    @GetMapping("/historial")
    public ResponseEntity<List<Servicio>> obtenerHistorial(
            @RequestParam(required = false) String fecha,
            @RequestParam(required = false) String pasajero) {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        return ResponseEntity.ok(com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraConductor(
                servicioService.obtenerHistorialConductor(conductor, fecha, pasajero)));
    }

    @GetMapping("/ingresos")
    public ResponseEntity<List<Map<String, Object>>> obtenerIngresos(
            @RequestParam(required = false) String periodo,
            @RequestParam(required = false) String fecha) {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        return ResponseEntity.ok(servicioService.obtenerIngresosConductor(conductor, periodo, fecha));
    }

    @GetMapping("/optimizar")
    public ResponseEntity<OptimizerResponseDto> optimizarJornada(
            @RequestParam(defaultValue = "0") double metaIngreso,
            @RequestParam(defaultValue = "8") double horasJornada,
            @RequestParam(defaultValue = "30000") double presupuestoGasolina,
            @RequestParam(defaultValue = "0.5") double riskAversion) {
        return ResponseEntity.ok(optimizerService.optimizarJornada(metaIngreso, horasJornada, presupuestoGasolina, riskAversion));
    }
}
