package com.example.MotvirsWeb.dominio.modelo;

import lombok.*;
import lombok.experimental.SuperBuilder;
import org.springframework.data.annotation.TypeAlias;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

@Document(collection = "Usuarios")
@TypeAlias("ADMIN")
@Data
@EqualsAndHashCode(callSuper = true)
@SuperBuilder
@NoArgsConstructor
public class Admin extends Usuario{
    @Builder.Default
    @Field("config_notificaciones")
    private boolean recibirNotificaciones = true;

    public Admin(String email, String passwordHash) {
        this.setEmail(email);
        this.setPassword(passwordHash);
        this.setRol(Rol.ADMIN);
        this.setEstadoValidacion(EstadoValidacion.APROBADO);
        this.recibirNotificaciones =true;
    }


    public void aprobarConductor(Conductor conductor) {
        conductor.setEstadoValidacion(EstadoValidacion.APROBADO);
    }

    public void rechazarConductor(Conductor conductor) {
        conductor.setEstadoValidacion(EstadoValidacion.RECHAZADO);

    }
    public void pendienteConductor (Conductor conductor){
        conductor.setEstadoValidacion(EstadoValidacion.PENDIENTE);
    }
}
