package com.example.MotvirsWeb.infraestructura.socket;

import com.example.MotvirsWeb.infraestructura.seguridad.CustomUserDetailsService;
import com.example.MotvirsWeb.infraestructura.seguridad.JwtService;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;

/**
 * Autentica el CONNECT de STOMP de la app con el mismo JWT de la API (cabecera nativa {@code Authorization: Bearer
 * ...}). La web sigue usando la sesión del navegador; un token inválido, vencido o de un usuario que ya no existe no
 * autentica a nadie (y sin usuario no se puede suscribir a nada).
 */
public class AutenticadorStompJwt {

    private final JwtService jwt;
    private final CustomUserDetailsService usuarios;

    public AutenticadorStompJwt(JwtService jwt, CustomUserDetailsService usuarios) {
        this.jwt = jwt;
        this.usuarios = usuarios;
    }

    /** null si la cabecera falta o el token no es válido. */
    public Authentication autenticar(String cabecera) {
        if (cabecera == null || !cabecera.startsWith("Bearer ")) {
            return null;
        }
        String token = cabecera.substring(7).trim();
        try {
            String email = jwt.extractUsername(token);
            if (email == null) {
                return null;
            }
            String id = jwt.extractUserId(token);
            UserDetails u = id == null ? usuarios.loadUserByUsername(email) : usuarios.loadUserById(id);
            if (!jwt.isTokenValid(token, u)) {
                return null;
            }
            return new UsernamePasswordAuthenticationToken(u, null, u.getAuthorities());
        } catch (RuntimeException e) {
            return null;
        }
    }
}
