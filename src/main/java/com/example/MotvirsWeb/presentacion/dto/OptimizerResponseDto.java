package com.example.MotvirsWeb.presentacion.dto;

/**
 * Objeto de transferencia de datos (DTO) para enviar los resultados
 * detallados del plan de viajes optimizado con Google OR-Tools.
 */
public record OptimizerResponseDto(
    boolean factible,
    int x1,
    int x2,
    int x3,
    double beneficioEsperado,
    double riesgoDiario,
    double utilidadAjustada,
    double tiempoTotal,
    double costoGasolina,
    String mensaje
) {}
