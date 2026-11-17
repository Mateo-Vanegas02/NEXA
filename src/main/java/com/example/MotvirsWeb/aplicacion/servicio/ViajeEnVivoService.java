package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal;
import com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal.PosicionViaje;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.regla.ReglaViaje;
import org.bson.types.ObjectId;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Clock;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Viaje en vivo: mientras un viaje está {@code ACEPTADO} o {@code EN_CURSO}, la posición que reporta el conductor
 * (la misma de {@code POST /conductor/ubicacion}) se reenvía al pasajero de ese viaje y, con el viaje en curso, se
 * va guardando como recorrido real. Todo vive en memoria mientras dura el viaje; al finalizar solo se persiste el
 * recorrido ya reducido (puntos separados ≥ {@code nexa.viaje.punto-minimo-metros}). No hay consultas a Mongo en
 * cada reporte: eso con la latencia de Atlas haría lento el seguimiento.
 */
@Service
public class ViajeEnVivoService {

    /** Recorrido real de un viaje ya terminado. */
    public record Recorrido(double km, List<Servicio.Coordenada> puntos) {
    }

    private static final long MIN_MS_ENTRE_ENVIOS = 1000;

    /** Cuánto vale la última posición para el pasajero (igual que la vigencia de la ubicación del conductor). */
    private static final long VIGENCIA_MS = 45_000;

    private static final class Viaje {
        final String servicioId;
        final String pasajeroId;
        final PuntoGeo recogida;
        final PuntoGeo destino;
        boolean enCurso;
        long ultimoEnvio;
        /** Desde cuándo se guarda el recorrido (ms): puntos más viejos, enviados tras un corte, no cuentan. */
        long inicioMs;
        /** Hora (ms) del último reporte en vivo del conductor en este viaje. */
        long ultimoVivoMs;
        /** Posición más nueva de un lote enviado tras un corte de señal, y su hora (ms). */
        PuntoGeo ultimoDelLote;
        long ultimoDelLoteMs;
        /** Último mensaje calculado: lo consulta el pasajero por REST (la app móvil no usa el WebSocket). */
        volatile PosicionViaje ultima;
        PuntoGeo ultimoGuardado;
        long ultimoGuardadoMs;
        final List<PuntoGeo> recorrido = new ArrayList<>();
        final List<Long> horas = new ArrayList<>();

        Viaje(String servicioId, String pasajeroId, PuntoGeo recogida, PuntoGeo destino, boolean enCurso) {
            this.servicioId = servicioId;
            this.pasajeroId = pasajeroId;
            this.recogida = recogida;
            this.destino = destino;
            this.enCurso = enCurso;
        }
    }

    private final Map<ObjectId, Viaje> porConductor = new ConcurrentHashMap<>();
    private final NotificadorTiempoReal notificador;
    private final ReglaViaje regla;
    private final UbicacionConductorService ubicaciones;
    private final Clock clock;

    public ViajeEnVivoService(NotificadorTiempoReal notificador, ReglaViaje regla,
            UbicacionConductorService ubicaciones, Clock clock) {
        this.notificador = notificador;
        this.regla = regla;
        this.ubicaciones = ubicaciones;
        this.clock = clock;
    }

    /**
     * Empieza (o retoma, tras un reinicio del servidor o una recarga) el seguimiento de un viaje aceptado o en curso.
     * Si ya se sigue ese mismo viaje no hace nada, para no perder el recorrido acumulado.
     */
    public void seguir(Servicio servicio) {
        if (servicio == null || servicio.getConductor() == null || servicio.getConductor().getId() == null
                || servicio.getPasajero() == null || servicio.getPasajero().getId() == null) {
            return;
        }
        if (servicio.getEstado() != EstadoServicio.ACEPTADO && servicio.getEstado() != EstadoServicio.EN_CURSO) {
            return;
        }
        PuntoGeo recogida = punto(servicio.getUbicacionOrigen());
        PuntoGeo destino = punto(servicio.getUbicacionDestino());
        if (recogida == null || destino == null) {
            return;
        }
        boolean enCurso = servicio.getEstado() == EstadoServicio.EN_CURSO;
        porConductor.compute(servicio.getConductor().getId(), (id, actual) -> {
            if (actual != null && actual.servicioId.equals(servicio.getId())) {
                actual.enCurso = actual.enCurso || enCurso;
                return actual;
            }
            return new Viaje(servicio.getId(), servicio.getPasajero().getId().toHexString(), recogida, destino, enCurso);
        });
    }

