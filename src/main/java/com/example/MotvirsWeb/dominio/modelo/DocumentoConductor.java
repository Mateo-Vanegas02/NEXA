package com.example.MotvirsWeb.dominio.modelo;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

/**
 * Metadatos de una foto de documento subida por un conductor. El archivo vive en el almacén de documentos
 * ({@code archivoId}); aquí queda el número declarado para que el administrador contraste foto y número.
 */
@Document(collection = "documentos_conductor")
@CompoundIndex(name = "conductor_tipo", def = "{'conductorId': 1, 'tipo': 1}")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DocumentoConductor {

    @Id
    private String id;
    private String conductorId;
    /** Solo para documentos de vehículo (tarjeta de propiedad, SOAT, tecnomecánica). */
    private String vehiculoId;
    private TipoDocumento tipo;
    /** Número que el conductor escribió en el formulario. */
    private String numeroDeclarado;
    private String archivoId;
    private String nombreOriginal;
    /** Tipo real del archivo, detectado por su contenido (no el que declara el navegador). */
    private String contentType;
    private long tamano;
    private LocalDateTime subidoEn;
}
