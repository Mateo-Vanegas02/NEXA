package com.example.MotvirsWeb.integracion;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo;
import com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal;
import com.example.MotvirsWeb.aplicacion.servicio.AuthService;
import com.example.MotvirsWeb.aplicacion.servicio.AvisosPendientesService;
import com.example.MotvirsWeb.aplicacion.servicio.AvisosService;
import com.example.MotvirsWeb.aplicacion.servicio.DeudaService;
import com.example.MotvirsWeb.aplicacion.servicio.PasswordResetService;
import com.example.MotvirsWeb.dominio.modelo.*;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.example.MotvirsWeb.dominio.repositorio.VehiculoRepository;
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
import org.springframework.data.mongodb.MongoTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.data.mongodb.repository.support.MongoRepositoryFactory;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.testcontainers.mongodb.MongoDBContainer;

import java.time.LocalDateTime;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Proxy;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static com.mongodb.client.model.Filters.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.times;

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
    void registroConcurrenteConPrechecksSuperadosTerminaEnConflictoSeguro() throws Exception {
        mongo.getCollection("Usuarios").createIndex(Indexes.ascending("licencia"),
                new IndexOptions().unique(true)
                        .partialFilterExpression(and(eq("rol", "CONDUCTOR"), gt("licencia", 0))));
        CountDownLatch consultas = new CountDownLatch(2);
        UsuarioRepository repoConBarrera = (UsuarioRepository) Proxy.newProxyInstance(
                UsuarioRepository.class.getClassLoader(), new Class<?>[]{UsuarioRepository.class},
                (proxy, metodo, args) -> {
                    try {
                        Object resultado = metodo.invoke(usuarios, args);
                        if (metodo.getName().equals("existsByRolAndLicencia")) {
                            consultas.countDown();
                            assertTrue(consultas.await(10, TimeUnit.SECONDS));
                        }
                        return resultado;
                    } catch (InvocationTargetException e) {
                        throw e.getCause();
                    }
                });
        AuthService registro = new AuthService(repoConBarrera, mock(VehiculoRepository.class),
                new BCryptPasswordEncoder(), mock(UserDetailsService.class), mock(NotificadorTiempoReal.class));
        var pool = Executors.newFixedThreadPool(2);
        CountDownLatch inicio = new CountDownLatch(1);
        try {
            var a = pool.submit(() -> registrarAlArrancar(registro, inicio, "a@example.test"));
            var b = pool.submit(() -> registrarAlArrancar(registro, inicio, "b@example.test"));
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
    void tokenExpiradoYClaveDebilNoCambianLaCuenta() throws Exception {
        String token = "token-expirado-sintetico";
        String hash = java.util.Base64.getUrlEncoder().withoutPadding().encodeToString(
                java.security.MessageDigest.getInstance("SHA-256")
                        .digest(token.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
        Pasajero p = pasajero("expirado@example.test");
        p.setPassword("hash-anterior");
        p.setResetPasswordTokenHash(hash);
        p.setResetPasswordTokenExpiry(LocalDateTime.now().minusMinutes(1));
        usuarios.save(p);
        PasswordResetService reset = new PasswordResetService(usuarios, new BCryptPasswordEncoder(),
                mock(NotificadorCorreo.class), mongo);
        assertThrows(IllegalArgumentException.class, () -> reset.resetPassword(token, "NuevaClave123!"));
        assertThrows(IllegalArgumentException.class, () -> reset.resetPassword(token, "debil"));
        assertThrows(IllegalArgumentException.class,
                () -> reset.resetPassword("token-desconocido", "NuevaClave123!"));
        assertEquals("hash-anterior", usuarios.findById(p.getId().toHexString()).orElseThrow().getPassword());
    }

    @Test
    void claveDebilNoConsumeUnTokenVigente() throws Exception {
        String token = "token-vigente-para-clave-debil";
        String hash = java.util.Base64.getUrlEncoder().withoutPadding().encodeToString(
                java.security.MessageDigest.getInstance("SHA-256")
                        .digest(token.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
        Pasajero p = pasajero("clave-debil@example.test");
        p.setPassword("hash-anterior");
        p.setResetPasswordTokenHash(hash);
        p.setResetPasswordTokenExpiry(LocalDateTime.now().plusMinutes(5));
        usuarios.save(p);
        PasswordResetService reset = new PasswordResetService(usuarios, new BCryptPasswordEncoder(),
                mock(NotificadorCorreo.class), mongo);

        assertThrows(IllegalArgumentException.class, () -> reset.resetPassword(token, "debil"));
        Document despues = mongo.getCollection("Usuarios").find(eq("_id", p.getId())).first();
        assertNotNull(despues);
        assertEquals(hash, despues.getString("usuario_reset_password_token_hash"));
        assertEquals("hash-anterior", despues.getString("password"));
        reset.resetPassword(token, "NuevaClave123!");
        assertTrue(new BCryptPasswordEncoder().matches("NuevaClave123!",
                mongo.getCollection("Usuarios").find(eq("_id", p.getId())).first().getString("password")));
    }

    @Test
    void iniciarYCancelarCompitenSinSobrescribirElEstado() throws Exception {
        Conductor conductor = conductor("carrera@example.test", 110, 210L);
        Servicio viaje = new Servicio();
        viaje.setEstado(EstadoServicio.ACEPTADO);
        viaje.setConductor(new Servicio.ConductorEmbedded(conductor));
        viaje.setFechaLlegada(LocalDateTime.now().minusMinutes(1));
        String id = servicios.save(viaje).getId();
        var pool = Executors.newFixedThreadPool(2);
        CountDownLatch inicio = new CountDownLatch(1);
        try {
            var iniciar = pool.submit(() -> {
                inicio.await();
                return servicios.iniciarSiAceptado(id, conductor.getId(), LocalDateTime.now(), 1);
            });
            var cancelar = pool.submit(() -> {
                inicio.await();
                return servicios.cancelarSiAsignado(id, conductor.getId(), LocalDateTime.now());
            });
            inicio.countDown();
            assertEquals(1, iniciar.get(10, TimeUnit.SECONDS) + cancelar.get(10, TimeUnit.SECONDS));
            assertTrue(java.util.Set.of(EstadoServicio.EN_CURSO, EstadoServicio.CANCELADO)
                    .contains(servicios.findById(id).orElseThrow().getEstado()));
        } finally {
            pool.shutdownNow();
        }
    }

    @Test
    void finalizarYCalificarSoloUnaVezEnMongoReal() throws Exception {
        Conductor conductor = conductor("finalizar@example.test", 111, 211L);
        Pasajero pasajero = pasajero("calificar@example.test");
        Servicio viaje = new Servicio();
        viaje.setEstado(EstadoServicio.EN_CURSO);
        viaje.setConductor(new Servicio.ConductorEmbedded(conductor));
        viaje.setPasajero(new Servicio.PasajeroEmbedded(pasajero.getId(), "sintetico", "calificar@example.test"));
        String id = servicios.save(viaje).getId();
        var pool = Executors.newFixedThreadPool(2);
        CountDownLatch inicio = new CountDownLatch(1);
        try {
            var uno = pool.submit(() -> {
                inicio.await();
                return servicios.finalizarSiEnCurso(id, conductor.getId(), LocalDateTime.now(), false, 1);
            });
            var dos = pool.submit(() -> {
                inicio.await();
                return servicios.finalizarSiEnCurso(id, conductor.getId(), LocalDateTime.now(), false, 1);
            });
            inicio.countDown();
            assertEquals(1, uno.get(10, TimeUnit.SECONDS) + dos.get(10, TimeUnit.SECONDS));
        } finally {
            pool.shutdownNow();
        }
        assertEquals(1, servicios.calificarConductorUnaVez(id, pasajero.getId(), 5.0, "bien", java.util.List.of()));
        assertEquals(0, servicios.calificarConductorUnaVez(id, pasajero.getId(), 2.0, "otro", java.util.List.of()));
        assertEquals(5.0, servicios.findById(id).orElseThrow().getCalificacionConductor());
    }

    @Test
    void llegadaYTransicionesRechazanOtroConductorYEstadosCerrados() {
        Conductor asignado = conductor("asignado@example.test", 113, 213L);
        Conductor ajeno = conductor("ajeno@example.test", 114, 214L);
        Servicio viaje = new Servicio();
        viaje.setEstado(EstadoServicio.ACEPTADO);
        viaje.setConductor(new Servicio.ConductorEmbedded(asignado));
        String id = servicios.save(viaje).getId();
        var ubicacion = new Servicio.Coordenada(4.6, -74.1);

        assertEquals(0, servicios.registrarLlegadaSiAceptado(id, ajeno.getId(), LocalDateTime.now(), ubicacion));
        assertEquals(0, servicios.iniciarSiAceptado(id, ajeno.getId(), LocalDateTime.now(), 0));
        assertEquals(0, servicios.cancelarSiAsignado(id, ajeno.getId(), LocalDateTime.now()));
        assertEquals(1, servicios.registrarLlegadaSiAceptado(id, asignado.getId(), LocalDateTime.now(), ubicacion));
        assertEquals(0, servicios.registrarLlegadaSiAceptado(id, asignado.getId(), LocalDateTime.now(), ubicacion));
        assertEquals(1, servicios.iniciarSiAceptado(id, asignado.getId(), LocalDateTime.now(), 0));
        assertEquals(1, servicios.finalizarSiEnCurso(id, asignado.getId(), LocalDateTime.now(), false, 1));
        assertEquals(0, servicios.finalizarSiEnCurso(id, asignado.getId(), LocalDateTime.now(), false, 1));
        assertEquals(0, servicios.cancelarSiAsignado(id, asignado.getId(), LocalDateTime.now()));
        assertEquals(EstadoServicio.FINALIZADO, servicios.findById(id).orElseThrow().getEstado());
    }

    @Test
    void cancelacionDeudaYAvisoCompartenCommitYElAvisoSeReintenta() {
        Pasajero pasajero = usuarios.save(pasajero("deuda-atomica@example.test"));
        Servicio viaje = new Servicio();
        viaje.setEstado(EstadoServicio.ACEPTADO);
        viaje.setPasajero(new Servicio.PasajeroEmbedded(pasajero.getId(), "sintetico", pasajero.getEmail()));
        String id = servicios.save(viaje).getId();
        DeudaService deudas = new DeudaService(usuarios, servicios, mongo, mock(NotificadorCorreo.class));
        NotificadorTiempoReal socket = mock(NotificadorTiempoReal.class);
        AvisosPendientesService bandeja = new AvisosPendientesService(mongo, servicios, socket,
                mock(AvisosService.class), deudas);
        TransactionTemplate tx = new TransactionTemplate(new MongoTransactionManager(mongo.getMongoDatabaseFactory()));

        assertThrows(IllegalStateException.class, () -> tx.executeWithoutResult(estado -> {
            assertEquals(1, servicios.cancelarSiVigente(id, pasajero.getId(), EstadoServicio.ACEPTADO,
                    LocalDateTime.now(), 4000, false, null));
            assertTrue(deudas.registrar(pasajero.getId(), id, 4000, LocalDateTime.now()));
            bandeja.registrar(id, AvisosPendientesService.Tipo.CANCELADO);
            throw new IllegalStateException("fallo sintético antes del commit");
        }));
        assertEquals(EstadoServicio.ACEPTADO, servicios.findById(id).orElseThrow().getEstado());
        assertTrue(deudas.deudaDe(pasajero.getId()).isEmpty());
        assertEquals(0, mongo.count(new Query(), AvisosPendientesService.Pendiente.class,
                "avisos_viaje_pendientes"));

        tx.executeWithoutResult(estado -> {
            assertEquals(1, servicios.cancelarSiVigente(id, pasajero.getId(), EstadoServicio.ACEPTADO,
                    LocalDateTime.now(), 4000, false, null));
            assertTrue(deudas.registrar(pasajero.getId(), id, 4000, LocalDateTime.now()));
            bandeja.registrar(id, AvisosPendientesService.Tipo.CANCELADO);
        });
        assertEquals(EstadoServicio.CANCELADO, servicios.findById(id).orElseThrow().getEstado());
        assertEquals(4000, deudas.deudaDe(pasajero.getId()).orElseThrow().getMonto());
        String avisoId = id + ":CANCELADO";
        doThrow(new IllegalStateException("socket caído")).doNothing()
                .when(socket).notificarCambioEstadoServicio(org.mockito.ArgumentMatchers.any());
        bandeja.despachar(avisoId);
        assertEquals("PENDIENTE", mongo.findById(avisoId, AvisosPendientesService.Pendiente.class,
                "avisos_viaje_pendientes").estado());
        mongo.updateFirst(Query.query(Criteria.where("_id").is(avisoId)),
                new Update().set("proximoIntento", LocalDateTime.now().minusSeconds(1)),
                "avisos_viaje_pendientes");
        bandeja.despachar(avisoId);
        assertEquals("ENVIADO", mongo.findById(avisoId, AvisosPendientesService.Pendiente.class,
                "avisos_viaje_pendientes").estado());
        verify(socket, times(2)).notificarCambioEstadoServicio(org.mockito.ArgumentMatchers.any());
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

    private static int registrarAlArrancar(AuthService registro, CountDownLatch inicio, String email) {
        try {
            inicio.await();
            registro.registrarConductor("Prueba", email, "Clave123!", "3001234567", 77777, 88888L, 99999L);
            return 1;
        } catch (IllegalStateException e) {
            assertEquals("Ya existe un conductor con esos datos", e.getMessage());
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
