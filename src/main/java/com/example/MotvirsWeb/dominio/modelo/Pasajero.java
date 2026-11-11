package com.example.MotvirsWeb.dominio.modelo;

import lombok.*;
import lombok.experimental.SuperBuilder;
import org.springframework.data.annotation.TypeAlias;
import org.bson.types.ObjectId;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;
import java.util.List;

@Document(collection = "Usuarios")
@Data
@AllArgsConstructor
@EqualsAndHashCode(callSuper = true)
@SuperBuilder
@TypeAlias("PASAJERO")
public class Pasajero extends Usuario implements Gamificado {
    private String nombreCompleto;
    private String telefono;

    // ── Sistema de niveles ──
    private double xpTotal;
    /** Nivel desde 1 y sin techo (modelo v2.2); un valor menor a 1 (usuario nuevo) cuenta como 1. */
    private int nivel;
    private LocalDateTime nivelActualizadoEn;
    /** Último viaje completado; base de la caída por inactividad. */
    private LocalDateTime ultimoViajeEn;
    /** Cuándo se le avisó que estaba por bajar de nivel; evita repetir el correo cada día. */
    private LocalDateTime avisoInactividadEn;
    /** Conductores favoritos (desde el nivel 5). */
    private List<ObjectId> conductoresFavoritos;

    /** Cargo de cancelación pendiente de pago; null si no debe nada. */
    private DeudaCancelacion deuda;

    public Pasajero() {
        this.setRol(Rol.PASAJERO);
    }
}
