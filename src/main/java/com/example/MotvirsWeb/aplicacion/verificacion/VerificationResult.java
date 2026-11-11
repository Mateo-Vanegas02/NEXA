package com.example.MotvirsWeb.aplicacion.verificacion;

/**
 * Resultado mínimo de una verificación. No transporta datos personales del propietario:
 * solo el estado y atributos del vehículo necesarios para decidir.
 *
 * @param fuente  identificador del proveedor (MOCK, MANUAL, RUNT_HTTP...)
 * @param detalle mensaje corto y seguro de mostrar al admin (sin detalles internos)
 */
public record VerificationResult(VerificationStatus status, String fuente, String detalle,
                                 String marca, String modelo, Boolean soatVigente, Boolean tecnoVigente) {

    public static VerificationResult of(VerificationStatus status, String fuente, String detalle) {
        return new VerificationResult(status, fuente, detalle, null, null, null, null);
    }

    public static VerificationResult unavailable(String fuente, String detalle) {
        return of(VerificationStatus.UNAVAILABLE, fuente, detalle);
    }
}
