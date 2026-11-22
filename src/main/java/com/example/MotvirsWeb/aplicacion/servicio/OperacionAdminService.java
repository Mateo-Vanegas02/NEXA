package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.presentacion.dto.OperacionAdminDto;
import com.example.MotvirsWeb.presentacion.dto.OperacionAdminDto.Alerta;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Cifras de la operación en vivo para el admin: viajes del día, motos en línea y alertas. Solo lee; las
 * posiciones vienen de {@link UbicacionConductorService} (en memoria) y no llevan id ni nombre.
 */
@Service
public class OperacionAdminService {

    /** Una solicitud abierta más de esto sin conductor sale como alerta. */
    static final Duration ESPERA_ALERTA = Duration.ofMinutes(5);
    /** Como mucho estas alertas de solicitudes (las más viejas primero). */
    static final int MAX_ALERTAS = 10;

    private final ServicioRepository servicios;
    private final UbicacionConductorService ubicaciones;
    private final AdminService admin;
    private final Clock clock;

    public OperacionAdminService(ServicioRepository servicios, UbicacionConductorService ubicaciones,
                                 AdminService admin, Clock clock) {
        this.servicios = servicios;
        this.ubicaciones = ubicaciones;
        this.admin = admin;
        this.clock = clock;
    }

    public OperacionAdminDto resumen() {
        LocalDateTime ahora = LocalDateTime.now(clock);
        LocalDateTime inicioDia = LocalDate.now(clock).atStartOfDay();
        var flota = ubicaciones.flota();
        long disponibles = flota.stream().filter(UbicacionConductorService.PosicionFlota::disponible).count();
        long pendientes = admin.obtenerConductoresPorEstado(EstadoValidacion.PENDIENTE).size();

        List<Alerta> alertas = new ArrayList<>();
        servicios.findByEstado(EstadoServicio.SOLICITADO).stream()
                .filter(s -> s.getFechaHora() != null
                        && Duration.between(s.getFechaHora(), ahora).compareTo(ESPERA_ALERTA) >= 0)
                .sorted(Comparator.comparing(com.example.MotvirsWeb.dominio.modelo.Servicio::getFechaHora))
                .limit(MAX_ALERTAS)
                .forEach(s -> {
                    long min = Duration.between(s.getFechaHora(), ahora).toMinutes();
                    alertas.add(new Alerta("SOLICITUD_SIN_CONDUCTOR",
                            "Solicitud desde " + s.getOrigen() + " sin conductor hace " + min + " min",
                            s.getId(), min));
                });
        if (pendientes > 0) {
            alertas.add(new Alerta("CONDUCTORES_POR_APROBAR",
                    pendientes == 1 ? "1 conductor espera aprobación"
                            : pendientes + " conductores esperan aprobación",
                    null, 0));
        }

        return new OperacionAdminDto(
                servicios.countByFechaHoraGreaterThanEqual(inicioDia),
                servicios.countByFechaHoraGreaterThanEqualAndEstado(inicioDia, EstadoServicio.FINALIZADO),
                servicios.countByFechaHoraGreaterThanEqualAndEstado(inicioDia, EstadoServicio.CANCELADO),
                servicios.countByEstado(EstadoServicio.EN_CURSO),
                servicios.countByEstado(EstadoServicio.ACEPTADO),
                servicios.countByEstado(EstadoServicio.SOLICITADO),
                flota.size(),
                disponibles,
                pendientes,
                flota,
                alertas);
    }
}
