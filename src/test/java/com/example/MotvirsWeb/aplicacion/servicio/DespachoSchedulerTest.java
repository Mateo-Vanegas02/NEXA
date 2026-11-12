package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class DespachoSchedulerTest {

    private final ServicioRepository repo = mock(ServicioRepository.class);
    private final DespachoService despacho = mock(DespachoService.class);
    private final NotificadorTiempoReal notificador = mock(NotificadorTiempoReal.class);
    private final AvisosService avisos = mock(AvisosService.class);
    private final DespachoScheduler scheduler =
            new DespachoScheduler(repo, despacho, mock(UbicacionConductorService.class),
                    mock(SeguimientoPasajeroService.class), notificador, avisos);

    private Servicio solicitud(String id) {
        Servicio s = new Servicio();
        s.setId(id);
        return s;
    }

    @Test
    void avisaSoloCuandoLaOlaCreceYNoLaPrimeraVez() {
        Servicio s = solicitud("s1");
        when(repo.findByEstado(EstadoServicio.SOLICITADO)).thenReturn(List.of(s));
        when(despacho.olaDe(s)).thenReturn(1, 1, 2, 2);

        scheduler.ampliarOlas(); // primera vez: la ola inicial ya la avisó la creación
        scheduler.ampliarOlas(); // sigue en la 1
        verify(notificador, never()).notificarOlaAmpliada(anyString(), anyInt());

        scheduler.ampliarOlas(); // pasó a la 2
        verify(notificador).notificarOlaAmpliada("s1", 2);
        verify(avisos).olaAmpliada(s, 1, 2);

        scheduler.ampliarOlas(); // sigue en la 2
        verify(notificador, times(1)).notificarOlaAmpliada(anyString(), anyInt());
    }

    @Test
    void olvidaLasSolicitudesQueYaNoEstanAbiertas() {
        Servicio s = solicitud("s1");
        when(repo.findByEstado(EstadoServicio.SOLICITADO)).thenReturn(List.of(s), List.of(), List.of(s));
        when(despacho.olaDe(s)).thenReturn(3);

        scheduler.ampliarOlas();
        scheduler.ampliarOlas(); // ya no está abierta
        scheduler.ampliarOlas(); // reaparece: cuenta como primera vez, no se avisa
        verify(notificador, never()).notificarOlaAmpliada(anyString(), anyInt());
    }

    @Test
    void avisaSinConductoresUnaSolaVezPorSolicitud() {
        Servicio s = solicitud("s1");
        when(repo.findByEstado(EstadoServicio.SOLICITADO)).thenReturn(List.of(s));
        when(despacho.olaDe(s)).thenReturn(4);
        when(despacho.sinConductoresTrasUltimaOla(s)).thenReturn(false, true, true);

        scheduler.ampliarOlas();
        verify(avisos, never()).sinConductores(s);
        scheduler.ampliarOlas();
        scheduler.ampliarOlas();
        verify(avisos, times(1)).sinConductores(s);
    }
}
