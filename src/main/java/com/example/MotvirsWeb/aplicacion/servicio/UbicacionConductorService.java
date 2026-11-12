package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.CanalServicio;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import org.bson.types.ObjectId;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Última posición conocida de cada conductor en línea, solo en memoria: cambia cada pocos segundos y solo vale
 * mientras es reciente, así que no se escribe en Mongo. Una posición vencida cuenta como "sin ubicación".
 * Con más de una instancia del servidor habría que moverla a una colección con índice TTL.
 *
 * <p>Cada posición guarda el canal por el que se reportó (WEB o APP): un conductor solo cuenta para las solicitudes
 * de su mismo canal. Los métodos que reciben {@code canal = null} cuentan todos los canales.
 */
@Service
public class UbicacionConductorService {

    private record Registro(PuntoGeo punto, boolean disponible, CanalServicio canal, Instant en) {
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
        registrar(conductorId, punto, disponible, CanalServicio.WEB);
    }

    /** @param canal por dónde reportó el conductor: decide qué solicitudes le llegan */
    public void registrar(ObjectId conductorId, PuntoGeo punto, boolean disponible, CanalServicio canal) {
        ultimas.put(conductorId, new Registro(punto, disponible, CanalServicio.oWeb(canal), clock.instant()));
    }

    /** Posición del conductor si es reciente. */
    public Optional<PuntoGeo> vigente(ObjectId conductorId) {
        Registro r = ultimas.get(conductorId);
        return r != null && esVigente(r) ? Optional.of(r.punto()) : Optional.empty();
    }

    /** Conductores disponibles con posición reciente a {@code radioKm} o menos del punto (infinito = todos). */
    public long contarDisponiblesEnRadio(PuntoGeo centro, double radioKm) {
        return contarDisponiblesEnRadio(centro, radioKm, null);
    }

    /** Igual, pero solo los conductores de ese canal ({@code null} = todos). */
    public long contarDisponiblesEnRadio(PuntoGeo centro, double radioKm, CanalServicio canal) {
        return ultimas.values().stream()
                .filter(r -> deCanal(r, canal) && r.disponible() && esVigente(r) && centro.distanciaKm(r.punto()) <= radioKm)
                .count();
    }

    /**
     * Conductores disponibles con posición reciente entre dos radios: más lejos que {@code desdeKm} y a
     * {@code hastaKm} o menos. Sirve para avisar solo a los que entran en una ola nueva.
     */
    public List<ObjectId> disponiblesEntreRadios(PuntoGeo centro, double desdeKm, double hastaKm, CanalServicio canal) {
        return ultimas.entrySet().stream()
                .filter(e -> {
                    Registro r = e.getValue();
                    if (!deCanal(r, canal) || !r.disponible() || !esVigente(r)) {
                        return false;
                    }
                    double d = centro.distanciaKm(r.punto());
                    return d > desdeKm && d <= hastaKm;
                })
                .map(Map.Entry::getKey).toList();
    }

    /** Conductores en línea de ese canal cuya posición venció pero siguen dentro de la retención. */
    public List<ObjectId> disponiblesSinPosicionVigente(CanalServicio canal) {
        return ultimas.entrySet().stream()
                .filter(e -> deCanal(e.getValue(), canal) && e.getValue().disponible() && !esVigente(e.getValue())
                        && dentroDeRetencion(e.getValue()))
                .map(Map.Entry::getKey).toList();
    }

    /**
     * Conductores en línea cuya posición ya venció: en la web el navegador deja de reportar con la pantalla
     * bloqueada, pero siguen trabajando. Solo ven las solicitudes de la última ola, así que se cuentan ahí.
     */
    public long contarDisponiblesSinPosicionVigente() {
        return contarDisponiblesSinPosicionVigente(null);
    }

    /** Igual, pero solo los de ese canal ({@code null} = todos). */
    public long contarDisponiblesSinPosicionVigente(CanalServicio canal) {
        return ultimas.values().stream()
                .filter(r -> deCanal(r, canal) && r.disponible() && !esVigente(r) && dentroDeRetencion(r))
                .count();
    }

    /** Descarta las posiciones que ya no sirven ni para contar conductores en línea; devuelve cuántas. */
    public int purgar() {
        int antes = ultimas.size();
        ultimas.values().removeIf(r -> !dentroDeRetencion(r));
        return antes - ultimas.size();
    }

    private static boolean deCanal(Registro r, CanalServicio canal) {
        return canal == null || r.canal() == canal;
    }

    private boolean esVigente(Registro r) {
        return Duration.between(r.en(), clock.instant()).compareTo(vigencia) <= 0;
    }

    private boolean dentroDeRetencion(Registro r) {
        return Duration.between(r.en(), clock.instant()).compareTo(retencion) <= 0;
    }
}
