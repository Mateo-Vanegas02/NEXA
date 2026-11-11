package com.example.MotvirsWeb.dominio.modelo;

public enum EstadoValidacion {
    APROBADO,
    RECHAZADO,
    PENDIENTE,
    /** El admin pidió más información; hay plazo para responder o la solicitud se rechaza sola. */
    EN_REVISION
}
