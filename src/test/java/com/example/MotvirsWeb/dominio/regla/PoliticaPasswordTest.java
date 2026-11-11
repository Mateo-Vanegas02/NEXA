package com.example.MotvirsWeb.dominio.regla;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class PoliticaPasswordTest {

    @Test
    void aceptaContrasenasConMayusculaMinusculaYNumero() {
        assertTrue(PoliticaPassword.esValida("Abcdefg1"));
        assertTrue(PoliticaPassword.esValida("Clave-Segura-2026"));
    }

    @Test
    void rechazaLasDebiles() {
        assertFalse(PoliticaPassword.esValida(null));
        assertFalse(PoliticaPassword.esValida("Ab1"));
        assertFalse(PoliticaPassword.esValida("abcdefgh1"));
        assertFalse(PoliticaPassword.esValida("ABCDEFGH1"));
        assertFalse(PoliticaPassword.esValida("Abcdefghi"));
        assertFalse(PoliticaPassword.esValida("Aa1" + "x".repeat(100)));
    }
}
