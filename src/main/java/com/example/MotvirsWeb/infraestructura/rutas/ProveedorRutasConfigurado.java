package com.example.MotvirsWeb.infraestructura.rutas;

import com.example.MotvirsWeb.aplicacion.puerto.ProveedorRutas;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.regla.Ruta;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

/**
 * El proveedor que usa la aplicación, elegido con {@code nexa.rutas.proveedor} ({@code recta} u {@code osrm}).
 * Cambiar a {@code osrm} cambia la distancia que se cobra: calles reales en vez de línea recta × factor.
 */
@Primary
@Component
public class ProveedorRutasConfigurado implements ProveedorRutas {

    private final ProveedorRutas elegido;

    public ProveedorRutasConfigurado(ModeloNexaProperties cfg, RutaLineaRecta recta, RutaOsrm osrm) {
        this.elegido = elegir(cfg.getRutas().getProveedor(), recta, osrm);
    }

    static ProveedorRutas elegir(String nombre, ProveedorRutas recta, ProveedorRutas osrm) {
        if (RutaLineaRecta.FUENTE.equalsIgnoreCase(nombre)) {
            return recta;
        }
        if (RutaOsrm.FUENTE.equalsIgnoreCase(nombre)) {
            return osrm;
        }
        throw new IllegalStateException("nexa.rutas.proveedor debe ser 'recta' u 'osrm' (es '" + nombre + "')");
    }

    @Override
    public Ruta calcular(PuntoGeo origen, PuntoGeo destino) {
        return elegido.calcular(origen, destino);
    }

    @Override
    public java.util.List<Ruta> alternativas(PuntoGeo origen, PuntoGeo destino) {
        return elegido.alternativas(origen, destino);
    }
}
