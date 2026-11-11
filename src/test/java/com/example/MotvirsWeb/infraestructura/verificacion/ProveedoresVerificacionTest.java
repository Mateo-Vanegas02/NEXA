package com.example.MotvirsWeb.infraestructura.verificacion;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificationResult;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificationStatus;
import com.example.MotvirsWeb.aplicacion.verificacion.LimitadorTasa;

class ProveedoresVerificacionTest {

    private static final String OK_BODY = "{\"data\":{\"informacionGeneral\":{\"marca\":\"AKT\",\"modelo\":\"2022\"},"
            + "\"soat\":[{\"estado\":\"VIGENTE\"}],\"tecnoMecanica\":[{\"vigente\":\"SI\"}]}}";

    @Test
    void mockSigueReglasDeterministas() {
        MockVerificationProvider p = new MockVerificationProvider();
        assertEquals(VerificationStatus.VERIFIED, p.verifyPlate("ABC123").status());
        assertEquals(VerificationStatus.NOT_FOUND, p.verifyPlate("XXX123").status());
        assertEquals(VerificationStatus.MISMATCH, p.verifyPlate("MMM123").status());
        assertEquals(VerificationStatus.UNAVAILABLE, p.verifyPlate("UUU123").status());
        assertEquals(VerificationStatus.VERIFIED, p.verifyDriver("123456").status());
        assertEquals(VerificationStatus.NOT_FOUND, p.verifyDriver("1230000").status());
        assertEquals(VerificationStatus.MISMATCH, p.verifyDriver("1231111").status());
        assertEquals(VerificationStatus.UNAVAILABLE, p.verifyDriver("1239999").status());
    }

    @Test
    void manualSiempreEsUnavailable() {
        ManualVerificationProvider p = new ManualVerificationProvider();
        assertEquals(VerificationStatus.UNAVAILABLE, p.verifyPlate("ABC123").status());
        assertEquals(VerificationStatus.UNAVAILABLE, p.verifyDriver("123456").status());
    }

    @Test
    void seleccionPorPropiedadConDefaultManual() {
        VerificacionConfig cfg = new VerificacionConfig();
        assertInstanceOf(ManualVerificationProvider.class, cfg.driverVerificationProvider("", "", "", 1000, 1));
        assertInstanceOf(ManualVerificationProvider.class, cfg.driverVerificationProvider("loquesea", "", "", 1000, 1));
        assertInstanceOf(MockVerificationProvider.class, cfg.driverVerificationProvider("MOCK", "", "", 1000, 1));
        assertInstanceOf(ManualVerificationProvider.class, cfg.driverVerificationProvider("real", "https://x", "", 1000, 1));
        // La rama real+clave crea un HttpClient (necesita sockets de loopback); se cubre por el adaptador en pruebas con mock.
    }

    private RuntHttpVerificationProvider real(HttpClient client, int max) {
        return new RuntHttpVerificationProvider(client, "https://api.example.test/", "token-de-prueba",
                Duration.ofSeconds(1), new LimitadorTasa(max, 60_000));
    }

    @SuppressWarnings("unchecked")
    private HttpClient clientConRespuesta(int status, String body) throws Exception {
        HttpClient c = mock(HttpClient.class);
        HttpResponse<String> r = mock(HttpResponse.class);
        when(r.statusCode()).thenReturn(status);
        when(r.body()).thenReturn(body);
        doReturn(r).when(c).send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class));
        return c;
    }

    @Test
    void realInterpretaRespuestas() throws Exception {
        VerificationResult ok = real(clientConRespuesta(200, OK_BODY), 5).verifyPlate("ABC123", "123456");
        assertEquals(VerificationStatus.VERIFIED, ok.status());
        assertEquals("AKT", ok.marca());
        assertTrue(ok.soatVigente());
        assertTrue(ok.tecnoVigente());
        assertEquals(VerificationStatus.NOT_FOUND, real(clientConRespuesta(404, "{}"), 5).verifyPlate("ABC123", "123456").status());
        assertEquals(VerificationStatus.UNAVAILABLE, real(clientConRespuesta(500, "x"), 5).verifyPlate("ABC123", "123456").status());
        assertEquals(VerificationStatus.UNAVAILABLE, real(clientConRespuesta(200, "no-json"), 5).verifyPlate("ABC123", "123456").status());
        assertEquals(VerificationStatus.UNAVAILABLE, real(clientConRespuesta(200, "{}"), 5).verifyPlate("ABC123", "123456").status());
    }

    @Test
    @SuppressWarnings("unchecked")
    void realDegradaAUnavailableSiLaFuenteFalla() throws Exception {
        HttpClient c = mock(HttpClient.class);
        doThrow(new IOException("timeout")).when(c).send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class));
        assertEquals(VerificationStatus.UNAVAILABLE, real(c, 5).verifyPlate("ABC123", "123456").status());
        doThrow(new IllegalStateException("boom")).when(c).send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class));
        assertEquals(VerificationStatus.UNAVAILABLE, real(c, 5).verifyPlate("ABC123", "123456").status());
    }

    @Test
    void realSinDocumentoDelPropietarioNoLlamaALaFuente() {
        HttpClient c = mock(HttpClient.class);
        RuntHttpVerificationProvider p = real(c, 5);
        assertEquals(VerificationStatus.UNAVAILABLE, p.verifyPlate("ABC123").status());
        assertEquals(VerificationStatus.UNAVAILABLE, p.verifyPlate("ABC123", null).status());
        assertEquals(VerificationStatus.UNAVAILABLE, p.verifyDriver("123456").status());
        verifyNoInteractions(c);
    }

    @Test
    void realAplicaLimiteDeTasa() throws Exception {
        RuntHttpVerificationProvider p = real(clientConRespuesta(200, OK_BODY), 1);
        assertEquals(VerificationStatus.VERIFIED, p.verifyPlate("ABC123", "123456").status());
        assertEquals(VerificationStatus.UNAVAILABLE, p.verifyPlate("ABC123", "123456").status());
    }
}
