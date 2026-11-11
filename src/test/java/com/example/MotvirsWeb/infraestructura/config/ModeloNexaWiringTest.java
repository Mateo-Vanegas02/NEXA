package com.example.MotvirsWeb.infraestructura.config;

import com.example.MotvirsWeb.aplicacion.puerto.ProveedorRutas;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.ModeloTarifa;
import com.example.MotvirsWeb.dominio.regla.ModeloXp;
import com.example.MotvirsWeb.dominio.regla.ZonaServicio;
import com.example.MotvirsWeb.infraestructura.rutas.ProveedorRutasConfigurado;
import com.example.MotvirsWeb.infraestructura.rutas.RutaLineaRecta;
import com.example.MotvirsWeb.infraestructura.rutas.RutaOsrm;
import org.junit.jupiter.api.Test;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.context.annotation.Configuration;

import static org.junit.jupiter.api.Assertions.*;

/** Verifica que Spring carga modelo-nexa.properties y arma las reglas v2.0 sin Mongo. */
class ModeloNexaWiringTest {

    @Configuration
    @EnableConfigurationProperties
    static class Habilitar {
    }

    private final ApplicationContextRunner runner = new ApplicationContextRunner()
            .withUserConfiguration(Habilitar.class, ModeloNexaProperties.class, ZonaServicio.class,
                    ModeloTarifa.class, ModeloXp.class, RutaLineaRecta.class, RutaOsrm.class,
                    ProveedorRutasConfigurado.class);

    @Test
    void cargaLaConfiguracionYLosBeans() {
        runner.run(ctx -> {
            assertNull(ctx.getStartupFailure());
            ModeloNexaProperties cfg = ctx.getBean(ModeloNexaProperties.class);
            assertEquals(4000, cfg.getTarifa().getMinima());
            assertEquals(5, cfg.getComision().getPorNivel().length);
            assertEquals(12, ctx.getBean(ZonaServicio.class).vertices().size());
            assertEquals(10800, ctx.getBean(ModeloTarifa.class).tarifaBase(6.5));
            assertEquals(270, ctx.getBean(ModeloXp.class).xpParaNivel(2));
            assertInstanceOf(ProveedorRutasConfigurado.class, ctx.getBean(ProveedorRutas.class));
            // Sin llamar a la red: el proveedor configurado es OSRM (con respaldo a línea recta si falla)
            assertEquals("osrm", cfg.getRutas().getProveedor());
        });
    }
}
