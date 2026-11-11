package com.example.MotvirsWeb.dominio.repositorio;

import com.example.MotvirsWeb.dominio.modelo.DocumentoConductor;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface DocumentoConductorRepository extends MongoRepository<DocumentoConductor, String> {
    List<DocumentoConductor> findByConductorId(String conductorId);

    void deleteByConductorId(String conductorId);
}
