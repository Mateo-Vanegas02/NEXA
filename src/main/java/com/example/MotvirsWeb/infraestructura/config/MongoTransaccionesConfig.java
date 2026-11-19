package com.example.MotvirsWeb.infraestructura.config;

import com.example.MotvirsWeb.aplicacion.servicio.EjecutorTransacciones;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.MongoDatabaseFactory;
import org.springframework.data.mongodb.MongoTransactionManager;

/**
 * Transacciones MongoDB (exigen replica set: Atlas, o el Mongo local de docker-compose en rs0). Los casos de uso
 * del viaje y de la deuda las abren con {@link EjecutorTransacciones}, que reintenta los conflictos transitorios.
 */
@Configuration
public class MongoTransaccionesConfig {
    @Bean
    public MongoTransactionManager transactionManager(MongoDatabaseFactory fabrica) {
        return new MongoTransactionManager(fabrica);
    }

    @Bean
    public EjecutorTransacciones ejecutorTransacciones(MongoTransactionManager transactionManager) {
        return new EjecutorTransacciones(transactionManager);
    }
}
