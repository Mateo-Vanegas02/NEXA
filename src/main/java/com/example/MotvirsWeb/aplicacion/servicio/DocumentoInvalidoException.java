package com.example.MotvirsWeb.aplicacion.servicio;

/** El archivo subido no cumple las reglas (falta, es muy pesado o no es una imagen). El mensaje es apto para mostrar al usuario. */
public class DocumentoInvalidoException extends IllegalStateException {
    public DocumentoInvalidoException(String mensaje) {
        super(mensaje);
    }
}
