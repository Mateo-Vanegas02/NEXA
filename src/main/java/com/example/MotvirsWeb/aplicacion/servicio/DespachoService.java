package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.CanalServicio;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.DespachoOlas;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Clock;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/** Despacho por olas: qué solicitudes ve cada conductor según su cercanía y cuánto lleva esperando la solicitud. */
@Service
@RequiredArgsConstructor
public class DespachoService {

    /**
     * Lo que ve el pasajero mientras espera: ola actual, radio y a cuántos conductores se avisó.
     * {@code adelantadaPorExtra} es true cuando su extra voluntario le adelantó la ola.
     */
    public record AvisoDespacho(int ola, int totalOlas, Double radioKm, long conductoresAvisados,
            Long segundosSiguienteOla, boolean adelantadaPorExtra) {
    }

    private final DespachoOlas olas;
    private final UbicacionConductorService ubicaciones;
    private final Clock clock;
    private final com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties cfg;

    /** Posición a usar para el conductor: la que envía la petición, si es válida, o la última vigente. */
    public Optional<PuntoGeo> posicionDe(Conductor conductor, Double lat, Double lng) {
        if (lat != null && lng != null) {
            try {
                return Optional.of(new PuntoGeo(lat, lng));
            } catch (IllegalArgumentException e) {
                // coordenadas inválidas: se ignoran y se usa la última conocida
            }
        }
        return ubicaciones.vigente(conductor.getId());
    }

    /** Deja solo las solicitudes que le tocan a este conductor en la ola actual de cada una. */
    public List<Servicio> filtrarPorOla(List<Servicio> solicitudes, Conductor conductor, Double lat, Double lng) {
        Optional<PuntoGeo> posicion = posicionDe(conductor, lat, lng);
        LocalDateTime ahora = LocalDateTime.now(clock);
        return solicitudes.stream().filter(s -> visible(s, posicion.orElse(null), ahora)).toList();
    }

    /** Un conductor no puede aceptar una solicitud que todavía no le llega (la lista ya se la oculta). */
    public void verificarPuedeAceptar(Servicio servicio, Conductor conductor) {
        if (!visible(servicio, ubicaciones.vigente(conductor.getId()).orElse(null), LocalDateTime.now(clock))) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Esta solicitud aún no llega a tu zona. En unos segundos se amplía el alcance.");
        }
    }

    /** Estado del despacho de una solicitud pendiente, para el pasajero. */
    public AvisoDespacho avisoDe(Servicio servicio) {
        long segundos = segundosEsperando(servicio, LocalDateTime.now(clock));
        boolean extra = conExtra(servicio);
        int ola = olas.ola(segundos, extra);
        double radio = olas.radioKm(ola);
        PuntoGeo origen = origenDe(servicio);
        CanalServicio canal = CanalServicio.oWeb(servicio.getCanal());
        long avisados = origen == null ? 0 : ubicaciones.contarDisponiblesEnRadio(origen, radio, canal);
        // En la última ola también la ven los que dejaron de reportar posición (pantalla bloqueada).
        if (olas.esUltima(ola)) {
            avisados += ubicaciones.contarDisponiblesSinPosicionVigente(canal);
        }
        return new AvisoDespacho(ola, olas.totalOlas(), Double.isInfinite(radio) ? null : radio, avisados,
                olas.segundosParaSiguiente(segundos, extra), extra && olas.olasPorExtra() > 0);
    }

    private static boolean conExtra(Servicio s) {
        return s != null && s.getExtraVoluntario() > 0;
    }

    /** Ola y distancia de recogida en el momento en que este conductor acepta (para las métricas). */
    public record DatosAceptacion(int ola, Double distanciaKm) {
    }

    public DatosAceptacion datosAceptacion(Servicio servicio, Conductor conductor) {
        int ola = olaDe(servicio);
        PuntoGeo origen = origenDe(servicio);
        Double distancia = origen == null ? null
                : ubicaciones.vigente(conductor.getId()).map(p -> redondear(p.distanciaKm(origen))).orElse(null);
        return new DatosAceptacion(ola, distancia);
    }

    private static double redondear(double km) {
        return Math.round(km * 100) / 100.0;
    }

    /** Radio en km de una ola (infinito en la última si no tiene tope). */
    public double radioKm(int ola) {
        return olas.radioKm(ola);
    }

    /**
     * ¿Ya pasó el tiempo para avisar al pasajero que nadie aceptó? Cuenta desde el inicio de la última ola
     * ({@code nexa.despacho.aviso-sin-conductores-segundos} después).
     */
    public boolean sinConductoresTrasUltimaOla(Servicio servicio) {
        if (servicio.getSolicitadoEn() == null) {
            return false;
        }
        long limite = olas.inicioSegundos(olas.totalOlas()) + (long) cfg.getDespacho().getAvisoSinConductoresSegundos();
        return segundosEsperando(servicio) >= limite;
    }

    public boolean esUltimaOla(int ola) {
        return olas.esUltima(ola);
    }

    /** Segundos que lleva esperando una solicitud según el reloj del servidor. */
    public long segundosEsperando(Servicio servicio) {
        return segundosEsperando(servicio, LocalDateTime.now(clock));
    }

    public int olaDe(Servicio servicio) {
        return olas.ola(segundosEsperando(servicio, LocalDateTime.now(clock)), conExtra(servicio));
    }

    private boolean visible(Servicio s, PuntoGeo posicion, LocalDateTime ahora) {
        if (s.getSolicitadoEn() == null) {
            return true; // solicitud antigua sin hora: no se esconde
        }
        PuntoGeo origen = origenDe(s);
        Double distancia = posicion == null || origen == null ? null : posicion.distanciaKm(origen);
        return olas.visible(segundosEsperando(s, ahora), distancia, conExtra(s));
    }

    private static long segundosEsperando(Servicio s, LocalDateTime ahora) {
        return s.getSolicitadoEn() == null ? Long.MAX_VALUE
                : Math.max(0, Duration.between(s.getSolicitadoEn(), ahora).getSeconds());
    }

    private static PuntoGeo origenDe(Servicio s) {
        Servicio.Coordenada o = s.getUbicacionOrigen();
        if (o == null) {
            return null;
        }
        try {
            return new PuntoGeo(o.getLatitud(), o.getLongitud());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
