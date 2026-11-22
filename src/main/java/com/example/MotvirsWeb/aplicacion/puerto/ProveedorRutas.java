package com.example.MotvirsWeb.aplicacion.puerto;

import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.regla.Ruta;

/**
 * Puerto de salida: distancia de un viaje entre dos puntos. Hoy la implementa la línea
 * recta por un factor (infraestructura.rutas.RutaLineaRecta); después, un servicio de rutas
 * reales, sin cambiar a quien lo usa.
 */
public interface ProveedorRutas {

    Ruta calcular(PuntoGeo origen, PuntoGeo destino);

    /**
     * Hasta tres rutas distintas entre dos puntos, la principal primero. Sirve para recalcular la ruta en vivo cuando
     * el conductor toma otra calle; un proveedor sin alternativas devuelve solo la principal.
     */
    default java.util.List<Ruta> alternativas(PuntoGeo origen, PuntoGeo destino) {
        return java.util.List.of(calcular(origen, destino));
    }
}
