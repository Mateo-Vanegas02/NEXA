package com.example.MotvirsWeb.infraestructura.socket;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Value("${app.base-url}")
    private String baseUrl;

    private final Environment environment;

    public WebSocketConfig(Environment environment) {
        this.environment = environment;
    }

    /** Solo el origen público de la app; en dev también localhost. Nunca "*". */
    private String[] origenesPermitidos() {
        List<String> origenes = new ArrayList<>();
        if (baseUrl != null && !baseUrl.isBlank()) {
            origenes.add(baseUrl.trim().replaceAll("/+$", ""));
        }
        if (!environment.acceptsProfiles(Profiles.of("prod"))) {
            origenes.add("http://localhost:*");
            origenes.add("http://127.0.0.1:*");
        }
        return origenes.toArray(new String[0]);
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(new WebSocketAuthInterceptor());
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic"); // Habilita un broker simple para enviar mensajes a los clientes
        config.setApplicationDestinationPrefixes("/app"); // Prefijo para los mensajes enviados desde el cliente
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry
                .addEndpoint("/ws")
                .setAllowedOriginPatterns(origenesPermitidos())
                .withSockJS();
    }
}