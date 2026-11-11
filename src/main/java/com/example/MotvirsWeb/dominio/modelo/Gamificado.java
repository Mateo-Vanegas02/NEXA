package com.example.MotvirsWeb.dominio.modelo;

import java.time.LocalDateTime;

/** Usuario que participa del sistema de niveles (pasajero o conductor). */
public interface Gamificado {
    double getXpTotal();
    void setXpTotal(double xpTotal);
    int getNivel();
    void setNivel(int nivel);
    LocalDateTime getNivelActualizadoEn();
    void setNivelActualizadoEn(LocalDateTime fecha);
}
