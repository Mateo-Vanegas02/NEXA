package com.example.MotvirsWeb.dominio.regla;

import java.util.Locale;

/** Forma única del correo en entradas y búsquedas de la aplicación. */
public final class Correo {
    private Correo() { }

    public static String normalizar(String email) {
        return email == null ? null : email.trim().toLowerCase(Locale.ROOT);
    }
}
