package com.example.MotvirsWeb.aplicacion.verificacion;

public class VerificacionException extends RuntimeException {

    public enum Tipo {
        NO_ENCONTRADO, ESTADO_INVALIDO, NO_VERIFICADO, LIMITE_EXCEDIDO
    }

    private final Tipo tipo;

    public VerificacionException(Tipo tipo, String message) {
        super(message);
        this.tipo = tipo;
    }

    public Tipo getTipo() {
        return tipo;
    }
}
