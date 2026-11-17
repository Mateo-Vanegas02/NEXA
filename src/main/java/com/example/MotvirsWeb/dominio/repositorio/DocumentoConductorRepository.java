package com.example.MotvirsWeb.dominio.repositorio;

import com.example.MotvirsWeb.dominio.modelo.DocumentoConductor;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface DocumentoConductorRepository extends MongoRepository<DocumentoConductor, String> {
    List<DocumentoConductor> findByConductorId(String conductorId);

    void deleteByConductorId(String conductorId);

    /** ¿Otro conductor (distinto de {@code excepto}; null = cualquiera) declaró este número de tarjeta de propiedad? */
    @org.springframework.data.mongodb.repository.Query(value = "{ 'tipo': 'TARJETA_PROPIEDAD', 'numeroDeclarado': ?0, "
            + "'conductorId': { '$ne': ?1 } }", exists = true)
    boolean existeTarjetaDeclaradaPorOtro(String numero, String excepto);
}
