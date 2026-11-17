package com.example.MotvirsWeb.infraestructura.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.MongoTransactionManager;

@Configuration
public class MongoTransaccionesConfig {
    @Bean
    public MongoTransactionManager transactionManager(org.springframework.data.mongodb.MongoDatabaseFactory fabrica) {
        return new MongoTransactionManager(fabrica);
    }
}
