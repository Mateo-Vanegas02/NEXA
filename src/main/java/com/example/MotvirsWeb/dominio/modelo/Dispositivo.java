package com.example.MotvirsWeb.dominio.modelo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.bson.types.ObjectId;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

/**
 * Teléfono donde un usuario tiene la app abierta con su sesión: guarda el token de FCM para enviarle avisos push.
 * Un token pertenece a un solo usuario a la vez (si otra persona inicia sesión en el mismo teléfono, el token
 * pasa a ella). Los tokens que FCM rechaza se borran.
 */
@Document(collection = "dispositivos")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Dispositivo {

    @Id
    private String id;

    @Indexed
    private ObjectId usuarioId;

    private Rol rol;

    @Indexed(unique = true)
    private String token;

    /** ANDROID por ahora; IOS cuando se publique allí. */
    private String plataforma;

    private LocalDateTime actualizadoEn;
}
