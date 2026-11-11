package com.example.MotvirsWeb.dominio.repositorio;

import com.example.MotvirsWeb.dominio.modelo.NotaAdmin;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;

import java.util.List;

public interface NotaAdminRepository extends MongoRepository<NotaAdmin, String> {

    @Query("{ 'titulo': { $regex: ?0, $options: 'i' } }")
    List<NotaAdmin> findByTituloLikeIgnoreCase(String titulo);
}