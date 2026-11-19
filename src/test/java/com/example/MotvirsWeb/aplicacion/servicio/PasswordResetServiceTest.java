package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Usuario;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.mongodb.client.result.UpdateResult;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.Test;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.convert.MappingMongoConverter;
import org.springframework.data.mongodb.core.convert.QueryMapper;
import org.springframework.data.mongodb.core.convert.UpdateMapper;
import org.springframework.data.mongodb.core.mapping.MongoMappingContext;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.lang.reflect.Proxy;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.CountDownLatch;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class PasswordResetServiceTest {
    @Test
    void almacenaSoloElHashYEnviaElTokenOriginal() {
        Usuario usuario = Pasajero.builder().email("persona@example.com").build();
        AtomicReference<Usuario> guardado = new AtomicReference<>();
        AtomicReference<String> tokenEnviado = new AtomicReference<>();
        PasswordResetService service = new PasswordResetService(repository(usuario, guardado, null), encoder(), notifier(tokenEnviado), mock(MongoTemplate.class));

        service.initiatePasswordReset("persona@example.com");

        assertSame(usuario, guardado.get());
        assertNotNull(tokenEnviado.get());
        assertNotNull(usuario.getResetPasswordTokenHash());
        assertNotEquals(tokenEnviado.get(), usuario.getResetPasswordTokenHash());
        assertEquals(43, usuario.getResetPasswordTokenHash().length());
        assertEquals(PasswordResetService.hashToken(tokenEnviado.get()), usuario.getResetPasswordTokenHash());
    }

    @Test
    void consultaElCorreoUnaSolaVezYNoEnviaSiEsAmbiguo() {
        UsuarioRepository repo = mock(UsuarioRepository.class);
        when(repo.findByEmail("compartido@example.com"))
                .thenThrow(new org.springframework.dao.IncorrectResultSizeDataAccessException(1, 2));
        NotificadorCorreo correo = mock(NotificadorCorreo.class);
        PasswordResetService service = new PasswordResetService(repo, encoder(), correo, mock(MongoTemplate.class));
        assertThrows(org.springframework.dao.IncorrectResultSizeDataAccessException.class,
                () -> service.initiatePasswordReset("compartido@example.com"));
        verify(repo, times(1)).findByEmail("compartido@example.com");
        verifyNoInteractions(correo);
    }

    @Test
    void conductorConCorreoUnicoRecibeRecuperacion() {
        Usuario conductor = com.example.MotvirsWeb.dominio.modelo.Conductor.builder()
                .email("conductor@example.com").build();
        AtomicReference<String> enviado = new AtomicReference<>();
        PasswordResetService service = new PasswordResetService(
                repository(conductor, new AtomicReference<>(), null), encoder(), notifier(enviado),
                mock(MongoTemplate.class));
        service.initiatePasswordReset("conductor@example.com");
        assertNotNull(enviado.get());
        assertEquals(PasswordResetService.hashToken(enviado.get()), conductor.getResetPasswordTokenHash());
    }

    @Test
    void restableceConElTokenOriginalYLoInvalida() {
        Usuario usuario = Pasajero.builder()
                .id(new ObjectId())
                .resetPasswordTokenHash(PasswordResetService.hashToken("token-valido"))
                .resetPasswordTokenExpiry(LocalDateTime.now().plusMinutes(5)).build();
        AtomicReference<Usuario> guardado = new AtomicReference<>();
        MongoTemplate mongo = mock(MongoTemplate.class);
        when(mongo.updateFirst(any(Query.class), any(Update.class), eq(Usuario.class)))
                .thenReturn(UpdateResult.acknowledged(1, 1L, null));
        PasswordResetService service = new PasswordResetService(repository(usuario, guardado, usuario), encoder(), notifier(new AtomicReference<>()), mongo);

        service.resetPassword("token-valido", "NuevaClave123!");

        var query = org.mockito.ArgumentCaptor.forClass(Query.class);
        var update = org.mockito.ArgumentCaptor.forClass(Update.class);
        verify(mongo).updateFirst(query.capture(), update.capture(), eq(Usuario.class));
        assertTrue(query.getValue().getQueryObject().containsKey("resetPasswordTokenHash"));
        assertTrue(query.getValue().getQueryObject().containsKey("resetPasswordTokenExpiry"));
        assertEquals("encoded:NuevaClave123!", update.getValue().getUpdateObject().get("$set", org.bson.Document.class).getString("password"));
        assertTrue(update.getValue().getUpdateObject().get("$unset", org.bson.Document.class).containsKey("resetPasswordTokenHash"));
        MongoMappingContext context = new MongoMappingContext();
        context.setSimpleTypeHolder(new org.springframework.data.mapping.model.SimpleTypeHolder(
                java.util.Set.of(LocalDateTime.class),
                org.springframework.data.mongodb.core.mapping.MongoSimpleTypes.HOLDER));
        context.afterPropertiesSet();
        MappingMongoConverter converter = new MappingMongoConverter(
                org.springframework.data.mongodb.core.convert.NoOpDbRefResolver.INSTANCE, context);
        converter.afterPropertiesSet();
        var entity = context.getPersistentEntity(Usuario.class);
        var mappedQuery = new QueryMapper(converter).getMappedObject(query.getValue().getQueryObject(), entity);
        var mappedUpdate = new UpdateMapper(converter).getMappedObject(update.getValue().getUpdateObject(), entity);
        assertTrue(mappedQuery.containsKey("_id"));
        assertTrue(mappedQuery.containsKey("usuario_reset_password_token_hash"));
        assertTrue(mappedQuery.containsKey("usuario_reset_password_token_expiry"));
        assertTrue(mappedUpdate.get("$unset", org.bson.Document.class)
                .containsKey("usuario_reset_password_token_hash"));
        assertNull(guardado.get());
    }

    @Test
    void rechazaTokenExpirado() {
        Usuario usuario = Pasajero.builder()
                .resetPasswordTokenHash(PasswordResetService.hashToken("token-expirado"))
                .resetPasswordTokenExpiry(LocalDateTime.now().minusSeconds(1)).build();
        AtomicReference<Usuario> guardado = new AtomicReference<>();
        AtomicInteger saves = new AtomicInteger();
        MongoTemplate mongo = mock(MongoTemplate.class);
        PasswordResetService service = new PasswordResetService(repository(usuario, guardado, usuario, saves), encoder(), notifier(new AtomicReference<>()), mongo);

        assertThrows(RuntimeException.class, () -> service.resetPassword("token-expirado", "NuevaClave123!"));
        assertEquals(0, saves.get());
        verifyNoInteractions(mongo);
    }

    @Test
    void soloUnIntentoPuedeConsumirElToken() throws Exception {
        Usuario usuario = Pasajero.builder().id(new ObjectId())
                .resetPasswordTokenHash(PasswordResetService.hashToken("token-compartido"))
                .resetPasswordTokenExpiry(LocalDateTime.now().plusMinutes(5)).build();
        MongoTemplate mongo = mock(MongoTemplate.class);
        AtomicInteger matches = new AtomicInteger();
        when(mongo.updateFirst(any(Query.class), any(Update.class), eq(Usuario.class)))
                .thenAnswer(i -> UpdateResult.acknowledged(matches.getAndIncrement() == 0 ? 1 : 0, 0L, null));
        PasswordResetService service = new PasswordResetService(repository(null, new AtomicReference<>(), usuario),
                encoder(), notifier(new AtomicReference<>()), mongo);
        var pool = Executors.newFixedThreadPool(2);
        CountDownLatch start = new CountDownLatch(1);
        try {
            var a = pool.submit(() -> consumir(service, start));
            var b = pool.submit(() -> consumir(service, start));
            start.countDown();
            assertEquals(1, (a.get(5, TimeUnit.SECONDS) ? 1 : 0) + (b.get(5, TimeUnit.SECONDS) ? 1 : 0));
            verify(mongo, times(2)).updateFirst(any(Query.class), any(Update.class), eq(Usuario.class));
        } finally {
            pool.shutdownNow();
        }
    }

    @Test
    void rechazaPasswordDebilAntesDeActualizar() {
        MongoTemplate mongo = mock(MongoTemplate.class);
        PasswordResetService service = new PasswordResetService(repository(null, new AtomicReference<>(), null),
                encoder(), notifier(new AtomicReference<>()), mongo);
        assertThrows(IllegalArgumentException.class, () -> service.resetPassword("token", "debil"));
        verifyNoInteractions(mongo);
    }

    @Test
    void tokenInexistenteNoModificaPassword() {
        MongoTemplate mongo = mock(MongoTemplate.class);
        PasswordResetService service = new PasswordResetService(repository(null, new AtomicReference<>(), null),
                encoder(), notifier(new AtomicReference<>()), mongo);
        assertThrows(IllegalArgumentException.class, () -> service.resetPassword("inexistente", "NuevaClave123!"));
        verifyNoInteractions(mongo);
    }

    @Test
    void errorDeMongoNoSePresentaComoConsumoCorrecto() {
        Usuario usuario = Pasajero.builder().id(new ObjectId())
                .resetPasswordTokenHash(PasswordResetService.hashToken("token"))
                .resetPasswordTokenExpiry(LocalDateTime.now().plusMinutes(5)).build();
        MongoTemplate mongo = mock(MongoTemplate.class);
        when(mongo.updateFirst(any(Query.class), any(Update.class), eq(Usuario.class)))
                .thenThrow(new org.springframework.dao.DataAccessResourceFailureException("base no disponible"));
        PasswordResetService service = new PasswordResetService(repository(null, new AtomicReference<>(), usuario),
                encoder(), notifier(new AtomicReference<>()), mongo);
        assertThrows(org.springframework.dao.DataAccessResourceFailureException.class,
                () -> service.resetPassword("token", "NuevaClave123!"));
    }

    @Test
    void correoCompartidoNoCambiaLaPasswordDeOtraCuenta() {
        UsuarioRepository repo = mock(UsuarioRepository.class);
        when(repo.findByEmail("compartido@example.com"))
                .thenThrow(new org.springframework.dao.IncorrectResultSizeDataAccessException(1, 2));
        PasswordResetService service = new PasswordResetService(repo, encoder(), mock(NotificadorCorreo.class),
                mock(MongoTemplate.class));
        assertThrows(org.springframework.dao.IncorrectResultSizeDataAccessException.class,
                () -> service.changePassword("compartido@example.com", "Actual123", "NuevaClave123!"));
        verify(repo, never()).save(any());
    }

    private static boolean consumir(PasswordResetService service, CountDownLatch start) {
        try {
            start.await();
            service.resetPassword("token-compartido", "NuevaClave123!");
            return true;
        } catch (IllegalArgumentException e) {
            return false;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return false;
        }
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
