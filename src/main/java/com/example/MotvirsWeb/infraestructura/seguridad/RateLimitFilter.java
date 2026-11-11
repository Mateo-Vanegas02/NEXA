package com.example.MotvirsWeb.infraestructura.seguridad;

import java.io.IOException;
import java.util.ArrayDeque;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.LongSupplier;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * Limitador de peticiones por IP (ventana deslizante en memoria) para los
 * endpoints sensibles: login, recuperación de contraseña, registro, contacto y
 * chats de IA (que consumen cuota de Gemini). Responde 429 con Retry-After.
 *
 * Es por instancia: con varias réplicas cada una cuenta por separado. Detrás de
 * un proxy se requiere server.forward-headers-strategy (ya definido en prod).
 */
@Component
public class RateLimitFilter extends OncePerRequestFilter {

    record Regla(String metodo, String ruta, int maximo, long ventanaSegundos) {
        boolean aplica(HttpServletRequest req) {
            return metodo.equals(req.getMethod()) && req.getRequestURI().startsWith(ruta);
        }
    }

    static final List<Regla> REGLAS = List.of(
            new Regla("POST", "/login", 10, 15 * 60),
            new Regla("POST", "/api/auth/login", 10, 15 * 60),
            new Regla("POST", "/auth/forgot-password", 5, 15 * 60),
            new Regla("POST", "/auth/reset-password", 10, 15 * 60),
            new Regla("POST", "/auth/registro", 10, 60 * 60),
            new Regla("POST", "/api/auth/registro", 10, 60 * 60),
            new Regla("POST", "/public/contact", 5, 15 * 60),
            new Regla("POST", "/public/chat", 20, 60),
            new Regla("POST", "/api/admin/chat", 30, 60));

    private static final int MAX_CLAVES = 50_000;

    private final boolean habilitado;
    private final LongSupplier reloj; // segundos
    private final Map<String, ArrayDeque<Long>> intentos = new ConcurrentHashMap<>();

    @Autowired
    public RateLimitFilter(@Value("${nexa.seguridad.rate-limit.habilitado:true}") boolean habilitado) {
        this(habilitado, () -> System.nanoTime() / 1_000_000_000L);
    }

    RateLimitFilter(boolean habilitado, LongSupplier relojSegundos) {
        this.habilitado = habilitado;
        this.reloj = relojSegundos;
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response,
            @NonNull FilterChain chain) throws ServletException, IOException {
        if (habilitado) {
            for (Regla regla : REGLAS) {
                if (regla.aplica(request)) {
                    long espera = registrar(regla, request.getRemoteAddr());
                    if (espera > 0) {
                        response.setStatus(429);
                        response.setHeader("Retry-After", String.valueOf(espera));
                        response.setContentType("application/json;charset=UTF-8");
                        response.getWriter().write(
                                "{\"error\":\"Too Many Requests\",\"message\":\"Demasiados intentos. Intenta de nuevo mas tarde.\"}");
                        return;
                    }
                    break;
                }
            }
        }
        chain.doFilter(request, response);
    }

    /** @return 0 si se permite; si no, segundos de espera. */
    long registrar(Regla regla, String ip) {
        if (intentos.size() > MAX_CLAVES) {
            limpiar();
        }
        long ahora = reloj.getAsLong();
        ArrayDeque<Long> cola = intentos.computeIfAbsent(regla.ruta() + "|" + ip, k -> new ArrayDeque<>());
        synchronized (cola) {
            while (!cola.isEmpty() && ahora - cola.peekFirst() >= regla.ventanaSegundos()) {
                cola.pollFirst();
            }
            if (cola.size() >= regla.maximo()) {
                return Math.max(1, regla.ventanaSegundos() - (ahora - cola.peekFirst()));
            }
            cola.addLast(ahora);
            return 0;
        }
    }

    private void limpiar() {
        long ahora = reloj.getAsLong();
        long maxVentana = REGLAS.stream().mapToLong(Regla::ventanaSegundos).max().orElse(3600);
        intentos.entrySet().removeIf(e -> {
            synchronized (e.getValue()) {
                return e.getValue().isEmpty() || ahora - e.getValue().peekLast() >= maxVentana;
            }
        });
    }
}
