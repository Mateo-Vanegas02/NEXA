package com.example.MotvirsWeb.infraestructura.config;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Base64;

import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

class EntornoObligatorioPostProcessorTest {

    private final EntornoObligatorioPostProcessor pp = new EntornoObligatorioPostProcessor();

    private static String secretoValido() {
        return Base64.getEncoder().encodeToString(new byte[48]);
    }

    private static MockEnvironment entornoCompleto() {
        return new MockEnvironment()
                .withProperty("MONGODB_URI", "mongodb://localhost:27017/test")
                .withProperty("JWT_SECRET", secretoValido())
                .withProperty("GEMINI_API_KEY", "k")
                .withProperty("SPRING_MAIL_USERNAME", "a@b.c")
                .withProperty("SPRING_MAIL_PASSWORD", "p");
    }

    @Test
    void conTodasLasVariablesArranca() {
        assertDoesNotThrow(() -> pp.postProcessEnvironment(entornoCompleto(), null));
    }

    @Test
    void sinVariablesFallaListandoTodasLasFaltantes() {
        IllegalStateException e = assertThrows(IllegalStateException.class,
                () -> pp.postProcessEnvironment(new MockEnvironment(), null));
        for (String nombre : EntornoObligatorioPostProcessor.OBLIGATORIAS) {
            assertTrue(e.getMessage().contains(nombre), nombre);
        }
    }

    @Test
    void variableEnBlancoCuentaComoFaltante() {
        MockEnvironment env = entornoCompleto().withProperty("GEMINI_API_KEY", "   ");
        IllegalStateException e = assertThrows(IllegalStateException.class,
                () -> pp.postProcessEnvironment(env, null));
        assertTrue(e.getMessage().contains("GEMINI_API_KEY"));
        assertFalse(e.getMessage().contains("MONGODB_URI"));
    }

    @Test
    void enProduccionTambienExigeAppBaseUrl() {
        MockEnvironment env = entornoCompleto();
        env.setActiveProfiles("prod");
        IllegalStateException e = assertThrows(IllegalStateException.class,
                () -> pp.postProcessEnvironment(env, null));
        assertTrue(e.getMessage().contains("APP_BASE_URL"));
        env.setProperty("APP_BASE_URL", "https://nexa.example.com");
        assertDoesNotThrow(() -> pp.postProcessEnvironment(env, null));
    }

    @Test
    void secretoJwtCortoOSinBase64SeRechaza() {
        MockEnvironment corto = entornoCompleto().withProperty("JWT_SECRET",
                Base64.getEncoder().encodeToString("corto".getBytes()));
        assertThrows(IllegalStateException.class, () -> pp.postProcessEnvironment(corto, null));
        MockEnvironment noBase64 = entornoCompleto().withProperty("JWT_SECRET", "esto no es base64 !!!");
        assertThrows(IllegalStateException.class, () -> pp.postProcessEnvironment(noBase64, null));
    }

    @Test
    void elMensajeDeErrorNuncaIncluyeElValorDelSecreto() {
        String valor = "valor-secreto-que-no-debe-aparecer";
        MockEnvironment env = entornoCompleto().withProperty("JWT_SECRET", valor);
        IllegalStateException e = assertThrows(IllegalStateException.class,
                () -> pp.postProcessEnvironment(env, null));
        assertFalse(e.getMessage().contains(valor));
    }

    @Test
    void sePuedeOmitirLaValidacionEnTests() {
        MockEnvironment env = new MockEnvironment().withProperty("nexa.config.validar-entorno", "false");
        assertDoesNotThrow(() -> pp.postProcessEnvironment(env, null));
        MockEnvironment test = new MockEnvironment();
        test.setActiveProfiles("test");
        assertDoesNotThrow(() -> pp.postProcessEnvironment(test, null));
    }

    @Test
    void validarSecretoJwt() {
        assertNull(EntornoObligatorioPostProcessor.validarSecretoJwt(secretoValido()));
        assertNotNull(EntornoObligatorioPostProcessor.validarSecretoJwt("***"));
    }
}
