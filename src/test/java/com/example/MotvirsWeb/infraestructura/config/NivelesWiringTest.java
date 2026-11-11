package com.example.MotvirsWeb.infraestructura.config;

import org.junit.jupiter.api.Test;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.context.annotation.Configuration;

import org.springframework.data.mongodb.core.MongoTemplate;

import java.time.Clock;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.CatalogoBeneficios;
import com.example.MotvirsWeb.dominio.regla.ModeloTarifa;
import com.example.MotvirsWeb.dominio.regla.ModeloXp;
import com.example.MotvirsWeb.aplicacion.servicio.NivelesScheduler;
import com.example.MotvirsWeb.aplicacion.servicio.NivelesService;
import com.example.MotvirsWeb.dominio.regla.PrioridadRecogida;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.example.MotvirsWeb.dominio.repositorio.XpEventoRepository;

/** Verifica el cableado de Spring (propiedades, Clock, scheduler) sin conectarse a Mongo. */
class NivelesWiringTest {

    @Configuration
    @EnableConfigurationProperties
    static class Habilitar {
    }

    private final ApplicationContextRunner runner = new ApplicationContextRunner()
            .withUserConfiguration(Habilitar.class, NivelesConfig.class, ModeloXp.class, CatalogoBeneficios.class,
                    ModeloNexaProperties.class, ModeloTarifa.class, PrioridadRecogida.class, NivelesService.class, NivelesScheduler.class)
            .withBean(MongoTemplate.class, () -> mock(MongoTemplate.class))
            .withBean(UsuarioRepository.class, () -> mock(UsuarioRepository.class))
            .withBean(ServicioRepository.class, () -> mock(ServicioRepository.class))
            .withBean(XpEventoRepository.class, () -> mock(XpEventoRepository.class))
            .withBean(com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo.class,
                    () -> mock(com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo.class));

    @Test
    void elContextoArrancaYLaConfiguracionSeEnlazaDesdeModeloNexa() {
        runner.run(ctx -> {
            assertNull(ctx.getStartupFailure());
            ModeloNexaProperties cfg = ctx.getBean(ModeloNexaProperties.class);
            assertEquals(0.1, cfg.getMargen().getMinimo());
            assertEquals(5, cfg.getConductor().getNivelMax());
            assertEquals("America/Bogota", ctx.getBean(Clock.class).getZone().getId());
            assertNotNull(ctx.getBean(NivelesScheduler.class));
        });
    }
}
