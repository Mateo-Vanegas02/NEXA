package com.example.MotvirsWeb.presentacion.api;

import com.example.MotvirsWeb.presentacion.dto.ChatRequestDto;
import com.example.MotvirsWeb.presentacion.dto.ChatResponseDto;
import com.example.MotvirsWeb.aplicacion.servicio.AdminChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Endpoint para el chatbot privado del Administrador.
 * Protegido automáticamente por SecurityConfig ya que está bajo /api/admin/**
 */
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminChatController {

    private final AdminChatService adminChatService;

    @PostMapping("/chat")
    public ResponseEntity<ChatResponseDto> chat(@RequestBody ChatRequestDto request) {
        try {
            String response = adminChatService.processMessage(request.message());
            if (response == null || response.trim().isEmpty()) {
                response = "Acción completada con éxito en el tablero de notas.";
            }
            return ResponseEntity.ok(new ChatResponseDto(response));
        } catch (Exception e) {
            org.slf4j.LoggerFactory.getLogger(AdminChatController.class).error("Error en el chat de admin", e);
            return ResponseEntity.status(500)
                    .body(new ChatResponseDto("Error procesando la solicitud. Intenta de nuevo."));
        }
    }
}