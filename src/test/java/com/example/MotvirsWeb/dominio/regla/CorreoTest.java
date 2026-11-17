package com.example.MotvirsWeb.dominio.regla;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;

class CorreoTest {
    @Test
    void normalizaMayusculasEspaciosYAmbos() {
        assertEquals("a@example.com", Correo.normalizar("A@EXAMPLE.COM"));
        assertEquals("a@example.com", Correo.normalizar(" a@example.com "));
        assertEquals("a@example.com", Correo.normalizar(" A@EXAMPLE.COM "));
    }
}
