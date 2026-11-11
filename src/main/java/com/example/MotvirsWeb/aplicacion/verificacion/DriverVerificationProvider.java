package com.example.MotvirsWeb.aplicacion.verificacion;

/**
 * Adaptador hacia una fuente de verificación. Las implementaciones no deben lanzar excepciones por fallos
 * de la fuente: devuelven {@link VerificationStatus#UNAVAILABLE}. Reciben entradas ya validadas y normalizadas.
 */
public interface DriverVerificationProvider {

    /** Nombre corto de la fuente, se guarda en la auditoría. */
    String nombre();

    VerificationResult verifyPlate(String plate);

    /** Algunas fuentes exigen el documento del propietario para consultar una placa. */
    default VerificationResult verifyPlate(String plate, String ownerDocumentId) {
        return verifyPlate(plate);
    }

    VerificationResult verifyDriver(String documentId);
}
