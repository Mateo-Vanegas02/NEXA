package com.example.MotvirsWeb.dominio.regla;

/** Punto geográfico en grados decimales (WGS84). */
public record PuntoGeo(double latitud, double longitud) {

    /** Radio medio de la Tierra en km. */
    private static final double RADIO_TIERRA_KM = 6371.0088;

    public PuntoGeo {
        if (!Double.isFinite(latitud) || latitud < -90 || latitud > 90) {
            throw new IllegalArgumentException("Latitud fuera de rango: " + latitud);
        }
        if (!Double.isFinite(longitud) || longitud < -180 || longitud > 180) {
            throw new IllegalArgumentException("Longitud fuera de rango: " + longitud);
        }
    }

    /** Distancia en línea recta (fórmula del haversine), en km. */
    public double distanciaKm(PuntoGeo otro) {
        double lat1 = Math.toRadians(latitud);
        double lat2 = Math.toRadians(otro.latitud);
        double dLat = lat2 - lat1;
        double dLng = Math.toRadians(otro.longitud - longitud);
        double h = Math.pow(Math.sin(dLat / 2), 2)
                + Math.cos(lat1) * Math.cos(lat2) * Math.pow(Math.sin(dLng / 2), 2);
        return 2 * RADIO_TIERRA_KM * Math.asin(Math.min(1, Math.sqrt(h)));
    }
}
