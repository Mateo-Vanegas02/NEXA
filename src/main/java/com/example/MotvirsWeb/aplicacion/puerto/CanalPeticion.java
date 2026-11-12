package com.example.MotvirsWeb.aplicacion.puerto;

import com.example.MotvirsWeb.dominio.modelo.CanalServicio;

/**
 * Canal de la petición en curso: APP si llegó con un token Bearer (la app móvil), WEB si llegó con la sesión del
 * navegador. Fuera de una petición HTTP (tareas programadas) es WEB.
 */
public interface CanalPeticion {

    CanalServicio actual();
}
