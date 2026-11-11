package com.example.MotvirsWeb.presentacion.api;

import com.example.MotvirsWeb.presentacion.dto.NivelDto;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Usuario;
import com.example.MotvirsWeb.aplicacion.servicio.NivelesService;
import com.example.MotvirsWeb.aplicacion.util.UsuarioContextHelper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;


/**
 * Niveles y XP para pasajero y conductor. Cae bajo {@code /api/**}: requiere autenticación
 * (sesión o JWT) y el rol se valida aquí.
 */
@RestController
@RequestMapping("/api/niveles")
@RequiredArgsConstructor
public class ApiNivelesController {

    private final NivelesService nivelesService;
    private final UsuarioContextHelper usuarioContext;

    @GetMapping("/me")
    public ResponseEntity<NivelDto> me(@RequestParam(required = false) String rol) {
        Usuario usuario = usuarioContext.getUsuarioAutenticado();
        boolean esConductor = usuario instanceof Conductor;
        if (!esConductor && !(usuario instanceof Pasajero)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Solo pasajeros y conductores tienen niveles");
        }
        if (rol != null && !rol.equalsIgnoreCase(esConductor ? "conductor" : "pasajero")) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "El rol solicitado no corresponde a tu cuenta");
        }
        return ResponseEntity.ok(nivelesService.estado(usuario));
    }

    /** Desglose del cobro de un viaje, en la versión que corresponde al rol de quien pregunta. */
    @GetMapping("/viajes/{servicioId}/desglose")
    public ResponseEntity<Object> desglose(@PathVariable String servicioId) {
        return ResponseEntity.ok(nivelesService.desgloseParaUsuario(servicioId, usuarioContext.getUsuarioAutenticado()));
    }

    @PutMapping("/favoritos/{conductorId}")
    public ResponseEntity<Void> agregarFavorito(@PathVariable String conductorId) {
        nivelesService.cambiarFavorito(usuarioContext.getPasajeroAutenticado(), conductorId, true);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/favoritos/{conductorId}")
    public ResponseEntity<Void> quitarFavorito(@PathVariable String conductorId) {
        nivelesService.cambiarFavorito(usuarioContext.getPasajeroAutenticado(), conductorId, false);
        return ResponseEntity.noContent().build();
    }
}
