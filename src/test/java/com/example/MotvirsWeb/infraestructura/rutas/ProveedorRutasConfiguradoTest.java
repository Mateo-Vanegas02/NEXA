package com.example.MotvirsWeb.infraestructura.rutas;

import com.example.MotvirsWeb.aplicacion.puerto.ProveedorRutas;
import com.example.MotvirsWeb.dominio.regla.Ruta;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class ProveedorRutasConfiguradoTest {

    private final ProveedorRutas recta = (a, b) -> new Ruta(1, 1, "recta");
    private final ProveedorRutas osrm = (a, b) -> new Ruta(1, 1, "osrm");

    @Test
    void eligeSegunLaConfiguracion() {
        assertSame(recta, ProveedorRutasConfigurado.elegir("recta", recta, osrm));
        assertSame(osrm, ProveedorRutasConfigurado.elegir("OSRM", recta, osrm));
    }

    @Test
    void unNombreDesconocidoImpideArrancar() {
        assertThrows(IllegalStateException.class, () -> ProveedorRutasConfigurado.elegir("google", recta, osrm));
        assertThrows(IllegalStateException.class, () -> ProveedorRutasConfigurado.elegir(null, recta, osrm));
    }
}
