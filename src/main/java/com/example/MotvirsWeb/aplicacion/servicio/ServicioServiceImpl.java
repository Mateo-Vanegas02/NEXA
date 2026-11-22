package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.ReglaSinConexion;
import com.example.MotvirsWeb.aplicacion.comando.SolicitudViaje;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.TemporalAdjusters;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import com.example.MotvirsWeb.dominio.modelo.CanalServicio;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.FactoresCalificacion;
import com.example.MotvirsWeb.dominio.regla.ModeloTarifa;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.regla.RegistroLlegada;

/**
 * Implementación de {@link ServicioService}.
 *
 * Centraliza toda la lógica de negocio relacionada con el ciclo de vida de un
 * Servicio:
 * solicitud, aceptación, inicio, finalización, cancelación y calificación.
 *
 * Principios aplicados:
 * - SRP: un único lugar para las reglas de negocio de Servicio.
 * - DIP: los Controllers dependen de la interfaz, no de esta clase
 * directamente.
 * - OCP: agregar nuevos periodos de filtro de ingresos no requiere modificar
 * controllers.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ServicioServiceImpl implements ServicioService {

    private final ServicioRepository servicioRepository;
    private final NotificadorTiempoReal notificadorTiempoReal;
    private final NivelesService nivelesService;
    private final CotizacionService cotizacionService;
    private final DeudaService deudaService;
    private final ModeloTarifa modeloTarifa;
    private final RegistroLlegada registroLlegada;
    private final com.example.MotvirsWeb.dominio.regla.ModeloExtra modeloExtra;
    private final DespachoService despachoService;
    private final com.example.MotvirsWeb.dominio.regla.PuntoRecogida puntoRecogida;
    private final ViajeEnVivoService viajeEnVivo;
    private final com.example.MotvirsWeb.dominio.repositorio.VehiculoRepository vehiculoRepository;
    private final com.example.MotvirsWeb.aplicacion.puerto.CanalPeticion canalPeticion;
    private final AvisosService avisos;
    private final AvisosPendientesService avisosPendientes;
    private final ModeloNexaProperties modeloNexa;
    /** Transacción Mongo con reintento ante conflictos transitorios; sin Spring (pruebas), sin transacción. */
    private EjecutorTransacciones transacciones = EjecutorTransacciones.sinTransaccion();

    @org.springframework.beans.factory.annotation.Autowired(required = false)
    public void setTransacciones(EjecutorTransacciones transacciones) {
        this.transacciones = transacciones;
    }

    static final String VIAJE_NO_DISPONIBLE = "Otro conductor ya tomó este viaje. Ya no está disponible.";

    // ─────────────────────────── CONDUCTOR ───────────────────────────

    @Override
    public Map<String, Object> aceptarServicio(String servicioId, Conductor conductor) {
        return transacciones.ejecutar(() -> aceptarEnTransaccion(servicioId, conductor));
    }

    /** Lecturas, escrituras condicionales y avisos para después del commit: se puede reintentar entero. */
    private Map<String, Object> aceptarEnTransaccion(String servicioId, Conductor conductor) {
        Servicio servicio = buscarServicio(servicioId);

        if (servicio.getEstado() != EstadoServicio.SOLICITADO) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, VIAJE_NO_DISPONIBLE);
        }
        exigirMismoCanal(servicio);
        despachoService.verificarPuedeAceptar(servicio, conductor);
        nivelesService.verificarPuedeAceptar(servicio, conductor);

        Servicio.ConductorEmbedded asignado = new Servicio.ConductorEmbedded(conductor);
        completarFichaConductor(asignado, conductor);
        LocalDateTime ahora = LocalDateTime.now();
        // Atómico: si otro conductor lo tomó entre la lectura y este punto, no se sobrescribe
        if (servicioRepository.tomarSiDisponible(servicioId, asignado, ahora) == 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, VIAJE_NO_DISPONIBLE);
        }
        servicio.setConductor(asignado);
        servicio.setEstado(EstadoServicio.ACEPTADO);
        servicio.setFechaAceptacion(ahora);
        registrarMetricasDespacho(servicio, conductor);
        despuesDeConfirmar(() -> viajeEnVivo.seguir(servicio));
        avisosPendientes.registrar(servicioId, AvisosPendientesService.Tipo.ACEPTADO);

        return Map.of("mensaje", "Servicio aceptado con éxito", "servicioId", servicioId);
    }

    /** Calificación, moto y placa que ve el pasajero; nunca debe impedir aceptar el viaje. */
    private void completarFichaConductor(Servicio.ConductorEmbedded asignado, Conductor conductor) {
        try {
            asignado.setCalificacion(nivelesService.estadisticasCacheadas(conductor).calificacion());
        } catch (RuntimeException e) {
            log.warn("No se pudo leer la calificación del conductor {}", conductor.getId(), e);
        }
        try {
            vehiculoRepository.findByConductorAsignado(conductor).stream()
                    .filter(com.example.MotvirsWeb.dominio.modelo.Vehiculo::isActivo).findFirst()
                    .ifPresent(v -> {
                        String moto = java.util.stream.Stream.of(v.getMarca(), v.getModelo())
                                .filter(t -> t != null && !t.isBlank()).collect(java.util.stream.Collectors.joining(" "));
                        if (v.getColor() != null && !v.getColor().isBlank()) {
                            moto = moto.isEmpty() ? v.getColor() : moto + " · " + v.getColor();
                        }
                        asignado.setVehiculo(moto.isEmpty() ? null : moto);
                        asignado.setPlaca(v.getPlaca());
                    });
        } catch (RuntimeException e) {
            log.warn("No se pudo leer el vehículo del conductor {}", conductor.getId(), e);
        }
    }

    /** Las métricas del despacho nunca deben impedir aceptar el viaje. */
    private void registrarMetricasDespacho(Servicio servicio, Conductor conductor) {
        try {
            DespachoService.DatosAceptacion datos = despachoService.datosAceptacion(servicio, conductor);
            if (datos != null) {
                servicioRepository.registrarDespacho(servicio.getId(), datos.ola(), datos.distanciaKm());
                servicio.setOlaAceptacion(datos.ola());
                servicio.setDistanciaRecogidaKm(datos.distanciaKm());
            }
        } catch (RuntimeException e) {
            log.warn("No se pudieron guardar las métricas de despacho del servicio {}", servicio.getId(), e);
        }
    }

    @Override
    public Map<String, Object> confirmarLlegada(String servicioId, Conductor conductor, double latitud,
            double longitud, LocalDateTime ocurridoEn) {
        return transacciones.ejecutar(() -> confirmarLlegadaEnTransaccion(servicioId, conductor, latitud, longitud, ocurridoEn));
    }

    /** Lecturas, escrituras condicionales y avisos para después del commit: se puede reintentar entero. */
    private Map<String, Object> confirmarLlegadaEnTransaccion(String servicioId, Conductor conductor, double latitud,
            double longitud, LocalDateTime ocurridoEn) {
        Servicio servicio = buscarServicio(servicioId);
        exigirConductorAsignado(servicio, conductor);
        exigirMismoCanal(servicio);
        if (servicio.getEstado() != EstadoServicio.ACEPTADO) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Solo puedes confirmar la llegada de un servicio aceptado");
        }
        if (servicio.getFechaLlegada() != null) {
            return Map.of("mensaje", "La llegada ya estaba registrada", "servicioId", servicioId);
        }
        PuntoGeo posicion = new PuntoGeo(latitud, longitud);
        PuntoGeo recogida = new PuntoGeo(servicio.getUbicacionOrigen().getLatitud(),
                servicio.getUbicacionOrigen().getLongitud());
        if (!registroLlegada.enElPuntoDeRecogida(posicion, recogida)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Aún no estás en el punto de recogida (a "
                            + Math.round(registroLlegada.distanciaMetros(posicion, recogida)) + " m; debes estar a menos de "
                            + Math.round(registroLlegada.radioMetros()) + " m)");
        }
        servicio.setFechaLlegada(ReglaSinConexion.horaEvento(LocalDateTime.now(), ocurridoEn,
                servicio.getFechaAceptacion(), toleranciaSinConexion(servicio, false)));
        servicio.setUbicacionLlegada(new Servicio.Coordenada(latitud, longitud));
        if (servicioRepository.registrarLlegadaSiAceptado(servicioId, conductor.getId(),
                servicio.getFechaLlegada(), servicio.getUbicacionLlegada()) == 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "La llegada ya fue registrada o el viaje cambió de estado");
        }
        avisosPendientes.registrar(servicioId, AvisosPendientesService.Tipo.LLEGADA);
        return Map.of("mensaje", "Llegada registrada. Se cuenta la espera del pasajero.", "servicioId", servicioId);
    }

    @Override
    public Map<String, Object> iniciarServicio(String servicioId, Conductor conductor, LocalDateTime ocurridoEn) {
        return transacciones.ejecutar(() -> iniciarEnTransaccion(servicioId, conductor, ocurridoEn));
    }

    /** Lecturas, escrituras condicionales y avisos para después del commit: se puede reintentar entero. */
    private Map<String, Object> iniciarEnTransaccion(String servicioId, Conductor conductor, LocalDateTime ocurridoEn) {
        Servicio servicio = buscarServicio(servicioId);

        if (servicio.getEstado() != EstadoServicio.ACEPTADO) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "El servicio no está en estado ACEPTADO");
        }
        if (servicio.getConductor() == null || servicio.getConductor().getId() == null
                || !servicio.getConductor().getId().equals(conductor.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Este servicio no está asignado a ti");
        }
        exigirMismoCanal(servicio);
        // Sin "llegué" verificado no hay recogida: el viaje no arranca desde cualquier lugar
        if (servicio.getFechaLlegada() == null) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Confirma que llegaste al punto de recogida antes de iniciar el viaje");
        }

        LocalDateTime ahora = ReglaSinConexion.horaEvento(LocalDateTime.now(), ocurridoEn,
                servicio.getFechaLlegada(), toleranciaSinConexion(servicio, false));
        servicio.setEstado(EstadoServicio.EN_CURSO);
        servicio.setFechaInicio(ahora);
        if (servicio.getFechaLlegada() != null) {
            servicio.setMinutosEspera(minutosEntre(servicio.getFechaLlegada(), ahora));
        }
        if (servicioRepository.iniciarSiAceptado(servicioId, conductor.getId(), ahora,
                servicio.getMinutosEspera()) == 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "El viaje cambió de estado antes de iniciarse");
        }
        despuesDeConfirmar(() -> viajeEnVivo.iniciar(servicio));
        avisosPendientes.registrar(servicioId, AvisosPendientesService.Tipo.INICIADO);

        return Map.of("mensaje", "Viaje iniciado con éxito", "servicioId", servicioId);
    }

    /** Minutos que se acepta la hora del teléfono (ver {@link ReglaSinConexion#toleranciaMinutos}). */
    private long toleranciaSinConexion(Servicio servicio, boolean enCurso) {
        var sinConexion = modeloNexa == null ? new ModeloNexaProperties.SinConexion() : modeloNexa.getSinConexion();
        return ReglaSinConexion.toleranciaMinutos(sinConexion.getToleranciaMinutos(), enCurso,
                servicio.getDuracionEstimadaMin());
    }

    /** Una fracción de cobro fuera de (0, 1] se ignora: se cobra el viaje completo. */
    private static double fraccionValida(double f) {
        return f > 0 && f <= 1.0 ? f : 1.0;
    }

    /**
     * Finaliza en dos partes. Crítico, en una transacción (todo o nada): el paso a FINALIZADO con la fracción
     * cobrada, el recorrido, el cobro de la deuda aceptada y la inscripción del aviso. Recuperable, después del
     * commit: niveles/XP y desglose definitivo; si fallan, el viaje queda finalizado y {@code NivelesScheduler}
     * los reprocesa (es idempotente).
     */
    @Override
    public Map<String, Object> finalizarServicio(String servicioId, Conductor conductor, LocalDateTime ocurridoEn) {
        Servicio servicio = transacciones.ejecutar(() -> finalizarEnTransaccion(servicioId, conductor, ocurridoEn));

        // Niveles: nunca debe impedir que el viaje se complete (se reprocesa si falla).
        NivelesService.ResultadoViaje niveles = null;
        try {
            niveles = nivelesService.procesarFinalizacion(servicio);
            servicioRepository.guardarResultadoNiveles(servicioId, servicio.getDesglose(),
                    servicio.getXpGanadoPasajero(), servicio.getXpGanadoConductor(), servicio.getTarifa());
        } catch (Exception e) {
            log.error("No se pudo procesar niveles/XP del servicio {}; queda para el reproceso", servicioId, e);
            niveles = null;
        }

        Map<String, Object> respuesta = new HashMap<>();
        respuesta.put("mensaje", "Servicio finalizado con éxito. Redirigiendo a calificación...");
        respuesta.put("servicioId", servicioId);
        respuesta.put("redirectUrl", "/rating?servicioId=" + servicioId + "&rol=conductor");
        if (niveles != null) {
            respuesta.put("xpGanado", niveles.xpConductor());
            respuesta.put("nivel", niveles.nivelConductorDespues());
            respuesta.put("subioNivel", niveles.subioNivelConductor());
            if (niveles.xpFaltanteConductor() != null) {
                respuesta.put("xpFaltante", niveles.xpFaltanteConductor());
            }
            respuesta.put("desglose", com.example.MotvirsWeb.presentacion.dto.DesgloseConductorDto.de(
                    niveles.desglose(), servicio.getDeudaCobrada()));
        }
        return respuesta;
    }

    /** Parte crítica de {@link #finalizarServicio}: devuelve el viaje ya finalizado (en memoria) para niveles. */
    private Servicio finalizarEnTransaccion(String servicioId, Conductor conductor, LocalDateTime ocurridoEn) {
        Servicio servicio = buscarServicio(servicioId);

        if (servicio.getEstado() != EstadoServicio.EN_CURSO ||
                !servicio.getConductor().getId().equals(conductor.getId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "No puedes finalizar este servicio");
        }
        exigirMismoCanal(servicio);
        // Regla de oro: el viaje lo finaliza siempre el conductor, en cualquier tramo. Si no llegó al destino
        // (el pasajero se bajó antes) se cobra según lo recorrido: antes de la mitad, la mitad; desde la mitad, todo.
        boolean enDestino = viajeEnVivo.estaEnElDestino(servicio, conductor.getId());
        servicio.setEstado(EstadoServicio.FINALIZADO);
        // Sin señal se finaliza con la hora del teléfono (dentro de la tolerancia); el cobro sigue saliendo de las
        // posiciones que el servidor recibió (en vivo o en el lote al volver la señal), nunca de lo que diga la acción.
        servicio.setFechaFinalizacion(ReglaSinConexion.horaEvento(LocalDateTime.now(), ocurridoEn,
                servicio.getFechaInicio(), toleranciaSinConexion(servicio, true)));
        ViajeEnVivoService.Recorrido recorridoPrevio = viajeEnVivo.recorridoActual(conductor.getId(), servicioId);
        double fraccion = enDestino ? 1.0 : fraccionValida(viajeEnVivo.factorCobro(servicio, conductor.getId(), recorridoPrevio));
        if (servicioRepository.finalizarSiEnCurso(servicioId, conductor.getId(), servicio.getFechaFinalizacion(),
                !enDestino, fraccion) == 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "El viaje cambió de estado antes de finalizarse");
        }
        ViajeEnVivoService.Recorrido recorrido = recorridoPrevio;
        if (recorrido != null && !recorrido.puntos().isEmpty()) {
            servicio.setDistanciaRecorridaKm(recorrido.km());
            servicio.setRecorrido(recorrido.puntos());
        }
        servicio.setFinalizadoAntesDelDestino(!enDestino);
        servicio.setFraccionCobrada(fraccion);
        if (recorrido != null && !recorrido.puntos().isEmpty()) {
            servicioRepository.guardarRecorridoFinal(servicioId, recorrido.km(), recorrido.puntos());
        }
        despuesDeConfirmar(() -> viajeEnVivo.terminar(conductor.getId(), servicioId));

        // La deuda que el pasajero aceptó al pedir el viaje se cobra ahora, en efectivo, junto con la tarifa.
        // Es parte del cobro: si falla, se revierte la finalización entera (el conductor reintenta) en vez de
        // dejar un viaje cerrado con la deuda a medias. Si otro ya la resolvió, cobrarEnViaje devuelve 0.
        long cobrado = deudaService.cobrarEnViaje(servicio, servicio.getFechaFinalizacion());
        if (cobrado != servicio.getDeudaCobrada()) {
            servicio.setDeudaCobrada(cobrado);
            servicioRepository.guardarDeudaCobrada(servicioId, cobrado);
        }
        avisosPendientes.registrar(servicioId, AvisosPendientesService.Tipo.FINALIZADO);
        return servicio;
    }

    @Override
    public Map<String, Object> cancelarServicioConductor(String servicioId, Conductor conductor) {
        return transacciones.ejecutar(() -> cancelarConductorEnTransaccion(servicioId, conductor));
    }

    /** Lecturas, escrituras condicionales y avisos para después del commit: se puede reintentar entero. */
    private Map<String, Object> cancelarConductorEnTransaccion(String servicioId, Conductor conductor) {
        Servicio servicio = buscarServicio(servicioId);

        if (!servicio.getConductor().getId().equals(conductor.getId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "No puedes cancelar este servicio");
        }

        if (servicio.getEstado() == EstadoServicio.FINALIZADO ||
                servicio.getEstado() == EstadoServicio.CANCELADO) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "El servicio ya está completado o cancelado");
        }
        exigirMismoCanal(servicio);

        servicio.setEstado(EstadoServicio.CANCELADO);
        servicio.setCanceladoPor("CONDUCTOR");
        servicio.setFechaCancelacion(LocalDateTime.now());
        if (servicioRepository.cancelarSiAsignado(servicioId, conductor.getId(), servicio.getFechaCancelacion()) == 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "El viaje cambió de estado antes de cancelarse");
        }
        despuesDeConfirmar(() -> viajeEnVivo.terminar(conductor.getId(), servicioId));
        avisosPendientes.registrar(servicioId, AvisosPendientesService.Tipo.CANCELADO);

        return Map.of("mensaje", "Servicio cancelado con éxito", "servicioId", servicioId);
    }

    @Override
    public List<Servicio> obtenerServiciosDisponibles() {
        return servicioRepository.findByEstado(EstadoServicio.SOLICITADO).stream()
                .filter(this::esSolicitudVisibleParaConductor)
                .sorted((a, b) -> {
                    if (a.getFechaHora() == null && b.getFechaHora() == null) {
                        return 0;
                    }
                    if (a.getFechaHora() == null) {
                        return 1;
                    }
                    if (b.getFechaHora() == null) {
                        return -1;
                    }
                    return b.getFechaHora().compareTo(a.getFechaHora());
                })
                .collect(Collectors.toList());
    }

    @Override
    public List<Servicio> obtenerServiciosDisponibles(Conductor conductor, Double lat, Double lng) {
        // Primero el despacho por olas (qué le llega a este conductor) y luego el orden por prioridad del pasajero
        var posicion = despachoService.posicionDe(conductor, lat, lng);
        Double latitud = posicion.map(com.example.MotvirsWeb.dominio.regla.PuntoGeo::latitud).orElse(null);
        Double longitud = posicion.map(com.example.MotvirsWeb.dominio.regla.PuntoGeo::longitud).orElse(null);
        // Cada canal atiende sus propias solicitudes: la app ve las de la app y la web las de la web
        CanalServicio canal = canalActual();
        List<Servicio> delCanal = obtenerServiciosDisponibles().stream()
                .filter(s -> CanalServicio.oWeb(s.getCanal()) == canal).toList();
        return nivelesService.ordenarParaConductor(
                despachoService.filtrarPorOla(delCanal, conductor, latitud, longitud),
                conductor, latitud, longitud);
    }

    @Override
    public List<Servicio> obtenerServiciosEnCurso(Conductor conductor) {
        return servicioRepository.findByConductorIdAndEstado(
                conductor.getId(), EstadoServicio.EN_CURSO);
    }

    @Override
    public java.util.Optional<Servicio> obtenerViajeActivo(Conductor conductor) {
        // Un conductor tiene a lo sumo un viaje a la vez; EN_CURSO manda sobre ACEPTADO
        java.util.Optional<Servicio> activo = servicioRepository
                .findByConductorIdAndEstado(conductor.getId(), EstadoServicio.EN_CURSO).stream().findFirst()
                .or(() -> servicioRepository.findByConductorIdAndEstado(conductor.getId(), EstadoServicio.ACEPTADO)
                        .stream().findFirst());
        // Tras recargar la página o reiniciar el servidor se retoma el envío de la posición al pasajero
        activo.ifPresent(viajeEnVivo::seguir);
        return activo;
    }

    @Override
    public Servicio obtenerServicioPorId(String servicioId) {
        return buscarServicio(servicioId);
    }

    @Override
    public Servicio obtenerServicioDeConductor(String servicioId, Conductor conductor) {
        Servicio servicio = buscarServicio(servicioId);
        boolean asignado = servicio.getConductor() != null && servicio.getConductor().getId() != null
                && servicio.getConductor().getId().equals(conductor.getId());
        if (!asignado && servicio.getEstado() != EstadoServicio.SOLICITADO) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "No tienes permiso para ver este servicio");
        }
        return servicio;
    }

    @Override
    public List<Servicio> obtenerHistorialConductor(Conductor conductor,
            String fecha, String pasajero) {
        List<Servicio> historial = servicioRepository.findByConductorIdAndEstado(
                conductor.getId(), EstadoServicio.FINALIZADO);

        if (fecha != null || pasajero != null) {
            historial = historial.stream()
                    .filter(s -> {
                        boolean matchFecha = fecha == null ||
                                s.getFechaHora().toLocalDate().toString().equals(fecha);
                        boolean matchPasajero = pasajero == null ||
                                s.getPasajero().getNombre().toLowerCase()
                                        .contains(pasajero.toLowerCase());
                        return matchFecha && matchPasajero;
                    })
                    .collect(Collectors.toList());
        }
        return historial;
    }

    @Override
    public List<Map<String, Object>> obtenerIngresosConductor(Conductor conductor,
            String periodo, String fecha) {
        List<Servicio> servicios = servicioRepository.findByConductorIdAndEstado(
                conductor.getId(), EstadoServicio.FINALIZADO);

        List<Servicio> filtrados = filtrarPorPeriodo(servicios, periodo, fecha);

        return filtrados.stream()
                .map(s -> {
                    Map<String, Object> ingreso = new HashMap<>();
                    ingreso.put("fecha", s.getFechaHora().toLocalDate().toString());
                    // Hora del viaje (la app agrupa lo ganado hoy por hora).
                    ingreso.put("hora", (s.getFechaFinalizacion() != null ? s.getFechaFinalizacion()
                            : s.getFechaHora()).toString());
                    boolean neto = s.getDesglose() != null && s.getDesglose().isDefinitivo();
                    ingreso.put("monto", neto ? s.getDesglose().getGananciaConductor() : s.getTarifa());
                    ingreso.put("descripcion", "Viaje con " + s.getPasajero().getNombre());
                    return ingreso;
                })
                .collect(Collectors.toList());
    }

    // ─────────────────────────── PASAJERO ────────────────────────────

    @Override
    public Map<String, Object> solicitarViaje(SolicitudViaje solicitud, Pasajero pasajero) {
        validarSolicitud(solicitud);
        var deuda = deudaService.deudaACobrarEnViaje(pasajero, solicitud.aceptaDeuda());
        if (servicioRepository.existsByPasajeroIdAndEstado(pasajero.getId(), EstadoServicio.SOLICITADO)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Ya tienes una solicitud esperando conductor. Cancélala para pedir otro viaje.");
        }

        Servicio servicio = new Servicio();
        Servicio.PasajeroEmbedded pasajeroEmbebido = new Servicio.PasajeroEmbedded(
                pasajero.getId(),
                pasajero.getNombreCompleto(),
                pasajero.getEmail());
        pasajeroEmbebido.setFotoUrl(pasajero.fotoPerfilUrl());
        servicio.setPasajero(pasajeroEmbebido);

        servicio.setOrigen(solicitud.origen());
        servicio.setDestino(solicitud.destino());
        servicio.setUbicacionOrigen(new Servicio.Coordenada(
                solicitud.ubicacionOrigen().latitud(), solicitud.ubicacionOrigen().longitud()));
        servicio.setUbicacionDestino(new Servicio.Coordenada(
                solicitud.ubicacionDestino().latitud(), solicitud.ubicacionDestino().longitud()));
        puntoRecogida.exigirCerca(solicitud.ubicacionPasajero() == null ? null
                : new PuntoGeo(solicitud.ubicacionPasajero().latitud(), solicitud.ubicacionPasajero().longitud()),
                new PuntoGeo(solicitud.ubicacionOrigen().latitud(), solicitud.ubicacionOrigen().longitud()));
        if (deuda.isPresent()) {
            servicio.setDeudaPorCobrar(deuda.get().getMonto());
            servicio.setDeudaServicioId(deuda.get().getServicioId());
        }

        // El precio y la distancia los fija el servidor: se ignora lo que declare el cliente.
        CotizacionService.Cotizacion cotizacion = cotizacionService.cotizar(pasajero,
                new PuntoGeo(solicitud.ubicacionOrigen().latitud(), solicitud.ubicacionOrigen().longitud()),
                new PuntoGeo(solicitud.ubicacionDestino().latitud(), solicitud.ubicacionDestino().longitud()));
        Servicio.DesgloseTarifa desglose = Servicio.DesgloseTarifa.deCobro(cotizacion.cobro(), false);
        servicio.setTarifa(cotizacion.cobro().precio());
        servicio.setDesglose(desglose);
        servicio.setDistanciaKM(cotizacion.ruta().distanciaKm());
        servicio.setRutaGeometria(cotizacion.ruta().geometria());
        servicio.setPasosRuta(cotizacion.ruta().pasos());
        servicio.setDuracionEstimadaMin(cotizacion.ruta().duracionMin());
        servicio.setNivelPasajero(Math.max(1, pasajero.getNivel()));
        servicio.setSolicitadoEn(nivelesService.momentoActual());
        servicio.setCanal(canalActual());

        servicio.setFechaHora(parsearFechaHora(solicitud.fechaHora()));

        if (solicitud.metodoPago() != null) {
            servicio.setMetodoPago(solicitud.metodoPago());
        }

        servicio.setEstado(EstadoServicio.SOLICITADO);
        servicio = servicioRepository.save(servicio);
        notificadorTiempoReal.notificarNuevoServicioDisponible(servicio);
        avisos.solicitudNueva(servicio);

        Map<String, Object> respuesta = new HashMap<>();
        respuesta.put("mensaje", "Viaje solicitado con éxito. Esperando conductor...");
        respuesta.put("servicioId", servicio.getId() != null ? servicio.getId() : "null-id");
        respuesta.put("desglose",
                com.example.MotvirsWeb.presentacion.dto.DesglosePasajeroDto.de(desglose, servicio.getDeudaPorCobrar()));
        return respuesta;
    }

    @Override
    public java.util.Optional<Servicio> solicitudPendienteDe(Pasajero pasajero) {
        return servicioRepository.findByPasajeroIdAndEstado(pasajero.getId(), EstadoServicio.SOLICITADO)
                .stream().findFirst();
    }

    @Override
    public Map<String, Object> subirOferta(String servicioId, long incremento, Pasajero pasajero) {
        Servicio servicio = buscarServicio(servicioId);
        if (servicio.getPasajero() == null || !pasajero.getId().equals(servicio.getPasajero().getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No tienes permiso sobre este servicio");
        }
        if (servicio.getEstado() != EstadoServicio.SOLICITADO) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Solo puedes subir la oferta mientras esperas conductor");
        }
        long actual = servicio.getExtraVoluntario();
        long nuevoTotal;
        try {
            nuevoTotal = modeloExtra.nuevoTotal(actual, incremento);
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
        }
        long aplicado = servicioRepository.subirExtra(servicioId, pasajero.getId(),
                modeloExtra.tope() - incremento, incremento,
                new Servicio.OfertaExtra(incremento, LocalDateTime.now()));
        if (aplicado == 0) {
            // Se tomó, canceló o alcanzó el tope entre la lectura y la escritura
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "No se pudo subir la oferta: la solicitud cambió o ya llegaste al tope");
        }
        Servicio actualizado = buscarServicio(servicioId);
        notificadorTiempoReal.notificarOfertaSubida(servicioId, actualizado.getExtraVoluntario());
        avisos.extraSubido(actualizado);
        Map<String, Object> respuesta = new HashMap<>();
        respuesta.put("mensaje", "Oferta enviada a los conductores");
        respuesta.put("servicioId", servicioId);
        respuesta.put("extraVoluntario", actualizado.getExtraVoluntario());
        respuesta.put("margenRestante", modeloExtra.margen(actualizado.getExtraVoluntario()));
        return respuesta;
    }

    @Override
    public Map<String, Object> datosDeOferta(Servicio servicio) {
        Map<String, Object> datos = new HashMap<>();
        datos.put("tarifa", Math.round(servicio.getTarifa()));
        datos.put("extraVoluntario", servicio.getExtraVoluntario());
        datos.put("margenExtra", modeloExtra.margen(servicio.getExtraVoluntario()));
        datos.put("pasosExtra", modeloExtra.pasos());
        datos.put("topeExtra", modeloExtra.tope());
        datos.put("despacho", despachoService.avisoDe(servicio));
        return datos;
    }

    @Override
    public Map<String, Object> cancelarViajePasajero(String servicioId, Pasajero pasajero) {
        return transacciones.ejecutar(() -> cancelarPasajeroEnTransaccion(servicioId, pasajero));
    }

    /** Lecturas, escrituras condicionales y avisos para después del commit: se puede reintentar entero. */
    private Map<String, Object> cancelarPasajeroEnTransaccion(String servicioId, Pasajero pasajero) {
        Servicio servicio = buscarServicio(servicioId);

        if (servicio.getPasajero() == null || servicio.getPasajero().getId() == null ||
                !servicio.getPasajero().getId().equals(pasajero.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "No tienes permiso para cancelar este servicio");
        }

        if (servicio.getEstado() != EstadoServicio.SOLICITADO &&
                servicio.getEstado() != EstadoServicio.ACEPTADO) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "No puedes cancelar un servicio que ya está " + servicio.getEstado());
        }
        boolean seguiaSolicitado = servicio.getEstado() == EstadoServicio.SOLICITADO;
        // Una solicitud que aún espera conductor la puede cancelar su pasajero desde la web o la app (si la pidió en
        // la app y la perdió de vista, no queda bloqueado). Con conductor asignado rige el canal del viaje.
        if (!seguiaSolicitado) {
            exigirMismoCanal(servicio);
        }
        LocalDateTime ahora = LocalDateTime.now();
        long cargo = calcularCargoCancelacion(servicio, ahora);
        if (cargo > 0 && deudaService.deudaDe(pasajero.getId()).isPresent()) cargo = 0;
        boolean llegadaVerificada = servicio.getFechaLlegada() != null;
        if (llegadaVerificada) {
            servicio.setMinutosEspera(minutosEntre(servicio.getFechaLlegada(), ahora));
        }
        servicio.setCargoCancelacion(cargo);
        // Con llegada verificada la plataforma le reconoce el cargo al conductor de inmediato
        servicio.setCargoAcreditadoConductor(cargo > 0 && llegadaVerificada);
        servicio.setEstado(EstadoServicio.CANCELADO);
        servicio.setCanceladoPor("PASAJERO");
        servicio.setFechaCancelacion(ahora);
        if (servicioRepository.cancelarSiVigente(servicioId, pasajero.getId(),
                seguiaSolicitado ? EstadoServicio.SOLICITADO : EstadoServicio.ACEPTADO,
                ahora, cargo, servicio.isCargoAcreditadoConductor(), servicio.getMinutosEspera()) == 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "El viaje cambió de estado antes de cancelarse");
        }
        if (cargo > 0 && !deudaService.registrar(pasajero.getId(), servicioId, cargo, ahora)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "La deuda cambió antes de cancelar; intenta de nuevo");
        }
        avisosPendientes.registrar(servicioId, AvisosPendientesService.Tipo.CANCELADO);
        if (cargo > 0) avisosPendientes.registrar(servicioId, AvisosPendientesService.Tipo.DEUDA);
        if (servicio.getConductor() != null) {
            org.bson.types.ObjectId conductorId = servicio.getConductor().getId();
            despuesDeConfirmar(() -> viajeEnVivo.terminar(conductorId, servicioId));
        }

        Map<String, Object> respuesta = new HashMap<>();
        respuesta.put("mensaje", cargo > 0
                ? "Viaje cancelado. Se generó un cargo que debes pagar para volver a solicitar un viaje."
                : "Viaje cancelado con éxito");
        respuesta.put("servicioId", servicioId);
        respuesta.put("cargoCancelacion", cargo);
        return respuesta;
    }

    @Override
    public List<Servicio> obtenerHistorialPasajero(Pasajero pasajero,
            String fecha, String conductor) {
        List<Servicio> historial = servicioRepository.findByPasajeroIdAndEstado(
                pasajero.getId(), EstadoServicio.FINALIZADO);

        if (fecha != null || conductor != null) {
            historial = historial.stream()
                    .filter(s -> {
                        boolean matchFecha = fecha == null ||
                                s.getFechaHora().toLocalDate().toString().equals(fecha);
                        boolean matchConductor = conductor == null || conductor.isEmpty() ||
                                (s.getConductor() != null &&
                                        s.getConductor().getNombre() != null &&
                                        s.getConductor().getNombre().toLowerCase()
                                                .contains(conductor.toLowerCase()));
                        return matchFecha && matchConductor;
                    })
                    .collect(Collectors.toList());
        }
        return historial;
    }

    @Override
    public Servicio obtenerServicioDePasajero(String servicioId, Pasajero pasajero) {
        Servicio servicio = buscarServicio(servicioId);
        if (!servicio.getPasajero().getId().equals(pasajero.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "No tienes permiso para ver este servicio");
        }
        return servicio;
    }

    // ───────────────────────── CALIFICACIÓN ──────────────────────────

    @Override
    public Map<String, Object> calificarServicio(String servicioId, String rol,
            Double calificacion, String comentarios, String usuarioId) {
        return calificarServicio(servicioId, rol, calificacion, comentarios, List.of(), usuarioId);
    }

    @Override
    public Map<String, Object> calificarServicio(String servicioId, String rol,
            Double calificacion, String comentarios, List<String> factores, String usuarioId) {
        if (usuarioId == null || usuarioId.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Inicia sesión para calificar");
        }
        if (!"pasajero".equals(rol) && !"conductor".equals(rol)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No puedes calificar este servicio");
        }
        Servicio servicio = buscarServicio(servicioId);
        org.bson.types.ObjectId participante = "pasajero".equals(rol)
                ? (servicio.getPasajero() != null ? servicio.getPasajero().getId() : null)
                : ("conductor".equals(rol)
                        ? (servicio.getConductor() != null ? servicio.getConductor().getId() : null)
                        : null);
        if (participante == null || usuarioId == null || !participante.toString().equals(usuarioId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "No puedes calificar este servicio");
        }
        if (servicio.getEstado() != EstadoServicio.FINALIZADO) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Solo se puede calificar un viaje finalizado");
        }
        if (calificacion != null && (calificacion.isNaN() || calificacion < 0 || calificacion > 5)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La calificación debe estar entre 0 y 5");
        }
        if (comentarios != null && comentarios.length() > 500) {
            comentarios = comentarios.substring(0, 500);
        }
        List<String> elegidos;
        try {
            elegidos = FactoresCalificacion.normalizar(rol, calificacion, factores);
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
        }
        return registrarCalificacion(servicio, rol, calificacion, comentarios, elegidos);
    }

    /**
     * Escribe la calificación ya autorizada. Privado a propósito: el único punto de entrada público es
     * {@link #calificarServicio(String, String, Double, String, List, String)}, que exige al participante.
     */
    private Map<String, Object> registrarCalificacion(Servicio servicio, String rol,
            Double calificacion, String comentarios, List<String> factores) {
        String servicioId = servicio.getId();
        List<String> guardar = factores == null || factores.isEmpty() ? null : List.copyOf(factores);

        if ("pasajero".equals(rol)) {
            servicio.setCalificacionConductor(calificacion);
            servicio.setComentariosConductor(comentarios);
            servicio.setFactoresConductor(guardar);
        } else if ("conductor".equals(rol)) {
            servicio.setCalificacionPasajero(calificacion);
            servicio.setComentariosPasajero(comentarios);
            servicio.setFactoresPasajero(guardar);
        } else {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Rol inválido: " + rol);
        }

        long aplicado = "pasajero".equals(rol)
                ? servicioRepository.calificarConductorUnaVez(servicioId, servicio.getPasajero().getId(),
                        calificacion, comentarios, guardar)
                : servicioRepository.calificarPasajeroUnaVez(servicioId, servicio.getConductor().getId(),
                        calificacion, comentarios, guardar);
        if (aplicado == 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "La calificación ya existe o el viaje cambió de estado");
        }

        if ("pasajero".equals(rol)) {
            try {
                if (nivelesService.registrarCalificacionConductor(servicio) != 0) {
                    servicioRepository.guardarXpConductor(servicioId, servicio.getXpGanadoConductor());
                }
            } catch (Exception e) {
                log.error("No se pudo ajustar el XP por calificación del servicio {}", servicioId, e);
            }
        }

        return Map.of("mensaje", "Calificación enviada con éxito", "servicioId", servicioId);
    }

    // ─────────────────────── MÉTODOS PRIVADOS ────────────────────────

    /**
     * Busca un servicio por ID o lanza 404.
     */
    private Servicio buscarServicio(String servicioId) {
        return servicioRepository.findById(servicioId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Servicio no encontrado: " + servicioId));
    }

    /**
     * Filtra una lista de servicios por periodo o fecha exacta.
     * Principio OCP: agregar un nuevo periodo solo requiere añadir un case aquí.
     */
    private List<Servicio> filtrarPorPeriodo(List<Servicio> servicios,
            String periodo, String fecha) {
        if (servicios == null || servicios.isEmpty()) {
            return servicios;
        }

        LocalDate today = LocalDate.now();

        if (fecha != null) {
            return servicios.stream()
                    .filter(s -> s.getFechaHora().toLocalDate().toString().equals(fecha))
                    .collect(Collectors.toList());
        }

        if (periodo == null) {
            return servicios;
        }

        return switch (periodo) {
            case "año" -> servicios.stream()
                    .filter(s -> s.getFechaHora().getYear() == today.getYear())
                    .collect(Collectors.toList());
            case "mes" -> servicios.stream()
                    .filter(s -> s.getFechaHora().getYear() == today.getYear() &&
                            s.getFechaHora().getMonth() == today.getMonth())
                    .collect(Collectors.toList());
            case "semana" -> {
                LocalDate startOfWeek = today.with(
                        TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY));
                LocalDate endOfWeek = startOfWeek.plusDays(6);
                yield servicios.stream()
                        .filter(s -> {
                            LocalDate d = s.getFechaHora().toLocalDate();
                            return !d.isBefore(startOfWeek) && !d.isAfter(endOfWeek);
                        })
                        .collect(Collectors.toList());
            }
            case "día" -> servicios.stream()
                    .filter(s -> s.getFechaHora().toLocalDate().equals(today))
                    .collect(Collectors.toList());
            default -> servicios;
        };
    }

    /** Defensa para llamadores que no pasan por el DTO validado de la capa web. */
    /** Canal de la petición en curso (WEB si no se puede saber). */
    private CanalServicio canalActual() {
        return CanalServicio.oWeb(canalPeticion.actual());
    }

    /** Un viaje se atiende solo por el canal en que se pidió: por el otro responde 409. */
    private void exigirMismoCanal(Servicio servicio) {
        CanalServicio delViaje = CanalServicio.oWeb(servicio.getCanal());
        if (delViaje != canalActual()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, delViaje.mensajeOtroCanal());
        }
    }

    private void exigirConductorAsignado(Servicio servicio, Conductor conductor) {
        if (servicio.getConductor() == null || servicio.getConductor().getId() == null
                || !servicio.getConductor().getId().equals(conductor.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Este servicio no está asignado a ti");
        }
    }

    private static double minutosEntre(LocalDateTime desde, LocalDateTime hasta) {
        return Duration.between(desde, hasta).toMillis() / 60000.0;
    }

    /** Cargo al pasajero por cancelar (ModeloTarifa.cargoCancelacion); 0 si aún no hay conductor. */
    private long calcularCargoCancelacion(Servicio s, LocalDateTime ahora) {
        boolean aceptado = s.getEstado() == EstadoServicio.ACEPTADO;
        double desdeAceptacion = aceptado && s.getFechaAceptacion() != null
                ? minutosEntre(s.getFechaAceptacion(), ahora) : 0;
        boolean llego = s.getFechaLlegada() != null;
        double esperando = llego ? minutosEntre(s.getFechaLlegada(), ahora) : 0;
        long tarifaBase = s.getDesglose() != null ? Math.round(s.getDesglose().getTarifaBase())
                : modeloTarifa.tarifaBase(s.getDistanciaKM());
        return modeloTarifa.cargoCancelacion(Math.max(1, s.getNivelPasajero()), tarifaBase,
                new ModeloTarifa.SituacionCancelacion(aceptado, desdeAceptacion, llego, esperando));
    }

    private void validarSolicitud(SolicitudViaje solicitud) {
        if (solicitud == null
                || solicitud.origen() == null || solicitud.origen().isBlank()
                || solicitud.destino() == null || solicitud.destino().isBlank()
                || solicitud.ubicacionOrigen() == null || solicitud.ubicacionDestino() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Faltan datos requeridos en la solicitud: origen, destino y ubicaciones");
        }
    }

    private LocalDateTime parsearFechaHora(String fechaHora) {
        if (fechaHora == null || fechaHora.isBlank()) {
            return LocalDateTime.now();
        }
        try {
            return LocalDateTime.parse(fechaHora, DateTimeFormatter.ISO_DATE_TIME);
        } catch (java.time.format.DateTimeParseException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La fecha de la solicitud no es válida");
        }
    }

    /**
     * Descarta solicitudes incompletas o de prueba antes de mostrarlas al
     * conductor.
     *
     * Esto evita que el dashboard pinte documentos residuales en Mongo que tengan
     * estado SOLICITADO pero no representen una petición real.
     */
    private static void despuesDeConfirmar(Runnable accion) {
        if (org.springframework.transaction.support.TransactionSynchronizationManager.isActualTransactionActive()) {
            org.springframework.transaction.support.TransactionSynchronizationManager.registerSynchronization(
                    new org.springframework.transaction.support.TransactionSynchronization() {
                        @Override public void afterCommit() {
                            try { accion.run(); }
                            catch (RuntimeException e) { log.warn("Falló la actualización del seguimiento en memoria", e); }
                        }
                    });
        } else {
            accion.run();
        }
    }

    private boolean esSolicitudVisibleParaConductor(Servicio servicio) {
        if (servicio == null || servicio.getEstado() != EstadoServicio.SOLICITADO) {
            return false;
        }

        if (servicio.getPasajero() == null
                || servicio.getPasajero().getId() == null
                || servicio.getPasajero().getNombre() == null
                || servicio.getPasajero().getNombre().isBlank()) {
            return false;
        }

        if (servicio.getOrigen() == null || servicio.getOrigen().isBlank()
                || servicio.getDestino() == null || servicio.getDestino().isBlank()) {
            return false;
        }

        if (servicio.getUbicacionOrigen() == null || servicio.getUbicacionDestino() == null) {
            return false;
        }

        if (servicio.getFechaHora() == null || servicio.getTarifa() <= 0 || servicio.getDistanciaKM() <= 0) {
            return false;
        }

        return true;
    }

}
