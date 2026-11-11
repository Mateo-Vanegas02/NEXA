package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.DespachoOlas;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Métricas para calibrar el despacho por olas: en qué ola, a qué distancia y en cuánto tiempo se aceptan las
 * solicitudes, y cuántas se quedan sin conductor. Solo lee los campos necesarios del periodo pedido.
 */
@Service
@RequiredArgsConstructor
public class MetricasDespachoService {

    /** Una solicitud que sigue sin conductor tras este tiempo cuenta como "sin conductor". */
    static final long SEGUNDOS_SIN_CONDUCTOR = 10 * 60;

    public record MetricaOla(int ola, int desdeSegundos, Double radioKm, long aceptadas, double porcentaje,
            Double medianaSegundos, Double medianaDistanciaKm) {
    }

    public record MetricasDespacho(int dias, long solicitudes, long aceptadas, long sinConductor,
            double porcentajeSinConductor, Double medianaSegundosAceptar, Double p90SegundosAceptar,
            Double medianaDistanciaKm, long aceptadasSinMedicion, List<MetricaOla> olas) {
    }

    private final ServicioRepository servicios;
    private final DespachoOlas olas;
    private final Clock clock;

    public MetricasDespacho calcular(int dias) {
        int d = Math.max(1, Math.min(dias, 90));
        LocalDateTime ahora = LocalDateTime.now(clock);
        return calcular(servicios.metricasDespachoDesde(ahora.minusDays(d)), olas, d, ahora);
    }

    /** Cálculo puro (probado sin base de datos). */
    static MetricasDespacho calcular(List<Servicio> lista, DespachoOlas olas, int dias, LocalDateTime ahora) {
        int total = olas.totalOlas();
        List<List<Double>> segundosPorOla = new ArrayList<>();
        List<List<Double>> distanciaPorOla = new ArrayList<>();
        for (int i = 0; i < total; i++) {
            segundosPorOla.add(new ArrayList<>());
            distanciaPorOla.add(new ArrayList<>());
        }
        List<Double> segundos = new ArrayList<>();
        List<Double> distancias = new ArrayList<>();
        long aceptadas = 0;
        long sinConductor = 0;
        long sinMedicion = 0;

        for (Servicio s : lista) {
            if (s.getSolicitadoEn() == null) {
                continue;
            }
            if (s.getFechaAceptacion() != null) {
                aceptadas++;
                double seg = Math.max(0, Duration.between(s.getSolicitadoEn(), s.getFechaAceptacion()).getSeconds());
                segundos.add(seg);
                if (s.getDistanciaRecogidaKm() != null) {
                    distancias.add(s.getDistanciaRecogidaKm());
                }
                int ola = s.getOlaAceptacion() > 0 ? s.getOlaAceptacion() : 0;
                if (ola == 0) {
                    sinMedicion++;
                    continue;
                }
                int i = Math.min(ola, total) - 1;
                segundosPorOla.get(i).add(seg);
                if (s.getDistanciaRecogidaKm() != null) {
                    distanciaPorOla.get(i).add(s.getDistanciaRecogidaKm());
                }
            } else if (s.getEstado() == EstadoServicio.CANCELADO
                    || (s.getEstado() == EstadoServicio.SOLICITADO
                            && Duration.between(s.getSolicitadoEn(), ahora).getSeconds() >= SEGUNDOS_SIN_CONDUCTOR)) {
                sinConductor++;
            }
        }

        long medidas = aceptadas - sinMedicion;
        List<MetricaOla> porOla = new ArrayList<>();
        for (int i = 0; i < total; i++) {
            int ola = i + 1;
            double radio = olas.radioKm(ola);
            long n = segundosPorOla.get(i).size();
            porOla.add(new MetricaOla(ola, olas.inicioSegundos(ola), Double.isInfinite(radio) ? null : radio, n,
                    medidas == 0 ? 0 : redondear(100.0 * n / medidas), percentil(segundosPorOla.get(i), 50),
                    percentil(distanciaPorOla.get(i), 50)));
        }
        long cerradas = aceptadas + sinConductor;
        return new MetricasDespacho(dias, lista.size(), aceptadas, sinConductor,
                cerradas == 0 ? 0 : redondear(100.0 * sinConductor / cerradas), percentil(segundos, 50),
                percentil(segundos, 90), percentil(distancias, 50), sinMedicion, porOla);
    }

    /** Percentil por el método del rango más cercano; null si no hay datos. */
    static Double percentil(List<Double> valores, int p) {
        if (valores.isEmpty()) {
            return null;
        }
        List<Double> orden = new ArrayList<>(valores);
        orden.sort(Double::compare);
        int rango = (int) Math.ceil(p / 100.0 * orden.size());
        return redondear(orden.get(Math.max(0, rango - 1)));
    }

    private static double redondear(double v) {
        return Math.round(v * 10) / 10.0;
    }
}
