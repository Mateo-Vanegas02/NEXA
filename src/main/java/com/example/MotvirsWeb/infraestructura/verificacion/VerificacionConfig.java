package com.example.MotvirsWeb.infraestructura.verificacion;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.net.http.HttpClient;
import java.time.Duration;
import com.example.MotvirsWeb.aplicacion.verificacion.DriverVerificationProvider;
import com.example.MotvirsWeb.aplicacion.verificacion.LimitadorTasa;

/** Selecciona el proveedor con VERIFICATION_PROVIDER=mock|real|manual (por defecto manual). Claves solo por entorno. */
@Configuration
public class VerificacionConfig {

    private static final Logger log = LoggerFactory.getLogger(VerificacionConfig.class);

    @Bean
    public DriverVerificationProvider driverVerificationProvider(
            @Value("${verification.provider:manual}") String modo,
            @Value("${verification.real.base-url:}") String baseUrl,
            @Value("${verification.real.api-key:}") String apiKey,
            @Value("${verification.real.timeout-ms:5000}") long timeoutMs,
            @Value("${verification.real.max-per-minute:30}") int maxPorMinuto) {
        switch (modo == null ? "manual" : modo.trim().toLowerCase()) {
            case "mock":
                log.warn("Verificación: proveedor MOCK activo (solo desarrollo)");
                return new MockVerificationProvider();
            case "real":
                if (baseUrl.isBlank() || apiKey.isBlank()) {
                    log.warn("Verificación: modo real sin configuración completa; se degrada a manual");
                    return new ManualVerificationProvider();
                }
                HttpClient client = HttpClient.newBuilder()
                        .connectTimeout(Duration.ofMillis(timeoutMs))
                        .followRedirects(HttpClient.Redirect.NEVER).build();
                return new RuntHttpVerificationProvider(client, baseUrl, apiKey, Duration.ofMillis(timeoutMs),
                        new LimitadorTasa(maxPorMinuto, 60_000));
            default:
                return new ManualVerificationProvider();
        }
    }
}
