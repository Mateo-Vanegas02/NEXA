package com.example.MotvirsWeb.infraestructura.seguridad;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.test.context.junit.jupiter.web.SpringJUnitWebConfig;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;

import com.example.MotvirsWeb.presentacion.api.ApiAdminController;
import com.example.MotvirsWeb.presentacion.api.ApiAuthController;
import com.example.MotvirsWeb.presentacion.api.ApiConductorController;
import com.example.MotvirsWeb.presentacion.api.ApiNivelesController;
import com.example.MotvirsWeb.presentacion.api.ApiPasajeroController;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.aplicacion.servicio.AdminService;
import com.example.MotvirsWeb.aplicacion.servicio.DashboardService;
import com.example.MotvirsWeb.aplicacion.servicio.NivelesService;
import com.example.MotvirsWeb.aplicacion.servicio.NotaAdminService;
import com.example.MotvirsWeb.aplicacion.servicio.OptimizerService;
import com.example.MotvirsWeb.aplicacion.servicio.ServicioService;
import com.example.MotvirsWeb.aplicacion.util.UsuarioContextHelper;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Seguridad HTTP con la cadena de filtros real (SecurityConfig + SecurityConstants),
 * sin Mongo ni contexto completo: controladores reales con servicios simulados.
 */
@SpringJUnitWebConfig(SeguridadHttpTest.Config.class)
@org.springframework.test.context.TestPropertySource(properties = { "jwt.secret=dGVzdA==", "jwt.expiration=1000" })
class SeguridadHttpTest {

    @Configuration
    @EnableWebMvc
    @Import({ SecurityConfig.class, SecurityExceptionHandler.class, JwtAuthFilter.class })
    static class Config {
        @Bean
        static org.springframework.context.support.PropertySourcesPlaceholderConfigurer placeholders() {
            return new org.springframework.context.support.PropertySourcesPlaceholderConfigurer();
        }

        @Bean
        RateLimitFilter rateLimitFilter() {
            return new RateLimitFilter(true);
        }

        @Bean
        BloqueoCierreSesionFilter bloqueoCierreSesionFilter() {
            return new BloqueoCierreSesionFilter(mock(com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository.class),
                    mock(com.example.MotvirsWeb.dominio.repositorio.ServicioRepository.class));
        }

        @Bean
        org.springframework.security.web.authentication.AuthenticationFailureHandler failureHandler() {
            return mock(org.springframework.security.web.authentication.AuthenticationFailureHandler.class);
        }

        @Bean
        AuthenticationSuccessHandler successHandler() {
            return mock(AuthenticationSuccessHandler.class);
        }

        @Bean
        CustomUserDetailsService customUserDetailsService() {
            return mock(CustomUserDetailsService.class);
        }

        @Bean
        JwtService jwtService() {
            return mock(JwtService.class);
        }

        @Bean
        AuthenticationManager authenticationManager(AuthenticationConfiguration cfg) throws Exception {
            return cfg.getAuthenticationManager();
        }

        @Bean
        ServicioService servicioService() {
            return mock(ServicioService.class);
        }

        @Bean
        UsuarioContextHelper usuarioContextHelper() {
            return mock(UsuarioContextHelper.class);
        }

        @Bean
        OptimizerService optimizerService() {
            return mock(OptimizerService.class);
        }

        @Bean
        NivelesService nivelesService() {
            return mock(NivelesService.class);
        }

        @Bean
        AdminService adminService() {
            return mock(AdminService.class);
        }

        @Bean
        DashboardService dashboardService() {
            return mock(DashboardService.class);
        }

        @Bean
        NotaAdminService notaAdminService() {
            return mock(NotaAdminService.class);
        }

        @Bean
        com.example.MotvirsWeb.aplicacion.verificacion.VerificacionConductorService verificacionConductorService() {
            return mock(com.example.MotvirsWeb.aplicacion.verificacion.VerificacionConductorService.class);
        }

