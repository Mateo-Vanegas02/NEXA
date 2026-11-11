package com.example.MotvirsWeb.infraestructura.config;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.DateTimeException;
import java.time.ZoneId;
import java.util.Properties;
import java.util.TimeZone;

/**
 * Fija la zona horaria por defecto de la JVM en la zona del negocio ({@code nexa.zona-horaria}) antes de
 * arrancar Spring.
 *
 * <p>El reloj de niveles ({@code NivelesConfig}) ya usa esa zona, pero varias fechas del viaje se toman
 * con {@code LocalDateTime.now()}, que usa la zona de la JVM. En Docker y Azure la JVM corre en UTC, así
 * que {@code solicitadoEn} (reloj de niveles) quedaba 5 h atrás de {@code fechaAceptacion},
 * {@code fechaLlegada}, {@code fechaInicio} y {@code fechaFinalizacion}: las métricas de despacho y los
 * tiempos de espera salían mal. Con una sola zona, todas las fechas comparten la misma referencia y
 * MongoDB sigue guardando el instante correcto.</p>
 *
 * <p>Orden: variable de entorno {@code NEXA_ZONA_HORARIA}, propiedad del sistema {@code nexa.zona-horaria},
 * {@code modelo-nexa.properties} y, si nada es válido, America/Bogota.</p>
 */
public final class ZonaHorariaNegocio {

    static final String POR_DEFECTO = "America/Bogota";
    private static final String PROPIEDAD = "nexa.zona-horaria";

    private ZonaHorariaNegocio() {
    }

    /** Aplica la zona del negocio como zona por defecto de la JVM y la devuelve. */
    public static ZoneId aplicar() {
        ZoneId zona = resolver(System.getenv("NEXA_ZONA_HORARIA"), System.getProperty(PROPIEDAD), desdeArchivo());
        TimeZone.setDefault(TimeZone.getTimeZone(zona));
        return zona;
    }

    /** Primera zona válida entre los candidatos, en orden; America/Bogota si ninguno sirve. */
    static ZoneId resolver(String... candidatos) {
        for (String candidato : candidatos) {
            if (candidato == null || candidato.isBlank()) {
                continue;
            }
            try {
                return ZoneId.of(candidato.trim());
            } catch (DateTimeException e) {
                System.err.println("WARN: zona horaria inválida '" + candidato + "', se ignora.");
            }
        }
        return ZoneId.of(POR_DEFECTO);
    }

    private static String desdeArchivo() {
        try (InputStream in = ZonaHorariaNegocio.class.getResourceAsStream("/modelo-nexa.properties")) {
            if (in == null) {
                return null;
            }
            Properties props = new Properties();
            props.load(new InputStreamReader(in, StandardCharsets.UTF_8));
            return props.getProperty(PROPIEDAD);
        } catch (IOException e) {
            return null;
        }
    }
}
