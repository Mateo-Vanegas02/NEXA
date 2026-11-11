package com.example.MotvirsWeb.dominio.regla;

/** Política mínima de contraseñas: 8-100 caracteres con mayúscula, minúscula y número. */
public final class PoliticaPassword {

    public static final String MENSAJE =
            "La contraseña debe tener entre 8 y 100 caracteres, con una mayúscula, una minúscula y un número.";

    private PoliticaPassword() {
    }

    public static boolean esValida(String password) {
        if (password == null || password.length() < 8 || password.length() > 100) {
            return false;
        }
        boolean mayuscula = false;
        boolean minuscula = false;
        boolean numero = false;
        for (char c : password.toCharArray()) {
            mayuscula |= Character.isUpperCase(c);
            minuscula |= Character.isLowerCase(c);
            numero |= Character.isDigit(c);
        }
        return mayuscula && minuscula && numero;
    }
}
