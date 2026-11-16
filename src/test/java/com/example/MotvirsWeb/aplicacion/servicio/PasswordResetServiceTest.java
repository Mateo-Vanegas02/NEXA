package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Usuario;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.lang.reflect.Proxy;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.*;

class PasswordResetServiceTest {
    @Test
    void almacenaSoloElHashYEnviaElTokenOriginal() {
        Usuario usuario = Pasajero.builder().email("persona@example.com").build();
        AtomicReference<Usuario> guardado = new AtomicReference<>();
        AtomicReference<String> tokenEnviado = new AtomicReference<>();
        PasswordResetService service = new PasswordResetService(repository(usuario, guardado, null), encoder(), notifier(tokenEnviado));

        service.initiatePasswordReset("persona@example.com");

        assertSame(usuario, guardado.get());
        assertNotNull(tokenEnviado.get());
        assertNotNull(usuario.getResetPasswordTokenHash());
        assertNotEquals(tokenEnviado.get(), usuario.getResetPasswordTokenHash());
        assertEquals(43, usuario.getResetPasswordTokenHash().length());
        assertEquals(PasswordResetService.hashToken(tokenEnviado.get()), usuario.getResetPasswordTokenHash());
    }

    @Test
    void restableceConElTokenOriginalYLoInvalida() {
        Usuario usuario = Pasajero.builder()
                .resetPasswordTokenHash(PasswordResetService.hashToken("token-valido"))
                .resetPasswordTokenExpiry(LocalDateTime.now().plusMinutes(5)).build();
        AtomicReference<Usuario> guardado = new AtomicReference<>();
        PasswordResetService service = new PasswordResetService(repository(usuario, guardado, usuario), encoder(), notifier(new AtomicReference<>()));

        service.resetPassword("token-valido", "NuevaClave123!");

        assertEquals("encoded:NuevaClave123!", usuario.getPassword());
        assertNull(usuario.getResetPasswordTokenHash());
        assertNull(usuario.getResetPasswordTokenExpiry());
        assertSame(usuario, guardado.get());
    }

    @Test
    void rechazaTokenExpirado() {
        Usuario usuario = Pasajero.builder()
                .resetPasswordTokenHash(PasswordResetService.hashToken("token-expirado"))
                .resetPasswordTokenExpiry(LocalDateTime.now().minusSeconds(1)).build();
        AtomicReference<Usuario> guardado = new AtomicReference<>();
        AtomicInteger saves = new AtomicInteger();
        PasswordResetService service = new PasswordResetService(repository(usuario, guardado, usuario, saves), encoder(), notifier(new AtomicReference<>()));

        assertThrows(RuntimeException.class, () -> service.resetPassword("token-expirado", "NuevaClave123!"));
        assertEquals(0, saves.get());
    }

    private static PasswordEncoder encoder() {
        return new PasswordEncoder() {
            @Override public String encode(CharSequence rawPassword) { return "encoded:" + rawPassword; }
            @Override public boolean matches(CharSequence rawPassword, String encodedPassword) { return encodedPassword.equals(encode(rawPassword)); }
        };
    }

    private static NotificadorCorreo notifier(AtomicReference<String> token) {
        return new NotificadorCorreo() {
            @Override public void enviarCorreoRecuperacion(String email, String value) { token.set(value); }
            @Override public void enviarMensajeContacto(String n, String e, String m) { }
            @Override public void enviarSolicitudInformacion(String e, String n, String m, java.time.LocalDate p) { }
            @Override public void enviarRechazoPorPlazo(String e, String n) { }
            @Override public void enviarAvisoInactividad(String e, String n, int nivel, java.time.LocalDate baja) { }
            @Override public void enviarDeudaCondonada(String e, String n, long monto, String motivo) { }
            @Override public void enviarDeudaSeCobraEnProximoViaje(String e, String n, long monto) { }
        };
    }

    private static UsuarioRepository repository(Usuario byEmail, AtomicReference<Usuario> saved, Usuario byHash) {
        return repository(byEmail, saved, byHash, new AtomicInteger());
    }

    private static UsuarioRepository repository(Usuario byEmail, AtomicReference<Usuario> saved, Usuario byHash, AtomicInteger saves) {
        return (UsuarioRepository) Proxy.newProxyInstance(UsuarioRepository.class.getClassLoader(), new Class<?>[] { UsuarioRepository.class },
                (proxy, method, args) -> {
                    if (method.getName().equals("findByEmail")) return Optional.ofNullable(byEmail);
                    if (method.getName().equals("findByResetPasswordTokenHash")) return Optional.ofNullable(byHash);
                    if (method.getName().equals("save")) { saves.incrementAndGet(); saved.set((Usuario) args[0]); return args[0]; }
                    if (method.getReturnType().equals(boolean.class)) return false;
                    if (method.getReturnType().equals(long.class)) return 0L;
                    if (method.getReturnType().equals(int.class)) return 0;
                    if (Optional.class.isAssignableFrom(method.getReturnType())) return Optional.empty();
                    return null;
                });
    }
}
