package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.AccionIdempotente;
import com.example.MotvirsWeb.dominio.repositorio.AccionIdempotenteRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class IdempotenciaServiceTest {

    private final Map<String, AccionIdempotente> guardadas = new HashMap<>();
    private final AccionIdempotenteRepository repo = mock(AccionIdempotenteRepository.class);
    private IdempotenciaService servicio;
    private final AtomicInteger veces = new AtomicInteger();

    @BeforeEach
    void setUp() {
        when(repo.findById(any())).thenAnswer(i -> Optional.ofNullable(guardadas.get(i.<String>getArgument(0))));
        when(repo.insert(any(AccionIdempotente.class))).thenAnswer(i -> {
            AccionIdempotente a = i.getArgument(0);
            if (guardadas.containsKey(a.getId())) {
                throw new DuplicateKeyException("dup");
            }
            guardadas.put(a.getId(), a);
            return a;
        });
        when(repo.save(any(AccionIdempotente.class))).thenAnswer(i -> {
            AccionIdempotente a = i.getArgument(0);
            guardadas.put(a.getId(), a);
            return a;
        });
        doAnswer(i -> guardadas.remove(i.<String>getArgument(0))).when(repo).deleteById(any());
        servicio = new IdempotenciaService(repo, new ObjectMapper(),
                Clock.fixed(Instant.parse("2026-11-13T15:00:00Z"), ZoneOffset.UTC));
    }

    private ResponseEntity<?> finalizar(String llave) {
        return servicio.ejecutar(llave, "c1", "finalizar:s1", () -> {
            veces.incrementAndGet();
            return ResponseEntity.ok(Map.of("mensaje", "Servicio finalizado", "servicioId", "s1"));
        });
    }

    @Test
    void unReintentoDevuelveLaMismaRespuestaSinRepetirLaAccion() {
        ResponseEntity<?> primera = finalizar("llave-0001");
        ResponseEntity<?> reintento = finalizar("llave-0001");

        assertEquals(1, veces.get());
        assertEquals(HttpStatus.OK, reintento.getStatusCode());
        assertEquals(primera.getBody(), reintento.getBody());
    }

    @Test
    void sinLlaveSeHaceSiempre() {
        finalizar(null);
        finalizar(null);
        assertEquals(2, veces.get());
    }

    @Test
    void laLlaveEsDeCadaUsuario() {
        finalizar("llave-0001");
        servicio.ejecutar("llave-0001", "otro", "finalizar:s1", () -> {
            veces.incrementAndGet();
            return ResponseEntity.ok().build();
        });
        assertEquals(2, veces.get());
    }

    @Test
    void mientrasSeProcesaUnReintentoRecibe409() {
        guardadas.put("c1:llave-0002", new AccionIdempotente("c1:llave-0002", "finalizar:s1", false, 0, null,
                Instant.now()));
        assertEquals(HttpStatus.CONFLICT, finalizar("llave-0002").getStatusCode());
        assertEquals(0, veces.get());
    }

    @Test
    void laMismaLlaveEnOtraAccionSeRechaza() {
        finalizar("llave-0003");
        ResponseEntity<?> otra = servicio.ejecutar("llave-0003", "c1", "iniciar:s1", () -> ResponseEntity.ok().build());
        assertEquals(HttpStatus.UNPROCESSABLE_ENTITY, otra.getStatusCode());
    }

    @Test
    void unErrorDelServidorNoSeGuardaYSePuedeReintentar() {
        assertThrows(IllegalStateException.class, () -> servicio.ejecutar("llave-0004", "c1", "finalizar:s1", () -> {
            throw new IllegalStateException("Mongo caído");
        }));
        finalizar("llave-0004");
        assertEquals(1, veces.get());
    }

    @Test
    void unErrorDeNegocioSeRepiteIgual() {
        servicio.ejecutar("llave-0005", "c1", "llegue:s1",
                () -> ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of("error", "Ya no aplica")));
        ResponseEntity<?> reintento = servicio.ejecutar("llave-0005", "c1", "llegue:s1", () -> {
            veces.incrementAndGet();
            return ResponseEntity.ok().build();
        });
        assertEquals(HttpStatus.CONFLICT, reintento.getStatusCode());
        assertEquals(0, veces.get());
    }

    @Test
    void unaLlaveMalFormadaEs400() {
        assertEquals(HttpStatus.BAD_REQUEST, finalizar("corta").getStatusCode());
    }
}
