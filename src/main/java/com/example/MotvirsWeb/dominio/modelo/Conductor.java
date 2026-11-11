package com.example.MotvirsWeb.dominio.modelo;
import lombok.*;
import lombok.experimental.SuperBuilder;
import org.bson.types.ObjectId;
import org.springframework.data.annotation.TypeAlias;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.DBRef;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Document(collection = "Usuarios")
@TypeAlias("CONDUCTOR")
@Data
@EqualsAndHashCode(callSuper = true)
@SuperBuilder

public class Conductor extends Usuario implements Gamificado {
    private String nombre_y_Apellido;

    private Long ntelefono;
    @Indexed(unique = true)
    private long licencia;
    @Indexed(unique = true)
    private Long soat;
    @Indexed(unique = true)
    private Long tarjeta_de_propiedad;


    private List<ObjectId> vehiculos;

    // ── Revisión con información adicional (estado EN_REVISION) ──
    /** Qué información pidió el admin. */
    private String revisionMensaje;
    /** Último día para responder (se rechaza automáticamente después). */
    private java.time.LocalDate revisionPlazo;

    // ── Sistema de niveles ──
    /** XP histórico acumulado, informativo: el nivel sale de xp90d y la calidad, no de este campo. */
    private double xpTotal;
    /** XP de la ventana móvil (levels.ventana-dias); define el nivel junto con la calidad. */
    private double xp90d;
    private int nivel;
    private LocalDateTime nivelActualizadoEn;


    public void agregarVehiculo(Vehiculo vehiculo) {
        if (this.vehiculos == null) {
            this.vehiculos = new ArrayList<>();
        }
        if (vehiculo != null && vehiculo.getId() != null) {
            this.vehiculos.add(new ObjectId(vehiculo.getId()));
        }
    }


    public Conductor() {
        this.setRol(Rol.CONDUCTOR);
        this.setEstadoValidacion(EstadoValidacion.PENDIENTE);
    }
}
