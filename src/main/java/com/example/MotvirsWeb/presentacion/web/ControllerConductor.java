package com.example.MotvirsWeb.presentacion.web;

import jakarta.validation.Valid;
import com.example.MotvirsWeb.presentacion.dto.SolicitudViajeRequest;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.presentacion.dto.UbicacionConductorRequest;
import com.example.MotvirsWeb.aplicacion.servicio.UbicacionConductorService;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.RegistroLlegada;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.aplicacion.servicio.NivelesService;
import com.example.MotvirsWeb.aplicacion.servicio.ServicioService;
import com.example.MotvirsWeb.aplicacion.util.UsuarioContextHelper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

/**
 * Controller HTTP para el Conductor.
 *
 * Responsabilidad única: mapear rutas HTTP, delegar al servicio y retornar
 * respuestas.
 * Toda la lógica de negocio vive en {@link ServicioService}.
 */
@Controller
@RequestMapping("/conductor")
@RequiredArgsConstructor
public class ControllerConductor {

    private final ServicioService servicioService;
    private final UsuarioContextHelper usuarioContext;
    private final com.example.MotvirsWeb.aplicacion.servicio.SeguimientoPasajeroService seguimientoPasajero;
    private final UbicacionConductorService ubicacionConductorService;
    private final com.example.MotvirsWeb.aplicacion.servicio.ViajeEnVivoService viajeEnVivoService;
    private final com.example.MotvirsWeb.aplicacion.servicio.SaldoConductorService saldoConductorService;
    private final ServicioRepository servicioRepository; // solo para la vista del panel
    private final NivelesService nivelesService;
    private final RegistroLlegada registroLlegada;
    private final com.example.MotvirsWeb.dominio.regla.ReglaViaje reglaViaje;

    @GetMapping("/panel")
    public String mapearpanelconductor(Model model) {
        Conductor conductor = usuarioContext.getConductorAutenticado();

        List<Servicio> serviciosDisponibles = servicioService.obtenerServiciosDisponibles(conductor, null, null);
        List<Servicio> serviciosEnCurso = servicioService.obtenerServiciosEnCurso(conductor);
        List<Servicio> historialServicios = servicioService.obtenerHistorialConductor(conductor, null, null);
        List<Servicio> serviciosCalificados = servicioRepository
                .findByConductorIdAndCalificacionPasajeroIsNotNull(conductor.getId());

        model.addAttribute("conductor", conductor);
        model.addAttribute("comisionConductor", nivelesService.comisionDe(conductor));
        model.addAttribute("radioLlegada", Math.round(registroLlegada.radioMetros()));
        // Solo para habilitar el botón «Finalizar» cerca del destino; el servidor valida de todos modos
        model.addAttribute("radioDestino", Math.round(reglaViaje.radioDestinoMetros()));
        model.addAttribute("serviciosDisponibles", com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraConductor(serviciosDisponibles));
        model.addAttribute("serviciosEnCurso", com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraConductor(serviciosEnCurso));
        model.addAttribute("historialServicios", com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraConductor(historialServicios));
        model.addAttribute("serviciosCalificados", com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraConductor(serviciosCalificados));

        return "conductor/panel_conductor";
    }

    @PostMapping("/aceptar-servicio/{servicioId}")
    @ResponseBody
    public ResponseEntity<?> aceptarServicio(@PathVariable String servicioId) {
        try {
            Conductor conductor = usuarioContext.getConductorAutenticado();
            return ResponseEntity.ok(servicioService.aceptarServicio(servicioId, conductor));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(e.getReason());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error al aceptar el servicio: " + e.getMessage());
        }
    }

    /** Saldo del conductor con NEXA en los últimos días (efectivo cobrado − lo que le corresponde). */
    @GetMapping("/saldo")
    @ResponseBody
    public com.example.MotvirsWeb.aplicacion.servicio.SaldoConductorService.VistaConductor saldo(
            @RequestParam(defaultValue = "30") int dias) {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        return com.example.MotvirsWeb.aplicacion.servicio.SaldoConductorService.VistaConductor.de(
                saldoConductorService.saldoDe(conductor.getId(), conductor.getNombre_y_Apellido(), dias));
    }

