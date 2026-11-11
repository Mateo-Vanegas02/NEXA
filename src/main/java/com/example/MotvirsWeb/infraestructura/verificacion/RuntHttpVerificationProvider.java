package com.example.MotvirsWeb.infraestructura.verificacion;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import com.example.MotvirsWeb.aplicacion.verificacion.DriverVerificationProvider;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificationResult;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificationStatus;
import com.example.MotvirsWeb.aplicacion.verificacion.LimitadorTasa;

/**
 * Adaptador HTTP hacia un proveedor legítimo de consulta RUNT por placa (diseñado según la documentación pública de
 * Verifik: GET {base}/v2/co/runt/vehicle-by-plate?plate&documentType&documentNumber, Bearer token).
 * NO ha sido probado contra el servicio real (requiere cuenta/convenio). No evade captchas: consume una API contratada.
 * La consulta de placa exige el documento del propietario; sin él devuelve UNAVAILABLE. No hay endpoint de conductor
 * verificado, por lo que verifyDriver devuelve UNAVAILABLE (verificación manual).
 */
public class RuntHttpVerificationProvider implements DriverVerificationProvider {

    public static final String NOMBRE = "RUNT_HTTP";
    private static final Logger log = LoggerFactory.getLogger(RuntHttpVerificationProvider.class);

    private final HttpClient client;
    private final String baseUrl;
    private final String token;
    private final Duration timeout;
    private final LimitadorTasa limitador;
    private final ObjectMapper mapper = new ObjectMapper();

    public RuntHttpVerificationProvider(HttpClient client, String baseUrl, String token, Duration timeout,
                                        LimitadorTasa limitador) {
        this.client = client;
        this.baseUrl = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
        this.token = token;
        this.timeout = timeout;
        this.limitador = limitador;
    }

    @Override
    public String nombre() {
        return NOMBRE;
    }

    @Override
    public VerificationResult verifyPlate(String plate) {
        return VerificationResult.unavailable(NOMBRE, "La fuente exige el documento del propietario");
    }

    @Override
    public VerificationResult verifyPlate(String plate, String ownerDocumentId) {
        if (ownerDocumentId == null || ownerDocumentId.isBlank()) {
            return verifyPlate(plate);
        }
        if (!limitador.permitir("runt")) {
            return VerificationResult.unavailable(NOMBRE, "Límite de consultas alcanzado, intente más tarde");
        }
        try {
            String url = baseUrl + "/v2/co/runt/vehicle-by-plate?documentType=CC"
                    + "&documentNumber=" + enc(ownerDocumentId) + "&plate=" + enc(plate);
            HttpRequest req = HttpRequest.newBuilder(URI.create(url))
                    .timeout(timeout)
                    .header("Accept", "application/json")
                    .header("Authorization", "Bearer " + token)
                    .GET().build();
            HttpResponse<String> resp = client.send(req, HttpResponse.BodyHandlers.ofString());
            return interpretar(resp.statusCode(), resp.body());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return VerificationResult.unavailable(NOMBRE, "Fuente no disponible");
        } catch (IOException | RuntimeException e) {
            // No se registra el mensaje: puede contener la URL con el documento.
            log.warn("Fallo consultando fuente externa: {}", e.getClass().getSimpleName());
            return VerificationResult.unavailable(NOMBRE, "Fuente no disponible");
        }
    }

    @Override
    public VerificationResult verifyDriver(String documentId) {
        return VerificationResult.unavailable(NOMBRE, "Verificación de conductor no automatizada: requiere revisión manual");
    }

    VerificationResult interpretar(int status, String body) {
        if (status == 404) {
            return VerificationResult.of(VerificationStatus.NOT_FOUND, NOMBRE, "Placa no encontrada en la fuente");
        }
        if (status != 200 || body == null) {
            log.warn("Fuente externa respondió HTTP {}", status);
            return VerificationResult.unavailable(NOMBRE, "Fuente no disponible");
        }
        try {
            JsonNode data = mapper.readTree(body).path("data");
            JsonNode info = data.path("informacionGeneral");
            if (info.isMissingNode() || info.isNull()) {
                return VerificationResult.unavailable(NOMBRE, "Respuesta inesperada de la fuente");
            }
            return new VerificationResult(VerificationStatus.VERIFIED, NOMBRE, "Placa encontrada en la fuente",
                    texto(info, "marca"), texto(info, "modelo"),
                    vigente(data.path("soat"), "estado"), vigente(data.path("tecnoMecanica"), "vigente"));
        } catch (IOException e) {
            return VerificationResult.unavailable(NOMBRE, "Respuesta inesperada de la fuente");
        }
    }

    private static Boolean vigente(JsonNode arr, String campo) {
        if (!arr.isArray() || arr.isEmpty()) {
            return null;
        }
        for (JsonNode n : arr) {
            String v = n.path(campo).asText("");
            if (v.equalsIgnoreCase("VIGENTE") || v.equalsIgnoreCase("SI") || v.equalsIgnoreCase("true")) {
                return true;
            }
        }
        return false;
    }

    private static String texto(JsonNode n, String campo) {
        String v = n.path(campo).asText(null);
        return v == null || v.length() > 60 ? null : v;
    }

    private static String enc(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }
}
