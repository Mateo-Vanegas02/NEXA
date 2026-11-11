package com.example.MotvirsWeb.aplicacion.verificacion;

import java.util.regex.Pattern;

/** Validación estricta con lista blanca de caracteres. Devuelve la forma normalizada o lanza {@link EntradaInvalidaException}. */
public final class ValidadorEntradas {

    /** Colombia: carro ABC123, moto ABC12D. */
    private static final Pattern PLACA = Pattern.compile("^[A-Z]{3}\\d{2}[A-Z0-9]$");
    /** Licencia/cédula: solo dígitos, 5 a 12. */
    private static final Pattern DOCUMENTO = Pattern.compile("^\\d{5,12}$");
    private static final Pattern MOTIVO = Pattern.compile("^[\\p{L}\\p{N} .,;:()?!%/_-]{5,300}$");

    private ValidadorEntradas() {
    }

    public static String placa(String raw) {
        String v = raw == null ? "" : raw.trim().toUpperCase();
        if (!PLACA.matcher(v).matches()) {
            throw new EntradaInvalidaException("Placa inválida (formato esperado: ABC123 o ABC12D)");
        }
        return v;
    }

    public static String documento(String raw) {
        String v = raw == null ? "" : raw.trim();
        if (!DOCUMENTO.matcher(v).matches()) {
            throw new EntradaInvalidaException("Documento inválido (5 a 12 dígitos)");
        }
        return v;
    }

    public static String motivo(String raw) {
        String v = raw == null ? "" : raw.trim();
        if (!MOTIVO.matcher(v).matches()) {
            throw new EntradaInvalidaException("Motivo inválido (5 a 300 caracteres, sin símbolos especiales)");
        }
        return v;
    }

    public static String motivoOpcional(String raw) {
        return raw == null || raw.isBlank() ? null : motivo(raw);
    }

    /** Enmascara para logs/auditoría: deja los últimos 3 caracteres. */
    public static String enmascarar(String v) {
        if (v == null || v.length() <= 3) {
            return "***";
        }
        return "*".repeat(v.length() - 3) + v.substring(v.length() - 3);
    }
}
