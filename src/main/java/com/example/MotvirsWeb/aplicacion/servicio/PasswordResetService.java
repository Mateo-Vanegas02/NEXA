package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.Usuario;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.example.MotvirsWeb.dominio.regla.PoliticaPassword;
import lombok.RequiredArgsConstructor;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
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
    private final MongoTemplate mongoTemplate;

    private static final long EXPIRE_TOKEN_AFTER_MINUTES = 30;

    public void initiatePasswordReset(String email) {
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("No se encontró ninguna cuenta con ese correo electrónico"));
        procesarReset(usuario);
    }

    private void procesarReset(Usuario usuario) {
        String token = generateToken();
        usuario.setResetPasswordTokenHash(hashToken(token));
        usuario.setResetPasswordTokenExpiry(LocalDateTime.now().plusMinutes(EXPIRE_TOKEN_AFTER_MINUTES));
        usuarioRepository.save(usuario);

        notificadorCorreo.enviarCorreoRecuperacion(usuario.getEmail(), token);
    }

    public void resetPassword(String token, String newPassword) {
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("Token inválido");
        }
        validarPassword(newPassword);

        String tokenHash = hashToken(token);
        Usuario usuario = usuarioRepository.findByResetPasswordTokenHash(tokenHash)
                .orElseThrow(() -> new IllegalArgumentException("Token inválido o no encontrado"));
        if (isTokenExpired(usuario.getResetPasswordTokenExpiry())) {
            throw new IllegalArgumentException("El token ha expirado");
        }
        Query query = Query.query(Criteria.where("id").is(usuario.getId())
                .and("resetPasswordTokenHash").is(tokenHash)
                .and("resetPasswordTokenExpiry").gt(LocalDateTime.now()));
        Update update = new Update().set("password", passwordEncoder.encode(newPassword))
                .unset("resetPasswordTokenHash").unset("resetPasswordTokenExpiry");
        if (mongoTemplate.updateFirst(query, update, Usuario.class).getMatchedCount() != 1) {
            throw new IllegalArgumentException("Token inválido o ya utilizado");
        }
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

    @Transactional
    public void changePassword(String email, String currentPassword, String newPassword) {
        validarPassword(newPassword);
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

    private static void validarPassword(String password) {
        if (!PoliticaPassword.esValida(password)) {
            throw new IllegalArgumentException(PoliticaPassword.MENSAJE);
        }
    }
}
