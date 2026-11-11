package com.example.MotvirsWeb.presentacion.web;

import com.example.MotvirsWeb.dominio.regla.FactoresCalificacion;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.mock.web.MockServletContext;
import org.thymeleaf.context.WebContext;
import org.thymeleaf.spring6.SpringTemplateEngine;
import org.thymeleaf.templatemode.TemplateMode;
import org.thymeleaf.templateresolver.ClassLoaderTemplateResolver;
import org.thymeleaf.web.servlet.JakartaServletWebApplication;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/** La pantalla de calificación se arma con el catálogo del servidor y el enlace «Ahora no» al panel del rol. */
class RatingPlantillaTest {

    private String renderizar(String rol, String nombreOtro) {
        ClassLoaderTemplateResolver resolver = new ClassLoaderTemplateResolver();
        resolver.setPrefix("templates/");
        resolver.setSuffix(".html");
        resolver.setTemplateMode(TemplateMode.HTML);
        resolver.setCharacterEncoding("UTF-8");
        SpringTemplateEngine motor = new SpringTemplateEngine();
        motor.setTemplateResolver(resolver);

        MockServletContext contexto = new MockServletContext();
        MockHttpServletRequest peticion = new MockHttpServletRequest(contexto, "GET", "/rating");
        var intercambio = JakartaServletWebApplication.buildApplication(contexto)
                .buildExchange(peticion, new MockHttpServletResponse());
        WebContext ctx = new WebContext(intercambio);
        ctx.setVariable("servicioId", "s1");
        ctx.setVariable("rol", rol);
        ctx.setVariable("nombreOtro", nombreOtro);
        ctx.setVariable("factores", FactoresCalificacion.catalogo(rol));
        ctx.setVariable("notaSatisfecho", FactoresCalificacion.NOTA_SATISFECHO);
        ctx.setVariable("urlPanel", "conductor".equals(rol) ? "/conductor/panel" : "/pasajero/panel");
        ctx.setVariable("_csrf", Map.of("parameterName", "_csrf", "token", "t"));
        return motor.process("rating", ctx);
    }

    @Test
    void pasajeroVeSusFactoresYPuedeOmitir() {
        String html = renderizar("pasajero", "Carlos <b>");
        assertTrue(html.contains("data-codigo=\"ACEPTACION_LENTA\""));
        assertTrue(html.contains("data-positivo=\"false\""));
        assertTrue(html.contains("Tardaron en aceptar"));
        assertFalse(html.contains("ESPERA_EN_EL_PUNTO"), "no muestra los factores del conductor");
        assertTrue(html.contains("href=\"/pasajero/panel\""));
        assertTrue(html.contains("Ahora no"));
        assertTrue(html.contains("Carlos &lt;b&gt;"), "el nombre se escapa");
        assertTrue(html.contains("data-nota-satisfecho=\"4.0\""));
    }

    @Test
    void conductorVuelveASuPanel() {
        String html = renderizar("conductor", "");
        assertTrue(html.contains("ESPERA_EN_EL_PUNTO"));
        assertTrue(html.contains("href=\"/conductor/panel\""));
        assertTrue(html.contains("¿Cómo te fue? Es opcional."));
    }
}
