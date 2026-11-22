package com.example.MotvirsWeb.dominio.regla;

/**
 * Distancia de un viaje según el proveedor de rutas.
 *
 * @param distanciaKm      distancia de la ruta que se cobra (D)
 * @param distanciaRectaKm línea recta origen-destino, base del antifraude de XP
 * @param fuente           proveedor que la calculó ("recta", "osrm", ...)
 * @param duracionMin      duración estimada del recorrido en minutos (0 si el proveedor no la conoce)
 * @param geometria        trazado de la ruta como polyline codificada (precisión 5); null si no hay trazado real
 * @param pasos            maniobras con nombre de calle (vacío si el proveedor no las da)
 */
public record Ruta(double distanciaKm, double distanciaRectaKm, String fuente, double duracionMin, String geometria,
                   java.util.List<PasoRuta> pasos) {

    public Ruta {
        pasos = pasos == null ? java.util.List.of() : java.util.List.copyOf(pasos);
    }

    public Ruta(double distanciaKm, double distanciaRectaKm, String fuente, double duracionMin, String geometria) {
        this(distanciaKm, distanciaRectaKm, fuente, duracionMin, geometria, java.util.List.of());
    }

    public Ruta(double distanciaKm, double distanciaRectaKm, String fuente) {
        this(distanciaKm, distanciaRectaKm, fuente, 0, null);
    }

    public boolean tieneTrazado() {
        return geometria != null && !geometria.isBlank();
    }
}
