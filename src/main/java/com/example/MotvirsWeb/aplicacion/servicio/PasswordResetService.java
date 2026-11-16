package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.Usuario;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;
import java.time.LocalDateTime;
import java.util.Optional;
import com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo;


@Service
@RequiredArgsConstructor
public class PasswordResetService {

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final NotificadorCorreo notificadorCorreo;

    private static final long EXPIRE_TOKEN_AFTER_MINUTES = 30;

    public void initiatePasswordReset(String email) {
        // Buscar primero en los usuarios
        Optional<Usuario> usuarioOpt = usuarioRepository.findByEmail(email);

        if (usuarioOpt.isPresent()) {
            procesarReset(usuarioOpt.get(), "usuario");
            return;
        }

        // Si no es usuario, buscar en conductor
        Optional<Usuario> conductorOpt = usuarioRepository.findByEmail(email); // Asumo que findByEmail busca en ambos o tienes lógica polimórfica

        // NOTA: En tu código original usabas usuarioRepository para ambos.
        // Si conductor está en la misma colección, esto funciona.
        if (conductorOpt.isPresent()) {
            // Si ya lo encontraste arriba, no entrará aquí, pero mantengo tu lógica
            // Si son entidades distintas, asegúrate de que 'conductorOpt' sea correcto.
            procesarReset(conductorOpt.get(), "conductor");
            return;
        }

        throw new RuntimeException("No se encontró ninguna cuenta con ese correo electrónico");
    }

    // Método auxiliar para no repetir código (DRY)
    private void procesarReset(Usuario usuario, String tipo) {
        String token = generateToken();
        usuario.setResetPasswordTokenHash(hashToken(token));
        usuario.setResetPasswordTokenExpiry(LocalDateTime.now().plusMinutes(EXPIRE_TOKEN_AFTER_MINUTES));
        usuarioRepository.save(usuario);

        // CAMBIO 2: Usamos NotificadorCorreo.
        // Él se encarga de buscar la BaseURL correcta (HTTPS) y enviar el correo.
        notificadorCorreo.enviarCorreoRecuperacion(usuario.getEmail(), token);
    }

    public void resetPassword(String token, String newPassword) {
        // Buscar usuario por token
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("Token inválido");
        }

        Optional<Usuario> usuarioOpt = usuarioRepository.findByResetPasswordTokenHash(hashToken(token));

        if (usuarioOpt.isPresent()) {
            actualizarPassword(usuarioOpt.get(), newPassword);
            return;
        }

        throw new RuntimeException("Token inválido o no encontrado");
    }

    private void actualizarPassword(Usuario usuario, String newPassword) {
        if (isTokenExpired(usuario.getResetPasswordTokenExpiry())) {
            throw new RuntimeException("El token ha expirado");
        }

        usuario.setPassword(passwordEncoder.encode(newPassword));
        usuario.setResetPasswordTokenHash(null);
        usuario.setResetPasswordTokenExpiry(null);
        usuarioRepository.save(usuario);
    }

    private String generateToken() {
        byte[] bytes = new byte[32];
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    static String hashToken(String token) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(token.getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 no está disponible", e);
        }
    }

    private boolean isTokenExpired(LocalDateTime tokenExpiry) {
        return tokenExpiry == null || LocalDateTime.now().isAfter(tokenExpiry);
    }

    // CAMBIO 3: Eliminamos el método 'sendResetEmail' privado antiguo.
    // CAMBIO 4: Eliminamos las variables @Value de baseUrl y fromEmail de esta clase.

    @Transactional
    public void changePassword(String email, String currentPassword, String newPassword) {
        Optional<Usuario> usuarioOpt = usuarioRepository.findByEmail(email);

        if (usuarioOpt.isEmpty()) {
            throw new RuntimeException("Usuario no encontrado.");
        }

        Usuario usuario = usuarioOpt.get();

        if (!passwordEncoder.matches(currentPassword, usuario.getPassword())) {
            throw new BadCredentialsException("La contraseña actual es incorrecta.");
        }

        usuario.setPassword(passwordEncoder.encode(newPassword));
        usuarioRepository.save(usuario);
    }
}
