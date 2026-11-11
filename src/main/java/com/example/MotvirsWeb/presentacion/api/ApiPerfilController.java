package com.example.MotvirsWeb.presentacion.api;

import com.example.MotvirsWeb.aplicacion.servicio.DocumentoInvalidoException;
import com.example.MotvirsWeb.aplicacion.servicio.PerfilService;
import com.example.MotvirsWeb.aplicacion.util.UsuarioContextHelper;
import com.example.MotvirsWeb.presentacion.dto.ActualizarPerfilRequest;
import com.example.MotvirsWeb.presentacion.dto.PerfilDto;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.MultipartFile;

import java.time.Duration;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Perfil del usuario autenticado (pasajero o conductor) y foto de perfil.
 * Bajo {@code /api/**}: sesión (con CSRF) o JWT. La foto de cualquier usuario la puede pedir otro usuario
 * autenticado (p. ej. el pasajero ve a su conductor).
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class ApiPerfilController {

    private final PerfilService perfilService;
    private final UsuarioContextHelper usuarioContext;

    @GetMapping("/perfil")
    public PerfilDto obtener() {
        return perfilService.perfil(usuarioContext.getUsuarioAutenticado());
    }

    @PutMapping("/perfil")
    public PerfilDto actualizar(@Valid @RequestBody ActualizarPerfilRequest datos) {
        return perfilService.actualizarDatos(usuarioContext.getUsuarioAutenticado(), datos.nombre(), datos.telefono());
    }

    @PutMapping(value = "/perfil/foto", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public PerfilDto subirFoto(@RequestPart("foto") MultipartFile foto) {
        return perfilService.guardarFoto(usuarioContext.getUsuarioAutenticado(), foto.getOriginalFilename(),
                foto.getSize(), foto::getInputStream);
    }

    @DeleteMapping("/perfil/foto")
    public PerfilDto quitarFoto() {
        return perfilService.quitarFoto(usuarioContext.getUsuarioAutenticado());
    }

    @GetMapping("/usuarios/{id}/foto")
    public ResponseEntity<InputStreamResource> foto(@PathVariable String id) {
        return perfilService.abrirFoto(id)
                .map(f -> ResponseEntity.ok()
                        .contentType(MediaType.parseMediaType(f.contentType()))
                        .header("X-Content-Type-Options", "nosniff")
                        .header(HttpHeaders.CONTENT_DISPOSITION, "inline")
                        // La URL del perfil lleva ?v=<archivo>, así que puede guardarse en caché sin servir fotos viejas.
                        .cacheControl(CacheControl.maxAge(Duration.ofHours(1)).cachePrivate())
                        .body(new InputStreamResource(f.flujo())))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @ExceptionHandler(DocumentoInvalidoException.class)
    public ResponseEntity<Map<String, String>> fotoInvalida(DocumentoInvalidoException e) {
        return error(HttpStatus.BAD_REQUEST, e.getMessage());
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<Map<String, String>> fotoMuyPesada(MaxUploadSizeExceededException e) {
        return error(HttpStatus.PAYLOAD_TOO_LARGE, "La foto debe pesar máximo 5 MB");
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> datosInvalidos(MethodArgumentNotValidException e) {
        String mensaje = e.getBindingResult().getFieldErrors().stream()
                .map(f -> f.getDefaultMessage()).sorted().collect(Collectors.joining("; "));
        return error(HttpStatus.BAD_REQUEST, mensaje.isBlank() ? "Datos inválidos" : mensaje);
    }

    private static ResponseEntity<Map<String, String>> error(HttpStatus estado, String mensaje) {
        return ResponseEntity.status(estado).body(Map.of("error", mensaje, "message", mensaje));
    }
}
