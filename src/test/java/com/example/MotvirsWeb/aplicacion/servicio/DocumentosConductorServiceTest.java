package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.AlmacenDocumentos;
import com.example.MotvirsWeb.aplicacion.servicio.DocumentosConductorService.ArchivoSubido;
import com.example.MotvirsWeb.dominio.modelo.DocumentoConductor;
import com.example.MotvirsWeb.dominio.modelo.TipoDocumento;
import com.example.MotvirsWeb.dominio.repositorio.DocumentoConductorRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.io.ByteArrayInputStream;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DocumentosConductorServiceTest {

    private static final byte[] JPEG = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0, 16, 'J', 'F', 'I', 'F', 0, 1};
    private static final byte[] PNG = {(byte) 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13};
    private static final byte[] EXE = {'M', 'Z', (byte) 0x90, 0, 3, 0, 0, 0, 4, 0, 0, 0};

    @Mock
    AlmacenDocumentos almacen;
    @Mock
    DocumentoConductorRepository repositorio;
    @Mock
    UsuarioRepository usuarioRepository;

    DocumentosConductorService servicio;

    @BeforeEach
    void setUp() {
        servicio = new DocumentosConductorService(almacen, repositorio, usuarioRepository);
    }

    private static ArchivoSubido archivo(TipoDocumento t, byte[] contenido) {
        return new ArchivoSubido(t, "123456", t.name() + ".jpg", contenido.length, () -> new ByteArrayInputStream(contenido));
    }

    private static List<ArchivoSubido> cuatro() {
        return List.of(archivo(TipoDocumento.LICENCIA, JPEG), archivo(TipoDocumento.TARJETA_PROPIEDAD, PNG),
                archivo(TipoDocumento.SOAT, JPEG), archivo(TipoDocumento.TECNOMECANICA, JPEG));
    }

    @Test
    void aceptaLosCuatroDocumentosValidos() {
        assertDoesNotThrow(() -> servicio.validarConjunto(cuatro()));
    }

    @Test
    void rechazaArchivoQueNoEsImagenAunqueLlameJpg() {
        var e = assertThrows(DocumentoInvalidoException.class,
                () -> servicio.validar(archivo(TipoDocumento.SOAT, EXE)));
        assertTrue(e.getMessage().contains("SOAT"));
    }

    @Test
    void rechazaArchivoVacio() {
        var vacio = new ArchivoSubido(TipoDocumento.LICENCIA, "1", "x.jpg", 0, () -> new ByteArrayInputStream(new byte[0]));
        assertThrows(DocumentoInvalidoException.class, () -> servicio.validar(vacio));
    }

    @Test
    void rechazaArchivoMayorA5Mb() {
        var grande = new ArchivoSubido(TipoDocumento.LICENCIA, "1", "x.jpg", DocumentosConductorService.MAX_BYTES + 1,
                () -> new ByteArrayInputStream(JPEG));
        var e = assertThrows(DocumentoInvalidoException.class, () -> servicio.validar(grande));
        assertTrue(e.getMessage().contains("5 MB"));
    }

    @Test
    void exigeLosCuatroTipos() {
        var tres = cuatro().subList(0, 3);
        var e = assertThrows(DocumentoInvalidoException.class, () -> servicio.validarConjunto(tres));
        assertTrue(e.getMessage().contains("tecnomecánica"));
    }

    @Test
    void rechazaTipoRepetido() {
        var repetido = new ArrayList<>(cuatro());
        repetido.set(3, archivo(TipoDocumento.SOAT, JPEG));
        assertThrows(DocumentoInvalidoException.class, () -> servicio.validarConjunto(repetido));
    }

    @Test
    void guardaConNumeroDeclaradoYVehiculoSoloEnDocumentosDeVehiculo() {
        when(almacen.guardar(anyString(), anyString(), any())).thenReturn("a1", "a2", "a3", "a4");
        when(repositorio.save(any(DocumentoConductor.class))).thenAnswer(i -> i.getArgument(0));

        List<DocumentoConductor> docs = servicio.guardarTodos("cond1", "veh1", cuatro());

        assertEquals(4, docs.size());
        DocumentoConductor licencia = docs.stream().filter(d -> d.getTipo() == TipoDocumento.LICENCIA).findFirst().orElseThrow();
        DocumentoConductor soat = docs.stream().filter(d -> d.getTipo() == TipoDocumento.SOAT).findFirst().orElseThrow();
        assertNull(licencia.getVehiculoId());
        assertEquals("veh1", soat.getVehiculoId());
        assertEquals("123456", soat.getNumeroDeclarado());
        assertEquals("image/jpeg", soat.getContentType());
    }

    @Test
    void siFallaUnoBorraLoYaGuardado() {
        when(almacen.guardar(anyString(), anyString(), any())).thenReturn("a1").thenThrow(new RuntimeException("disco"));
        DocumentoConductor primero = DocumentoConductor.builder().id("d1").archivoId("a1").build();
        when(repositorio.save(any(DocumentoConductor.class))).thenReturn(primero);

        assertThrows(RuntimeException.class, () -> servicio.guardarTodos("cond1", "veh1", cuatro()));

        verify(almacen).eliminar("a1");
        verify(repositorio).deleteById("d1");
    }
}
