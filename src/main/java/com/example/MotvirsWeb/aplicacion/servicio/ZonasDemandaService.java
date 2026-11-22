package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Zonas con más solicitudes recientes, para el mapa del conductor. Agrupa el origen de las solicitudes de las últimas
 * {@link #VENTANA} en celdas de {@link #CELDA_GRADOS}° (≈550 m) y devuelve el centro de cada celda, nunca el punto
 * exacto de un pasajero. Una celda con menos de {@link #MINIMO} solicitudes no se muestra.
 */
@Service
public class ZonasDemandaService {

    static final Duration VENTANA = Duration.ofHours(2);
    static final double CELDA_GRADOS = 0.005;
    static final int MINIMO = 2;
    static final int MAX_ZONAS = 15;

    /** Una zona: el centro de la celda, cuántas solicitudes y su intensidad relativa (1 = la que más tiene). */
    public record Zona(double latitud, double longitud, int solicitudes, double intensidad) {
    }

    private final ServicioRepository servicios;
    private final Clock clock;

    public ZonasDemandaService(ServicioRepository servicios, Clock clock) {
        this.servicios = servicios;
        this.clock = clock;
    }

    public List<Zona> zonas() {
        LocalDateTime desde = LocalDateTime.now(clock).minus(VENTANA);
        Map<Long, int[]> celdas = new HashMap<>();
        for (Servicio s : servicios.findByFechaHoraGreaterThanEqual(desde)) {
            Servicio.Coordenada o = s.getUbicacionOrigen();
            if (o == null) {
                continue;
            }
            long fila = (long) Math.floor(o.getLatitud() / CELDA_GRADOS);
            long col = (long) Math.floor(o.getLongitud() / CELDA_GRADOS);
            celdas.computeIfAbsent(fila * 1_000_003L + col, k -> new int[] {(int) fila, (int) col, 0})[2]++;
        }
        List<int[]> visibles = celdas.values().stream()
                .filter(c -> c[2] >= MINIMO)
                .sorted(Comparator.comparingInt((int[] c) -> c[2]).reversed())
                .limit(MAX_ZONAS)
                .toList();
        if (visibles.isEmpty()) {
            return List.of();
        }
        double mayor = visibles.get(0)[2];
        return visibles.stream()
                .map(c -> new Zona(
                        redondear((c[0] + 0.5) * CELDA_GRADOS),
                        redondear((c[1] + 0.5) * CELDA_GRADOS),
                        c[2],
                        Math.round(c[2] / mayor * 100) / 100.0))
                .toList();
    }

    private static double redondear(double v) {
        return Math.round(v * 1e5) / 1e5;
    }
}
