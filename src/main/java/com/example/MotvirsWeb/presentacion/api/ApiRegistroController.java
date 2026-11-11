package com.example.MotvirsWeb.presentacion.api;

import com.example.MotvirsWeb.aplicacion.servicio.AuthService;
import com.example.MotvirsWeb.aplicacion.servicio.DocumentoInvalidoException;
import com.example.MotvirsWeb.aplicacion.servicio.RegistroConductorService;
import com.example.MotvirsWeb.presentacion.dto.ConductorRegistroRequest;
import com.example.MotvirsWeb.presentacion.dto.RegistroPasajeroRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

import java.util.Map;
import java.util.stream.Collectors;

/**
 * Registro para la app móvil: mismo flujo que {@code AuthController} (formularios web) pero con
 * respuestas JSON y sin CSRF. Rutas públicas, con límite de intentos por IP ({@code RateLimitFilter}).
 */
@RestController
@RequestMapping("/api/auth/registro")
@RequiredArgsConstructor
@lombok.extern.slf4j.Slf4j
public class ApiRegistroController {

    private final AuthService authService;
    private final RegistroConductorService registroConductorService;

    @PostMapping("/pasajero")
    public ResponseEntity<Map<String, String>> registrarPasajero(@Valid @RequestBody RegistroPasajeroRequest solicitud) {
        try {
            authService.registrarPasajero(solicitud.nombre().trim(), solicitud.email(), solicitud.telefono(),
                    solicitud.password());
            return creado("Registro exitoso. Ya puedes iniciar sesión.");
        } catch (IllegalStateException e) {
            return error(HttpStatus.CONFLICT, e.getMessage());
        } catch (Exception e) {
            log.error("Error registrando pasajero desde la app", e);
            return error(HttpStatus.INTERNAL_SERVER_ERROR, "No se pudo completar el registro. Intenta de nuevo.");
        }
    }

    /** Multipart: los campos del formulario web más las cuatro fotos (licencia, tarjeta, SOAT y tecnomecánica). */
    @PostMapping(value = "/conductor", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, String>> registrarConductor(@Valid @ModelAttribute ConductorRegistroRequest solicitud,
            BindingResult errores) {
        if (errores.hasErrors()) {
            String mensaje = errores.getFieldErrors().stream()
                    .map(e -> e.getDefaultMessage())
                    .sorted()
                    .collect(Collectors.joining("; "));
            return error(HttpStatus.BAD_REQUEST,
                    mensaje.isBlank() ? "Datos inválidos. Verifica todos los campos." : mensaje);
        }
        try {
            registroConductorService.registrar(solicitud.aSolicitud());
            return creado("Registro recibido. Un administrador revisará tus documentos y podrás iniciar sesión cuando te aprueben.");
        } catch (DocumentoInvalidoException e) {
            return error(HttpStatus.BAD_REQUEST, e.getMessage());
        } catch (IllegalStateException e) {
            return error(HttpStatus.CONFLICT, e.getMessage());
        } catch (Exception e) {
            log.error("Error registrando conductor desde la app", e);
            return error(HttpStatus.INTERNAL_SERVER_ERROR,
                    "No se pudo completar el registro. Verifica los datos e intenta de nuevo.");
        }
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<Map<String, String>> archivoMuyPesado() {
        return error(HttpStatus.PAYLOAD_TOO_LARGE, "Cada foto debe pesar máximo 5 MB.");
    }

    private static ResponseEntity<Map<String, String>> creado(String mensaje) {
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("mensaje", mensaje));
    }

    private static ResponseEntity<Map<String, String>> error(HttpStatus estado, String mensaje) {
        return ResponseEntity.status(estado).body(Map.of("error", mensaje, "message", mensaje));
    }
}
