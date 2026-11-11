package com.example.MotvirsWeb.dominio.repositorio;

import com.example.MotvirsWeb.dominio.modelo.Rol;
import com.example.MotvirsWeb.dominio.modelo.XpEvento;
import org.bson.types.ObjectId;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface XpEventoRepository extends MongoRepository<XpEvento, String> {

    boolean existsByViajeIdAndRolAndMotivo(String viajeId, Rol rol, String motivo);

    java.util.Optional<XpEvento> findByViajeIdAndRolAndMotivo(String viajeId, Rol rol, String motivo);

    List<XpEvento> findByUsuarioIdAndRolAndCreadoEnBetween(ObjectId usuarioId, Rol rol,
            LocalDateTime desde, LocalDateTime hasta);

    List<XpEvento> findByUsuarioIdAndRolAndCreadoEnAfter(ObjectId usuarioId, Rol rol, LocalDateTime desde);

    List<XpEvento> findByViajeIdAndRol(String viajeId, Rol rol);
}
