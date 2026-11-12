package com.example.MotvirsWeb.infraestructura.push;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorPush;
import lombok.extern.slf4j.Slf4j;

import java.util.Collection;

/** Se usa cuando el servidor no tiene credenciales de Firebase: los avisos se descartan sin error. */
@Slf4j
public class NotificadorPushInactivo implements NotificadorPush {

    @Override
    public void enviar(Collection<String> tokens, Aviso aviso) {
        log.debug("Push desactivado: se descarta {} para {} dispositivo(s)", aviso.tipo(), tokens.size());
    }

    @Override
    public boolean activo() {
        return false;
    }
}
