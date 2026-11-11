package com.example.MotvirsWeb.presentacion.api;

import com.example.MotvirsWeb.presentacion.web.ControllerPasajero;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;
import java.util.stream.Collectors;

/**
 * Responde en JSON {@code {"error": "...", "message": "..."}} cuando el cuerpo de una petición
 * no pasa la validación (Bean Validation) o no se puede leer. Se limita a los controladores que ya
 * usan DTOs validados; el resto conserva su comportamiento.
 */
@RestControllerAdvice(assignableTypes = {ControllerPasajero.class, ApiPasajeroController.class, ApiRegistroController.class,
        ApiNivelesController.class})
public class ManejadorErroresValidacion {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> datosInvalidos(MethodArgumentNotValidException e) {
        String mensaje = e.getBindingResult().getFieldErrors().stream()
                .map(f -> f.getDefaultMessage())
                .sorted()
                .collect(Collectors.joining("; "));
        return cuerpo(mensaje.isBlank() ? "Datos de la solicitud inválidos" : mensaje);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, String>> cuerpoIlegible(HttpMessageNotReadableException e) {
        return cuerpo("El cuerpo de la solicitud no tiene un formato válido");
    }

    private static ResponseEntity<Map<String, String>> cuerpo(String mensaje) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("error", mensaje, "message", mensaje));
    }
}
