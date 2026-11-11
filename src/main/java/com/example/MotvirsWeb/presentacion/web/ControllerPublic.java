package com.example.MotvirsWeb.presentacion.web;

import com.example.MotvirsWeb.presentacion.dto.ContactForm;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/public")
public class ControllerPublic {
    @Autowired
    private NotificadorCorreo notificadorCorreo;
    // Estas dos paginas traen un formulario (th:action) con token CSRF. Thymeleaf lo crea al llegar al
    // formulario, cuando la respuesta (>8 KB) ya se envio, y Tomcat no puede crear la sesion en ese punto.
    // Se crea la sesion antes de renderizar para que el token pueda guardarse.
    @GetMapping("/home/pasajero")
    public String apartadodelHome(jakarta.servlet.http.HttpServletRequest request) {
        request.getSession(true);
        return "index";
    }

    @GetMapping("/home/conductor")
    public String aparatadoconductor(jakarta.servlet.http.HttpServletRequest request){
        request.getSession(true);
        return "home_conductor";
    }

    @GetMapping("/surge")
    public String surgeExperience() {
        return "surge";
    }

    @PostMapping("/contact")
    public String procesarContacto(@jakarta.validation.Valid @ModelAttribute ContactForm form,
            org.springframework.validation.BindingResult errores, RedirectAttributes redirectAttributes) {
        if (errores.hasErrors()) {
            redirectAttributes.addFlashAttribute("mensajeError", "Revisa los datos del formulario de contacto.");
            return "redirect:/public/home/pasajero#contact";
        }
        // Llamamos al servicio
        notificadorCorreo.enviarMensajeContacto(form.getNombre(), form.getEmail(), form.getMensaje());

        // Agregamos un mensaje flash para mostrar en el HTML después de recargar
        redirectAttributes.addFlashAttribute("mensajeExito", "¡Gracias por escribirnos! Nos pondremos en contacto pronto.");

        // Redirigimos al fragmento #contact para que el usuario no pierda el foco
        return "redirect:/public/home/pasajero#contact";
    }
}


