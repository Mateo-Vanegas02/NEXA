package com.example.MotvirsWeb.presentacion.api;

import jakarta.validation.Valid;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.presentacion.dto.UbicacionConductorRequest;
import com.example.MotvirsWeb.presentacion.dto.AccionSinConexionRequest;
import com.example.MotvirsWeb.presentacion.dto.LlegadaRequest;
import com.example.MotvirsWeb.presentacion.dto.UbicacionLoteRequest;
import com.example.MotvirsWeb.aplicacion.servicio.IdempotenciaService;
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
    private final com.example.MotvirsWeb.aplicacion.puerto.CanalPeticion canalPeticion;
    private final com.example.MotvirsWeb.aplicacion.servicio.ViajeEnVivoService viajeEnVivoService;
    private final com.example.MotvirsWeb.aplicacion.servicio.SaldoConductorService saldoConductorService;
    private final com.example.MotvirsWeb.aplicacion.servicio.IdempotenciaService idempotencia;
    private final com.example.MotvirsWeb.aplicacion.servicio.UbicacionLoteService ubicacionLote;
    private final com.example.MotvirsWeb.aplicacion.servicio.NivelesService nivelesService;

    @GetMapping("/perfil")
    public ResponseEntity<Conductor> obtenerPerfil() {
        return ResponseEntity.ok(usuarioContext.getConductorAutenticado());
    }

    /**
     * Solicitudes que le tocan al conductor, cada una con {@code gananciaEstimada}: lo que se quedaría según su
     * nivel (la app muestra «Ganas $X» sin conocer la comisión).
     */
    @GetMapping("/servicios-disponibles")
    public ResponseEntity<List<Servicio>> obtenerServiciosDisponibles(
            @RequestParam(required = false) Double lat, @RequestParam(required = false) Double lng) {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        List<Servicio> vistas = new java.util.ArrayList<>();
        for (Servicio s : servicioService.obtenerServiciosDisponibles(conductor, lat, lng)) {
            Servicio v = com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio.paraConductor(s);
            v.setGananciaEstimada(nivelesService.gananciaEstimada(s, conductor));
            vistas.add(v);
        }
        return ResponseEntity.ok(vistas);
    }

    /**
     * El conductor califica al pasajero de un viaje finalizado (estrellas, comentario y factores de
     * {@code FactoresCalificacion} para el conductor). 400 si un factor no existe o contradice la nota.
     */
    @PostMapping("/calificar-servicio/{servicioId}")
    public ResponseEntity<?> calificarServicio(@PathVariable String servicioId,
            @Valid @RequestBody com.example.MotvirsWeb.presentacion.dto.CalificacionRequest datos) {
        if (datos.calificacion() == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "La calificación es obligatoria"));
        }
        Conductor conductor = usuarioContext.getConductorAutenticado();
        return responder(() -> servicioService.calificarServicio(servicioId, "conductor", datos.calificacion(),
                datos.comentarios() == null ? "" : datos.comentarios(), datos.factores(), conductor.getIdString()));
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
        ubicacionConductorService.registrar(conductor.getId(), punto, posicion.estaDisponible(),
                canalPeticion.actual());
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

    /**
     * Posiciones guardadas sin señal, cada una con su hora (fase 5 de la app). Se suman al recorrido real en orden de
     * hora; las que caen fuera de la tolerancia sin conexión se ignoran.
     */
    @PostMapping("/ubicacion/lote")
    public ResponseEntity<?> reportarUbicacionLote(@Valid @RequestBody UbicacionLoteRequest lote) {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        try {
            return ResponseEntity.ok(ubicacionLote.recibir(conductor, lote.puntos().stream()
                    .map(p -> new com.example.MotvirsWeb.aplicacion.servicio.UbicacionLoteService.Punto(
                            new PuntoGeo(p.latitud(), p.longitud()), p.ocurridoEn()))
                    .toList()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * El conductor confirma que llegó al punto de recogida (la ubicación se verifica en el servidor). Con
     * {@code Idempotency-Key} un reintento devuelve la misma respuesta; {@code ocurridoEn} si fue sin señal.
     */
    @PostMapping("/llegue/{servicioId}")
    public ResponseEntity<?> confirmarLlegada(@PathVariable String servicioId,
            @Valid @RequestBody LlegadaRequest llegada,
            @RequestHeader(value = IdempotenciaService.CABECERA, required = false) String llave) {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        return idempotencia.ejecutar(llave, conductor.getIdString(), "llegue:" + servicioId,
                () -> responder(() -> servicioService.confirmarLlegada(servicioId, conductor,
                        llegada.latitud(), llegada.longitud(), hora(llegada.ocurridoEn()))));
    }

    @PostMapping("/iniciar-servicio/{servicioId}")
    public ResponseEntity<?> iniciarServicio(@PathVariable String servicioId,
            @RequestBody(required = false) AccionSinConexionRequest accion,
            @RequestHeader(value = IdempotenciaService.CABECERA, required = false) String llave) {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        return idempotencia.ejecutar(llave, conductor.getIdString(), "iniciar:" + servicioId,
                () -> responder(() -> servicioService.iniciarServicio(servicioId, conductor,
                        hora(accion == null ? null : accion.ocurridoEn()))));
    }

    @PostMapping("/finalizar-servicio/{servicioId}")
    public ResponseEntity<?> finalizarServicio(@PathVariable String servicioId,
            @RequestBody(required = false) AccionSinConexionRequest accion,
            @RequestHeader(value = IdempotenciaService.CABECERA, required = false) String llave) {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        return idempotencia.ejecutar(llave, conductor.getIdString(), "finalizar:" + servicioId,
                () -> responder(() -> servicioService.finalizarServicio(servicioId, conductor,
                        hora(accion == null ? null : accion.ocurridoEn()))));
    }

    @PostMapping("/cancelar-servicio/{servicioId}")
    public ResponseEntity<?> cancelarServicio(@PathVariable String servicioId,
            @RequestHeader(value = IdempotenciaService.CABECERA, required = false) String llave) {
        Conductor conductor = usuarioContext.getConductorAutenticado();
        return idempotencia.ejecutar(llave, conductor.getIdString(), "cancelar:" + servicioId,
                () -> responder(() -> servicioService.cancelarServicioConductor(servicioId, conductor)));
    }

    /** Errores del servicio con el formato de siempre ({@code error} y, para la web, {@code message}). */
    private static ResponseEntity<?> responder(java.util.function.Supplier<Object> accion) {
        try {
            return ResponseEntity.ok(accion.get());
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode())
                    .body(Map.of("error", e.getReason(), "message", e.getReason()));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", String.valueOf(e.getMessage())));
        }
    }

    private static java.time.LocalDateTime hora(java.time.Instant ocurridoEn) {
        return ocurridoEn == null ? null
                : java.time.LocalDateTime.ofInstant(ocurridoEn, java.time.ZoneId.systemDefault());
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
