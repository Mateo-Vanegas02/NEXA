package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.CanalPeticion;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.regla.ReglaSinConexion;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

/**
 * Posiciones que el conductor guardó sin señal (fase 5 de la app). Se aceptan solo las que caen dentro de la tolerancia
 * sin conexión; se suman al recorrido real del viaje en el orden de sus horas y la más nueva, si es reciente, vuelve a
 * ser su posición vigente para el despacho.
 */
@Service
public class UbicacionLoteService {

    public record Resultado(int recibidos, int aceptados, int guardados) {
    }

    private final ServicioService servicios;
    private final ViajeEnVivoService viajeEnVivo;
    private final UbicacionConductorService ubicaciones;
    private final CanalPeticion canal;
    private final ModeloNexaProperties cfg;
    private final Clock clock;

    public UbicacionLoteService(ServicioService servicios, ViajeEnVivoService viajeEnVivo,
            UbicacionConductorService ubicaciones, CanalPeticion canal, ModeloNexaProperties cfg, Clock clock) {
        this.servicios = servicios;
        this.viajeEnVivo = viajeEnVivo;
        this.ubicaciones = ubicaciones;
        this.canal = canal;
        this.cfg = cfg;
        this.clock = clock;
    }

    public record Punto(PuntoGeo punto, Instant tomada) {
    }

    public Resultado recibir(Conductor conductor, List<Punto> puntos) {
        if (puntos.size() > cfg.getSinConexion().getMaxPuntosLote()) {
            throw new IllegalArgumentException(
                    "Máximo " + cfg.getSinConexion().getMaxPuntosLote() + " posiciones por envío");
        }
        Optional<Servicio> activo = servicios.obtenerViajeActivo(conductor);
        long tolerancia = ReglaSinConexion.toleranciaMinutos(cfg.getSinConexion().getToleranciaMinutos(),
                activo.map(s -> s.getEstado() == EstadoServicio.EN_CURSO).orElse(false),
                activo.map(Servicio::getDuracionEstimadaMin).orElse(0.0));
        LocalDateTime ahora = LocalDateTime.now(clock);
        List<Punto> aceptados = puntos.stream()
                .filter(p -> ReglaSinConexion.puntoAceptable(ahora,
                        LocalDateTime.ofInstant(p.tomada(), clock.getZone()), tolerancia))
                .sorted(Comparator.comparing(Punto::tomada))
                .toList();
        if (aceptados.isEmpty()) {
            return new Resultado(puntos.size(), 0, 0);
        }
        activo.ifPresent(viajeEnVivo::seguir);
        int guardados = viajeEnVivo.reportarLote(conductor.getId(), aceptados.stream()
                .map(p -> new ViajeEnVivoService.PuntoConHora(p.punto(), p.tomada().toEpochMilli()))
                .toList());
        // La más nueva vuelve a ser su posición vigente solo si es de hace segundos (no lo pone en línea con una vieja)
        Punto ultimo = aceptados.get(aceptados.size() - 1);
        long segundos = cfg.getDespacho().getUbicacionVigenciaSegundos();
        if (!ultimo.tomada().isBefore(clock.instant().minusSeconds(segundos))) {
            ubicaciones.registrar(conductor.getId(), ultimo.punto(), activo.isEmpty(), canal.actual());
        }
        return new Resultado(puntos.size(), aceptados.size(), guardados);
    }
}
