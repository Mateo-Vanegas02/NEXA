package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.LectorDocumentos;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificacionException;
import com.example.MotvirsWeb.dominio.modelo.DocumentoConductor;
import com.example.MotvirsWeb.dominio.modelo.TipoDocumento;
import com.example.MotvirsWeb.dominio.regla.ComparadorDocumento.Resultado;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class LecturaDocumentosServiceTest {

    private final DocumentosConductorService documentos = mock(DocumentosConductorService.class);
    private final LectorDocumentos lector = mock(LectorDocumentos.class);
    private final LecturaDocumentosService servicio = new LecturaDocumentosService(documentos, lector);

    private void documento(String declarado) {
        DocumentoConductor d = DocumentoConductor.builder().id("d1").tipo(TipoDocumento.SOAT)
                .numeroDeclarado(declarado).contentType("image/jpeg").build();
        when(documentos.abrir("d1")).thenReturn(Optional.of(
                new DocumentosConductorService.Contenido(d, new ByteArrayInputStream(new byte[]{1, 2, 3}))));
    }

    @Test
    void coincideCuandoLoLeidoEsIgualAlDeclarado() {
        documento("9876543");
        when(lector.leerNumero(eq(TipoDocumento.SOAT), any(), eq("image/jpeg"))).thenReturn(Optional.of("9876543"));

        var l = servicio.leer("d1", "admin@x.com");

        assertEquals(Resultado.COINCIDE, l.resultado());
        assertEquals("9876543", l.leido());
    }

    @Test
    void sinLecturaDevuelveNoLegible() {
        documento("9876543");
        when(lector.leerNumero(any(), any(), any())).thenReturn(Optional.empty());

        assertEquals(Resultado.NO_LEGIBLE, servicio.leer("d1", "admin@x.com").resultado());
    }

    @Test
    void documentoInexistente() {
        when(documentos.abrir("x")).thenReturn(Optional.empty());
        assertThrows(VerificacionException.class, () -> servicio.leer("x", "admin@x.com"));
    }

    @Test
    void limitaLecturasPorMinuto() {
        documento("1111");
        when(lector.leerNumero(any(), any(), any())).thenReturn(Optional.empty());
        for (int i = 0; i < 10; i++) {
            documento("1111");
            servicio.leer("d1", "admin@x.com");
        }
        assertThrows(VerificacionException.class, () -> servicio.leer("d1", "admin@x.com"));
    }
}