    /** El viaje pasó a EN_CURSO: desde aquí se guarda el recorrido real. */
    public void iniciar(Servicio servicio) {
        seguir(servicio);
        if (servicio == null || servicio.getConductor() == null || servicio.getConductor().getId() == null) {
            return;
        }
        Viaje v = porConductor.get(servicio.getConductor().getId());
        if (v != null && v.servicioId.equals(servicio.getId())) {
            synchronized (v) {
                v.enCurso = true;
                v.recorrido.clear();
                v.horas.clear();
                v.ultimoGuardado = null;
                v.ultimoGuardadoMs = 0;
                v.inicioMs = servicio.getFechaInicio() == null ? clock.millis()
                        : servicio.getFechaInicio().atZone(clock.getZone()).toInstant().toEpochMilli();
                // El primer punto del recorrido es donde está el conductor al arrancar, si lo conocemos
                long ahora = clock.millis();
                ubicaciones.vigente(servicio.getConductor().getId())
                        .ifPresent(p -> guardar(v, p, Math.max(ahora, v.inicioMs)));
            }
        }
    }

    /**
     * Posición nueva del conductor: la reenvía al pasajero (máx. 1 por segundo) y, con el viaje en curso, la suma al
     * recorrido. Devuelve lo que el servidor calcula (fase, distancia y ETA) para que el conductor lo vea igual que el
     * pasajero; vacío si no tiene un viaje que seguir.
     */
    public java.util.Optional<PosicionViaje> reportar(ObjectId conductorId, PuntoGeo posicion) {
        Viaje v = porConductor.get(conductorId);
        if (v == null) {
            return java.util.Optional.empty();
        }
        PosicionViaje mensaje;
        boolean publicar = false;
        synchronized (v) {
            long ahora = clock.millis();
            if (v.enCurso) {
                guardar(v, posicion, ahora);
            }
            v.ultimoVivoMs = ahora;
            PuntoGeo objetivo = v.enCurso ? v.destino : v.recogida;
            double km = regla.kmPorCalle(posicion, objetivo);
            mensaje = new PosicionViaje(v.servicioId, v.enCurso ? "EN_CURSO" : "ACEPTADO",
                    posicion.latitud(), posicion.longitud(), km, regla.etaMinutos(km), ahora);
            v.ultima = mensaje;
            if (ahora - v.ultimoEnvio >= MIN_MS_ENTRE_ENVIOS) {
                v.ultimoEnvio = ahora;
                publicar = true;
            }
        }
        if (publicar) {
            notificador.notificarPosicionConductor(v.pasajeroId, mensaje);
        }
        return java.util.Optional.of(mensaje);
    }

    /** Posición guardada en el teléfono durante un corte de señal, con la hora en que se tomó. */
    public record PuntoConHora(PuntoGeo punto, long ms) {
    }

    /**
     * Posiciones que el teléfono guardó sin señal y envía al volver: se suman al recorrido real en el orden de sus
     * horas (no del envío) con la misma regla que en vivo, y la más nueva pasa a ser la última conocida. No se reenvían
     * al pasajero (ya son viejas). Devuelve cuántos puntos quedaron en el recorrido.
     */
    public int reportarLote(ObjectId conductorId, List<PuntoConHora> puntos) {
        Viaje v = conductorId == null ? null : porConductor.get(conductorId);
        if (v == null || puntos == null || puntos.isEmpty()) {
            return 0;
        }
        synchronized (v) {
            List<PuntoConHora> ordenados = puntos.stream()
                    .sorted(java.util.Comparator.comparingLong(PuntoConHora::ms)).toList();
            PuntoConHora ultimo = ordenados.get(ordenados.size() - 1);
            if (ultimo.ms() > v.ultimoDelLoteMs) {
                v.ultimoDelLote = ultimo.punto();
                v.ultimoDelLoteMs = ultimo.ms();
            }
            if (!v.enCurso) {
                return 0;
            }
            int antes = v.recorrido.size();
            List<PuntoConHora> utiles = ordenados.stream().filter(p -> p.ms() >= v.inicioMs).toList();
            if (utiles.isEmpty()) {
                return 0;
            }
            if (utiles.get(0).ms() >= v.ultimoGuardadoMs) {
                utiles.forEach(p -> guardar(v, p.punto(), p.ms()));
            } else {
                // Llegan puntos anteriores a los ya guardados: se rearma el recorrido en orden de hora
                List<PuntoConHora> todos = new ArrayList<>();
                for (int i = 0; i < v.recorrido.size(); i++) {
                    todos.add(new PuntoConHora(v.recorrido.get(i), v.horas.get(i)));
                }
                todos.addAll(utiles);
                todos.sort(java.util.Comparator.comparingLong(PuntoConHora::ms));
                v.recorrido.clear();
                v.horas.clear();
                v.ultimoGuardado = null;
                v.ultimoGuardadoMs = 0;
                todos.forEach(p -> guardar(v, p.punto(), p.ms()));
            }
            return Math.max(0, v.recorrido.size() - antes);
        }
    }

