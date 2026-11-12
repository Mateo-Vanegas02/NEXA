package com.example.MotvirsWeb.infraestructura.seguridad;

import com.example.MotvirsWeb.aplicacion.puerto.CanalPeticion;
import com.example.MotvirsWeb.dominio.modelo.CanalServicio;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.RequestContextHolder;

/** Lee la marca que deja {@link JwtAuthFilter} cuando autentica una petición con token Bearer. */
@Component
public class CanalPeticionHttp implements CanalPeticion {

    @Override
    public CanalServicio actual() {
        RequestAttributes atributos = RequestContextHolder.getRequestAttributes();
        if (atributos == null) {
            return CanalServicio.WEB;
        }
        Object canal = atributos.getAttribute(JwtAuthFilter.ATRIBUTO_CANAL, RequestAttributes.SCOPE_REQUEST);
        return canal == CanalServicio.APP ? CanalServicio.APP : CanalServicio.WEB;
    }
}
