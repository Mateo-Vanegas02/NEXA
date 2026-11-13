package com.example.MotvirsWeb.dominio.repositorio;

import com.example.MotvirsWeb.dominio.modelo.AccionIdempotente;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface AccionIdempotenteRepository extends MongoRepository<AccionIdempotente, String> {
}
