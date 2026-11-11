package com.example.MotvirsWeb.dominio.modelo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Deuda del pasajero por el cargo de una cancelación. Solo puede haber una a la vez (monto del
 * servicio cancelado) y bloquea nuevos viajes hasta que un administrador confirma el pago.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DeudaCancelacion {
    private String servicioId;
    /** Pesos enteros. */
    private long monto;
    private LocalDateTime creadaEn;
}
