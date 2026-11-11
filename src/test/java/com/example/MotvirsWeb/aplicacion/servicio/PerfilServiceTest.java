package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.AlmacenDocumentos;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Rol;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.example.MotvirsWeb.presentacion.dto.PerfilDto;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.io.ByteArrayInputStream;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PerfilServiceTest {

    private static final byte[] JPEG = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0, 16, 'J', 'F', 'I', 'F', 0, 1};
    private static final byte[] EXE = {'M', 'Z', (byte) 0x90, 0, 3, 0, 0, 0, 4, 0, 0, 0};

    @Mock
    UsuarioRepository usuarioRepository;
    @Mock
    AlmacenDocumentos almacen;

    PerfilService servicio;
    Pasajero pasajero;

    @BeforeEach
    void setUp() {
        servicio = new PerfilService(usuarioRepository, almacen);
        pasajero = new Pasajero();
        pasajero.setId(new ObjectId());
        pasajero.setEmail("laura@test.com");
        pasajero.setNombreCompleto("Laura Gómez");
        pasajero.setTelefono("3001234567");
    }

    @Test
    void actualizarDatosDePasajeroNormalizaEspaciosYGuarda() {
        when(usuarioRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        PerfilDto dto = servicio.actualizarDatos(pasajero, "  Laura   Gómez Díaz ", "3109876543");

        assertEquals("Laura Gómez Díaz", dto.nombre());
        assertEquals("3109876543", dto.telefono());
        assertEquals("laura@test.com", dto.email());
        assertEquals("PASAJERO", dto.rol());
    }

    @Test
    void actualizarDatosDeConductorGuardaTelefonoNumerico() {
        Conductor c = new Conductor();
        c.setId(new ObjectId());
        c.setEmail("ana@test.com");
        c.setLicencia(1045678901L);
        when(usuarioRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        PerfilDto dto = servicio.actualizarDatos(c, "Ana Pérez", "3114567890");

        assertEquals(3114567890L, c.getNtelefono());
        assertEquals("3114567890", dto.telefono());
        assertEquals(1045678901L, dto.licencia());
        assertEquals(Rol.CONDUCTOR.name(), dto.rol());
    }

    @Test
    void sinFotoElPerfilNoTraUrl() {
        PerfilDto dto = servicio.perfil(pasajero);
        assertFalse(dto.tieneFoto());
        assertNull(dto.fotoUrl());
    }

    @Test
    void guardarFotoGuardaNuevaYBorraLaAnterior() {
        pasajero.setFotoPerfilId("anterior");
        pasajero.setFotoPerfilTipo("image/png");
        when(almacen.guardar(anyString(), eq("image/jpeg"), any())).thenReturn("nuevo");
        when(usuarioRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        PerfilDto dto = servicio.guardarFoto(pasajero, "yo.jpg", JPEG.length, () -> new ByteArrayInputStream(JPEG));

        assertTrue(dto.tieneFoto());
        assertTrue(dto.fotoUrl().startsWith("/api/usuarios/" + pasajero.getIdString() + "/foto?v=nuevo"));
        assertEquals("image/jpeg", pasajero.getFotoPerfilTipo());
        verify(almacen).eliminar("anterior");
    }

    @Test
    void guardarFotoRechazaArchivosQueNoSonImagen() {
        assertThrows(DocumentoInvalidoException.class,
                () -> servicio.guardarFoto(pasajero, "virus.jpg", EXE.length, () -> new ByteArrayInputStream(EXE)));
        verifyNoInteractions(almacen);
        verify(usuarioRepository, never()).save(any());
    }

    @Test
    void guardarFotoRechazaMasDeCincoMegas() {
        assertThrows(DocumentoInvalidoException.class,
                () -> servicio.guardarFoto(pasajero, "grande.jpg", 5L * 1024 * 1024 + 1, () -> new ByteArrayInputStream(JPEG)));
        verifyNoInteractions(almacen);
    }

    @Test
    void siFallaElGuardadoDelUsuarioSeBorraLaFotoNueva() {
        pasajero.setFotoPerfilId("anterior");
        when(almacen.guardar(anyString(), anyString(), any())).thenReturn("nuevo");
        when(usuarioRepository.save(any())).thenThrow(new IllegalStateException("bd caída"));

        assertThrows(IllegalStateException.class,
                () -> servicio.guardarFoto(pasajero, "yo.jpg", JPEG.length, () -> new ByteArrayInputStream(JPEG)));

        verify(almacen).eliminar("nuevo");
        verify(almacen, never()).eliminar("anterior");
    }

    @Test
    void quitarFotoLimpiaElCampoYBorraElArchivo() {
        pasajero.setFotoPerfilId("abc");
        pasajero.setFotoPerfilTipo("image/png");
        when(usuarioRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        PerfilDto dto = servicio.quitarFoto(pasajero);

        assertFalse(dto.tieneFoto());
        assertNull(pasajero.getFotoPerfilId());
        verify(almacen).eliminar("abc");
    }

    @Test
    void abrirFotoDevuelveVacioSiElIdNoEsValidoOElUsuarioNoTieneFoto() {
        assertTrue(servicio.abrirFoto("no-es-un-id").isEmpty());
        String id = pasajero.getIdString();
        when(usuarioRepository.findById(id)).thenReturn(Optional.of(pasajero));
        assertTrue(servicio.abrirFoto(id).isEmpty());
        verifyNoInteractions(almacen);
    }

    @Test
    void abrirFotoUsaElTipoGuardado() {
        pasajero.setFotoPerfilId("abc");
        pasajero.setFotoPerfilTipo("image/webp");
        String id = pasajero.getIdString();
        when(usuarioRepository.findById(id)).thenReturn(Optional.of(pasajero));
        when(almacen.abrir("abc")).thenReturn(Optional.of(new ByteArrayInputStream(JPEG)));

        var foto = servicio.abrirFoto(id).orElseThrow();

        assertEquals("image/webp", foto.contentType());
    }
}
