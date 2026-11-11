package com.example.MotvirsWeb.aplicacion.verificacion;

/** Resultado tipado de una verificación contra una fuente. UNAVAILABLE nunca equivale a aprobar. */
public enum VerificationStatus {
    VERIFIED,
    NOT_FOUND,
    MISMATCH,
    UNAVAILABLE
}
