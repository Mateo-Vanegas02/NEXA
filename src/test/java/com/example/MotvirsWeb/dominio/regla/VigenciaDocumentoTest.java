package com.example.MotvirsWeb.dominio.regla;

import com.example.MotvirsWeb.dominio.modelo.TipoDocumento;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class VigenciaDocumentoTest {

    private final LocalDate hoy = LocalDate.of(2026, 11, 22);

    @Test
    void clasificaSegunLaFecha() {
        assertEquals(VigenciaDocumento.NO_VENCE, VigenciaDocumento.de(TipoDocumento.TARJETA_PROPIEDAD, hoy, hoy));
        assertEquals(VigenciaDocumento.SIN_FECHA, VigenciaDocumento.de(TipoDocumento.SOAT, null, hoy));
        assertEquals(VigenciaDocumento.VENCIDO, VigenciaDocumento.de(TipoDocumento.SOAT, hoy.minusDays(1), hoy));
        assertEquals(VigenciaDocumento.POR_VENCER, VigenciaDocumento.de(TipoDocumento.SOAT, hoy, hoy));
        assertEquals(VigenciaDocumento.POR_VENCER,
                VigenciaDocumento.de(TipoDocumento.TECNOMECANICA, hoy.plusDays(30), hoy));
        assertEquals(VigenciaDocumento.VIGENTE, VigenciaDocumento.de(TipoDocumento.LICENCIA, hoy.plusDays(31), hoy));
    }

    @Test
    void cuentaLosDiasQueFaltan() {
        assertEquals(10L, VigenciaDocumento.diasRestantes(hoy.plusDays(10), hoy));
        assertEquals(-3L, VigenciaDocumento.diasRestantes(hoy.minusDays(3), hoy));
        assertNull(VigenciaDocumento.diasRestantes(null, hoy));
    }
}