        @Bean
        ApiPasajeroController apiPasajeroController(ServicioService s, UsuarioContextHelper u) {
            return new ApiPasajeroController(s, mock(com.example.MotvirsWeb.aplicacion.servicio.CotizacionService.class),
                    mock(com.example.MotvirsWeb.aplicacion.servicio.DeudaService.class), u,
                    mock(com.example.MotvirsWeb.aplicacion.servicio.SeguimientoPasajeroService.class),
                    mock(com.example.MotvirsWeb.aplicacion.servicio.ViajeEnVivoService.class),
                    mock(com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties.class));
        }

        @Bean
        ApiConductorController apiConductorController(ServicioService s, OptimizerService o, UsuarioContextHelper u) {
            return new ApiConductorController(s, o, u,
                    mock(com.example.MotvirsWeb.aplicacion.servicio.SeguimientoPasajeroService.class),
                    mock(com.example.MotvirsWeb.aplicacion.servicio.UbicacionConductorService.class),
                    mock(com.example.MotvirsWeb.aplicacion.puerto.CanalPeticion.class),
                    mock(com.example.MotvirsWeb.aplicacion.servicio.ViajeEnVivoService.class),
                    mock(com.example.MotvirsWeb.aplicacion.servicio.SaldoConductorService.class),
                    mock(com.example.MotvirsWeb.aplicacion.servicio.IdempotenciaService.class),
                    mock(com.example.MotvirsWeb.aplicacion.servicio.UbicacionLoteService.class),
                    mock(com.example.MotvirsWeb.aplicacion.servicio.NivelesService.class));
        }

        @Bean
        com.example.MotvirsWeb.presentacion.api.ApiDispositivosController apiDispositivosController(UsuarioContextHelper u) {
            return new com.example.MotvirsWeb.presentacion.api.ApiDispositivosController(
                    mock(com.example.MotvirsWeb.aplicacion.servicio.DispositivosService.class), u);
        }

        @Bean
        ApiNivelesController apiNivelesController(NivelesService n, UsuarioContextHelper u) {
            return new ApiNivelesController(n, u);
        }

        @Bean
        ApiAdminController apiAdminController(AdminService a, DashboardService d, NotaAdminService n,
                com.example.MotvirsWeb.aplicacion.verificacion.VerificacionConductorService v) {
            return new ApiAdminController(a, d, n, v, mock(com.example.MotvirsWeb.aplicacion.servicio.DeudaService.class),
                    mock(com.example.MotvirsWeb.aplicacion.servicio.MetricasDespachoService.class),
                    mock(com.example.MotvirsWeb.aplicacion.servicio.SaldoConductorService.class));
        }

        @Bean
        ApiAuthController apiAuthController(AuthenticationManager am, JwtService j) {
            return new ApiAuthController(am, j, mock(LoginFailureHandler.class));
        }

        @Bean
        com.example.MotvirsWeb.presentacion.api.ApiRegistroController apiRegistroController() {
            return new com.example.MotvirsWeb.presentacion.api.ApiRegistroController(
                    mock(com.example.MotvirsWeb.aplicacion.servicio.AuthService.class),
                    mock(com.example.MotvirsWeb.aplicacion.servicio.RegistroConductorService.class));
        }
    }

