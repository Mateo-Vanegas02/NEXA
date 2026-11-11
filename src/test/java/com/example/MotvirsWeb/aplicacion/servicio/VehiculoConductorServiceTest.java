package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.modelo.Vehiculo;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.dominio.repositorio.VehiculoRepository;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class VehiculoConductorServiceTest {

    private final VehiculoRepository vehiculoRepo = mock(VehiculoRepository.class);
    private final ServicioRepository servicioRepo = mock(ServicioRepository.class);
    private final com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository usuarioRepo = mock(com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository.class);
    private final DocumentosConductorService documentos = mock(DocumentosConductorService.class);
    private final VehiculoConductorService servicio = new VehiculoConductorService(vehiculoRepo, servicioRepo, usuarioRepo, documentos);
    private static final String NUEVO_ID = "507f1f77bcf86cd799439011";
    private Conductor conductor;
    private Vehiculo a;
    private Vehiculo b;

    @BeforeEach
    void preparar() {
        conductor = Conductor.builder().id(new ObjectId()).build();
        a = Vehiculo.builder().id("a").placa("KLM45D").activo(true).fechaRegistro(LocalDate.of(2026, 10, 1)).build();
        b = Vehiculo.builder().id("b").placa("RTX88A").activo(false).fechaRegistro(LocalDate.of(2026, 10, 5)).build();
        when(vehiculoRepo.findByConductorAsignado(conductor)).thenReturn(List.of(b, a));
    }

    @Test
    void listaEnOrdenDeRegistro() {
        assertEquals(List.of("a", "b"), servicio.listar(conductor).stream().map(v -> v.id()).toList());
    }

    @Test
    void elVehiculoActivoApareceEnServicioSoloConUnViajeEnCurso() {
        assertFalse(servicio.listar(conductor).get(0).enServicio());
        when(servicioRepo.findByConductorIdAndEstado(conductor.getId(), EstadoServicio.EN_CURSO))
                .thenReturn(List.of(new Servicio()));

        var lista = servicio.listar(conductor);

        assertTrue(lista.get(0).enServicio());
        assertFalse(lista.get(1).enServicio());
    }

    @Test
    void activarDejaSoloUnoActivo() {
        var elegido = servicio.activar(conductor, "b");

        assertTrue(elegido.activo());
        assertTrue(b.isActivo());
        assertFalse(a.isActivo());
        verify(vehiculoRepo).save(a);
        verify(vehiculoRepo).save(b);
    }

    @Test
    void noPermiteActivarUnVehiculoAjeno() {
        ResponseStatusException e = assertThrows(ResponseStatusException.class, () -> servicio.activar(conductor, "zzz"));

        assertEquals(404, e.getStatusCode().value());
        verify(vehiculoRepo, never()).save(any());
    }

    @Test
    void noPermiteCambiarConUnViajeEnCurso() {
        when(servicioRepo.findByConductorIdAndEstado(conductor.getId(), EstadoServicio.ACEPTADO))
                .thenReturn(List.of(new Servicio()));

        ResponseStatusException e = assertThrows(ResponseStatusException.class, () -> servicio.activar(conductor, "b"));

        assertEquals(409, e.getStatusCode().value());
        assertFalse(b.isActivo());
    }

    private VehiculoConductorService.NuevoVehiculo nuevo(String placa) {
        var fotos = java.util.List.of(
                new DocumentosConductorService.ArchivoSubido(com.example.MotvirsWeb.dominio.modelo.TipoDocumento.SOAT, null, "a.jpg", 10, () -> null),
                new DocumentosConductorService.ArchivoSubido(com.example.MotvirsWeb.dominio.modelo.TipoDocumento.TARJETA_PROPIEDAD, null, "b.jpg", 10, () -> null),
                new DocumentosConductorService.ArchivoSubido(com.example.MotvirsWeb.dominio.modelo.TipoDocumento.TECNOMECANICA, null, "c.jpg", 10, () -> null));
        return new VehiculoConductorService.NuevoVehiculo(placa, "Bajaj", "Boxer", "Negro", 111, 222, 333, fotos);
    }

    @Test
    void agregarCreaVehiculoInactivoYEnRevision() {
        when(vehiculoRepo.findByPlaca("ABC123")).thenReturn(java.util.Optional.empty());
        when(vehiculoRepo.save(any())).thenAnswer(i -> { Vehiculo v = i.getArgument(0); v.setId(NUEVO_ID); return v; });

        var r = servicio.agregar(conductor, nuevo("abc123"));

        assertFalse(r.activo());
        assertFalse(r.verificado());
        assertEquals("ABC123", r.placa());
        verify(documentos).guardarTodos(any(), eq(NUEVO_ID), any());
    }

    @Test
    void agregarRechazaPlacaRepetida() {
        when(vehiculoRepo.findByPlaca("ABC123")).thenReturn(java.util.Optional.of(a));
        var e = assertThrows(ResponseStatusException.class, () -> servicio.agregar(conductor, nuevo("ABC123")));
        assertEquals(409, e.getStatusCode().value());
    }

    @Test
    void agregarRechazaPlacaInvalida() {
        var e = assertThrows(ResponseStatusException.class, () -> servicio.agregar(conductor, nuevo("12")));
        assertEquals(400, e.getStatusCode().value());
    }

    @Test
    void agregarDeshaceElVehiculoSiFallanLasFotos() {
        when(vehiculoRepo.findByPlaca("ABC123")).thenReturn(java.util.Optional.empty());
        when(vehiculoRepo.save(any())).thenAnswer(i -> { Vehiculo v = i.getArgument(0); v.setId(NUEVO_ID); return v; });
        when(documentos.guardarTodos(any(), any(), any())).thenThrow(new IllegalStateException("fallo"));

        assertThrows(IllegalStateException.class, () -> servicio.agregar(conductor, nuevo("ABC123")));
        verify(vehiculoRepo).deleteById(NUEVO_ID);
    }

    @Test
    void noSePuedeActivarUnVehiculoEnRevision() {
        b.setVerificado(false);
        var e = assertThrows(ResponseStatusException.class, () -> servicio.activar(conductor, "b"));
        assertEquals(409, e.getStatusCode().value());
    }

    @Test
    void aprobarMarcaElVehiculoComoVerificado() {
        b.setVerificado(false);
        when(vehiculoRepo.findById("b")).thenReturn(java.util.Optional.of(b));
        servicio.aprobar("b");
        assertTrue(b.estaVerificado());
        verify(vehiculoRepo).save(b);
    }
}
