package com.example.MotvirsWeb.dominio.regla;

import org.springframework.stereotype.Component;

/**
 * Recogida prioritaria del pasajero (tabla de beneficios de la sección 10). Como el conductor elige de una
 * lista, la prioridad se aplica como (a) una ventana inicial —15, 25, 35 y 45 s en los niveles 2 a 5— en la
 * que solo ven el pedido los conductores bien calificados o los favoritos cercanos y (b) un puntaje de orden.
 */
@Component
public class PrioridadRecogida {

    private final ModeloNexaProperties.Beneficios cfg;

    public PrioridadRecogida(ModeloNexaProperties cfg) {
        this.cfg = cfg.getBeneficios();
    }

    /** Segundos de prioridad del nivel (los niveles más altos que la tabla usan el último valor). */
    public int ventanaSegundos(int nivel) {
        int[] v = cfg.getVentanaSegundos();
        return v[Math.max(0, Math.min(nivel, v.length) - 1)];
    }

    public boolean visiblePara(int nivelPasajero, Double calificacionConductor,
            boolean favoritoCercano, long segundosDesdeSolicitud) {
        if (ventanaSegundos(nivelPasajero) <= 0) {
            return true;
        }
        if (segundosDesdeSolicitud >= ventanaSegundos(nivelPasajero)) {
            return true;
        }
        if (calificacionConductor != null && calificacionConductor >= cfg.getCalificacionConductor()) {
            return true;
        }
        return favoritoCercano;
    }

    /** Mayor puntaje = se muestra primero a este conductor. 0 para pasajeros sin prioridad. */
    public double puntaje(int nivelPasajero, Double calificacionConductor, Double etaMinutos,
            boolean favorito) {
        if (ventanaSegundos(nivelPasajero) <= 0) {
            return 0;
        }
        double bonoCalificacion = calificacionConductor != null
                && calificacionConductor >= cfg.getCalificacionConductor() ? cfg.getPesoCalificacion() : 0;
        double cercania = etaMinutos == null ? 0
                : Math.max(0, 1 - etaMinutos / cfg.getEtaMaxMinutos()) * cfg.getPesoCercania();
        return Math.max(0, nivelPasajero - 1) * (bonoCalificacion + cercania)
                + (favorito && puedeTenerFavoritos(nivelPasajero) ? cfg.getBonoFavorito() : 0);
    }

    /** Los conductores favoritos se desbloquean en el nivel 5. */
    public boolean puedeTenerFavoritos(int nivelPasajero) {
        return nivelPasajero >= cfg.getFavoritosDesdeNivel();
    }

    /** A cuántos minutos puede estar un favorito para ver el pedido primero (se amplía desde el nivel 7). */
    public double favoritoEtaMinutos(int nivelPasajero) {
        return nivelPasajero >= cfg.getFavoritoAmpliadoDesdeNivel()
                ? cfg.getFavoritoAmpliadoEtaMinutos() : cfg.getFavoritoEtaMinutos();
    }

    /** ETA en minutos para una distancia en línea recta. */
    public double etaMinutos(double km) {
        return km / cfg.getVelocidadKmh() * 60.0;
    }

    public boolean favoritoCercano(int nivelPasajero, Double etaMinutos) {
        return puedeTenerFavoritos(nivelPasajero) && (etaMinutos == null || etaMinutos <= favoritoEtaMinutos(nivelPasajero));
    }

    public static double distanciaKm(double lat1, double lon1, double lat2, double lon2) {
        double r = 6371.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                        * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return r * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
}
