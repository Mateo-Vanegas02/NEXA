package com.example.MotvirsWeb.infraestructura.rutas;

import com.example.MotvirsWeb.aplicacion.puerto.ProveedorRutas;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.regla.Ruta;
import org.springframework.stereotype.Component;

/**
 * Distancia aproximada: línea recta × {@code nexa.rutas.factor-recta} (1,3 por defecto, lo que
 * suelen alargar las calles una línea recta en ciudad). Es la primera implementación; cuando
 * exista la de rutas reales, una configuración elegirá entre ambas con
 * {@code nexa.rutas.proveedor} (no se usa {@code @ConditionalOnProperty} aquí porque la
 * propiedad viene de un {@code @PropertySource} y el orden de carga no está garantizado).
 */
@Component
public class RutaLineaRecta implements ProveedorRutas {

    public static final String FUENTE = "recta";

    private final double factor;

    public RutaLineaRecta(ModeloNexaProperties cfg) {
        this.factor = cfg.getRutas().getFactorRecta();
        if (factor < 1.0) {
            throw new IllegalStateException("nexa.rutas.factor-recta debe ser ≥ 1.0");
        }
    }

    @Override
    public Ruta calcular(PuntoGeo origen, PuntoGeo destino) {
        double recta = origen.distanciaKm(destino);
        return new Ruta(recta * factor, recta, FUENTE);
    }
}
