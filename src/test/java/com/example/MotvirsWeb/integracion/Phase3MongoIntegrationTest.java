package com.example.MotvirsWeb.integracion;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo;
import com.example.MotvirsWeb.aplicacion.servicio.PasswordResetService;
import com.example.MotvirsWeb.dominio.modelo.*;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.example.MotvirsWeb.infraestructura.seguridad.CustomUserDetailsService;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.model.IndexOptions;
import com.mongodb.client.model.Indexes;
import org.bson.Document;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.dao.IncorrectResultSizeDataAccessException;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.repository.support.MongoRepositoryFactory;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.testcontainers.mongodb.MongoDBContainer;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static com.mongodb.client.model.Filters.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;

/** Solo usa el URI de su propio contenedor y una base sintética nueva por prueba. */
@Tag("requiere-mongo")
class Phase3MongoIntegrationTest {
    private static final MongoDBContainer MONGO = new MongoDBContainer("mongo:7");
    private static MongoClient cliente;

    private String base;
    private MongoTemplate mongo;
    private UsuarioRepository usuarios;
    private ServicioRepository servicios;

    @BeforeAll
    static void iniciarMongoAislado() {
        MONGO.start();
        cliente = MongoClients.create(MONGO.getConnectionString());
        assertTrue(MONGO.isRunning(), "MongoDB de pruebas debe ser un contenedor propio");
    }

    @AfterAll
    static void cerrarMongoAislado() {
        if (cliente != null) cliente.close();
        MONGO.stop();
    }

    @BeforeEach
    void prepararBaseSintetica() {
        base = "nexa_phase3_" + UUID.randomUUID().toString().replace("-", "");
        mongo = new MongoTemplate(cliente, base);
        MongoRepositoryFactory factory = new MongoRepositoryFactory(mongo);
        usuarios = factory.getRepository(UsuarioRepository.class);
        servicios = factory.getRepository(ServicioRepository.class);
    }

    @AfterEach
    void borrarSoloLaBaseCreadaPorEstaPrueba() {
        assertTrue(base.matches("nexa_phase3_[0-9a-f]{32}"));
        cliente.getDatabase(base).drop();
    }

    @Test
    void correoDuplicadoEntreRolesFallaCerradoYSeCuentaEnColeccionReal() {
        String correo = "compartido@example.test";
        usuarios.save(pasajero(correo));
        usuarios.save(conductor(correo, 10001, 20001L));
        assertEquals(2, mongo.getCollection("Usuarios").countDocuments(eq("email", correo)));
        assertThrows(IncorrectResultSizeDataAccessException.class, () -> usuarios.findByEmail(correo));
        assertThrows(UsernameNotFoundException.class,
                () -> new CustomUserDetailsService(usuarios).loadUserByUsername(correo));
        assertEquals(1, usuarios.countByRol(Rol.PASAJERO));
        assertEquals(1, usuarios.countConductoresByEstados(EstadoValidacion.PENDIENTE));
    }

    @Test
    void indicesParcialesProtegenLicenciaYSoatSinBloquearPasajeros() {
        var coleccion = mongo.getCollection("Usuarios");
        coleccion.createIndex(Indexes.ascending("licencia"), new IndexOptions().unique(true)
                .partialFilterExpression(and(eq("rol", "CONDUCTOR"), gt("licencia", 0))));
        coleccion.createIndex(Indexes.ascending("soat"), new IndexOptions().unique(true)
                .partialFilterExpression(and(eq("rol", "CONDUCTOR"), gt("soat", 0))));
        usuarios.save(pasajero("p1@example.test"));
        usuarios.save(pasajero("p2@example.test"));
        usuarios.save(conductor("c1@example.test", 10101, 20101L));
        assertTrue(usuarios.existsByRolAndLicencia(Rol.CONDUCTOR, 10101));
        assertTrue(usuarios.existsByRolAndSoat(Rol.CONDUCTOR, 20101L));
        assertThrows(DuplicateKeyException.class,
                () -> usuarios.save(conductor("c2@example.test", 10101, 20202L)));
        assertThrows(DuplicateKeyException.class,
                () -> usuarios.save(conductor("c3@example.test", 10303, 20101L)));
        usuarios.save(conductor("c4@example.test", 10404, 20404L));
        assertEquals(2, usuarios.countByRol(Rol.CONDUCTOR));
    }

    @Test
    void indiceUnicoResisteDosInsercionesSimultaneas() throws Exception {
        mongo.getCollection("Usuarios").createIndex(Indexes.ascending("licencia"),
                new IndexOptions().unique(true)
                        .partialFilterExpression(and(eq("rol", "CONDUCTOR"), gt("licencia", 0))));
        var pool = Executors.newFixedThreadPool(2);
        CountDownLatch inicio = new CountDownLatch(1);
        try {
            var a = pool.submit(() -> guardarConductorAlArrancar(inicio, "a@example.test"));
            var b = pool.submit(() -> guardarConductorAlArrancar(inicio, "b@example.test"));
            inicio.countDown();
            assertEquals(1, a.get(10, TimeUnit.SECONDS) + b.get(10, TimeUnit.SECONDS));
            assertEquals(1, usuarios.countByRol(Rol.CONDUCTOR));
        } finally {
            pool.shutdownNow();
        }
    }

