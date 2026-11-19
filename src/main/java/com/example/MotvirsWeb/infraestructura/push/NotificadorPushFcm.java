package com.example.MotvirsWeb.infraestructura.push;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorPush;
import com.example.MotvirsWeb.dominio.repositorio.DispositivoRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.google.auth.oauth2.GoogleCredentials;
import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Envía avisos con la API HTTP v1 de Firebase Cloud Messaging, con la cuenta de servicio del proyecto de Firebase
 * (variable {@code FIREBASE_CREDENCIALES}: el JSON o el JSON en base64).
 *
 * <p>El envío es asíncrono en una cola acotada (el servidor tiene 2 GB): si se llena, se descartan los avisos más
 * nuevos y se deja constancia en el log. Un error de red o 429/5xx se reintenta una vez; un token que FCM da por
 * desregistrado se borra de {@code dispositivos}.
 */
@Slf4j
public class NotificadorPushFcm implements NotificadorPush {

    static final String ALCANCE = "https://www.googleapis.com/auth/firebase.messaging";
    private static final int CAPACIDAD_COLA = 1000;

    private final GoogleCredentials credenciales;
    private final String proyecto;
    private final DispositivoRepository dispositivos;
    private final ObjectMapper json;
    private final HttpClient http;
    private final ThreadPoolExecutor cola;

    public NotificadorPushFcm(String credencialesJson, DispositivoRepository dispositivos, ObjectMapper json)
            throws IOException {
        byte[] bytes = credencialesJson.getBytes(StandardCharsets.UTF_8);
        this.proyecto = json.readTree(bytes).path("project_id").asText("");
        if (proyecto.isBlank()) {
            throw new IllegalArgumentException("FIREBASE_CREDENCIALES no trae project_id");
        }
        this.credenciales = GoogleCredentials.fromStream(new ByteArrayInputStream(bytes)).createScoped(List.of(ALCANCE));
        this.dispositivos = dispositivos;
        this.json = json;
        this.http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
        AtomicInteger hilos = new AtomicInteger();
        this.cola = new ThreadPoolExecutor(2, 2, 0, TimeUnit.SECONDS, new ArrayBlockingQueue<>(CAPACIDAD_COLA), r -> {
            Thread t = new Thread(r, "nexa-push-" + hilos.incrementAndGet());
            t.setDaemon(true);
            return t;
        }, (r, e) -> log.warn("Cola de push llena: se descarta un aviso"));
        log.info("Push activo con el proyecto de Firebase {}", proyecto);
    }

    @Override
    public boolean activo() {
        return true;
    }

    @Override
    public void enviar(Collection<String> tokens, Aviso aviso) {
        if (tokens == null || tokens.isEmpty()) {
            return;
        }
        for (String token : List.copyOf(tokens)) {
            cola.execute(() -> enviarUno(token, aviso));
        }
    }

    @Override
    public void enviarConConfirmacion(Collection<String> tokens, Aviso aviso) {
        if (tokens == null) return;
        java.util.Set<String> fallidos = new java.util.LinkedHashSet<>();
        for (String token : List.copyOf(tokens)) {
            if (!enviarUno(token, aviso)) {
                fallidos.add(token); // se sigue con los demás: un token caído no bloquea al resto
            }
        }
        if (!fallidos.isEmpty()) {
            log.warn("FCM no confirmó {} de {} envíos del aviso {}", fallidos.size(), tokens.size(), aviso.tipo());
            throw new EnvioIncompleto(fallidos);
        }
    }

    private boolean enviarUno(String token, Aviso aviso) {
        for (int intento = 1; intento <= 2; intento++) {
            try {
                HttpResponse<String> r = http.send(peticion(token, aviso), HttpResponse.BodyHandlers.ofString());
                int codigo = r.statusCode();
                if (codigo / 100 == 2) {
                    return true;
                }
                String error = codigoError(r.body());
                if (tokenInvalido(codigo, error)) {
                    long borrados = dispositivos.deleteByToken(token);
                    log.info("FCM rechazó un token ({}); dispositivos borrados: {}", error, borrados);
                    return true;
                }
                if ((codigo == 429 || codigo >= 500) && intento == 1) {
                    Thread.sleep(1000);
                    continue;
                }
                log.warn("FCM respondió {} ({}) al aviso {}", codigo, error, aviso.tipo());
                return false;
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return false;
            } catch (IOException | RuntimeException e) {
                if (intento == 2) {
                    log.warn("No se pudo enviar el aviso {} por FCM: {}", aviso.tipo(), e.getMessage());
                }
            }
        }
        return false;
    }

