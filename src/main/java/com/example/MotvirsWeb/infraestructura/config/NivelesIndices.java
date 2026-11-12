package com.example.MotvirsWeb.infraestructura.config;

import com.example.MotvirsWeb.dominio.modelo.Dispositivo;
import com.example.MotvirsWeb.dominio.modelo.XpEvento;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.index.IndexOperations;
import org.springframework.data.mongodb.core.index.MongoPersistentEntityIndexResolver;
import org.springframework.data.mongodb.core.mapping.MongoMappingContext;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Crea los índices de las colecciones del sistema de niveles (xp_eventos) y de dispositivos (token único por teléfono). Spring Boot no crea índices por sí solo y no se activa
 * auto-index-creation global para no afectar los índices únicos de otras colecciones.
 * El índice único de xp_eventos es lo que garantiza que un viaje nunca dé XP dos veces.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class NivelesIndices {

    private final MongoTemplate mongoTemplate;
    private final MongoMappingContext mappingContext;

    @EventListener(ApplicationReadyEvent.class)
    public void crear() {
        for (Class<?> tipo : List.of(XpEvento.class, Dispositivo.class)) {
            try {
                IndexOperations ops = mongoTemplate.indexOps(tipo);
                new MongoPersistentEntityIndexResolver(mappingContext)
                        .resolveIndexFor(mappingContext.getRequiredPersistentEntity(tipo).getTypeInformation())
                        .forEach(ops::ensureIndex);
            } catch (Exception e) {
                log.error("No se pudieron crear los índices de {}", tipo.getSimpleName(), e);
            }
        }
    }
}
