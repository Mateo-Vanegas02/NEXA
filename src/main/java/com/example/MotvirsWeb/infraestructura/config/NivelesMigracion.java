package com.example.MotvirsWeb.infraestructura.config;

import com.example.MotvirsWeb.dominio.modelo.Rol;
import com.example.MotvirsWeb.dominio.regla.ModeloXp;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.bson.Document;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Date;

/**
 * Migración única al modelo v2.2 (ecuación 29): el sistema anterior guardaba niveles 0–4 y el nuevo empieza
 * en 1, así que cada usuario sube un escalón conservando su posición: {@code nivel' = nivel + 1} y el XP del
 * pasajero pasa a {@code X_{nivel'}}. El conductor se limita a su nivel máximo; su XP de ventana lo recalcula el
 * mantenimiento diario. Un marcador global en la colección {@code migraciones} impide repetirla (guardar un
 * documento con Spring Data descartaría un marcador por usuario).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class NivelesMigracion implements ApplicationRunner {

    static final String ID = "niveles-v2.2";
    private static final String COLECCION_MIGRACIONES = "migraciones";
    private static final String COLECCION_USUARIOS = "Usuarios";

    private final MongoTemplate mongoTemplate;
    private final ModeloXp modeloXp;

    @Override
    public void run(ApplicationArguments args) {
        try {
            migrar();
        } catch (Exception e) {
            // Sin el marcador final se reintenta en el próximo arranque.
            log.error("Falló la migración de niveles v2.2", e);
        }
    }

    /** Devuelve cuántos usuarios migró; 0 si ya estaba hecha. */
    public int migrar() {
        if (mongoTemplate.exists(Query.query(Criteria.where("_id").is(ID)), COLECCION_MIGRACIONES)) {
            return 0;
        }
        int migrados = 0;
        Query query = Query.query(Criteria.where("rol").in(Rol.PASAJERO.name(), Rol.CONDUCTOR.name()));
        query.fields().include("_id").include("rol").include("nivel").include("xpTotal");
        try (var stream = mongoTemplate.stream(query, Document.class, COLECCION_USUARIOS)) {
            for (var it = stream.iterator(); it.hasNext();) {
                Document u = it.next();
                int nivelViejo = u.get("nivel") instanceof Number n ? n.intValue() : 0;
                boolean conductor = Rol.CONDUCTOR.name().equals(u.getString("rol"));
                Update update = new Update().set("nivelActualizadoEn", new Date());
                if (conductor) {
                    update.set("nivel", Math.min(nivelViejo + 1, modeloXp.nivelMaximoConductor()));
                } else {
                    int nuevo = nivelViejo + 1;
                    update.set("nivel", nuevo).set("xpTotal", modeloXp.xpParaNivel(nuevo));
                }
                mongoTemplate.updateFirst(Query.query(Criteria.where("_id").is(u.get("_id"))), update, COLECCION_USUARIOS);
                migrados++;
            }
        }
        try {
            mongoTemplate.insert(new Document("_id", ID).append("fecha", LocalDateTime.now().toString())
                    .append("usuarios", migrados), COLECCION_MIGRACIONES);
        } catch (DuplicateKeyException e) {
            log.warn("Otra instancia ya registró la migración {}", ID);
        }
        log.info("Migración de niveles v2.2: {} usuarios", migrados);
        return migrados;
    }
}
