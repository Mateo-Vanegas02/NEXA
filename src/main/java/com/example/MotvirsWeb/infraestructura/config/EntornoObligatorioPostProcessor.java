package com.example.MotvirsWeb.infraestructura.config;

import java.util.ArrayList;
import java.util.Base64;
import java.util.List;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.Profiles;

/**
 * Falla el arranque, con un mensaje claro, si falta una variable de entorno
 * obligatoria o si el secreto JWT no es válido. Los secretos no tienen valor
 * por defecto en application*.properties.
 *
 * Se omite con {@code nexa.config.validar-entorno=false} (tests) o con el
 * perfil {@code test}.
 */
public class EntornoObligatorioPostProcessor implements EnvironmentPostProcessor {

    static final String[] OBLIGATORIAS = {
            "MONGODB_URI", "JWT_SECRET", "GEMINI_API_KEY", "SPRING_MAIL_USERNAME", "SPRING_MAIL_PASSWORD" };

    /** Bytes mínimos del secreto HMAC-SHA256 (256 bits). */
    static final int JWT_MIN_BYTES = 32;

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment env, SpringApplication application) {
        if ("false".equalsIgnoreCase(env.getProperty("nexa.config.validar-entorno"))
                || env.acceptsProfiles(Profiles.of("test"))) {
            return;
        }
        List<String> faltan = new ArrayList<>();
        for (String nombre : OBLIGATORIAS) {
            if (esVacia(env.getProperty(nombre))) {
                faltan.add(nombre);
            }
        }
        if (env.acceptsProfiles(Profiles.of("prod")) && esVacia(env.getProperty("APP_BASE_URL"))) {
            faltan.add("APP_BASE_URL");
        }
        if (!faltan.isEmpty()) {
            throw new IllegalStateException("Configuracion incompleta: faltan las variables de entorno obligatorias "
                    + faltan + ". Definelas (ver .env.example y docs/SEGURIDAD.md) y vuelve a arrancar.");
        }
        String error = validarSecretoJwt(env.getProperty("JWT_SECRET"));
        if (error != null) {
            throw new IllegalStateException("JWT_SECRET invalido: " + error);
        }
    }

    /** @return null si el secreto es válido; si no, el motivo (nunca incluye el valor). */
    static String validarSecretoJwt(String secreto) {
        try {
            byte[] bytes = Base64.getDecoder().decode(secreto.trim());
            if (bytes.length < JWT_MIN_BYTES) {
                return "debe tener al menos " + JWT_MIN_BYTES + " bytes (256 bits) una vez decodificado de Base64";
            }
            return null;
        } catch (IllegalArgumentException e) {
            return "debe estar codificado en Base64 (genera uno con: openssl rand -base64 48)";
        }
    }

    private static boolean esVacia(String valor) {
        return valor == null || valor.isBlank();
    }
}
