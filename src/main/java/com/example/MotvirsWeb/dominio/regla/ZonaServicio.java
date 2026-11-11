package com.example.MotvirsWeb.dominio.regla;

import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * Zona donde NEXA presta el servicio (Cartagena) y distancia máxima por viaje.
 * El mapa de la app no está limitado a la ciudad, así que el servidor rechaza los
 * puntos de fuera y las rutas más largas que el viaje urbano más largo posible.
 */
@Component
public class ZonaServicio {

    public enum Resultado {
        VALIDO,
        ORIGEN_FUERA_DE_ZONA,
        DESTINO_FUERA_DE_ZONA,
        DISTANCIA_EXCEDIDA
    }

    private final List<PuntoGeo> vertices;
    private final double distanciaMaxKm;

    public ZonaServicio(ModeloNexaProperties cfg) {
        this.vertices = parsear(cfg.getZona().getPoligono());
        this.distanciaMaxKm = cfg.getZona().getDistanciaMaxKm();
    }

    public double distanciaMaxKm() {
        return distanciaMaxKm;
    }

    public List<PuntoGeo> vertices() {
        return vertices;
    }

    /** Punto dentro del polígono (algoritmo de cruce de rayos). */
    public boolean contiene(PuntoGeo p) {
        boolean dentro = false;
        for (int i = 0, j = vertices.size() - 1; i < vertices.size(); j = i++) {
            PuntoGeo a = vertices.get(i);
            PuntoGeo b = vertices.get(j);
            boolean cruza = (a.latitud() > p.latitud()) != (b.latitud() > p.latitud());
            if (cruza) {
                double lngCorte = (b.longitud() - a.longitud()) * (p.latitud() - a.latitud())
                        / (b.latitud() - a.latitud()) + a.longitud();
                if (p.longitud() < lngCorte) {
                    dentro = !dentro;
                }
            }
        }
        return dentro;
    }

    /** Valida un viaje: ambos extremos dentro de la zona y ruta dentro del máximo. */
    public Resultado evaluar(PuntoGeo origen, PuntoGeo destino, double distanciaRutaKm) {
        if (!contiene(origen)) {
            return Resultado.ORIGEN_FUERA_DE_ZONA;
        }
        if (!contiene(destino)) {
            return Resultado.DESTINO_FUERA_DE_ZONA;
        }
        if (distanciaRutaKm > distanciaMaxKm) {
            return Resultado.DISTANCIA_EXCEDIDA;
        }
        return Resultado.VALIDO;
    }

    static List<PuntoGeo> parsear(String texto) {
        if (texto == null || texto.isBlank()) {
            throw new IllegalStateException("nexa.zona.poligono no está configurado");
        }
        List<PuntoGeo> puntos = new ArrayList<>();
        for (String par : texto.split(";")) {
            String[] partes = par.trim().split("\\s+");
            if (partes.length != 2) {
                throw new IllegalStateException("Vértice inválido en nexa.zona.poligono: '" + par.trim() + "'");
            }
            puntos.add(new PuntoGeo(Double.parseDouble(partes[0]), Double.parseDouble(partes[1])));
        }
        if (puntos.size() < 3) {
            throw new IllegalStateException("nexa.zona.poligono necesita al menos 3 vértices");
        }
        return List.copyOf(puntos);
    }
}
