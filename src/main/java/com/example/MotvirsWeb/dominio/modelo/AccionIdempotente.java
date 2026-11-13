package com.example.MotvirsWeb.dominio.modelo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;

/**
 * Respuesta ya dada a una acción con cabecera {@code Idempotency-Key}: si el teléfono la reintenta (se cortó la señal
 * antes de recibir la respuesta), se devuelve la misma sin repetir la acción. Se borra sola a las 48 h.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "acciones_idempotentes")
public class AccionIdempotente {

    /** {@code usuarioId:llave}: la llave solo vale para quien la envió. */
    @Id
    private String id;

    /** Acción a la que pertenece la llave (p. ej. {@code POST /api/conductor/finalizar-servicio/{id}}). */
    private String accion;

    /** false mientras la acción se está procesando. */
    private boolean terminada;

    private int estadoHttp;

    /** Cuerpo de la respuesta en JSON. */
    private String cuerpo;

    @Indexed(expireAfter = "48h")
    private Instant creadaEn;
}
