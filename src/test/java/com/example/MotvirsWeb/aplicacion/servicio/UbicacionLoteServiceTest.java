package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.CanalPeticion;
import com.example.MotvirsWeb.dominio.modelo.CanalServicio;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaPropertiesTestSupport;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class UbicacionLoteServiceTest {

    private static final Instant AHORA = Instant.parse("2026-11-13T15:00:00Z");
    private static final PuntoGeo A = new PuntoGeo(10.42, -75.52);
    private static final PuntoGeo B = new PuntoGeo(10.43, -75.52);

    private final ServicioService servicios = mock(ServicioService.class);
    private final ViajeEnVivoService viajeEnVivo = mock(ViajeEnVivoService.class);
    private final UbicacionConductorService ubicaciones = mock(UbicacionConductorService.class);
    private final CanalPeticion canal = mock(CanalPeticion.class);
    private final Conductor conductor = new Conductor();
    private ModeloNexaProperties cfg;
    private UbicacionLoteService lote;

    @BeforeEach
    void setUp() {
        conductor.setId(new ObjectId());
        cfg = ModeloNexaPropertiesTestSupport.cargar();
        when(canal.actual()).thenReturn(CanalServicio.APP);
        lote = new UbicacionLoteService(servicios, viajeEnVivo, ubicaciones, canal, cfg,
                Clock.fixed(AHORA, ZoneOffset.UTC));
    }

    @SuppressWarnings("unchecked")
    @Test
    void conViajeEnCursoAceptaElCorteDeTodaLaCarreraYDescartaLoViejo() {
        Servicio s = new Servicio();
        s.setEstado(EstadoServicio.EN_CURSO);
        s.setDuracionEstimadaMin(20);
        when(servicios.obtenerViajeActivo(conductor)).thenReturn(Optional.of(s));
        when(viajeEnVivo.reportarLote(eq(conductor.getId()), any())).thenReturn(2);

        UbicacionLoteService.Resultado r = lote.recibir(conductor, List.of(
                new UbicacionLoteService.Punto(B, AHORA.minusSeconds(10)),
                new UbicacionLoteService.Punto(A, AHORA.minusSeconds(15 * 60)),
                new UbicacionLoteService.Punto(A, AHORA.minusSeconds(40 * 60))));

        assertEquals(3, r.recibidos());
        assertEquals(2, r.aceptados());
        ArgumentCaptor<List<ViajeEnVivoService.PuntoConHora>> puntos = ArgumentCaptor.forClass(List.class);
        verify(viajeEnVivo).reportarLote(eq(conductor.getId()), puntos.capture());
        assertEquals(A, puntos.getValue().get(0).punto(), "en orden de hora");
        // La más nueva (hace 10 s) vuelve a ser su posición vigente, ocupado en el viaje
        verify(ubicaciones).registrar(conductor.getId(), B, false, CanalServicio.APP);
    }

    @Test
    void sinViajeSoloCincoMinutosYUnaPosicionViejaNoLoPoneEnLinea() {
        when(servicios.obtenerViajeActivo(conductor)).thenReturn(Optional.empty());

        UbicacionLoteService.Resultado r = lote.recibir(conductor, List.of(
                new UbicacionLoteService.Punto(A, AHORA.minusSeconds(4 * 60)),
                new UbicacionLoteService.Punto(B, AHORA.minusSeconds(6 * 60))));

        assertEquals(1, r.aceptados());
        verify(ubicaciones, never()).registrar(any(), any(), eq(true), any());
    }

    @Test
    void unLoteDemasiadoGrandeSeRechaza() {
        int max = cfg.getSinConexion().getMaxPuntosLote();
        List<UbicacionLoteService.Punto> muchos = java.util.stream.IntStream.rangeClosed(0, max)
                .mapToObj(i -> new UbicacionLoteService.Punto(A, AHORA)).toList();
        assertThrows(IllegalArgumentException.class, () -> lote.recibir(conductor, muchos));
    }
}
