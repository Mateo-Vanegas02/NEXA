package com.example.MotvirsWeb.infraestructura.push;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorPush.Aviso;
import com.example.MotvirsWeb.aplicacion.puerto.NotificadorPush.Canal;
import com.example.MotvirsWeb.dominio.repositorio.DispositivoRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Base64;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;

class NotificadorPushFcmTest {

    private final ObjectMapper json = new ObjectMapper();

    private JsonNode mensaje(Aviso aviso) throws Exception {
        return json.readTree(NotificadorPushFcm.mensaje(json, "tok", aviso)).path("message");
    }

    @Test
    void unAvisoDelViajeViajaComoDatosParaQueLaAppLoDibuje() throws Exception {
        JsonNode m = mensaje(new Aviso("VIAJE_ACEPTADO:s1", "VIAJE_ACEPTADO", Canal.VIAJE, "Carlos va por ti",
                "KZT 38F", Map.of("servicioId", "s1", "placa", "KZT 38F"), Duration.ofMinutes(10)));

        assertEquals("tok", m.path("token").asText());
        assertTrue(m.path("notification").isMissingNode(), "la app arma la notificación con su diseño");
        assertEquals("HIGH", m.path("android").path("priority").asText(), "llega con la app cerrada");
        assertEquals("600s", m.path("android").path("ttl").asText());
        assertEquals("nexa_viaje", m.path("data").path("canal").asText());
        assertEquals("Carlos va por ti", m.path("data").path("titulo").asText());
        assertEquals("KZT 38F", m.path("data").path("placa").asText());
        assertEquals("VIAJE_ACEPTADO:s1", m.path("data").path("eventoId").asText());
        assertEquals("s1", m.path("data").path("servicioId").asText());
    }

    @Test
    void losAvisosDeLaCuentaLlevanNotificacionDelSistema() throws Exception {
        JsonNode m = mensaje(new Aviso("DEUDA:s1", "DEUDA", Canal.CUENTA, "Tienes un cargo pendiente",
                "Se cobra en tu próximo viaje", Map.of("servicioId", "s1"), Duration.ofDays(1)));

        assertEquals("Tienes un cargo pendiente", m.path("notification").path("title").asText());
        assertEquals("nexa_cuenta", m.path("android").path("notification").path("channel_id").asText());
        assertEquals("viaje-s1", m.path("android").path("notification").path("tag").asText());
        assertEquals("NORMAL", m.path("android").path("priority").asText());
    }

    @Test
    void lasSolicitudesYLosSilenciososViajanSoloComoDatos() throws Exception {
        JsonNode solicitud = mensaje(new Aviso("SOLICITUD_NUEVA:s1:1", "SOLICITUD_NUEVA", Canal.SOLICITUDES,
                "Nueva solicitud · Ganas $6.964", "A 700 m", Map.of("servicioId", "s1"), Duration.ofSeconds(45)));
        assertTrue(solicitud.path("notification").isMissingNode(), "la app arma la notificación con sus botones");
        assertEquals("Nueva solicitud · Ganas $6.964", solicitud.path("data").path("titulo").asText());
        assertEquals("nexa_solicitudes", solicitud.path("data").path("canal").asText());
        assertEquals("45s", solicitud.path("android").path("ttl").asText());

        JsonNode retiro = mensaje(new Aviso("SOLICITUD_RETIRADA:s1", "SOLICITUD_RETIRADA", Canal.SILENCIOSO, null, null,
                Map.of("servicioId", "s1", "motivo", "TOMADO"), Duration.ofSeconds(45)));
        assertTrue(retiro.path("notification").isMissingNode());
        assertFalse(retiro.path("data").has("canal"));
        assertEquals("NORMAL", retiro.path("android").path("priority").asText());
    }

    @Test
    void soloSeBorranLosTokensQueFcmDaPorMuertos() {
        assertTrue(NotificadorPushFcm.tokenInvalido(404, "UNREGISTERED"));
        assertTrue(NotificadorPushFcm.tokenInvalido(403, "SENDER_ID_MISMATCH"));
        assertFalse(NotificadorPushFcm.tokenInvalido(400, "INVALID_ARGUMENT"), "puede ser un error del mensaje");
        assertFalse(NotificadorPushFcm.tokenInvalido(503, "UNAVAILABLE"));
    }

    @Test
    void lasCredencialesSeAceptanEnJsonOEnBase64YSinEllasNoHayPush() {
        String cuenta = "{\"project_id\":\"nexa\"}";
        assertEquals(cuenta, PushConfig.decodificar(cuenta));
        assertEquals(cuenta, PushConfig.decodificar(Base64.getEncoder().encodeToString(cuenta.getBytes(StandardCharsets.UTF_8))));
        assertEquals("", PushConfig.decodificar(null));

        PushConfig config = new PushConfig();
        assertFalse(config.notificadorPush("", mock(DispositivoRepository.class), json).activo());
        assertFalse(config.notificadorPush("{\"project_id\":\"nexa\"}", mock(DispositivoRepository.class), json).activo(),
                "una cuenta incompleta no impide arrancar");
    }
}
