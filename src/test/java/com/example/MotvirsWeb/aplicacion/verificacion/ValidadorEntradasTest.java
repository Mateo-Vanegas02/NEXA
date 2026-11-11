package com.example.MotvirsWeb.aplicacion.verificacion;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

import java.util.concurrent.atomic.AtomicLong;

import static org.junit.jupiter.api.Assertions.*;

class ValidadorEntradasTest {

    @Test
    void placaValidaSeNormaliza() {
        assertEquals("ABC123", ValidadorEntradas.placa(" abc123 "));
        assertEquals("ABC12D", ValidadorEntradas.placa("abc12d"));
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"ABCDEF", "AB1234", "ABC1234", "ABC-12", "ABC 12", "ÁBC123", "ABC12\"", "A1C123", "<script>"})
    void placaInvalidaSeRechaza(String v) {
        assertThrows(EntradaInvalidaException.class, () -> ValidadorEntradas.placa(v));
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"1234", "1234567890123", "12a456", "12 456", "1.234.567", "123456 OR 1=1", "-123456"})
    void documentoInvalidoSeRechaza(String v) {
        assertThrows(EntradaInvalidaException.class, () -> ValidadorEntradas.documento(v));
    }

    @Test
    void documentoValido() {
        assertEquals("1234567", ValidadorEntradas.documento("1234567"));
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"abc", "<b>hola mundo</b>", "{\"a\":1} mas texto"})
    void motivoInvalidoSeRechaza(String v) {
        assertThrows(EntradaInvalidaException.class, () -> ValidadorEntradas.motivo(v));
    }

    @Test
    void motivoValidoYEnmascarado() {
        assertEquals("Documentos ilegibles, repetir", ValidadorEntradas.motivo(" Documentos ilegibles, repetir "));
        assertNull(ValidadorEntradas.motivoOpcional("  "));
        assertEquals("****456", ValidadorEntradas.enmascarar("1234456"));
        assertEquals("***", ValidadorEntradas.enmascarar("12"));
    }

    @Test
    void limitadorDeslizante() {
        AtomicLong t = new AtomicLong(0);
        LimitadorTasa l = new LimitadorTasa(2, 1000, t::get);
        assertTrue(l.permitir("a"));
        assertTrue(l.permitir("a"));
        assertFalse(l.permitir("a"));
        assertTrue(l.permitir("b"));
        t.set(1001);
        assertTrue(l.permitir("a"));
    }
}
