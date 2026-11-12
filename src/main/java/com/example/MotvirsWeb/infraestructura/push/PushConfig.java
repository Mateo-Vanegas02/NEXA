package com.example.MotvirsWeb.infraestructura.push;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorPush;
import com.example.MotvirsWeb.dominio.repositorio.DispositivoRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

/**
 * Elige cómo se envían los avisos push. Con {@code FIREBASE_CREDENCIALES} (cuenta de servicio de Firebase, el JSON
 * o el JSON en base64; en AWS va en Parameter Store como /nexa/prod/FIREBASE_CREDENCIALES) se envían por FCM; sin
 * ella el servidor arranca igual y los avisos se descartan. No es obligatoria: la web no la necesita.
 */
@Slf4j
@Configuration
public class PushConfig {

    @Bean
    NotificadorPush notificadorPush(@Value("${nexa.push.firebase-credenciales:}") String credenciales,
            DispositivoRepository dispositivos, ObjectMapper json) {
        String contenido = decodificar(credenciales);
        if (contenido.isBlank()) {
            log.info("Push desactivado: falta FIREBASE_CREDENCIALES");
            return new NotificadorPushInactivo();
        }
        try {
            return new NotificadorPushFcm(contenido, dispositivos, json);
        } catch (Exception e) {
            // Nunca se registra el contenido: es una clave privada
            log.error("FIREBASE_CREDENCIALES no es una cuenta de servicio válida: push desactivado ({})",
                    e.getClass().getSimpleName());
            return new NotificadorPushInactivo();
        }
    }

    /** Acepta el JSON tal cual o en base64 (una sola línea, más cómodo en Parameter Store y en .env). */
    static String decodificar(String valor) {
        String v = valor == null ? "" : valor.trim();
        if (v.isEmpty() || v.startsWith("{")) {
            return v;
        }
        try {
            return new String(Base64.getDecoder().decode(v), StandardCharsets.UTF_8).trim();
        } catch (IllegalArgumentException e) {
            return v;
        }
    }
}
