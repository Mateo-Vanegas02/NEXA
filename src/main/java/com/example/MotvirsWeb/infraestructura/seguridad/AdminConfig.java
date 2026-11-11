package com.example.MotvirsWeb.infraestructura.seguridad;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.example.MotvirsWeb.dominio.modelo.Admin;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;

@Configuration
public class AdminConfig {

    private static final Logger log = LoggerFactory.getLogger(AdminConfig.class);

    /**
     * Crea el administrador inicial SOLO si se definen ADMIN_EMAIL y ADMIN_PASSWORD
     * (variables de entorno) y todavía no existe una cuenta con ese correo.
     * Ya no existe un admin con credenciales fijas en el código.
     */
    @Bean
    public CommandLineRunner initAdmin(UsuarioRepository usuarioRepository,
                                       PasswordEncoder passwordEncoder) {
        return args -> {
            String email = System.getenv("ADMIN_EMAIL");
            String password = System.getenv("ADMIN_PASSWORD");
            if (email == null || email.isBlank() || password == null || password.isBlank()) {
                log.info("ADMIN_EMAIL/ADMIN_PASSWORD no definidos: no se crea administrador inicial");
                return;
            }
            if (password.length() < 12) {
                log.warn("ADMIN_PASSWORD debe tener al menos 12 caracteres: no se crea el administrador inicial");
                return;
            }
            if (!usuarioRepository.existsByEmail(email.trim())) {
                usuarioRepository.save(new Admin(email.trim(), passwordEncoder.encode(password)));
                log.info("Administrador inicial creado");
            }
        };
    }
}
