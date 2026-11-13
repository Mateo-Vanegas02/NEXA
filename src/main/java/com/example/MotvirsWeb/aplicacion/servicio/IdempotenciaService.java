package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.AccionIdempotente;
import com.example.MotvirsWeb.dominio.repositorio.AccionIdempotenteRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.util.Map;
import java.util.Optional;
import java.util.function.Supplier;
import java.util.regex.Pattern;

/**
 * Llave de idempotencia ({@code Idempotency-Key}) para las acciones que la app reintenta tras un corte de señal:
 * «llegué», iniciar, finalizar, cancelar y calificar. La primera vez se hace la acción y se guarda la respuesta; un
 * reintento con la misma llave recibe esa misma respuesta sin repetir nada (nunca se finaliza ni se cobra dos veces).
 * Sin llave, la acción se hace como siempre (la web no la envía).
 */
@Slf4j
@Service
public class IdempotenciaService {

    public static final String CABECERA = "Idempotency-Key";

    private static final Pattern LLAVE_VALIDA = Pattern.compile("[A-Za-z0-9_-]{8,100}");

    private final AccionIdempotenteRepository repositorio;
    private final ObjectMapper json;
    private final Clock clock;

    public IdempotenciaService(AccionIdempotenteRepository repositorio, ObjectMapper json, Clock clock) {
        this.repositorio = repositorio;
        this.json = json;
        this.clock = clock;
    }

    public ResponseEntity<?> ejecutar(String llave, String usuarioId, String accion,
            Supplier<ResponseEntity<?>> hacer) {
        if (llave == null || llave.isBlank()) {
            return hacer.get();
        }
        if (!LLAVE_VALIDA.matcher(llave).matches()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Idempotency-Key no válida"));
        }
        String id = usuarioId + ":" + llave;
        Optional<AccionIdempotente> previa = repositorio.findById(id);
        if (previa.isPresent()) {
            return repetir(previa.get(), accion);
        }
        try {
            repositorio.insert(new AccionIdempotente(id, accion, false, 0, null, clock.instant()));
        } catch (DuplicateKeyException carrera) {
            // Otro reintento llegó a la vez: que espere su respuesta
            return enProceso();
        }
        ResponseEntity<?> respuesta;
        try {
            respuesta = hacer.get();
        } catch (RuntimeException e) {
            repositorio.deleteById(id); // Sin respuesta guardada: se puede reintentar
            throw e;
        }
        if (respuesta.getStatusCode().is5xxServerError()) {
            repositorio.deleteById(id);
            return respuesta;
        }
        try {
            String cuerpo = respuesta.getBody() == null ? null : json.writeValueAsString(respuesta.getBody());
            repositorio.save(new AccionIdempotente(id, accion, true, respuesta.getStatusCode().value(), cuerpo,
                    clock.instant()));
        } catch (JsonProcessingException | RuntimeException e) {
            log.warn("No se pudo guardar la respuesta de la llave {}: {}", llave, e.getMessage());
            repositorio.deleteById(id);
        }
        return respuesta;
    }

    private ResponseEntity<?> repetir(AccionIdempotente previa, String accion) {
        if (!accion.equals(previa.getAccion())) {
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                    .body(Map.of("error", "Esa Idempotency-Key ya se usó en otra acción"));
        }
        if (!previa.isTerminada()) {
            return enProceso();
        }
        Object cuerpo = null;
        try {
            cuerpo = previa.getCuerpo() == null ? null : json.readValue(previa.getCuerpo(), Object.class);
        } catch (JsonProcessingException e) {
            log.warn("Respuesta guardada ilegible para {}", previa.getId());
        }
        return ResponseEntity.status(previa.getEstadoHttp()).body(cuerpo);
    }

    private static ResponseEntity<?> enProceso() {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(Map.of("error", "Esta acción ya se está procesando", "enProceso", true));
    }
}
