package com.example.MotvirsWeb.dominio.repositorio;

import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import com.example.MotvirsWeb.dominio.modelo.Admin;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Rol;
import com.example.MotvirsWeb.dominio.modelo.Usuario;

public interface UsuarioRepository extends MongoRepository <Usuario, String>  {

    boolean existsByEmail(String email);

    Optional<Usuario> findByEmail(String email);

    // Búsquedas por rol (discriminador)
    default Optional<Pasajero> findPasajeroByEmail(String email) {
        return findByEmailAndRol(email, Rol.PASAJERO)
                .map(usuario -> (Pasajero) usuario);
    }

    default Optional<Conductor> findConductorByEmail(String email) {
        return findByEmailAndRol(email, Rol.CONDUCTOR)
                .map(usuario -> (Conductor) usuario);
    }

    default Optional<Admin> findAdminByEmail(String email) {
        return findByEmailAndRol(email, Rol.ADMIN)
                .map(usuario -> (Admin) usuario);
    }

    Optional<Usuario> findByEmailAndRol(String email, Rol rol);

    @Query(value = "{ 'rol': ?0, 'licencia': ?1 }", exists = true)
    boolean existsByRolAndLicencia(Rol rol, long licencia);

    @Query(value = "{ 'rol': ?0, 'soat': ?1 }", exists = true)
    boolean existsByRolAndSoat(Rol rol, Long soat);

    List<Usuario> findByRolAndEstadoValidacion(Rol rol, EstadoValidacion estado);

    //metodos para los graficos panel del admin
    long countByRol (Rol rol);
    long countByRolAndEstadoValidacion (Rol rol, EstadoValidacion estado);

    // Método para conteo de conductores por múltiples estados
    default long countConductoresByEstados(EstadoValidacion... estados) {
        return this.findByRol(Rol.CONDUCTOR)
                .stream()
                .filter(u -> Arrays.asList(estados).contains(u.getEstadoValidacion()))
                .count();
    }

    // Método adicional para obtener conductores por rol
    List<Usuario> findByRol(Rol rol);

    org.springframework.data.domain.Page<Usuario> findByRol(Rol rol, org.springframework.data.domain.Pageable pageable);

    Optional<Usuario> findByResetPasswordTokenHash(String tokenHash);


}
