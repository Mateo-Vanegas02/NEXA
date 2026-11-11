package com.example.MotvirsWeb.presentacion.web;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * Pagina de inicio ("/"). Sin este controlador Spring la sirve como pagina de bienvenida, sin pasar por
 * ningun metodo, y el formulario de contacto (th:action con token CSRF) intenta crear la sesion cuando la
 * respuesta ya se envio. Se crea la sesion antes de renderizar.
 */
@Controller
public class ControllerInicio {

    @GetMapping("/")
    public String inicio(HttpServletRequest request) {
        request.getSession(true);
        return "index";
    }
}
