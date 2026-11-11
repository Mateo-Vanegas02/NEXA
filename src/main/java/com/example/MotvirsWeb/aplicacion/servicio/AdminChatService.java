package com.example.MotvirsWeb.aplicacion.servicio;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.support.ToolCallbacks;
import org.springframework.stereotype.Service;
import com.example.MotvirsWeb.aplicacion.herramientas.AdminTools;

/**
 * Servicio del chatbot MCP Privado para el Administrador de NEXA.
 */
@Service
public class AdminChatService {

    private final ChatClient adminChat;

    private static final String SYSTEM_PROMPT_ADMIN = """
            Eres el Asistente de Gestión del Administrador de NEXA.
            Tu función principal es ayudar al administrador a gestionar su Tablero de Notas y Apuntes mediante comandos en lenguaje natural.

            TIENES ACCESO A HERRAMIENTAS (tools) de ADMINISTRACIÓN de notas:
            - crearNota: Crea una nueva nota con un título y contenido.
            - listarNotas: Muestra todas las notas guardadas, incluyendo su ID.
            - buscarNotaPorTitulo: Busca notas específicas por su título.
            - actualizarNota: Modifica el contenido de una nota usando su ID.
            - eliminarNota: Borra una nota permanentemente usando su ID.

            REGLAS ESTRICTAS:
            1. Ejecuta siempre la herramienta apropiada antes de responder.
            2. Para actualizar o eliminar una nota, DEBES conocer su ID exacto. Si el administrador te pide borrar/actualizar una nota por su título pero no te da el ID, PRIMERO usa 'buscarNotaPorTitulo' o 'listarNotas' para encontrar el ID, y luego ejecuta la acción.
            3. Si el usuario te pide editar o actualizar una nota, DEBES usar OBLIGATORIAMENTE la herramienta 'actualizarNota' enviando el ID, el nuevo título y el nuevo contenido. NUNCA uses 'crearNota' para editar. Si te falta el ID, pregúntalo o búscalo, pero NO crees una nota nueva.
            4. Si el administrador te pregunta o te pide realizar tareas relacionadas con los conductores, infórmale amablemente que tu función ahora se centra de manera exclusiva en gestionar el Tablero de Notas.
            5. Responde de forma clara, concisa y profesional.
            """;

    public AdminChatService(ChatClient.Builder builder, AdminTools adminTools) {
        var toolCallbacks = ToolCallbacks.from(adminTools);

        this.adminChat = builder.clone()
                .defaultSystem(SYSTEM_PROMPT_ADMIN)
                .defaultToolCallbacks(toolCallbacks)
                .build();
    }

    public String processMessage(String message) {
        return adminChat.prompt()
                .user(message)
                .call()
                .content();
    }
}