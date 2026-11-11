package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Posición en vivo del pasajero mientras su conductor va en camino. Solo en memoria (cambia cada pocos segundos y
 * vale poco tiempo, igual que {@link UbicacionConductorService}) y solo la ve el conductor de ese viaje, y solo
 * entre que acepta y que inicia el viaje. Nunca se escribe en Mongo ni cambia el punto de recogida del servicio.
 * Con más de una instancia del servidor habría que moverla a una colección con índice TTL.
 */
@Service
public class SeguimientoPasajeroService {

    /** Lo que ve el conductor: dónde está el pasajero y qué tan lejos queda del punto de recogida. */
    public record PosicionPasajero(double latitud, double longitud, long haceSegundos, long distanciaRecogidaMetros) {
    }

    private record Registro(PuntoGeo punto, Instant en) {
    }

    private final Map<String, Registro> ultimas = new ConcurrentHashMap<>();
    private final ServicioRepository servicios;
    private final Duration vigencia;
    private final Clock clock;

    public SeguimientoPasajeroService(ServicioRepository servicios, ModeloNexaProperties cfg, Clock clock) {
        this.servicios = servicios;
        this.vigencia = Duration.ofSeconds(Math.max(5, cfg.getSeguimiento().getVigenciaSegundos()));
        this.clock = clock;
    }

    /** El pasajero reporta dónde está. Solo vale para su propio viaje ya aceptado y aún sin iniciar. */
    public void reportar(String servicioId, Pasajero pasajero, PuntoGeo punto) {
        Servicio servicio = buscar(servicioId);
        if (servicio.getPasajero() == null || !servicio.getPasajero().getId().equals(pasajero.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Este viaje no es tuyo");
        }
        if (servicio.getEstado() != EstadoServicio.ACEPTADO) {
            ultimas.remove(servicioId);
            throw new ResponseStatusException(HttpStatus.CONFLICT, "El conductor aún no va en camino o el viaje ya empezó");
        }
        ultimas.put(servicioId, new Registro(punto, clock.instant()));
    }

    /** Viaje del pasajero que ya tiene conductor en camino (para retomarlo y seguir reportando tras recargar). */
    public Optional<Servicio> viajeEnCamino(Pasajero pasajero) {
        return servicios.findByPasajeroIdAndEstado(pasajero.getId(), EstadoServicio.ACEPTADO).stream().findFirst();
    }

    /** Posición reciente del pasajero para el conductor asignado; vacío si no hay o ya venció. */
    public Optional<PosicionPasajero> consultar(String servicioId, Conductor conductor) {
        Servicio servicio = buscar(servicioId);
        if (servicio.getConductor() == null || !servicio.getConductor().getId().equals(conductor.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Este viaje no es tuyo");
        }
        if (servicio.getEstado() != EstadoServicio.ACEPTADO) {
            ultimas.remove(servicioId);
            return Optional.empty();
        }
        Registro r = ultimas.get(servicioId);
        if (r == null) {
            return Optional.empty();
        }
        long edad = Duration.between(r.en(), clock.instant()).toSeconds();
        if (edad > vigencia.toSeconds()) {
            return Optional.empty();
        }
        long distancia = 0;
        if (servicio.getUbicacionOrigen() != null) {
            PuntoGeo recogida = new PuntoGeo(servicio.getUbicacionOrigen().getLatitud(),
                    servicio.getUbicacionOrigen().getLongitud());
            distancia = Math.round(r.punto().distanciaKm(recogida) * 1000);
        }
        return Optional.of(new PosicionPasajero(r.punto().latitud(), r.punto().longitud(), edad, distancia));
    }

    /** Descarta las posiciones vencidas (viajes que se cancelaron o terminaron sin que nadie consultara). */
    public int purgar() {
        int antes = ultimas.size();
        Instant limite = clock.instant().minus(vigencia.multipliedBy(4));
        ultimas.values().removeIf(r -> r.en().isBefore(limite));
        return antes - ultimas.size();
    }

    private Servicio buscar(String servicioId) {
        return servicios.findById(servicioId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Servicio no encontrado"));
    }
}
