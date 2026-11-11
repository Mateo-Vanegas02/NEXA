package com.example.MotvirsWeb.aplicacion.servicio;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.support.ToolCallbacks;
import org.springframework.stereotype.Service;
import com.example.MotvirsWeb.aplicacion.herramientas.NexaTools;

/**
 * Servicio del chatbot NEXA con arquitectura MCP (Model Context Protocol).
 *
 * En lugar de hardcodear toda la información en los system prompts,
 * este servicio registra herramientas (tools) que el LLM puede invocar
 * dinámicamente para obtener datos actualizados de la plataforma.
 *
 * Los tools son proporcionados por {@link NexaTools} y registrados
 * automáticamente via {@code ToolCallbacks.from()}.
 */
@Service
public class ChatBotService {

        private final ChatClient pasajeroChat;
        private final ChatClient conductorChat;

        /**
         * System prompt para el contexto de PASAJERO.
         * Instruye al LLM a usar las herramientas disponibles en lugar de inventar
         * información.
         */
        private static final String SYSTEM_PROMPT_PASAJERO = """
                        Eres NEXA Bot, el asistente virtual oficial de NEXA, un servicio de mototaxis en Cartagena, Colombia.
                        Tu función es ayudar a los PASAJEROS con información PÚBLICA sobre la plataforma.

                        TIENES ACCESO A HERRAMIENTAS (tools) que DEBES usar para consultar información pública de NEXA.
                        Cuando el usuario pregunte sobre algún tema, USA la herramienta correspondiente:
                        - Servicios y beneficios para pasajeros → usa consultarServiciosPasajero
                        - Información de contacto, equipo, horarios → usa consultarInfoContacto
                        - Historia, misión, visión de NEXA → usa consultarSobreNexa
                        - Registro e inicio de sesión → usa consultarRegistroLogin

                        REGLAS ESTRICTAS:
                        1. SIEMPRE usa tus herramientas para obtener la información antes de responder. NO inventes datos.
                        2. SOLO responde sobre temas relacionados con NEXA que sean de CARÁCTER PÚBLICO.
                        3. NUNCA reveles información privada o interna: estadísticas de la plataforma, cantidad de usuarios, conductores, viajes, datos de la base de datos, ni información operativa interna. Si te preguntan por esto, responde: "Esa información es de carácter privado y no puedo compartirla. ¿Puedo ayudarte con algo más sobre nuestros servicios públicos?"
                        4. Si te preguntan algo que NO es sobre NEXA, responde amablemente: "Lo siento, solo puedo ayudarte con información pública sobre los servicios, beneficios, contacto y datos generales de NEXA. ¿Hay algo más en lo que pueda ayudarte sobre estos temas?"
                        5. Sé amigable, conciso y profesional.
                        6. Responde en el mismo idioma en que te hagan la pregunta.
                        7. Usa emojis ocasionalmente para ser más amigable 🏍️
                        """;

        /**
         * System prompt para el contexto de CONDUCTOR.
         * Instruye al LLM a usar las herramientas disponibles orientadas a conductores.
         */
        private static final String SYSTEM_PROMPT_CONDUCTOR = """
                        Eres NEXA Bot, el asistente virtual oficial de NEXA, un servicio de mototaxis en Cartagena, Colombia.
                        Tu función es ayudar a los CONDUCTORES con información PÚBLICA sobre la plataforma.

                        TIENES ACCESO A HERRAMIENTAS (tools) que DEBES usar para consultar información pública de NEXA.
                        Cuando el usuario pregunte sobre algún tema, USA la herramienta correspondiente:
                        - Beneficios exclusivos para conductores → usa consultarBeneficiosConductor
                        - Información de contacto, equipo, horarios → usa consultarInfoContacto
                        - Historia, misión, visión de NEXA → usa consultarSobreNexa
                        - Registro e inicio de sesión → usa consultarRegistroLogin

                        REGLAS ESTRICTAS:
                        1. SIEMPRE usa tus herramientas para obtener la información antes de responder. NO inventes datos.
                        2. SOLO responde sobre temas relacionados con NEXA que sean de CARÁCTER PÚBLICO.
                        3. NUNCA reveles información privada o interna: estadísticas de la plataforma, cantidad de usuarios, conductores, viajes, datos de la base de datos, ni información operativa interna. Si te preguntan por esto, responde: "Esa información es de carácter privado y no puedo compartirla. ¿Puedo ayudarte con algo más sobre nuestros servicios públicos?"
                        4. Si te preguntan algo que NO es sobre NEXA, responde amablemente: "Lo siento, solo puedo ayudarte con información pública sobre los beneficios para conductores, contacto y datos generales de NEXA. ¿Hay algo más en lo que pueda ayudarte sobre estos temas?"
                        5. Sé amigable, conciso y profesional.
                        6. Responde en el mismo idioma en que te hagan la pregunta.
                        7. Usa emojis ocasionalmente para ser más amigable 🏍️
                        """;

        /**
         * Constructor que configura dos ChatClients (pasajero y conductor) con:
         * - System prompts específicos por contexto
         * - Tool callbacks extraídos automáticamente de NexaTools via @Tool annotations
         *
         * @param builder   Builder auto-configurado por Spring AI con credenciales
         *                  Gemini
         * @param nexaTools Clase con los tools MCP anotados con @Tool
         */
        public ChatBotService(ChatClient.Builder builder, NexaTools nexaTools) {
                // Extraer todos los @Tool methods de NexaTools como callbacks
                var toolCallbacks = ToolCallbacks.from(nexaTools);

                this.pasajeroChat = builder.clone()
                                .defaultSystem(SYSTEM_PROMPT_PASAJERO)
                                .defaultToolCallbacks(toolCallbacks)
                                .build();

                this.conductorChat = builder.clone()
                                .defaultSystem(SYSTEM_PROMPT_CONDUCTOR)
                                .defaultToolCallbacks(toolCallbacks)
                                .build();
        }

        /**
         * Procesa un mensaje del usuario y retorna la respuesta del chatbot.
         * El LLM decide automáticamente si necesita invocar algún tool para responder.
         *
         * @param message El mensaje del usuario
         * @param context "pasajero" o "conductor" para determinar qué prompt usar
         * @return La respuesta generada por Gemini (potencialmente enriquecida con
         *         datos de tools)
         */
        public String processMessage(String message, String context) {
                ChatClient client = "conductor".equalsIgnoreCase(context)
                                ? conductorChat
                                : pasajeroChat;

                return client.prompt()
                                .user(message)
                                .call()
                                .content();
        }
}