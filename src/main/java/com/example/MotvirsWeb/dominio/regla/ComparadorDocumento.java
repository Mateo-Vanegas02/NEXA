package com.example.MotvirsWeb.dominio.regla;

/** Regla pura: contrasta el número que declaró el conductor con el que se lee en la foto del documento. */
public final class ComparadorDocumento {

    public enum Resultado { COINCIDE, DIFERENTE, NO_LEGIBLE }

    private ComparadorDocumento() {
    }

    /** Deja solo letras y dígitos en mayúscula (ignora espacios, guiones y puntos). */
    public static String normalizar(String s) {
        return s == null ? "" : s.replaceAll("[^A-Za-z0-9]", "").toUpperCase();
    }

    /** Extrae del texto del modelo un único token alfanumérico de 4 a 20 caracteres, o "" si no hay uno claro. */
    public static String extraerNumero(String respuesta) {
        if (respuesta == null) return "";
        String t = respuesta.trim();
        if (t.toUpperCase().startsWith("NO_LEGIBLE")) return "";
        String n = normalizar(t);
        return n.length() >= 4 && n.length() <= 20 ? n : "";
    }

    public static Resultado comparar(String declarado, String leido) {
        String l = normalizar(leido);
        if (l.isEmpty()) return Resultado.NO_LEGIBLE;
        return l.equals(normalizar(declarado)) ? Resultado.COINCIDE : Resultado.DIFERENTE;
    }
}
