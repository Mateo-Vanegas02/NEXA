package com.example.MotvirsWeb.dominio.repositorio;

import com.example.MotvirsWeb.dominio.modelo.Dispositivo;
import org.bson.types.ObjectId;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface DispositivoRepository extends MongoRepository<Dispositivo, String> {

    Optional<Dispositivo> findByToken(String token);

    List<Dispositivo> findByUsuarioIdOrderByActualizadoEnDesc(ObjectId usuarioId);

    List<Dispositivo> findByUsuarioIdIn(Collection<ObjectId> usuarioIds);

    long deleteByToken(String token);

    long deleteByUsuarioIdAndToken(ObjectId usuarioId, String token);
}