    @Autowired
    private WebApplicationContext ctx;

    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        // El limitador es un bean singleton: reconstruimos MockMvc con la cadena real
        mvc = MockMvcBuilders.webAppContextSetup(ctx).apply(springSecurity()).build();
    }

    // ── 401: sin autenticación ──────────────────────────────────────────

    @Test
    void apiProtegidaSinTokenDevuelve401() throws Exception {
        for (String ruta : new String[] { "/api/pasajero/perfil", "/api/conductor/perfil", "/api/admin/notas",
                "/api/niveles/me", "/api/user-id" }) {
            mvc.perform(get(ruta)).andExpect(status().isUnauthorized());
        }
    }

    @Test
    void tokenJwtBasuraDevuelve401() throws Exception {
        mvc.perform(get("/api/pasajero/perfil").header("Authorization", "Bearer no.es.un.jwt"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void elTokenDelTelefonoSeRegistraConSesionDeCualquierRolYValidaLaEntrada() throws Exception {
        String cuerpo = "{\"token\":\"fcm-123\",\"plataforma\":\"ANDROID\"}";
        mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put("/api/dispositivos")
                .with(csrf()).contentType(MediaType.APPLICATION_JSON).content(cuerpo)).andExpect(status().isUnauthorized());
        for (String rol : new String[] { "PASAJERO", "CONDUCTOR", "ADMIN" }) {
            mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put("/api/dispositivos")
                    .with(user("u@x.com").roles(rol)).with(csrf())
                    .contentType(MediaType.APPLICATION_JSON).content(cuerpo)).andExpect(status().isNoContent());
        }
        mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put("/api/dispositivos")
                .with(user("u@x.com").roles("PASAJERO")).with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content("{\"token\":\"\",\"plataforma\":\"WINDOWS\"}"))
                .andExpect(status().isBadRequest());
    }

    // ── 403: rol incorrecto ─────────────────────────────────────────────

    @Test
    void pasajeroNoAccedeAZonaConductorNiAdmin() throws Exception {
        mvc.perform(get("/api/conductor/perfil").with(user("p@x.com").roles("PASAJERO")))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/admin/notas").with(user("p@x.com").roles("PASAJERO")))
                .andExpect(status().isForbidden());
    }

    @Test
    void conductorNoAccedeAZonaPasajeroNiAdmin() throws Exception {
        mvc.perform(get("/api/pasajero/historial").with(user("c@x.com").roles("CONDUCTOR")))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/admin/dashboard-stats").with(user("c@x.com").roles("CONDUCTOR")))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/admin/despacho/metricas").with(user("c@x.com").roles("CONDUCTOR")))
                .andExpect(status().isForbidden());
    }

    @Test
    void beneficiosDePasajeroSonInaccesiblesParaConductorYAdmin() throws Exception {
        for (String rol : new String[] { "CONDUCTOR", "ADMIN" }) {
            mvc.perform(get("/api/niveles/favoritos/abc").with(user("u@x.com").roles(rol)))
                    .andExpect(status().isForbidden());
        }
    }

    @Test
    void adminNoUsaApisDePasajeroNiConductor() throws Exception {
        mvc.perform(get("/api/pasajero/historial").with(user("a@x.com").roles("ADMIN")))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/conductor/historial").with(user("a@x.com").roles("ADMIN")))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminAccedeASuZona() throws Exception {
        mvc.perform(get("/api/admin/notas").with(user("a@x.com").roles("ADMIN")))
                .andExpect(status().isOk());
    }

    // ── login JWT público + validación de entrada ───────────────────────

    @Test
    void loginApiEsPublicoYValidaLaEntrada() throws Exception {
        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"\",\"password\":\"\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void loginApiConDatosDeLongitudAbusivaSeRechaza() throws Exception {
        String largo = "a".repeat(5000);
        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + largo + "\",\"password\":\"x\"}"))
                .andExpect(status().isBadRequest());
    }

    // ── registro desde la app móvil: público, sin CSRF ni token ─────────

    @Test
    void registroDePasajeroPorApiEsPublicoYNoPideCsrf() throws Exception {
        mvc.perform(post("/api/auth/registro/pasajero").contentType(MediaType.APPLICATION_JSON)
                .content("{\"nombre\":\"Ana Perez\",\"email\":\"ana@x.com\",\"telefono\":\"3001234567\","
                        + "\"password\":\"Clave123\"}"))
                .andExpect(status().isCreated());
    }

    @Test
    void registroDePasajeroPorApiValidaLaEntrada() throws Exception {
        mvc.perform(post("/api/auth/registro/pasajero").contentType(MediaType.APPLICATION_JSON)
                .content("{\"nombre\":\"\",\"email\":\"x\",\"telefono\":\"1\",\"password\":\"a\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void registroPorApiSeLimitaTrasDemasiadosIntentos() throws Exception {
        int ultimo = 0;
        for (int i = 0; i < 12; i++) {
            ultimo = mvc.perform(post("/api/auth/registro/pasajero").contentType(MediaType.APPLICATION_JSON)
                    .content("{}")
                    .with(r -> {
                        r.setRemoteAddr("203.0.113.77");
                        return r;
                    })).andReturn().getResponse().getStatus();
        }
        assertEquals(429, ultimo);
    }

    // ── CSRF ────────────────────────────────────────────────────────────

    @Test
    void sesionSinTokenCsrfEnApiSeRechaza() throws Exception {
        mvc.perform(post("/api/admin/notas").with(user("a@x.com").roles("ADMIN"))
                .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void sesionConTokenCsrfEnApiSePermite() throws Exception {
        int estado = mvc.perform(post("/api/admin/notas").with(user("a@x.com").roles("ADMIN")).with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content("{}")).andReturn().getResponse().getStatus();
        assertNotEquals(403, estado);
        assertNotEquals(401, estado);
    }

    @Test
    void clienteJwtConBearerNoNecesitaCsrf() throws Exception {
        int estado = mvc.perform(post("/api/pasajero/cancelar-viaje/x").with(user("p@x.com").roles("PASAJERO"))
                .header("Authorization", "Bearer abc")).andReturn().getResponse().getStatus();
        assertNotEquals(403, estado);
    }

    @Test
    void peticionDeLaAppConTokenNoCreaSesionNiCookie() throws Exception {
        org.springframework.security.core.userdetails.UserDetails conductor =
                org.springframework.security.core.userdetails.User.withUsername("c@x.com").password("x")
                        .roles("CONDUCTOR").build();
        org.mockito.Mockito.when(ctx.getBean(JwtService.class).extractUsername("tok-app")).thenReturn("c@x.com");
        org.mockito.Mockito.when(ctx.getBean(CustomUserDetailsService.class).loadUserByUsername("c@x.com"))
                .thenReturn(conductor);
        org.mockito.Mockito.when(ctx.getBean(JwtService.class).isTokenValid("tok-app", conductor)).thenReturn(true);
        com.example.MotvirsWeb.dominio.modelo.Conductor yo = new com.example.MotvirsWeb.dominio.modelo.Conductor();
        yo.setId(new org.bson.types.ObjectId());
        org.mockito.Mockito.when(ctx.getBean(UsuarioContextHelper.class).getConductorAutenticado()).thenReturn(yo);

        var respuesta = mvc.perform(post("/api/conductor/ubicacion").header("Authorization", "Bearer tok-app")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"latitud\":10.37,\"longitud\":-75.48,\"disponible\":true}")).andReturn();

        int estado = respuesta.getResponse().getStatus();
        assertNotEquals(401, estado);
        assertNotEquals(403, estado);
        // Cada reporte de ubicacion (cada 5 s por conductor) creaba una sesion en memoria.
        assertEquals(null, respuesta.getRequest().getSession(false));
        assertEquals(null, respuesta.getResponse().getHeader("Set-Cookie"));
    }

    // ── rate limiting y cabeceras ───────────────────────────────────────

    @Test
    void loginApiSeLimitaTrasDemasiadosIntentos() throws Exception {
        int ultimo = 0;
        for (int i = 0; i < 12; i++) {
            ultimo = mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                    .content("{\"email\":\"\",\"password\":\"\"}")
                    .with(r -> {
                        r.setRemoteAddr("203.0.113.9");
                        return r;
                    })).andReturn().getResponse().getStatus();
        }
        assertEquals(429, ultimo);
    }

    @Test
    void respuestasLlevanCabecerasDeSeguridad() throws Exception {
        mvc.perform(get("/api/pasajero/perfil"))
                .andExpect(header().string("X-Content-Type-Options", "nosniff"))
                .andExpect(header().string("Referrer-Policy", "strict-origin-when-cross-origin"))
                .andExpect(header().exists("Permissions-Policy"))
                .andExpect(header().exists("X-Frame-Options"));
    }

    // ── no exponer el hash de la contraseña ─────────────────────────────

    @Test
    void laEntidadNoSerializaPasswordNiTokensDeReset() throws Exception {
        Pasajero p = Pasajero.builder().email("p@x.com").password("$2a$10$hashhashhash").build();
        p.setResetPasswordToken("token-secreto");
        String json = new ObjectMapper().findAndRegisterModules().writeValueAsString(p);
        assertFalse(json.contains("password"), json);
        assertFalse(json.contains("hashhash"), json);
        assertFalse(json.contains("token-secreto"), json);
        assertTrue(json.contains("p@x.com"));
    }
}
