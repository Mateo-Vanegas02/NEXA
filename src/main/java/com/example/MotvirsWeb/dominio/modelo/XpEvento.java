package com.example.MotvirsWeb.dominio.modelo;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.bson.types.ObjectId;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.CompoundIndexes;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

/**
 * Libro de XP. El índice único (viajeId, rol, motivo) garantiza que un viaje
 * nunca otorgue XP dos veces al mismo rol.
 */
@Document(collection = "xp_eventos")
@CompoundIndexes({
        @CompoundIndex(name = "viaje_rol_motivo_unique_idx", def = "{'viajeId': 1, 'rol': 1, 'motivo': 1}", unique = true),
        @CompoundIndex(name = "usuario_fecha_idx", def = "{'usuarioId': 1, 'creadoEn': -1}")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class XpEvento {
    public static final String MOTIVO_VIAJE = "VIAJE";
    public static final String MOTIVO_AJUSTE_CALIFICACION = "AJUSTE_CALIFICACION";

    @Id
    private String id;
    private ObjectId usuarioId;
    private Rol rol;
    private String viajeId;
    /** XP con un decimal; el ajuste por calificación puede ser negativo. */
    private double xp;
    private String motivo;
    /** Explicación libre (p. ej. por qué el XP fue 0 o se recortó). */
    private String nota;
    /** true cuando el XP ya se sumó al usuario; permite reintentar si el proceso se cortó a mitad. */
    private boolean aplicado;
    private LocalDateTime creadoEn;
}
