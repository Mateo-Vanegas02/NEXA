package com.example.MotvirsWeb.infraestructura.seguridad;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.concurrent.atomic.AtomicLong;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class RateLimitFilterTest {

    private final AtomicLong segundos = new AtomicLong(1000);

    private int llamar(RateLimitFilter filtro, String metodo, String ruta, String ip) throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest(metodo, ruta);
        req.setRemoteAddr(ip);
        MockHttpServletResponse res = new MockHttpServletResponse();
        filtro.doFilter(req, res, new MockFilterChain());
        return res.getStatus();
    }

    @Test
    void bloqueaTrasElMaximoYSeRecuperaAlPasarLaVentana() throws Exception {
        RateLimitFilter f = new RateLimitFilter(true, segundos::get);
        for (int i = 0; i < 10; i++) {
            assertEquals(200, llamar(f, "POST", "/login", "1.1.1.1"));
        }
        assertEquals(429, llamar(f, "POST", "/login", "1.1.1.1"));
        segundos.addAndGet(15 * 60 + 1);
        assertEquals(200, llamar(f, "POST", "/login", "1.1.1.1"));
    }

    @Test
    void cadaIpTieneSuPropioContador() throws Exception {
        RateLimitFilter f = new RateLimitFilter(true, segundos::get);
        for (int i = 0; i < 11; i++) {
            llamar(f, "POST", "/login", "1.1.1.1");
        }
        assertEquals(200, llamar(f, "POST", "/login", "2.2.2.2"));
    }

    @Test
    void soloAplicaALasRutasYMetodosSensibles() throws Exception {
        RateLimitFilter f = new RateLimitFilter(true, segundos::get);
        for (int i = 0; i < 50; i++) {
            assertEquals(200, llamar(f, "GET", "/login", "1.1.1.1"));
            assertEquals(200, llamar(f, "POST", "/api/pasajero/historial", "1.1.1.1"));
        }
    }

    @Test
    void respondeConRetryAfter() throws Exception {
        RateLimitFilter f = new RateLimitFilter(true, segundos::get);
        for (int i = 0; i < 5; i++) {
            llamar(f, "POST", "/auth/forgot-password", "9.9.9.9");
        }
        MockHttpServletRequest req = new MockHttpServletRequest("POST", "/auth/forgot-password");
        req.setRemoteAddr("9.9.9.9");
        MockHttpServletResponse res = new MockHttpServletResponse();
        f.doFilter(req, res, new MockFilterChain());
        assertEquals(429, res.getStatus());
        assertTrue(Long.parseLong(res.getHeader("Retry-After")) > 0);
    }

    @Test
    void deshabilitadoNoLimita() throws Exception {
        RateLimitFilter f = new RateLimitFilter(false, segundos::get);
        for (int i = 0; i < 100; i++) {
            assertEquals(200, llamar(f, "POST", "/login", "1.1.1.1"));
        }
    }
}
