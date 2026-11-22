package com.example.MotvirsWeb.infraestructura.rutas;

import com.example.MotvirsWeb.aplicacion.puerto.ProveedorRutas;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.PasoRuta;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.regla.Ruta;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Function;

/**
 * Ruta por calles reales con OSRM ({@code /route/v1/driving}): distancia, duración y trazado. Si OSRM no responde a
 * tiempo o devuelve algo inválido, cae a {@link RutaLineaRecta}: pedir un viaje nunca depende de un servicio externo.
 * Las consultas repetidas (el pasajero mueve el pin y se recotiza) se guardan 10 minutos.
 */
@Slf4j
@Component
public class RutaOsrm implements ProveedorRutas {

    public static final String FUENTE = "osrm";

    private static final long VIGENCIA_CACHE_MS = 10 * 60 * 1000L;
    private static final int MAX_CACHE = 500;

    private record Guardada(Ruta ruta, long vence) {
    }

    private final String base;
    private final Function<URI, String> http;
    private final ProveedorRutas respaldo;
    private final ObjectMapper json = new ObjectMapper();
    private final Map<String, Guardada> cache = new ConcurrentHashMap<>();

    @Autowired
    public RutaOsrm(ModeloNexaProperties cfg, RutaLineaRecta respaldo) {
        this(cfg.getRutas().getOsrmUrl(), clienteHttp(cfg.getRutas().getOsrmTimeoutMs()), respaldo);
    }

    /** Para pruebas: el transporte HTTP se sustituye por una función. */
    RutaOsrm(String base, Function<URI, String> http, ProveedorRutas respaldo) {
        this.base = base == null ? "" : base.replaceAll("/+$", "");
        this.http = http;
        this.respaldo = respaldo;
    }

    @Override
    public Ruta calcular(PuntoGeo origen, PuntoGeo destino) {
        String clave = clave(origen, destino);
        long ahora = System.currentTimeMillis();
        Guardada g = cache.get(clave);
        if (g != null && g.vence() > ahora) {
            return g.ruta();
        }
        try {
            if (base.isEmpty()) {
                throw new IllegalStateException("nexa.rutas.osrm-url no está configurada");
            }
            URI uri = URI.create(String.format(Locale.ROOT,
                    "%s/route/v1/driving/%.6f,%.6f;%.6f,%.6f?overview=full&geometries=polyline&steps=true",
                    base, origen.longitud(), origen.latitud(), destino.longitud(), destino.latitud()));
            Ruta ruta = parsear(http.apply(uri), origen.distanciaKm(destino));
            if (cache.size() >= MAX_CACHE) {
                cache.clear();
            }
            cache.put(clave, new Guardada(ruta, ahora + VIGENCIA_CACHE_MS));
            return ruta;
        } catch (RuntimeException e) {
            log.warn("OSRM no respondió ({}); se usa la línea recta", e.getMessage());
            return respaldo.calcular(origen, destino);
        }
    }

    /**
     * Rutas alternativas desde una posición en vivo (sin caché: el conductor se mueve). OSRM devuelve la principal y
     * hasta dos alternativas; si falla, queda solo la línea recta.
     */
    @Override
    public java.util.List<Ruta> alternativas(PuntoGeo origen, PuntoGeo destino) {
        try {
            if (base.isEmpty()) {
                throw new IllegalStateException("nexa.rutas.osrm-url no está configurada");
            }
            URI uri = URI.create(String.format(Locale.ROOT,
                    "%s/route/v1/driving/%.6f,%.6f;%.6f,%.6f?overview=full&geometries=polyline&steps=true&alternatives=2",
                    base, origen.longitud(), origen.latitud(), destino.longitud(), destino.latitud()));
            return parsearTodas(http.apply(uri), origen.distanciaKm(destino));
        } catch (RuntimeException e) {
            log.warn("OSRM no respondió las alternativas ({}); se usa la línea recta", e.getMessage());
            return java.util.List.of(respaldo.calcular(origen, destino));
        }
    }

    /** Convierte la respuesta de OSRM en una {@link Ruta}; lanza si no es una ruta válida. */
    Ruta parsear(String cuerpo, double rectaKm) {
        return parsearTodas(cuerpo, rectaKm).get(0);
    }

    /** Todas las rutas válidas de la respuesta, en el orden de OSRM (la principal primero). */
    java.util.List<Ruta> parsearTodas(String cuerpo, double rectaKm) {
        try {
            JsonNode raiz = json.readTree(cuerpo);
            if (!"Ok".equals(raiz.path("code").asText())) {
                throw new IllegalStateException("código " + raiz.path("code").asText("?"));
            }
            java.util.List<Ruta> rutas = new java.util.ArrayList<>();
            for (JsonNode r : raiz.path("routes")) {
                double km = r.path("distance").asDouble(-1) / 1000.0;
                if (!(km > 0) || !Double.isFinite(km)) {
                    if (rutas.isEmpty()) {
                        throw new IllegalStateException("distancia inválida");
                    }
                    continue;
                }
                double minutos = Math.max(0, r.path("duration").asDouble(0) / 60.0);
                String geometria = r.path("geometry").asText(null);
                // Por calle nunca es menos que la línea recta; si OSRM "ajusta" los puntos y da menos, manda la recta
                rutas.add(new Ruta(Math.max(km, rectaKm), rectaKm, FUENTE, minutos, geometria, pasos(r)));
            }
            if (rutas.isEmpty()) {
                throw new IllegalStateException("sin rutas");
            }
            return rutas;
        } catch (java.io.IOException e) {
            throw new IllegalStateException("respuesta ilegible", e);
        }
    }

    /** Maniobras de todos los tramos ({@code legs[].steps[]}); las que no se pueden leer se omiten. */
    static java.util.List<PasoRuta> pasos(JsonNode ruta) {
        java.util.List<PasoRuta> pasos = new java.util.ArrayList<>();
        for (JsonNode tramo : ruta.path("legs")) {
            for (JsonNode paso : tramo.path("steps")) {
                JsonNode m = paso.path("maneuver");
                JsonNode punto = m.path("location");
                if (!punto.isArray() || punto.size() < 2) {
                    continue;
                }
                pasos.add(new PasoRuta(punto.get(1).asDouble(), punto.get(0).asDouble(),
                        m.path("type").asText(""), m.path("modifier").asText(""),
                        paso.path("name").asText("").trim(), Math.max(0, paso.path("distance").asDouble(0))));
            }
        }
        return pasos;
    }

    private static String clave(PuntoGeo a, PuntoGeo b) {
        return String.format(Locale.ROOT, "%.5f,%.5f;%.5f,%.5f", a.latitud(), a.longitud(), b.latitud(), b.longitud());
    }

    private static Function<URI, String> clienteHttp(int timeoutMs) {
        HttpClient cliente = HttpClient.newBuilder().connectTimeout(Duration.ofMillis(timeoutMs)).build();
        return uri -> {
            try {
                HttpResponse<String> resp = cliente.send(
                        HttpRequest.newBuilder(uri).timeout(Duration.ofMillis(timeoutMs)).GET().build(),
                        HttpResponse.BodyHandlers.ofString());
                if (resp.statusCode() != 200) {
                    throw new IllegalStateException("HTTP " + resp.statusCode());
                }
                return resp.body();
            } catch (java.io.IOException e) {
                throw new IllegalStateException(e.getMessage(), e);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new IllegalStateException("interrumpido", e);
            }
        };
    }
}