    private HttpRequest peticion(String token, Aviso aviso) throws IOException {
        credenciales.refreshIfExpired();
        String acceso = credenciales.getAccessToken().getTokenValue();
        return HttpRequest.newBuilder(URI.create("https://fcm.googleapis.com/v1/projects/" + proyecto + "/messages:send"))
                .timeout(Duration.ofSeconds(10))
                .header("Authorization", "Bearer " + acceso)
                .header("Content-Type", "application/json; charset=UTF-8")
                .POST(HttpRequest.BodyPublishers.ofString(mensaje(json, token, aviso)))
                .build();
    }

    /** Mensaje de FCM v1 para un token (paquete visible para las pruebas). */
    static String mensaje(ObjectMapper json, String token, Aviso aviso) {
        ObjectNode mensaje = json.createObjectNode();
        mensaje.put("token", token);

        ObjectNode datos = mensaje.putObject("data");
        datos.put("eventoId", aviso.eventoId());
        datos.put("tipo", aviso.tipo());
        if (aviso.canal().idAndroid() != null) {
            datos.put("canal", aviso.canal().idAndroid());
        }
        if (aviso.titulo() != null) {
            datos.put("titulo", aviso.titulo());
        }
        if (aviso.cuerpo() != null) {
            datos.put("cuerpo", aviso.cuerpo());
        }
        for (Map.Entry<String, String> e : aviso.datos().entrySet()) {
            if (e.getValue() != null) {
                datos.put(e.getKey(), e.getValue());
            }
        }

        ObjectNode android = mensaje.putObject("android");
        android.put("priority", aviso.canal().urgente() ? "HIGH" : "NORMAL");
        if (aviso.vigencia() != null) {
            android.put("ttl", Math.max(0, aviso.vigencia().toSeconds()) + "s");
        }
        // Con notificación el sistema la muestra aunque la app esté cerrada; las de solo datos las arma la app.
        if (!aviso.canal().soloDatos() && aviso.titulo() != null) {
            ObjectNode notificacion = mensaje.putObject("notification");
            notificacion.put("title", aviso.titulo());
            if (aviso.cuerpo() != null) {
                notificacion.put("body", aviso.cuerpo());
            }
            ObjectNode notificacionAndroid = android.putObject("notification");
            notificacionAndroid.put("channel_id", aviso.canal().idAndroid());
            String servicioId = aviso.datos().get("servicioId");
            // Un aviso nuevo del mismo viaje reemplaza al anterior en la bandeja del teléfono
            notificacionAndroid.put("tag", servicioId != null ? "viaje-" + servicioId : aviso.tipo());
        }

        ObjectNode raiz = json.createObjectNode();
        raiz.set("message", mensaje);
        return raiz.toString();
    }

    /** {@code errorCode} de los detalles de FCM, o el {@code status} general. */
    private String codigoError(String cuerpo) {
        try {
            JsonNode error = json.readTree(cuerpo).path("error");
            for (JsonNode d : error.path("details")) {
                if (d.hasNonNull("errorCode")) {
                    return d.get("errorCode").asText();
                }
            }
            return error.path("status").asText("");
        } catch (IOException | RuntimeException e) {
            return "";
        }
    }

    static boolean tokenInvalido(int codigo, String error) {
        return "UNREGISTERED".equals(error) || "SENDER_ID_MISMATCH".equals(error)
                || (codigo == 404 && "NOT_FOUND".equals(error));
    }

    @PreDestroy
    void cerrar() {
        cola.shutdown();
    }
}
