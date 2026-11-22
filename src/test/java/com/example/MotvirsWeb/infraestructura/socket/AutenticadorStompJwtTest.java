package com.example.MotvirsWeb.infraestructura.socket;

import com.example.MotvirsWeb.infraestructura.seguridad.CustomUserDetails;
import com.example.MotvirsWeb.infraestructura.seguridad.CustomUserDetailsService;
import com.example.MotvirsWeb.infraestructura.seguridad.JwtService;
import org.junit.jupiter.api.Test;
import org.springframework.messaging.Message;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class AutenticadorStompJwtTest {

    private final JwtService jwt = mock(JwtService.class);
    private final CustomUserDetailsService usuarios = mock(CustomUserDetailsService.class);
    private final AutenticadorStompJwt autenticador = new AutenticadorStompJwt(jwt, usuarios);
    private final CustomUserDetails pasajero = new CustomUserDetails("p1", "p1@x.co", "x",
            List.of(new SimpleGrantedAuthority("ROLE_PASAJERO")), true);

    private void tokenValido() {
        when(jwt.extractUsername("bueno")).thenReturn("p1@x.co");
        when(jwt.extractUserId("bueno")).thenReturn("p1");
        when(usuarios.loadUserById("p1")).thenReturn(pasajero);
        when(jwt.isTokenValid("bueno", pasajero)).thenReturn(true);
    }

    @Test
    void conTokenValidoQuedaAutenticadoConSusRoles() {
        tokenValido();
        Authentication a = autenticador.autenticar("Bearer bueno");
        assertNotNull(a);
        assertSame(pasajero, a.getPrincipal());
        assertTrue(WebSocketAuthInterceptor.suscripcionPermitida("/topic/pasajero/p1/posicion", a));
    }

    @Test
    void sinCabeceraOConTokenMaloNoAutentica() {
        when(jwt.extractUsername("malo")).thenThrow(new IllegalArgumentException("firma"));
        assertNull(autenticador.autenticar(null));
        assertNull(autenticador.autenticar("Basic abc"));
        assertNull(autenticador.autenticar("Bearer malo"));
        when(jwt.extractUsername("vencido")).thenReturn("p1@x.co");
        when(jwt.extractUserId("vencido")).thenReturn("p1");
        when(usuarios.loadUserById("p1")).thenReturn(pasajero);
        when(jwt.isTokenValid("vencido", pasajero)).thenReturn(false);
        assertNull(autenticador.autenticar("Bearer vencido"));
    }

    @Test
    void elConnectDeLaAppFijaElUsuarioDeLaConexion() {
        tokenValido();
        StompHeaderAccessor h = StompHeaderAccessor.create(StompCommand.CONNECT);
        h.addNativeHeader("Authorization", "Bearer bueno");
        h.setLeaveMutable(true);
        Message<byte[]> m = MessageBuilder.createMessage(new byte[0], h.getMessageHeaders());

        new WebSocketAuthInterceptor(autenticador).preSend(m, null);

        StompHeaderAccessor despues = StompHeaderAccessor.wrap(m);
        assertNotNull(despues.getUser());
        assertEquals("p1@x.co", despues.getUser().getName());
    }
}
