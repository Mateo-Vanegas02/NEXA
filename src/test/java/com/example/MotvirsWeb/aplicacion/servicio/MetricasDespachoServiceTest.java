package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.DespachoOlas;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaPropertiesTestSupport;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class MetricasDespachoServiceTest {

    private static final LocalDateTime AHORA = LocalDateTime.of(2026, 10, 24, 12, 0, 0);
    private final DespachoOlas olas = new DespachoOlas(ModeloNexaPropertiesTestSupport.cargar());

    private static Servicio aceptada(long segundos, int ola, Double km) {
        Servicio s = new Servicio();
        s.setEstado(EstadoServicio.FINALIZADO);
        s.setSolicitadoEn(AHORA.minusHours(1));
        s.setFechaAceptacion(AHORA.minusHours(1).plusSeconds(segundos));
        s.setOlaAceptacion(ola);
        s.setDistanciaRecogidaKm(km);
        return s;
    }

    private static Servicio sinAceptar(EstadoServicio estado, long hace) {
        Servicio s = new Servicio();
        s.setEstado(estado);
        s.setSolicitadoEn(AHORA.minusSeconds(hace));
        return s;
    }

    @Test
    void agrupaPorOlaYCalculaMedianas() {
        var m = MetricasDespachoService.calcular(List.of(
                aceptada(10, 1, 1.0), aceptada(20, 1, 1.2), aceptada(40, 2, 2.0), aceptada(80, 4, null),
                aceptada(15, 0, null), // viaje anterior a la medición
                sinAceptar(EstadoServicio.CANCELADO, 3600),
                sinAceptar(EstadoServicio.SOLICITADO, 30), // aún buscando: no cuenta
                sinAceptar(EstadoServicio.SOLICITADO, 3600)), olas, 30, AHORA);

        assertEquals(8, m.solicitudes());
        assertEquals(5, m.aceptadas());
        assertEquals(2, m.sinConductor());
        assertEquals(28.6, m.porcentajeSinConductor());
        assertEquals(1, m.aceptadasSinMedicion());
        assertEquals(20.0, m.medianaSegundosAceptar());
        assertEquals(80.0, m.p90SegundosAceptar());
        assertEquals(1.2, m.medianaDistanciaKm());

        assertEquals(4, m.olas().size());
        var primera = m.olas().get(0);
        assertEquals(2, primera.aceptadas());
        assertEquals(50.0, primera.porcentaje());
        assertEquals(10.0, primera.medianaSegundos());
        assertEquals(1.5, primera.radioKm());
        assertEquals(0, m.olas().get(2).aceptadas());
        assertNull(m.olas().get(2).medianaSegundos());
        assertEquals(75, m.olas().get(3).desdeSegundos());
        assertNull(m.olas().get(3).medianaDistanciaKm());
    }

    @Test
    void sinDatosNoFalla() {
        var m = MetricasDespachoService.calcular(List.of(), olas, 7, AHORA);
        assertEquals(0, m.solicitudes());
        assertNull(m.medianaSegundosAceptar());
        assertEquals(0, m.porcentajeSinConductor());
    }

    @Test
    void percentilPorRangoMasCercano() {
        assertEquals(2.0, MetricasDespachoService.percentil(List.of(3.0, 1.0, 2.0, 4.0), 50));
        assertEquals(4.0, MetricasDespachoService.percentil(List.of(3.0, 1.0, 2.0, 4.0), 90));
        assertNull(MetricasDespachoService.percentil(List.of(), 50));
    }
}
