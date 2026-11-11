package com.example.MotvirsWeb.dominio.repositorio;

import com.example.MotvirsWeb.dominio.modelo.ModeloInfo;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Optional;

public interface ModeloInfoRepository extends MongoRepository <ModeloInfo , String> {

    Optional<ModeloInfo> findFirstByNombreModeloOrderByFechaEntrenamientoDesc(String nombreModelo);

}
