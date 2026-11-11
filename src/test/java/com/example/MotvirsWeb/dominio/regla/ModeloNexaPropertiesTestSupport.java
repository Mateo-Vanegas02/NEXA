package com.example.MotvirsWeb.dominio.regla;

import org.springframework.boot.context.properties.bind.Binder;
import org.springframework.boot.context.properties.source.ConfigurationPropertySources;
import org.springframework.core.env.PropertiesPropertySource;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.support.EncodedResource;
import org.springframework.core.io.support.PropertiesLoaderUtils;

/** Carga modelo-nexa.properties real para tests unitarios (sin contexto de Spring). */
public final class ModeloNexaPropertiesTestSupport {

    private ModeloNexaPropertiesTestSupport() {
    }

    public static ModeloNexaProperties cargar() {
        try {
            var recurso = new EncodedResource(new ClassPathResource("modelo-nexa.properties"), "UTF-8");
            var props = PropertiesLoaderUtils.loadProperties(recurso);
            var fuente = new PropertiesPropertySource("nexa", props);
            return new Binder(ConfigurationPropertySources.from(fuente))
                    .bind("nexa", ModeloNexaProperties.class).get();
        } catch (java.io.IOException e) {
            throw new IllegalStateException(e);
        }
    }
}
