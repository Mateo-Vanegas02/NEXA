package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import org.bson.types.ObjectId;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Última posición conocida de cada conductor en línea, solo en memoria: cambia cada pocos segundos y solo vale
 * mientras es reciente, así que no se escribe en Mongo. Una posición vencida cuenta como "sin ubicación".
 * Con más de una instancia del servidor habría que moverla a una colección con índice TTL.
 */
@Service
public class UbicacionConductorService {

    private record Registro(PuntoGeo punto, boolean disponible, Instant en) {
    }

    private final Map<ObjectId, Registro> ultimas = new ConcurrentHashMap<>();
    private final Duration vigencia;
    private final Duration retencion;
    private final Clock clock;

    public UbicacionConductorService(ModeloNexaProperties cfg, Clock clock) {
        this.vigencia = Duration.ofSeconds(cfg.getDespacho().getUbicacionVigenciaSegundos());
        this.retencion = Duration.ofMinutes(Math.max(1, cfg.getDespacho().getRetencionMinutos()));
        this.clock = clock;
    }

    /** @param disponible false si el conductor está en un viaje: no cuenta como aviso para nuevas solicitudes */
    public void registrar(ObjectId conductorId, PuntoGeo punto, boolean disponible) {
        ultimas.put(conductorId, new Registro(punto, disponible, clock.instant()));
    }

    /** Posición del conductor si es reciente. */
    public Optional<PuntoGeo> vigente(ObjectId conductorId) {
        Registro r = ultimas.get(conductorId);
        return r != null && esVigente(r) ? Optional.of(r.punto()) : Optional.empty();
    }

    /** Conductores disponibles con posición reciente a {@code radioKm} o menos del punto (infinito = todos). */
    public long contarDisponiblesEnRadio(PuntoGeo centro, double radioKm) {
        return ultimas.values().stream()
                .filter(r -> r.disponible() && esVigente(r) && centro.distanciaKm(r.punto()) <= radioKm)
                .count();
    }

    /**
     * Conductores en línea cuya posición ya venció: en la web el navegador deja de reportar con la pantalla
     * bloqueada, pero siguen trabajando. Solo ven las solicitudes de la última ola, así que se cuentan ahí.
     */
    public long contarDisponiblesSinPosicionVigente() {
        return ultimas.values().stream()
                .filter(r -> r.disponible() && !esVigente(r) && dentroDeRetencion(r))
                .count();
    }

    /** Descarta las posiciones que ya no sirven ni para contar conductores en línea; devuelve cuántas. */
    public int purgar() {
        int antes = ultimas.size();
        ultimas.values().removeIf(r -> !dentroDeRetencion(r));
        return antes - ultimas.size();
    }

    private boolean esVigente(Registro r) {
        return Duration.between(r.en(), clock.instant()).compareTo(vigencia) <= 0;
    }

    private boolean dentroDeRetencion(Registro r) {
        return Duration.between(r.en(), clock.instant()).compareTo(retencion) <= 0;
    }
}
