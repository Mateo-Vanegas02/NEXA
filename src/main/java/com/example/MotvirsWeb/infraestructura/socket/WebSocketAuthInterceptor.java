package com.example.MotvirsWeb.infraestructura.socket;

import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.MessagingException;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.core.Authentication;

import com.example.MotvirsWeb.infraestructura.seguridad.CustomUserDetails;

/**
 * Autoriza cada SUBSCRIBE STOMP según el rol y el id del usuario autenticado en
 * el handshake (sesión). Evita que un usuario escuche los topics de otro
 * (viajes ajenos, registros de admin). Cualquier otro destino se rechaza.
 * Los clientes no tienen destinos {@code /app/**}: SEND se rechaza.
 */
public class WebSocketAuthInterceptor implements ChannelInterceptor {

    private final AutenticadorStompJwt autenticador;

    /** Solo sesión web (sin JWT). */
    public WebSocketAuthInterceptor() {
        this(null);
    }

    public WebSocketAuthInterceptor(AutenticadorStompJwt autenticador) {
        this.autenticador = autenticador;
    }

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (accessor == null || accessor.getCommand() == null) {
            return message;
        }
        StompCommand comando = accessor.getCommand();
        // La app no tiene sesión web: se autentica en el CONNECT con su JWT. Queda como usuario de la conexión.
        if (StompCommand.CONNECT.equals(comando) && accessor.getUser() == null && autenticador != null) {
            Authentication auth = autenticador.autenticar(accessor.getFirstNativeHeader("Authorization"));
            if (auth != null) {
                accessor.setUser(auth);
            }
        }
        if (StompCommand.SUBSCRIBE.equals(comando)
                && !suscripcionPermitida(accessor.getDestination(),
                        accessor.getUser() instanceof Authentication a ? a : null)) {
            throw new MessagingException("Suscripcion no autorizada");
        }
        if (StompCommand.SEND.equals(comando)) {
            throw new MessagingException("Envio no permitido");
        }
        return message;
    }

    static boolean suscripcionPermitida(String destino, Authentication auth) {
        if (destino == null || auth == null || !auth.isAuthenticated()) {
            return false;
        }
        if ("/topic/servicios-disponibles".equals(destino)) {
            return tieneRol(auth, "ROLE_CONDUCTOR");
        }
        if ("/topic/admin/registros".equals(destino)) {
            return tieneRol(auth, "ROLE_ADMIN");
        }
        if (destino.startsWith("/topic/pasajero/")) {
            String resto = destino.substring("/topic/pasajero/".length());
            // /topic/pasajero/{id}/posicion: la posición en vivo del conductor de su viaje
            if (resto.endsWith("/posicion")) {
                resto = resto.substring(0, resto.length() - "/posicion".length());
            }
            return tieneRol(auth, "ROLE_PASAJERO") && esElMismoId(auth, resto);
        }
        if (destino.startsWith("/topic/conductor/")) {
            return tieneRol(auth, "ROLE_CONDUCTOR")
                    && esElMismoId(auth, destino.substring("/topic/conductor/".length()));
        }
        return false;
    }

    private static boolean tieneRol(Authentication auth, String rol) {
        return auth.getAuthorities().stream().anyMatch(a -> rol.equals(a.getAuthority()));
    }

    private static boolean esElMismoId(Authentication auth, String id) {
        return auth.getPrincipal() instanceof CustomUserDetails d && d.getId() != null && d.getId().equals(id);
    }
}
