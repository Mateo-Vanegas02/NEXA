package com.example.MotvirsWeb.infraestructura.verificacion;

import com.example.MotvirsWeb.aplicacion.verificacion.DriverVerificationProvider;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificationResult;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificationStatus;

/**
 * Proveedor para desarrollo y pruebas, sin red. Reglas deterministas:
 * placa que empieza por XXX → NOT_FOUND, MMM → MISMATCH, UUU → UNAVAILABLE, otra → VERIFIED;
 * documento que termina en 0000 → NOT_FOUND, 1111 → MISMATCH, 9999 → UNAVAILABLE, otro → VERIFIED.
 */
public class MockVerificationProvider implements DriverVerificationProvider {

    public static final String NOMBRE = "MOCK";

    @Override
    public String nombre() {
        return NOMBRE;
    }

    @Override
    public VerificationResult verifyPlate(String plate) {
        if (plate.startsWith("XXX")) {
            return VerificationResult.of(VerificationStatus.NOT_FOUND, NOMBRE, "Placa no encontrada (mock)");
        }
        if (plate.startsWith("MMM")) {
            return VerificationResult.of(VerificationStatus.MISMATCH, NOMBRE, "Datos no coinciden (mock)");
        }
        if (plate.startsWith("UUU")) {
            return VerificationResult.unavailable(NOMBRE, "Fuente simulada no disponible");
        }
        return new VerificationResult(VerificationStatus.VERIFIED, NOMBRE, "Placa verificada (mock)",
                "MOCK", "MOCK", true, true);
    }

    @Override
    public VerificationResult verifyDriver(String documentId) {
        if (documentId.endsWith("0000")) {
            return VerificationResult.of(VerificationStatus.NOT_FOUND, NOMBRE, "Documento no encontrado (mock)");
        }
        if (documentId.endsWith("1111")) {
            return VerificationResult.of(VerificationStatus.MISMATCH, NOMBRE, "Datos no coinciden (mock)");
        }
        if (documentId.endsWith("9999")) {
            return VerificationResult.unavailable(NOMBRE, "Fuente simulada no disponible");
        }
        return VerificationResult.of(VerificationStatus.VERIFIED, NOMBRE, "Documento verificado (mock)");
    }
}
