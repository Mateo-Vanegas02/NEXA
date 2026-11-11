package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.regla.CatalogoBeneficios;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaPropertiesTestSupport;
import com.example.MotvirsWeb.dominio.regla.ModeloTarifa;
import com.example.MotvirsWeb.dominio.regla.ModeloXp;
import com.example.MotvirsWeb.dominio.regla.PrioridadRecogida;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.example.MotvirsWeb.dominio.repositorio.XpEventoRepository;
import com.example.MotvirsWeb.presentacion.dto.NivelDto;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.web.server.ResponseStatusException;

import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneId;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;

class NivelesServiceTest {

    private ModeloXp xp;
    private NivelesService service;
    private com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo correo;

    @BeforeEach
    void preparar() {
        ModeloNexaProperties cfg = ModeloNexaPropertiesTestSupport.cargar();
        correo = mock(com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo.class);
        xp = new ModeloXp(cfg);
        ModeloTarifa tarifa = new ModeloTarifa(cfg);
        PrioridadRecogida prioridad = new PrioridadRecogida(cfg);
        service = new NivelesService(cfg, xp, tarifa, prioridad, new CatalogoBeneficios(cfg, tarifa, prioridad),
                mock(UsuarioRepository.class), mock(ServicioRepository.class), mock(XpEventoRepository.class),
                Clock.system(ZoneId.of("America/Bogota")), mock(MongoTemplate.class), correo);
    }

    private Pasajero pasajero(int nivel, double xpTotal) {
        Pasajero p = new Pasajero();
        p.setId(new ObjectId());
        p.setNivel(nivel);
        p.setXpTotal(xpTotal);
        return p;
    }

    @Test
    void usuarioNuevoCuentaComoNivelUno() {
        NivelDto dto = service.estado(pasajero(0, 0));
        assertEquals(1, dto.nivel());
        assertEquals("pasajero", dto.rol());
        assertEquals(0.0, dto.descuento());
        assertEquals(xp.xpParaNivel(2), dto.xpSiguienteNivel());
    }

    @Test
    void elPasajeroNoTieneTechoYLaEscaleraCreceConElNivel() {
        NivelDto dto = service.estado(pasajero(8, xp.xpParaNivel(8)));
        assertEquals(8, dto.nivel());
        assertEquals(9, dto.niveles().size());
        assertNotNull(dto.xpSiguienteNivel());
        assertTrue(dto.descuento() > 0);
    }

    @Test
    void conductorEnElNivelMaximoNoTieneSiguiente() {
        Conductor c = new Conductor();
        c.setId(new ObjectId());
        c.setNivel(xp.nivelMaximoConductor());
        c.setXp90d(xp.xpConductorParaNivel(xp.nivelMaximoConductor()));
        NivelDto dto = service.estado(c);
        assertEquals("conductor", dto.rol());
        assertNull(dto.xpSiguienteNivel());
        assertEquals(1.0, dto.progreso());
        assertNull(dto.conductor().comisionSiguiente());
    }

    @Test
    void xpFaltanteDelConductorEsLaDistanciaAlSiguienteNivel() {
        Conductor c = new Conductor();
        c.setId(new ObjectId());
        c.setNivel(1);
        c.setXp90d(100);
        Double faltante = service.xpFaltanteConductor(c);
        assertNotNull(faltante);
        assertEquals(xp.xpConductorParaNivel(2) - 100, faltante, 0.11);
    }

    @Test
    void xpFaltanteDelConductorEsNuloEnElNivelMaximo() {
        Conductor c = new Conductor();
        c.setId(new ObjectId());
        c.setNivel(xp.nivelMaximoConductor());
        c.setXp90d(xp.xpConductorParaNivel(xp.nivelMaximoConductor()));
        assertNull(service.xpFaltanteConductor(c));
    }

    @Test
    void inactividadBajaAlInicioDelNivelAnterior() {
        Pasajero p = pasajero(4, xp.xpParaNivel(4) + 50);
        LocalDateTime ahora = LocalDateTime.of(2026, 10, 1, 8, 0);
        p.setUltimoViajeEn(ahora.minusDays(120));
        assertTrue(service.bajaPorInactividad(p, ahora.minusDays(90), ahora));
        assertEquals(3, p.getNivel());
        assertEquals(xp.xpParaNivel(3), p.getXpTotal());
    }

    @Test
    void nivelUnoNoBajaPorInactividad() {
        Pasajero p = pasajero(1, 100);
        LocalDateTime ahora = LocalDateTime.of(2026, 10, 1, 8, 0);
        p.setUltimoViajeEn(ahora.minusDays(400));
        assertFalse(service.bajaPorInactividad(p, ahora.minusDays(90), ahora));
    }

    @Test
    void favoritosSoloDesdeElNivelCinco() {
        Pasajero p = pasajero(4, xp.xpParaNivel(4));
        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> service.cambiarFavorito(p, new ObjectId().toHexString(), true));
        assertEquals(403, e.getStatusCode().value());
    }

    @Test
    void seAvisaEnLosDiasPreviosAPerderElNivel() {
        LocalDateTime ahora = LocalDateTime.of(2026, 10, 24, 12, 0);
        Pasajero p = pasajero(3, 1000);
        p.setUltimoViajeEn(ahora.minusDays(80));           // faltan 10 días para los 90

        assertTrue(service.debeAvisarInactividad(p, ahora));
        assertEquals(ahora.minusDays(80).plusDays(90), service.fechaBajaPorInactividad(p, ahora));
    }

    @Test
    void noSeAvisaDemasiadoProntoNiDespuesDeLaBaja() {
        LocalDateTime ahora = LocalDateTime.of(2026, 10, 24, 12, 0);
        Pasajero temprano = pasajero(3, 1000);
        temprano.setUltimoViajeEn(ahora.minusDays(60));
        assertFalse(service.debeAvisarInactividad(temprano, ahora));

        Pasajero tarde = pasajero(3, 1000);
        tarde.setUltimoViajeEn(ahora.minusDays(95));
        assertFalse(service.debeAvisarInactividad(tarde, ahora));
    }

    @Test
    void elAvisoNoSeRepiteDentroDelMismoPeriodoDeInactividad() {
        LocalDateTime ahora = LocalDateTime.of(2026, 10, 24, 12, 0);
        Pasajero p = pasajero(3, 1000);
        p.setUltimoViajeEn(ahora.minusDays(80));
        p.setAvisoInactividadEn(ahora.minusDays(1));       // ya se le avisó por esta misma racha
        assertFalse(service.debeAvisarInactividad(p, ahora));
    }

    @Test
    void despuesDeVolverAViajarSeLePuedeAvisarDeNuevo() {
        LocalDateTime ahora = LocalDateTime.of(2026, 10, 24, 12, 0);
        Pasajero p = pasajero(3, 1000);
        p.setAvisoInactividadEn(ahora.minusDays(100));     // aviso de una racha anterior
        p.setUltimoViajeEn(ahora.minusDays(80));           // viajó después de ese aviso
        assertTrue(service.debeAvisarInactividad(p, ahora));
    }

    @Test
    void alPasajeroDeNivel1NoSeLeAvisaPorqueNoPuedeBajar() {
        LocalDateTime ahora = LocalDateTime.of(2026, 10, 24, 12, 0);
        Pasajero p = pasajero(1, 0);
        p.setUltimoViajeEn(ahora.minusDays(85));
        assertFalse(service.debeAvisarInactividad(p, ahora));
    }
}
