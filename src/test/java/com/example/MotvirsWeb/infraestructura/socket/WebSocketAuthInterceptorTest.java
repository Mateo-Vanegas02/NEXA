package com.example.MotvirsWeb.infraestructura.socket;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.messaging.MessagingException;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.messaging.MessageChannel;
import static org.mockito.Mockito.mock;

import com.example.MotvirsWeb.infraestructura.seguridad.CustomUserDetails;

class WebSocketAuthInterceptorTest {

    private static Authentication usuario(String id, String rol) {
        CustomUserDetails d = new CustomUserDetails(id, id + "@x.com", "x",
                List.of(new SimpleGrantedAuthority(rol)), true);
        return new UsernamePasswordAuthenticationToken(d, null, d.getAuthorities());
    }

    @Test
    void pasajeroSoloEscuchaSuPropioTopic() {
        Authentication p = usuario("p1", "ROLE_PASAJERO");
        assertTrue(WebSocketAuthInterceptor.suscripcionPermitida("/topic/pasajero/p1", p));
        assertFalse(WebSocketAuthInterceptor.suscripcionPermitida("/topic/pasajero/p2", p));
        assertFalse(WebSocketAuthInterceptor.suscripcionPermitida("/topic/conductor/p1", p));
        assertFalse(WebSocketAuthInterceptor.suscripcionPermitida("/topic/admin/registros", p));
        assertFalse(WebSocketAuthInterceptor.suscripcionPermitida("/topic/servicios-disponibles", p));
    }

    @Test
    void pasajeroSoloEscuchaLaPosicionDeSuPropioViaje() {
        Authentication p = usuario("p1", "ROLE_PASAJERO");
        assertTrue(WebSocketAuthInterceptor.suscripcionPermitida("/topic/pasajero/p1/posicion", p));
        assertFalse(WebSocketAuthInterceptor.suscripcionPermitida("/topic/pasajero/p2/posicion", p));
        assertFalse(WebSocketAuthInterceptor.suscripcionPermitida("/topic/pasajero/p1/posicion/x", p));
        assertFalse(WebSocketAuthInterceptor.suscripcionPermitida("/topic/pasajero/p1/otro", p));
        assertFalse(WebSocketAuthInterceptor.suscripcionPermitida("/topic/pasajero/p1/posicion",
                usuario("c1", "ROLE_CONDUCTOR")));
    }

    @Test
    void conductorEscuchaSuTopicYLosServiciosDisponibles() {
        Authentication c = usuario("c1", "ROLE_CONDUCTOR");
        assertTrue(WebSocketAuthInterceptor.suscripcionPermitida("/topic/conductor/c1", c));
        assertTrue(WebSocketAuthInterceptor.suscripcionPermitida("/topic/servicios-disponibles", c));
        assertFalse(WebSocketAuthInterceptor.suscripcionPermitida("/topic/conductor/c2", c));
        assertFalse(WebSocketAuthInterceptor.suscripcionPermitida("/topic/pasajero/c1", c));
    }

    @Test
    void soloAdminEscuchaLosRegistros() {
        assertTrue(WebSocketAuthInterceptor.suscripcionPermitida("/topic/admin/registros",
                usuario("a1", "ROLE_ADMIN")));
        assertFalse(WebSocketAuthInterceptor.suscripcionPermitida("/topic/admin/registros",
                usuario("c1", "ROLE_CONDUCTOR")));
    }

    @Test
    void sinAutenticacionODestinoDesconocidoSeRechaza() {
        assertFalse(WebSocketAuthInterceptor.suscripcionPermitida("/topic/pasajero/p1", null));
        assertFalse(WebSocketAuthInterceptor.suscripcionPermitida(null, usuario("p1", "ROLE_PASAJERO")));
        assertFalse(WebSocketAuthInterceptor.suscripcionPermitida("/topic/otro", usuario("a1", "ROLE_ADMIN")));
    }

    @Test
    void interceptorRechazaSuscripcionAjenaYEnvio() {
        WebSocketAuthInterceptor interceptor = new WebSocketAuthInterceptor();
        MessageChannel canal = mock(MessageChannel.class);
        StompHeaderAccessor suscripcion = StompHeaderAccessor.create(StompCommand.SUBSCRIBE);
        suscripcion.setDestination("/topic/pasajero/p2");
        suscripcion.setUser(usuario("p1", "ROLE_PASAJERO"));
        suscripcion.setLeaveMutable(true);
        assertThrows(MessagingException.class,
                () -> interceptor.preSend(MessageBuilder.createMessage(new byte[0], suscripcion.getMessageHeaders()), canal));

        StompHeaderAccessor envio = StompHeaderAccessor.create(StompCommand.SEND);
        envio.setDestination("/app/otro");
        envio.setUser(usuario("p1", "ROLE_PASAJERO"));
        envio.setLeaveMutable(true);
        assertThrows(MessagingException.class,
                () -> interceptor.preSend(MessageBuilder.createMessage(new byte[0], envio.getMessageHeaders()), canal));
    }
}
