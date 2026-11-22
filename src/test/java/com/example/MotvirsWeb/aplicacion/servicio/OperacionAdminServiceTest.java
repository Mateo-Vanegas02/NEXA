package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaPropertiesTestSupport;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class OperacionAdminServiceTest {

    private UbicacionConductorServiceTest.RelojManual reloj;
    private ServicioRepository servicios;
    private AdminService admin;
    private UbicacionConductorService ubicaciones;
    private OperacionAdminService operacion;

    @BeforeEach
    void preparar() {
        reloj = new UbicacionConductorServiceTest.RelojManual();
        servicios = mock(ServicioRepository.class);
        admin = mock(AdminService.class);
        ubicaciones = new UbicacionConductorService(ModeloNexaPropertiesTestSupport.cargar(), reloj);
        operacion = new OperacionAdminService(servicios, ubicaciones, admin, reloj);
    }

    private Servicio solicitud(String id, int minutosAtras) {
        Servicio s = new Servicio();
        s.setId(id);
        s.setEstado(EstadoServicio.SOLICITADO);
        s.setOrigen("Bocagrande");
        s.setFechaHora(LocalDateTime.ofInstant(reloj.ahora, ZoneOffset.UTC).minusMinutes(minutosAtras));
        return s;
    }

    @Test
    void cuentaElDiaLaFlotaYLasAlertas() {
        LocalDateTime inicio = LocalDateTime.of(2026, 10, 24, 0, 0);
        when(servicios.countByFechaHoraGreaterThanEqual(inicio)).thenReturn(12L);
        when(servicios.countByFechaHoraGreaterThanEqualAndEstado(eq(inicio), eq(EstadoServicio.FINALIZADO)))
                .thenReturn(9L);
        when(servicios.countByFechaHoraGreaterThanEqualAndEstado(eq(inicio), eq(EstadoServicio.CANCELADO)))
                .thenReturn(1L);
        when(servicios.countByEstado(EstadoServicio.EN_CURSO)).thenReturn(2L);
        when(servicios.countByEstado(EstadoServicio.ACEPTADO)).thenReturn(1L);
        when(servicios.countByEstado(EstadoServicio.SOLICITADO)).thenReturn(2L);
        when(servicios.findByEstado(EstadoServicio.SOLICITADO))
                .thenReturn(List.of(solicitud("reciente", 2), solicitud("vieja", 7)));
        when(admin.obtenerConductoresPorEstado(EstadoValidacion.PENDIENTE))
                .thenReturn(List.of(new Conductor(), new Conductor()));
        ubicaciones.registrar(new ObjectId(), new PuntoGeo(10.42, -75.52), true);
        ubicaciones.registrar(new ObjectId(), new PuntoGeo(10.43, -75.53), false);

        var r = operacion.resumen();

        assertEquals(12, r.viajesHoy());
        assertEquals(9, r.finalizadosHoy());
        assertEquals(2, r.enCurso());
        assertEquals(2, r.conductoresEnLinea());
        assertEquals(1, r.conductoresDisponibles());
        assertEquals(2, r.conductoresPendientes());
        assertEquals(2, r.flota().size());
        // Solo la solicitud de más de 5 min, y el aviso de los conductores por aprobar.
        assertEquals(2, r.alertas().size());
        assertEquals("vieja", r.alertas().get(0).servicioId());
        assertEquals(7, r.alertas().get(0).minutos());
        assertEquals("CONDUCTORES_POR_APROBAR", r.alertas().get(1).tipo());
    }

    @Test
    void laFlotaNoIncluyePosicionesVencidas() {
        when(admin.obtenerConductoresPorEstado(any())).thenReturn(List.of());
        ubicaciones.registrar(new ObjectId(), new PuntoGeo(10.42, -75.52), true);
        reloj.ahora = reloj.ahora.plusSeconds(120);

        var r = operacion.resumen();

        assertEquals(0, r.conductoresEnLinea());
        assertTrue(r.flota().isEmpty());
        assertTrue(r.alertas().isEmpty());
    }
}
