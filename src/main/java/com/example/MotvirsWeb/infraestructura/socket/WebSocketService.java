package com.example.MotvirsWeb.infraestructura.socket;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal;
import com.example.MotvirsWeb.aplicacion.servicio.VisibilidadServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.modelo.Usuario;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class WebSocketService implements NotificadorTiempoReal {
    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Override
    public void notificarCambioEstadoServicio(Servicio servicio) {
        // Notificar al pasajero
        messagingTemplate.convertAndSend("/topic/pasajero/" + servicio.getPasajero().getId(),
                VisibilidadServicio.paraPasajero(servicio));

        // Notificar al conductor (si existe)
        if (servicio.getConductor() != null) {
            messagingTemplate.convertAndSend("/topic/conductor/" + servicio.getConductor().getId(),
                    VisibilidadServicio.paraConductor(servicio));
        }
    }

    @Override
    public void notificarNuevoServicioDisponible(Servicio servicio) {
        // Solo el id: el contenido lo entrega la lista filtrada por ola y cercanía, no este canal abierto a todos.
        if (servicio.getId() == null) {
            return;
        }
        messagingTemplate.convertAndSend("/topic/servicios-disponibles",
                Map.of("id", servicio.getId(), "estado", "SOLICITADO"));
    }

    @Override
    public void notificarOlaAmpliada(String servicioId, int ola) {
        messagingTemplate.convertAndSend("/topic/servicios-disponibles",
                Map.of("id", servicioId, "estado", "SOLICITADO", "ola", ola));
    }

    @Override
    public void notificarSolicitudRetirada(String servicioId, String motivo) {
        messagingTemplate.convertAndSend("/topic/servicios-disponibles",
                Map.of("id", servicioId, "estado", "RETIRADO", "motivo", motivo));
    }

    @Override
    public void notificarOfertaSubida(String servicioId, long extraVoluntario) {
        messagingTemplate.convertAndSend("/topic/servicios-disponibles",
                Map.of("id", servicioId, "estado", "OFERTA_SUBIDA", "extraVoluntario", extraVoluntario));
    }

    @Override
    public void notificarPosicionConductor(String pasajeroId, PosicionViaje posicion) {
        // Canal aparte del de estados: el cliente no lo confunde con un cambio de servicio
        messagingTemplate.convertAndSend("/topic/pasajero/" + pasajeroId + "/posicion", posicion);
    }

    @Override
    public void notificarNuevoRegistroAdmin(Usuario nuevoUsuario) {
        Map<String, Object> notificacion = new HashMap<>();
        notificacion.put("tipo", "NUEVO_REGISTRO");
        notificacion.put("email", nuevoUsuario.getEmail());
        notificacion.put("rol", nuevoUsuario.getRol().toString());
        notificacion.put("fecha",
                nuevoUsuario.getFechaRegistro() != null ? nuevoUsuario.getFechaRegistro().toString() : "Ahora");

        // Enviamos al topic específico
        messagingTemplate.convertAndSend("/topic/admin/registros", notificacion);
    }

    @Override
    public void notificarNuevoRegistroAdmin(String email, String rol) {
        Map<String, Object> notificacion = new HashMap<>();
        notificacion.put("tipo", "NUEVO_REGISTRO");
        notificacion.put("email", email);
        notificacion.put("rol", rol);
        notificacion.put("fecha", java.time.LocalDateTime.now().toString());
        messagingTemplate.convertAndSend("/topic/admin/registros", notificacion);
    }
}