package com.example.MotvirsWeb.dominio.modelo;

/** Documentos que el conductor sube al registrarse para que el administrador los contraste con los números declarados. */
public enum TipoDocumento {
    LICENCIA("licencia de conducción", false),
    TARJETA_PROPIEDAD("tarjeta de propiedad", true),
    SOAT("SOAT", true),
    TECNOMECANICA("tecnomecánica", true);

    private final String etiqueta;
    private final boolean deVehiculo;

    TipoDocumento(String etiqueta, boolean deVehiculo) {
        this.etiqueta = etiqueta;
        this.deVehiculo = deVehiculo;
    }

    public String etiqueta() {
        return etiqueta;
    }

    /** true si el documento pertenece a un vehículo concreto y no al conductor. */
    public boolean esDeVehiculo() {
        return deVehiculo;
    }
}
