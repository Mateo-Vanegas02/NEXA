package com.example.MotvirsWeb.presentacion.api;

import com.example.MotvirsWeb.aplicacion.servicio.DispositivosService;
import com.example.MotvirsWeb.aplicacion.util.UsuarioContextHelper;
import com.example.MotvirsWeb.presentacion.dto.DispositivoRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * La app registra el token de FCM del teléfono para recibir avisos push ({@code PUT}, al iniciar sesión y cuando
 * FCM lo rota) y lo quita al cerrar sesión ({@code DELETE}). Ambos responden 204.
 */
@RestController
@RequestMapping("/api/dispositivos")
@RequiredArgsConstructor
public class ApiDispositivosController {

    private final DispositivosService dispositivos;
    private final UsuarioContextHelper usuarioContext;

    @PutMapping
    public ResponseEntity<Void> registrar(@Valid @RequestBody DispositivoRequest peticion) {
        dispositivos.registrar(usuarioContext.getUsuarioAutenticado(), peticion.token(), peticion.plataforma());
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping
    public ResponseEntity<Void> eliminar(@Valid @RequestBody DispositivoRequest peticion) {
        dispositivos.eliminar(usuarioContext.getUsuarioAutenticado(), peticion.token());
        return ResponseEntity.noContent().build();
    }
}
