package com.example.MotvirsWeb.dominio.repositorio;

import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.Vehiculo;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;
import java.util.Optional;

public interface VehiculoRepository extends MongoRepository<Vehiculo, String> {
    Optional<Vehiculo> findByPlaca(String placa);
    List<Vehiculo> findByConductorAsignado(Conductor conductor);
    List<Vehiculo> findByActivo(boolean activo);
}