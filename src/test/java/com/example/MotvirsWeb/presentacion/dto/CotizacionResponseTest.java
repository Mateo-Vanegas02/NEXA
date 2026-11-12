package com.example.MotvirsWeb.presentacion.dto;

import com.example.MotvirsWeb.aplicacion.servicio.CotizacionService.Cotizacion;
import com.example.MotvirsWeb.dominio.regla.ModeloTarifa.Cobro;
import com.example.MotvirsWeb.dominio.regla.Ruta;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

/** La app dibuja la ruta por calles con el trazado de la cotización. */
class CotizacionResponseTest {

    private static final Cobro COBRO = new Cobro(4.2, 7000, 1, 7000, 1, 0, 0, 7000, 0.2, 5600, 1400, 0);

    @Test
    void entregaElTrazadoYLaDuracionDeLaRuta() {
        Ruta ruta = new Ruta(4.2, 3.1, "osrm", 11.26, "_p~iF~ps|U_ulLnnqC");

        CotizacionResponse r = CotizacionResponse.de(new Cotizacion(ruta, COBRO), 500);

        assertEquals("_p~iF~ps|U_ulLnnqC", r.rutaGeometria());
        assertEquals(11.3, r.duracionMin());
        assertEquals(7500, r.totalAPagar());
    }

    @Test
    void enLineaRectaNoHayTrazado() {
        CotizacionResponse r = CotizacionResponse.de(new Cotizacion(new Ruta(4.0, 3.1, "recta"), COBRO));

        assertNull(r.rutaGeometria());
    }
}
