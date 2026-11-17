package com.example.MotvirsWeb.infraestructura.seguridad;

import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.dominio.modelo.Usuario;
import com.example.MotvirsWeb.dominio.modelo.Rol;
import com.example.MotvirsWeb.dominio.regla.Correo;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.dao.IncorrectResultSizeDataAccessException;

import java.util.Collections;

@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UsuarioRepository usuarioRepository;

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        Usuario usuario;
        try {
            int separador = email == null ? -1 : email.lastIndexOf('|');
            String correo = Correo.normalizar(separador < 0 ? email : email.substring(0, separador));
            Rol rol = separador < 0 ? null : Rol.valueOf(email.substring(separador + 1));
            usuario = (rol == null ? usuarioRepository.findByEmail(correo)
                    : usuarioRepository.findByEmailAndRol(correo, rol))
                    .orElseThrow(() -> new UsernameNotFoundException("Credenciales inválidas"));
        } catch (IncorrectResultSizeDataAccessException | IllegalArgumentException e) {
            throw new UsernameNotFoundException("Credenciales inválidas", e);
        }

        return detalles(usuario);
    }

    /** Para JWT: resuelve la cuenta exacta; un correo compartido no cambia la identidad. */
    public UserDetails loadUserById(String id) {
        return detalles(usuarioRepository.findById(id)
                .orElseThrow(() -> new UsernameNotFoundException("Credenciales inválidas")));
    }

    private UserDetails detalles(Usuario usuario) {
        if (usuario instanceof Conductor conductor &&
                conductor.getEstadoValidacion() != EstadoValidacion.APROBADO) {
            throw new DisabledException("Cuenta de conductor no aprobada");
        }

        // Devuelve CustomUserDetails con el id del usuario
        return new CustomUserDetails(
                usuario.getIdString(),
                usuario.getEmail(),
                usuario.getPassword(),
                Collections.singletonList(new SimpleGrantedAuthority(usuario.getRol().getAuthority())), // Ajusta según tu método getRol()
                usuario.getEstadoValidacion() == EstadoValidacion.APROBADO
        );
    }
}
