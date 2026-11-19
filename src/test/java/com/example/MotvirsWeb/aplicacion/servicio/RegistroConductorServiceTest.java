package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.servicio.DocumentosConductorService.ArchivoSubido;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.TipoDocumento;
import com.example.MotvirsWeb.dominio.modelo.Vehiculo;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.example.MotvirsWeb.dominio.repositorio.VehiculoRepository;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.io.ByteArrayInputStream;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RegistroConductorServiceTest {

    @Mock
    AuthService authService;
    @Mock
    UsuarioRepository usuarioRepository;
    @Mock
    VehiculoRepository vehiculoRepository;
    @Mock
    DocumentosConductorService documentos;

    RegistroConductorService servicio;

    @BeforeEach
    void setUp() {
        servicio = new RegistroConductorService(authService, usuarioRepository, vehiculoRepository, documentos);
    }

    private static List<ArchivoSubido> fotos() {
        return java.util.Arrays.stream(TipoDocumento.values())
                .map(t -> new ArchivoSubido(t, null, t + ".jpg", 10, () -> new ByteArrayInputStream(new byte[10])))
                .toList();
    }

    private static RegistroConductorService.Solicitud solicitud() {
        return new RegistroConductorService.Solicitud("Ana Pérez", "ana@test.com", "Clave123", "3001234567",
                12345678901L, "abc123", "Bajaj", "Boxer", "Negro", 987654321012L, 123456789012L, 123456789012345L, fotos());
    }

    private static Conductor conductorGuardado() {
        Conductor c = new Conductor();
        c.setId(new ObjectId());
        c.setEmail("ana@test.com");
        return c;
    }

    @Test
    void creaConductorVehiculoActivoYDocumentosConNumerosLargos() {
        Conductor c = conductorGuardado();
        when(vehiculoRepository.findByPlaca("ABC123")).thenReturn(Optional.empty());
        when(authService.registrarConductor(anyString(), anyString(), anyString(), anyString(), anyLong(), anyLong(), anyLong()))
                .thenReturn(c);
        when(vehiculoRepository.save(any(Vehiculo.class))).thenAnswer(i -> {
            Vehiculo v = i.getArgument(0);
            v.setId(new ObjectId().toHexString());
            return v;
        });
        when(usuarioRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        servicio.registrar(solicitud());

        ArgumentCaptor<Vehiculo> vc = ArgumentCaptor.forClass(Vehiculo.class);
        verify(vehiculoRepository).save(vc.capture());
        assertEquals("ABC123", vc.getValue().getPlaca());
        assertTrue(vc.getValue().isActivo());
        assertEquals(123456789012345L, vc.getValue().getTecnomecanicaId());
        assertEquals(1, c.getVehiculos().size());

        ArgumentCaptor<List<ArchivoSubido>> fc = ArgumentCaptor.forClass(List.class);
        verify(documentos).guardarTodos(eq(c.getIdString()), anyString(), fc.capture());
        assertEquals("12345678901", fc.getValue().stream().filter(f -> f.tipo() == TipoDocumento.LICENCIA)
                .findFirst().orElseThrow().numeroDeclarado());
        assertEquals("123456789012", fc.getValue().stream().filter(f -> f.tipo() == TipoDocumento.SOAT)
                .findFirst().orElseThrow().numeroDeclarado());
    }

    @Test
    void placaRepetidaNoCreaNada() {
        when(vehiculoRepository.findByPlaca("ABC123")).thenReturn(Optional.of(new Vehiculo()));

        assertThrows(IllegalStateException.class, () -> servicio.registrar(solicitud()));

        verifyNoInteractions(authService);
        verify(documentos, never()).guardarTodos(anyString(), anyString(), anyList());
    }

    @Test
    void fotosInvalidasNoCreanLaCuenta() {
        when(vehiculoRepository.findByPlaca("ABC123")).thenReturn(Optional.empty());
        doThrow(new DocumentoInvalidoException("Falta la foto de la SOAT")).when(documentos).validarConjunto(anyList());

        assertThrows(DocumentoInvalidoException.class, () -> servicio.registrar(solicitud()));

        verifyNoInteractions(authService);
    }

    @Test
    void siFallanLosDocumentosDeshaceConductorYVehiculo() {
        Conductor c = conductorGuardado();
        String vehiculoId = new ObjectId().toHexString(); // id real: agregarVehiculo lo convierte a ObjectId
        when(vehiculoRepository.findByPlaca("ABC123")).thenReturn(Optional.empty());
        when(authService.registrarConductor(anyString(), anyString(), anyString(), anyString(), anyLong(), anyLong(), anyLong()))
                .thenReturn(c);
        when(vehiculoRepository.save(any(Vehiculo.class))).thenAnswer(i -> {
            Vehiculo v = i.getArgument(0);
            v.setId(vehiculoId);
            return v;
        });
        when(usuarioRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        when(documentos.guardarTodos(anyString(), anyString(), anyList())).thenThrow(new RuntimeException("disco"));

        RuntimeException e = assertThrows(RuntimeException.class, () -> servicio.registrar(solicitud()));
        assertEquals("disco", e.getMessage(), "debe fallar al guardar los documentos, no antes");

        verify(documentos).eliminarDeConductor(c.getIdString());
        verify(vehiculoRepository).deleteById(vehiculoId);
        verify(usuarioRepository).deleteById(c.getIdString());
    }

    @Test
    void rechazaUnaTarjetaDeclaradaPorOtroConductorSinCrearNada() {
        when(vehiculoRepository.findByPlaca("ABC123")).thenReturn(Optional.empty());
        when(documentos.tarjetaDeclaradaPorOtro(987654321012L, null)).thenReturn(true);

        IllegalStateException e = assertThrows(IllegalStateException.class, () -> servicio.registrar(solicitud()));

        assertEquals(AuthService.TARJETA_REGISTRADA, e.getMessage());
        verify(authService, never()).registrarConductor(anyString(), anyString(), anyString(), anyString(), anyLong(), anyLong(), anyLong());
        verify(vehiculoRepository, never()).save(any());
    }
}
