package com.example.MotvirsWeb.presentacion.dto;

import java.util.List;

/** Respuesta de GET /api/niveles/me. Los niveles empiezan en 1 y no tienen techo (modelo v2.2). */
public record NivelDto(
        /** Identifica al usuario en el cliente (claves de almacenamiento local). */
        String usuarioId,
        String rol,
        int nivel,
        /** XP total (pasajero) o XP de la ventana móvil (conductor), con un decimal. */
        double xpActual,
        double xpNivelActual,
        /** null en el último nivel del conductor; el pasajero siempre tiene uno siguiente. */
        Double xpSiguienteNivel,
        double xpFaltante,
        /** 0..1 dentro del tramo actual. */
        double progreso,
        /** Descuento vigente del pasajero (fracción); 0 para el conductor. */
        double descuento,
        /** Segundos de prioridad de recogida del pasajero; 0 si aún no tiene. */
        int prioridadSegundos,
        List<NivelInfo> niveles,
        List<BeneficioInfo> beneficiosActivos,
        ConductorInfo conductor) {

    public record NivelInfo(int nivel, double xp, Double descuento, List<BeneficioInfo> beneficios, Double comision) {
    }

    public record BeneficioInfo(String clave, String titulo, String descripcion, int nivelRequerido,
            boolean activo) {
    }

    public record Requisito(String texto, boolean cumplido) {
    }

    public record ConductorInfo(
            double comisionActual,
            Double comisionSiguiente,
            Double calificacion,
            double aceptacion,
            double cancelacion,
            /** Requisitos de calidad del nivel siguiente (checklist). */
            List<Requisito> requisitosSiguiente,
            /** Tiene los XP del nivel siguiente pero le falta calidad. */
            boolean bloqueadoPorCalidad) {
    }
}
