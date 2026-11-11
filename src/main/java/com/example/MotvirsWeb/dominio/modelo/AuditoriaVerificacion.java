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
 * Registro append-only de cada verificación y decisión sobre un conductor: quién, cuándo, resultado y fuente.
 * Minimiza datos personales: el documento se guarda enmascarado.
 */
@Document(collection = "auditoria_verificacion")
@CompoundIndex(name = "conductor_fecha", def = "{'conductorEmail': 1, 'fecha': -1}")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuditoriaVerificacion {

    public enum Accion {
        VERIFICACION_AUTOMATICA, VERIFICACION_MANUAL, APROBADO, RECHAZADO,
        SOLICITUD_INFO, INFO_RECIBIDA, PLAZO_VENCIDO
    }

    @Id
    private String id;
    private String conductorEmail;
    private Accion accion;
    /** VERIFIED, NOT_FOUND, MISMATCH o UNAVAILABLE (en APROBADO/RECHAZADO: el resultado vigente al decidir). */
    private String resultado;
    private String resultadoPlaca;
    private String resultadoDocumento;
    private String fuente;
    private String placa;
    private String documentoEnmascarado;
    private String adminEmail;
    private String motivo;
    private LocalDateTime fecha;
}
