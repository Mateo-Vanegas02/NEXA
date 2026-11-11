package com.example.MotvirsWeb.presentacion.api;


import com.example.MotvirsWeb.presentacion.dto.LoginRequest;
import com.example.MotvirsWeb.presentacion.dto.LoginResponse;
import com.example.MotvirsWeb.aplicacion.puerto.EmisorTokens;
import com.example.MotvirsWeb.infraestructura.seguridad.LoginFailureHandler;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus; // Importar
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map; // Importar

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class ApiAuthController {

    private final AuthenticationManager authenticationManager;
    private final EmisorTokens emisorTokens;
    private final LoginFailureHandler loginFailureHandler;

    @PostMapping("/login")
    // Cambiamos a ResponseEntity<?> para poder devolver OK o Error
    public ResponseEntity<?> login(@jakarta.validation.Valid @RequestBody LoginRequest loginRequest) {

        // 1. Autenticar (verifica email y password)
        Authentication authentication;
        try {
            authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            loginRequest.getEmail(),
                            loginRequest.getPassword()
                    )
            );
        } catch (DisabledException e) {
            // Conductor sin aprobar: solo se le dice su estado si la contraseña es correcta
            // (igual que en el login web), para no revelar a un tercero qué correos son conductores.
            return loginFailureHandler
                    .estadoSiCredencialesValidas(loginRequest.getEmail(), loginRequest.getPassword())
                    .<ResponseEntity<?>>map(this::cuentaSinAprobar)
                    .orElseThrow(() -> new BadCredentialsException("Bad credentials"));
        }

        // 2. Obtener detalles del usuario
        UserDetails userDetails = (UserDetails) authentication.getPrincipal();

        // 3. Validación de rol: la app móvil es para pasajeros, conductores aprobados y administradores
        boolean usaLaApp = userDetails.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_PASAJERO")
                        || a.getAuthority().equals("ROLE_CONDUCTOR")
                        || a.getAuthority().equals("ROLE_ADMIN"));

        if (!usaLaApp) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN) // HTTP 403 Prohibido
                    .body(Map.of("error", "Acceso denegado. Tu cuenta no puede usar la app."));
        }

        // 4. Si el rol es válido, generamos y devolvemos el token
        String token = emisorTokens.generateToken(userDetails);
        return ResponseEntity.ok(new LoginResponse(token));
    }

    /** 403 con el estado de la cuenta del conductor (PENDIENTE, EN_REVISION o RECHAZADO) y el motivo si lo hay. */
    private ResponseEntity<?> cuentaSinAprobar(LoginFailureHandler.EstadoCuenta cuenta) {
        String mensaje = switch (cuenta.estado()) {
            case "RECHAZADO" -> "Tu solicitud fue rechazada.";
            case "EN_REVISION" -> "Tu solicitud está en revisión: el administrador te pidió más información.";
            default -> "Tu cuenta está pendiente de aprobación. Podrás iniciar sesión cuando te aprueben.";
        };
        Map<String, Object> cuerpo = new HashMap<>();
        cuerpo.put("error", mensaje);
        cuerpo.put("estadoValidacion", cuenta.estado());
        if (cuenta.motivo() != null) {
            cuerpo.put("motivo", cuenta.motivo());
        }
        if (cuenta.plazo() != null) {
            cuerpo.put("plazoRevision", cuenta.plazo().toString());
        }
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(cuerpo);
    }
}