    /** El conductor en línea reporta su posición (cada pocos segundos); alimenta el despacho por olas. */
    @PostMapping("/ubicacion")
    @ResponseBody
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
    @ResponseBody
    public ResponseEntity<Servicio> viajeActivo() {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        return servicioService.obtenerViajeActivo(conductor)
                .map(s -> ResponseEntity.ok(com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraConductor(s)))
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    /** Dónde está el pasajero ahora (204 si no hay una posición reciente); solo para el conductor de ese viaje. */
    @GetMapping("/pasajero-ubicacion/{servicioId}")
    @ResponseBody
    public ResponseEntity<com.example.MotvirsWeb.aplicacion.servicio.SeguimientoPasajeroService.PosicionPasajero> ubicacionPasajero(@PathVariable String servicioId) {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        return seguimientoPasajero.consultar(servicioId, conductor)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    /** El conductor confirma que llegó al punto de recogida (la ubicación se verifica en el servidor). */
    @PostMapping("/llegue/{servicioId}")
    @ResponseBody
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
    @ResponseBody
    public ResponseEntity<?> iniciarServicio(@PathVariable String servicioId) {
        try {
            Conductor conductor = usuarioContext.getConductorAutenticado();
            return ResponseEntity.ok(servicioService.iniciarServicio(servicioId, conductor));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(e.getReason());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error al iniciar el viaje: " + e.getMessage());
        }
    }

    @PostMapping("/finalizar-servicio/{servicioId}")
    @ResponseBody
    public ResponseEntity<?> finalizarServicio(@PathVariable String servicioId) {
        try {
            Conductor conductor = usuarioContext.getConductorAutenticado();
            return ResponseEntity.ok(servicioService.finalizarServicio(servicioId, conductor));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(e.getReason());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error al finalizar el servicio: " + e.getMessage());
        }
    }

    @PostMapping("/cancelar-servicio/{servicioId}")
    @ResponseBody
    public ResponseEntity<?> cancelarServicio(@PathVariable String servicioId) {
        try {
            Conductor conductor = usuarioContext.getConductorAutenticado();
            return ResponseEntity.ok(servicioService.cancelarServicioConductor(servicioId, conductor));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(e.getReason());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error al cancelar el servicio: " + e.getMessage());
        }
    }

    @GetMapping("/servicios-disponibles")
    @ResponseBody
    public ResponseEntity<List<Servicio>> obtenerServiciosDisponibles(
            @RequestParam(required = false) Double lat, @RequestParam(required = false) Double lng) {
        return ResponseEntity.ok(com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraConductor(servicioService.obtenerServiciosDisponibles(
                usuarioContext.getConductorAutenticado(), lat, lng)));
    }

    @GetMapping("/servicios-en-curso")
    @ResponseBody
    public ResponseEntity<List<Servicio>> obtenerServiciosEnCurso() {
        try {
            Conductor conductor = usuarioContext.getConductorAutenticado();
            return ResponseEntity.ok(com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraConductor(servicioService.obtenerServiciosEnCurso(conductor)));
        } catch (Exception e) {
            throw new RuntimeException(e.getMessage());
        }
    }

    @GetMapping("/servicios/{servicioId}")
    @ResponseBody
    public ResponseEntity<Servicio> obtenerServicio(@PathVariable String servicioId) {
        return ResponseEntity.ok(com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraConductor(servicioService.obtenerServicioDeConductor(servicioId,
                usuarioContext.getConductorAutenticado())));
    }

    @GetMapping("/historial")
    @ResponseBody
    public ResponseEntity<List<Servicio>> obtenerHistorial(
            @RequestParam(required = false) String fecha,
            @RequestParam(required = false) String pasajero) {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        return ResponseEntity.ok(com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraConductor(
                servicioService.obtenerHistorialConductor(conductor, fecha, pasajero)));
    }

    @GetMapping("/ingresos")
    @ResponseBody
    public ResponseEntity<List<Map<String, Object>>> obtenerIngresos(
            @RequestParam(required = false) String periodo,
            @RequestParam(required = false) String fecha) {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        return ResponseEntity.ok(servicioService.obtenerIngresosConductor(conductor, periodo, fecha));
    }
}