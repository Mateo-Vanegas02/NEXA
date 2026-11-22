package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class ZonasDemandaServiceTest {

    private final Clock reloj = Clock.fixed(Instant.parse("2026-11-22T15:00:00Z"), ZoneOffset.UTC);

    private static Servicio en(double lat, double lng) {
        Servicio s = new Servicio();
        Servicio.Coordenada c = new Servicio.Coordenada();
        c.setLatitud(lat);
        c.setLongitud(lng);
        s.setUbicacionOrigen(c);
        return s;
    }

    @Test
    void agrupaPorCeldaYOcultaLasCeldasConUnaSolaSolicitud() {
        ServicioRepository repo = mock(ServicioRepository.class);
        List<Servicio> lista = new ArrayList<>();
        // Bocagrande: tres solicitudes en la misma celda; Manga: dos; un punto suelto.
        lista.add(en(10.3991, -75.5541));
        lista.add(en(10.3992, -75.5542));
        lista.add(en(10.3993, -75.5543));
        lista.add(en(10.4111, -75.5371));
        lista.add(en(10.4112, -75.5372));
        lista.add(en(10.4500, -75.5000));
        lista.add(new Servicio());
        when(repo.findByFechaHoraGreaterThanEqual(LocalDateTime.of(2026, 11, 22, 13, 0))).thenReturn(lista);

        var zonas = new ZonasDemandaService(repo, reloj).zonas();

        assertEquals(2, zonas.size());
        assertEquals(3, zonas.get(0).solicitudes());
        assertEquals(1.0, zonas.get(0).intensidad());
        assertEquals(0.67, zonas.get(1).intensidad());
        // El centro de la celda, no el punto de un pasajero.
        assertEquals(10.3975, zonas.get(0).latitud(), 1e-9);
        assertTrue(zonas.stream().noneMatch(z -> z.latitud() == 10.3991));
    }

    @Test
    void sinSolicitudesNoHayZonas() {
        ServicioRepository repo = mock(ServicioRepository.class);
        assertTrue(new ZonasDemandaService(repo, reloj).zonas().isEmpty());
    }
}
