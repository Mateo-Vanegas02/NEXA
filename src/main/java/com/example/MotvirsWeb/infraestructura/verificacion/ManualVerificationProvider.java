package com.example.MotvirsWeb.infraestructura.verificacion;

import com.example.MotvirsWeb.aplicacion.verificacion.DriverVerificationProvider;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificationResult;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificacionConductorService;

/** Sin fuente automática: siempre UNAVAILABLE, el admin revisa y marca el resultado a mano. Es el valor por defecto. */
public class ManualVerificationProvider implements DriverVerificationProvider {

    public static final String NOMBRE = VerificacionConductorService.FUENTE_MANUAL;
    private static final String MSG = "Sin fuente automática: requiere verificación manual del administrador";

    @Override
    public String nombre() {
        return NOMBRE;
    }

    @Override
    public VerificationResult verifyPlate(String plate) {
        return VerificationResult.unavailable(NOMBRE, MSG);
    }

    @Override
    public VerificationResult verifyDriver(String documentId) {
        return VerificationResult.unavailable(NOMBRE, MSG);
    }
}
