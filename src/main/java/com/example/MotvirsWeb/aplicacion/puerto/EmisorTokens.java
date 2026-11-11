package com.example.MotvirsWeb.aplicacion.puerto;

import org.springframework.security.core.userdetails.UserDetails;

/**
 * Puerto de salida: emisión de tokens de sesión para la API móvil. La implementación (JWT)
 * vive en infraestructura.seguridad.
 */
public interface EmisorTokens {

    String generateToken(UserDetails userDetails);
}
