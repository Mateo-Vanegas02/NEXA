package com.example.MotvirsWeb.dominio.repositorio;

import com.example.MotvirsWeb.dominio.modelo.AuditoriaVerificacion;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface AuditoriaVerificacionRepository extends MongoRepository<AuditoriaVerificacion, String> {
    List<AuditoriaVerificacion> findTop20ByConductorEmailOrderByFechaDesc(String conductorEmail);
}