    /**
     * Última posición del conductor del viaje {@code servicioId} para su pasajero (REST, sin WebSocket). Vacío si el
     * viaje no es de ese pasajero, no se sigue o el conductor dejó de reportar hace más de {@link #VIGENCIA_MS}.
     */
    public Optional<PosicionViaje> posicionDe(String servicioId, String pasajeroId) {
        if (servicioId == null || pasajeroId == null) {
            return Optional.empty();
        }
        long ahora = clock.millis();
        return porConductor.values().stream()
                .filter(v -> v.servicioId.equals(servicioId) && v.pasajeroId.equals(pasajeroId))
                .map(v -> v.ultima)
                .filter(p -> p != null && ahora - p.en() <= VIGENCIA_MS)
                .findFirst();
    }

    /** Deja de seguir el viaje y devuelve el recorrido real acumulado (null si no se seguía ese viaje). */
    public Recorrido terminar(ObjectId conductorId, String servicioId) {
        if (conductorId == null) {
            return null;
        }
        Viaje v = porConductor.get(conductorId);
        if (v == null || !v.servicioId.equals(servicioId)) {
            return null;
        }
        porConductor.remove(conductorId, v);
        synchronized (v) {
            if (v.recorrido.size() < 2) {
                return new Recorrido(0, List.of());
            }
            List<Servicio.Coordenada> puntos = v.recorrido.stream()
                    .map(p -> new Servicio.Coordenada(p.latitud(), p.longitud())).toList();
            return new Recorrido(ReglaViaje.distanciaRecorridaKm(v.recorrido), puntos);
        }
    }

    /** Instantánea del recorrido para calcular el cobro antes de cerrar el viaje en MongoDB. */
    public Recorrido recorridoActual(ObjectId conductorId, String servicioId) {
        Viaje v = conductorId == null ? null : porConductor.get(conductorId);
        if (v == null || !v.servicioId.equals(servicioId)) return null;
        synchronized (v) {
            if (v.recorrido.size() < 2) return new Recorrido(0, List.of());
            return new Recorrido(ReglaViaje.distanciaRecorridaKm(v.recorrido), v.recorrido.stream()
                    .map(p -> new Servicio.Coordenada(p.latitud(), p.longitud())).toList());
        }
    }

    /**
     * ¿Llegó el conductor al destino según la última posición que reportó al servidor (no la que diga el navegador)?
     * Con {@code nexa.viaje.exigir-destino=false} (solo desarrollo con recorrido simulado) siempre es true.
     */
    public boolean estaEnElDestino(Servicio servicio, ObjectId conductorId) {
        if (!regla.exigeDestino()) {
            return true;
        }
        PuntoGeo destino = punto(servicio.getUbicacionDestino());
        if (destino == null) {
            return true;
        }
        return ultimaPosicion(servicio, conductorId).map(p -> regla.enElDestino(p, destino)).orElse(false);
    }

    /**
     * Dónde está el conductor según el servidor: su posición vigente o, si se quedó sin señal y envió lo guardado al
     * volver, la última posición de ese lote (si es posterior a su último reporte en vivo). Una posición en vivo ya
     * vencida no cuenta, y nunca la que diga el teléfono en la acción.
     */
    private Optional<PuntoGeo> ultimaPosicion(Servicio servicio, ObjectId conductorId) {
        Optional<PuntoGeo> vigente = ubicaciones.vigente(conductorId);
        if (vigente.isPresent()) {
            return vigente;
        }
        Viaje v = conductorId == null ? null : porConductor.get(conductorId);
        if (v == null || !v.servicioId.equals(servicio.getId())) {
            return Optional.empty();
        }
        synchronized (v) {
            return v.ultimoDelLote != null && v.ultimoDelLoteMs >= v.ultimoVivoMs
                    ? Optional.of(v.ultimoDelLote) : Optional.empty();
        }
    }

    /**
     * Fracción del viaje que se cobra al finalizar (ver {@link ReglaViaje#factorCobro}). Se mide con el recorrido
     * real; si el servidor lo perdió (reinicio), se estima con la distancia por calle de la recogida a la posición.
     */
    public double factorCobro(Servicio servicio, ObjectId conductorId, Recorrido recorrido) {
        if (estaEnElDestino(servicio, conductorId)) {
            return 1.0;
        }
        Double km = recorrido != null && !recorrido.puntos().isEmpty() ? recorrido.km() : null;
        if (km == null) {
            PuntoGeo origen = punto(servicio.getUbicacionOrigen());
            Optional<PuntoGeo> posicion = ultimaPosicion(servicio, conductorId);
            if (origen != null && posicion.isPresent()) {
                km = regla.kmPorCalle(origen, posicion.get());
            }
        }
        return regla.factorCobro(false, km, servicio.getDistanciaKM());
    }

    private void guardar(Viaje v, PuntoGeo p, long ms) {
        if (regla.debeGuardarPunto(v.ultimoGuardado, p, v.recorrido.size())) {
            v.recorrido.add(p);
            v.horas.add(ms);
            v.ultimoGuardado = p;
            v.ultimoGuardadoMs = ms;
        }
    }

    private static PuntoGeo punto(Servicio.Coordenada c) {
        return c == null ? null : new PuntoGeo(c.getLatitud(), c.getLongitud());
    }
}