    @Test
    void tokenSeConsumeUnaVezConCamposMongoReales() throws Exception {
        String token = "token-sintetico-fase3";
        String hash = java.util.Base64.getUrlEncoder().withoutPadding().encodeToString(
                java.security.MessageDigest.getInstance("SHA-256")
                        .digest(token.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
        Pasajero p = pasajero("reset@example.test");
        p.setPassword("hash-anterior");
        p.setResetPasswordTokenHash(hash);
        p.setResetPasswordTokenExpiry(LocalDateTime.now().plusMinutes(5));
        usuarios.save(p);
        Document antes = mongo.getCollection("Usuarios").find(eq("_id", p.getId())).first();
        assertNotNull(antes);
        assertEquals(hash, antes.getString("usuario_reset_password_token_hash"));
        assertNotNull(antes.getDate("usuario_reset_password_token_expiry"));
        assertFalse(antes.containsKey("resetPasswordToken"));

        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        PasswordResetService reset = new PasswordResetService(usuarios, encoder,
                mock(NotificadorCorreo.class), mongo);
        var pool = Executors.newFixedThreadPool(2);
        CountDownLatch inicio = new CountDownLatch(1);
        AtomicInteger exitos = new AtomicInteger();
        try {
            var a = pool.submit(() -> consumirAlArrancar(reset, token, inicio, exitos));
            var b = pool.submit(() -> consumirAlArrancar(reset, token, inicio, exitos));
            inicio.countDown();
            a.get(10, TimeUnit.SECONDS);
            b.get(10, TimeUnit.SECONDS);
            assertEquals(1, exitos.get());
        } finally {
            pool.shutdownNow();
        }
        Document despues = mongo.getCollection("Usuarios").find(eq("_id", p.getId())).first();
        assertNotNull(despues);
        assertFalse(despues.containsKey("usuario_reset_password_token_hash"));
        assertFalse(despues.containsKey("usuario_reset_password_token_expiry"));
        assertTrue(encoder.matches("NuevaClave123!", despues.getString("password")));
        assertThrows(IllegalArgumentException.class, () -> reset.resetPassword(token, "OtraClave123!"));
    }

    @Test
    void tokenExpiradoYClaveDebilNoCambianLaCuenta() {
        Pasajero p = pasajero("expirado@example.test");
        p.setPassword("hash-anterior");
        p.setResetPasswordTokenHash("hash-sintetico");
        p.setResetPasswordTokenExpiry(LocalDateTime.now().minusMinutes(1));
        usuarios.save(p);
        PasswordResetService reset = new PasswordResetService(usuarios, new BCryptPasswordEncoder(),
                mock(NotificadorCorreo.class), mongo);
        assertThrows(IllegalArgumentException.class, () -> reset.resetPassword("token-desconocido", "NuevaClave123!"));
        assertThrows(IllegalArgumentException.class, () -> reset.resetPassword("token-desconocido", "debil"));
        assertEquals("hash-anterior", usuarios.findById(p.getId().toHexString()).orElseThrow().getPassword());
    }

    @Test
    void aceptarYVencerSonTransicionesCondicionales() throws Exception {
        Servicio viaje = new Servicio();
        viaje.setEstado(EstadoServicio.SOLICITADO);
        viaje = servicios.save(viaje);
        String id = viaje.getId();
        Conductor a = conductor("a@example.test", 111, 211L);
        Conductor b = conductor("b@example.test", 112, 212L);
        var pool = Executors.newFixedThreadPool(2);
        CountDownLatch inicio = new CountDownLatch(1);
        try {
            var uno = pool.submit(() -> aceptarAlArrancar(id, new Servicio.ConductorEmbedded(a), inicio));
            var dos = pool.submit(() -> aceptarAlArrancar(id, new Servicio.ConductorEmbedded(b), inicio));
            inicio.countDown();
            assertEquals(1, uno.get(10, TimeUnit.SECONDS) + dos.get(10, TimeUnit.SECONDS));
            assertEquals(0, servicios.vencerSiSigueSolicitado(id, LocalDateTime.now()));
            assertEquals(EstadoServicio.ACEPTADO, servicios.findById(id).orElseThrow().getEstado());
        } finally {
            pool.shutdownNow();
        }
        Servicio otro = new Servicio();
        otro.setEstado(EstadoServicio.SOLICITADO);
        otro = servicios.save(otro);
        assertEquals(1, servicios.vencerSiSigueSolicitado(otro.getId(), LocalDateTime.now()));
        assertEquals(EstadoServicio.CANCELADO, servicios.findById(otro.getId()).orElseThrow().getEstado());
    }

    private int guardarConductorAlArrancar(CountDownLatch inicio, String email) {
        try {
            inicio.await();
            usuarios.save(conductor(email, 77777, 88888L));
            return 1;
        } catch (DuplicateKeyException e) {
            return 0;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return 0;
        }
    }

    private static void consumirAlArrancar(PasswordResetService reset, String token,
            CountDownLatch inicio, AtomicInteger exitos) {
        try {
            inicio.await();
            reset.resetPassword(token, "NuevaClave123!");
            exitos.incrementAndGet();
        } catch (IllegalArgumentException ignored) {
            // La otra petición consumió el token.
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private long aceptarAlArrancar(String id, Servicio.ConductorEmbedded conductor, CountDownLatch inicio) {
        try {
            inicio.await();
            return servicios.tomarSiDisponible(id, conductor, LocalDateTime.now());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return 0;
        }
    }

    private static Pasajero pasajero(String email) {
        return Pasajero.builder().id(new ObjectId()).email(email).rol(Rol.PASAJERO)
                .estadoValidacion(EstadoValidacion.APROBADO).build();
    }

    private static Conductor conductor(String email, long licencia, Long soat) {
        return Conductor.builder().id(new ObjectId()).email(email).rol(Rol.CONDUCTOR)
                .estadoValidacion(EstadoValidacion.PENDIENTE).licencia(licencia).soat(soat).build();
    }
}
