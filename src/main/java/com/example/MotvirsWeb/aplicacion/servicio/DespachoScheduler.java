package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

/**
 * Avisa a los conductores cuando una solicitud pasa a la siguiente ola (para que recarguen su lista; en la app,
 * con un push a los que entran en la ola nueva), avisa al pasajero de la app cuando pasó la última ola sin que nadie
 * aceptara y descarta las posiciones de conductores vencidas. Solo recorre las solicitudes en estado SOLICITADO.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class DespachoScheduler {

    private final ServicioRepository servicioRepository;
    private final DespachoService despacho;
    private final UbicacionConductorService ubicaciones;
    private final SeguimientoPasajeroService seguimientoPasajero;
    private final NotificadorTiempoReal notificador;
    private final AvisosService avisos;

    /** Última ola publicada de cada solicitud abierta. */
    private final Map<String, Integer> publicadas = new ConcurrentHashMap<>();
    /** Solicitudes a cuyo pasajero ya se le avisó que no hay conductores (una sola vez). */
    private final Set<String> sinConductores = ConcurrentHashMap.newKeySet();

    @Scheduled(fixedDelayString = "${nexa.despacho.revision-segundos}",
            initialDelayString = "${nexa.despacho.revision-segundos}", timeUnit = TimeUnit.SECONDS)
    public void revisar() {
        try {
            ubicaciones.purgar();
            seguimientoPasajero.purgar();
            ampliarOlas();
        } catch (Exception e) {
            log.error("Falló la revisión de olas de despacho", e);
        }
    }

    void ampliarOlas() {
        Set<String> abiertas = new HashSet<>();
        for (Servicio s : servicioRepository.findByEstado(EstadoServicio.SOLICITADO)) {
            if (s.getId() == null) {
                continue;
            }
            abiertas.add(s.getId());
            int ola = despacho.olaDe(s);
            Integer previa = publicadas.put(s.getId(), ola);
            // Primera vez que se ve: la ola inicial ya la avisó la creación de la solicitud.
            if (previa != null && ola > previa) {
                notificador.notificarOlaAmpliada(s.getId(), ola);
                avisos.olaAmpliada(s, previa, ola);
            }
            if (despacho.sinConductoresTrasUltimaOla(s) && sinConductores.add(s.getId())) {
                avisos.sinConductores(s);
            }
        }
        publicadas.keySet().retainAll(abiertas);
        sinConductores.retainAll(abiertas);
    }
}
