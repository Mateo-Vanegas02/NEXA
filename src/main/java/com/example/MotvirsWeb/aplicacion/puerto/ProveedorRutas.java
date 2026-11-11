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
}
