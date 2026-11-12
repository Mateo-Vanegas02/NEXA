package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.Dispositivo;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Rol;
import com.example.MotvirsWeb.dominio.repositorio.DispositivoRepository;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class DispositivosServiceTest {

    private final DispositivoRepository repo = mock(DispositivoRepository.class);
    private final DispositivosService servicio = new DispositivosService(repo,
            Clock.fixed(Instant.parse("2026-11-11T17:00:00Z"), ZoneId.of("America/Bogota")));
    private final Pasajero laura = Pasajero.builder().id(new ObjectId()).rol(Rol.PASAJERO).email("l@t.co").build();

    @Test
    void unTokenDeOtraCuentaPasaAQuienInicioSesion() {
        Dispositivo previo = new Dispositivo("d1", new ObjectId(), Rol.CONDUCTOR, "tok", "ANDROID", LocalDateTime.MIN);
        when(repo.findByToken("tok")).thenReturn(Optional.of(previo));

        servicio.registrar(laura, " tok ", null);

        ArgumentCaptor<Dispositivo> guardado = ArgumentCaptor.forClass(Dispositivo.class);
        verify(repo).save(guardado.capture());
        assertEquals("d1", guardado.getValue().getId());
        assertEquals(laura.getId(), guardado.getValue().getUsuarioId());
        assertEquals(Rol.PASAJERO, guardado.getValue().getRol());
        assertEquals("ANDROID", guardado.getValue().getPlataforma());
    }

    @Test
    void cadaCuentaGuardaComoMaximoCincoTelefonos() {
        when(repo.findByToken(any())).thenReturn(Optional.empty());
        List<Dispositivo> suyos = new ArrayList<>();
        for (int i = 0; i < 7; i++) {
            suyos.add(new Dispositivo("d" + i, laura.getId(), Rol.PASAJERO, "t" + i, "ANDROID", LocalDateTime.MIN));
        }
        when(repo.findByUsuarioIdOrderByActualizadoEnDesc(laura.getId())).thenReturn(suyos);

        servicio.registrar(laura, "t0", "ANDROID");

        verify(repo).deleteAll(suyos.subList(5, 7));
    }

    @Test
    void cerrarSesionSoloQuitaElTokenDeEsaCuenta() {
        servicio.eliminar(laura, "tok");
        verify(repo).deleteByUsuarioIdAndToken(laura.getId(), "tok");
        verify(repo, never()).deleteByToken(any());
    }
}
