package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.ProveedorRutas;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.regla.Ruta;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.presentacion.dto.RutasEnVivoDto;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class RutaEnVivoServiceTest {

    private static final PuntoGeo AQUI = new PuntoGeo(10.40, -75.50);

    private final ServicioRepository repo = mock(ServicioRepository.class);
    private final AtomicReference<PuntoGeo> pedidoHacia = new AtomicReference<>();
    private List<Ruta> respuesta = List.of(
            new Ruta(3.3, 2.0, "osrm", 11, "lenta"),
            new Ruta(2.9, 2.0, "osrm", 8, "rapida"),
            new Ruta(2.7, 2.0, "osrm", 9, "corta"));
    private final ProveedorRutas proveedor = new ProveedorRutas() {
        @Override
        public Ruta calcular(PuntoGeo origen, PuntoGeo destino) {
            return respuesta.get(0);
        }

        @Override
        public List<Ruta> alternativas(PuntoGeo origen, PuntoGeo destino) {
            pedidoHacia.set(destino);
            return respuesta;
        }
    };
    private final Clock clock = Clock.fixed(Instant.parse("2026-11-22T12:00:00Z"), ZoneOffset.UTC);
    private RutaEnVivoService servicio;
    private Conductor conductor;
    private Servicio viaje;

    @BeforeEach
    void preparar() {
        servicio = new RutaEnVivoService(repo, proveedor, clock);
        conductor = new Conductor();
        conductor.setId(new ObjectId());
        viaje = new Servicio();
        viaje.setId("v1");
        Servicio.ConductorEmbedded c = new Servicio.ConductorEmbedded();
        c.setId(conductor.getId());
        viaje.setConductor(c);
        viaje.setUbicacionOrigen(coord(10.41, -75.51));
        viaje.setUbicacionDestino(coord(10.38, -75.48));
        viaje.setEstado(EstadoServicio.EN_CURSO);
        when(repo.findById("v1")).thenReturn(Optional.of(viaje));
    }

    @Test
    void enCursoPideHaciaElDestinoYOrdenaLaMasRapidaPrimero() {
        RutasEnVivoDto.Alternativas a = servicio.alternativas(conductor, "v1", AQUI);
        assertEquals("EN_CURSO", a.fase());
        assertEquals(10.38, pedidoHacia.get().latitud(), 1e-9);
        assertEquals(List.of("rapida", "corta", "lenta"), a.rutas().stream().map(RutasEnVivoDto.Opcion::geometria).toList());
        assertEquals(List.of("RAPIDA", "CORTA", "ALTERNATIVA"), a.rutas().stream().map(RutasEnVivoDto.Opcion::etiqueta).toList());
        assertEquals(List.of(0, 1, 2), a.rutas().stream().map(RutasEnVivoDto.Opcion::indice).toList());
    }

    @Test
    void yendoARecogerPideHaciaLaRecogidaYNoComparteLaRuta() {
        viaje.setEstado(EstadoServicio.ACEPTADO);
        RutasEnVivoDto.Alternativas a = servicio.alternativas(conductor, "v1", AQUI);
        assertEquals("ACEPTADO", a.fase());
        assertEquals(10.41, pedidoHacia.get().latitud(), 1e-9);
        RutasEnVivoDto.Elegida e = servicio.elegir(conductor, "v1", 0);
        assertFalse(e.compartidaConPasajero());
        assertEquals("rapida", e.rutaGeometria());
        verify(repo, never()).cambiarRutaEnCurso(any(), any(), any(), any());
    }

    @Test
    void elegirEnCursoGuardaElTrazadoParaElPasajero() {
        servicio.alternativas(conductor, "v1", AQUI);
        when(repo.cambiarRutaEnCurso(eq("v1"), eq(conductor.getId()), eq("corta"), any())).thenReturn(1L);
        RutasEnVivoDto.Elegida e = servicio.elegir(conductor, "v1", 1);
        assertTrue(e.compartidaConPasajero());
        assertEquals("corta", e.rutaGeometria());
        verify(repo).cambiarRutaEnCurso(eq("v1"), eq(conductor.getId()), eq("corta"), any());
    }

    @Test
    void sinPedirAntesOConIndiceFueraDeRangoEsConflicto() {
        assertEstado(HttpStatus.CONFLICT, () -> servicio.elegir(conductor, "v1", 0));
        servicio.alternativas(conductor, "v1", AQUI);
        assertEstado(HttpStatus.CONFLICT, () -> servicio.elegir(conductor, "v1", 3));
    }

    @Test
    void otroConductorNoPuedePedirNiElegir() {
        Conductor otro = new Conductor();
        otro.setId(new ObjectId());
        assertEstado(HttpStatus.FORBIDDEN, () -> servicio.alternativas(otro, "v1", AQUI));
        servicio.alternativas(conductor, "v1", AQUI);
        assertEstado(HttpStatus.FORBIDDEN, () -> servicio.elegir(otro, "v1", 0));
    }

    @Test
    void viajeTerminadoEsConflictoYDesconocidoNoExiste() {
        viaje.setEstado(EstadoServicio.FINALIZADO);
        assertEstado(HttpStatus.CONFLICT, () -> servicio.alternativas(conductor, "v1", AQUI));
        when(repo.findById("nada")).thenReturn(Optional.empty());
        assertEstado(HttpStatus.NOT_FOUND, () -> servicio.alternativas(conductor, "nada", AQUI));
    }

    @Test
    void sinTrazadoNoHayOpciones() {
        respuesta = List.of(new Ruta(2.6, 2.0, "recta"));
        assertTrue(servicio.alternativas(conductor, "v1", AQUI).rutas().isEmpty());
    }

    private static Servicio.Coordenada coord(double lat, double lng) {
        Servicio.Coordenada c = new Servicio.Coordenada();
        c.setLatitud(lat);
        c.setLongitud(lng);
        return c;
    }

    private static void assertEstado(HttpStatus esperado, Runnable accion) {
        ResponseStatusException e = assertThrows(ResponseStatusException.class, accion::run);
        assertEquals(esperado, e.getStatusCode());
    }
}
