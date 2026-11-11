package com.example.MotvirsWeb.dominio.modelo;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.bson.types.ObjectId;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Document(collection = "NotasAdmin")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotaAdmin {
    @Id
    private ObjectId id;

    private String titulo;
    private String contenido;

    @Builder.Default
    private LocalDateTime fechaCreacion = LocalDateTime.now();

    public String getIdString() {
        return id != null ? id.toString() : null;
    }
}