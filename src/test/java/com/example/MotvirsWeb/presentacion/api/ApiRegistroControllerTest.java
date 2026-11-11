package com.example.MotvirsWeb.presentacion.api;

import com.example.MotvirsWeb.aplicacion.servicio.AuthService;
import com.example.MotvirsWeb.aplicacion.servicio.DocumentoInvalidoException;
import com.example.MotvirsWeb.aplicacion.servicio.RegistroConductorService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Registro por JSON/multipart de la app móvil. Sin Mongo ni contexto de Spring. */
class ApiRegistroControllerTest {

    private final AuthService authService = mock(AuthService.class);
    private final RegistroConductorService registroConductor = mock(RegistroConductorService.class);
    private MockMvc mvc;

    @BeforeEach
    void preparar() {
        mvc = MockMvcBuilders.standaloneSetup(new ApiRegistroController(authService, registroConductor))
                .setControllerAdvice(new ManejadorErroresValidacion())
                .build();
    }

    private static final String PASAJERO_OK = """
            {"nombre":"Ana Perez","email":"ana@x.com","telefono":"3001234567","password":"Clave123"}""";

    @Test
    void pasajeroValidoSeRegistraYResponde201() throws Exception {
        mvc.perform(post("/api/auth/registro/pasajero").contentType(MediaType.APPLICATION_JSON).content(PASAJERO_OK))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.mensaje").exists());

        verify(authService).registrarPasajero("Ana Perez", "ana@x.com", "3001234567", "Clave123");
    }

    @Test
    void contrasenaDebilDevuelve400ConLaPolitica() throws Exception {
        mvc.perform(post("/api/auth/registro/pasajero").contentType(MediaType.APPLICATION_JSON)
                .content(PASAJERO_OK.replace("Clave123", "clave")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(org.hamcrest.Matchers.containsString("contraseña")));

        verifyNoInteractions(authService);
    }

    @Test
    void correoInvalidoYTelefonoCortoDevuelven400() throws Exception {
        mvc.perform(post("/api/auth/registro/pasajero").contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"nombre":"Ana Perez","email":"no-es-correo","telefono":"123","password":"Clave123"}"""))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(org.hamcrest.Matchers.containsString("email")))
                .andExpect(jsonPath("$.error").value(org.hamcrest.Matchers.containsString("teléfono")));

        verifyNoInteractions(authService);
    }

    @Test
    void correoYaRegistradoDevuelve409() throws Exception {
        when(authService.registrarPasajero(anyString(), anyString(), anyString(), anyString()))
                .thenThrow(new IllegalStateException("Ya existe un pasajero registrado con este email: ana@x.com"));

        mvc.perform(post("/api/auth/registro/pasajero").contentType(MediaType.APPLICATION_JSON).content(PASAJERO_OK))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value(org.hamcrest.Matchers.containsString("Ya existe")));
    }

    @Test
    void cuerpoQueNoEsJsonDevuelve400() throws Exception {
        mvc.perform(post("/api/auth/registro/pasajero").contentType(MediaType.APPLICATION_JSON).content("no es json"))
                .andExpect(status().isBadRequest());
    }

    // ---------- conductor (multipart) ----------

    private static org.springframework.test.web.servlet.request.MockMultipartHttpServletRequestBuilder conductorValido() {
        byte[] bytes = { 1, 2, 3 };
        var req = multipart("/api/auth/registro/conductor")
                .file(new MockMultipartFile("fotoLicencia", "l.jpg", "image/jpeg", bytes))
                .file(new MockMultipartFile("fotoTarjetaPropiedad", "t.jpg", "image/jpeg", bytes))
                .file(new MockMultipartFile("fotoSoat", "s.jpg", "image/jpeg", bytes))
                .file(new MockMultipartFile("fotoTecnomecanica", "m.jpg", "image/jpeg", bytes));
        String[][] campos = {
                { "nombre", "Carlos Gomez" }, { "email", "carlos@x.com" }, { "telefono", "3001234567" },
                { "password", "Clave123" }, { "confirmPassword", "Clave123" }, { "licencia", "123456789" },
                { "placa", "ABC123" }, { "marca", "Bajaj" }, { "modelo", "Boxer" }, { "color", "Negro" },
                { "tarjetaPropiedad", "12345678" }, { "soat", "123456789012" }, { "tecnomecanica", "123456" } };
        for (String[] c : campos) {
            req.param(c[0], c[1]);
        }
        return req;
    }

    @Test
    void conductorValidoSeRegistraYResponde201() throws Exception {
        mvc.perform(conductorValido())
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.mensaje").exists());

        verify(registroConductor).registrar(any());
    }

    @Test
    void conductorSinFotoDevuelve400() throws Exception {
        var sinFoto = multipart("/api/auth/registro/conductor")
                .file(new MockMultipartFile("fotoLicencia", "l.jpg", "image/jpeg", new byte[] { 1 }))
                .param("nombre", "Carlos Gomez").param("email", "carlos@x.com").param("telefono", "3001234567")
                .param("password", "Clave123").param("confirmPassword", "Clave123").param("licencia", "123456789")
                .param("placa", "ABC123").param("marca", "Bajaj").param("modelo", "Boxer").param("color", "Negro")
                .param("tarjetaPropiedad", "12345678").param("soat", "123456789012").param("tecnomecanica", "123456");

        mvc.perform(sinFoto)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(org.hamcrest.Matchers.containsString("foto")));

        verifyNoInteractions(registroConductor);
    }

    @Test
    void fotoInvalidaDevuelve400ConElMotivo() throws Exception {
        doThrow(new DocumentoInvalidoException("La foto de la licencia no es una imagen válida"))
                .when(registroConductor).registrar(any());

        mvc.perform(conductorValido())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("La foto de la licencia no es una imagen válida"));
    }

    @Test
    void conductorDuplicadoDevuelve409() throws Exception {
        doThrow(new IllegalStateException("Ya existe un conductor con ese correo"))
                .when(registroConductor).registrar(any());

        mvc.perform(conductorValido())
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("Ya existe un conductor con ese correo"));
    }
}
