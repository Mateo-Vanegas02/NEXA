package com.example.MotvirsWeb.presentacion.dto;

/**
 * DTO para transferir la pregunta del usuario desde el frontend al backend.
 * Contiene el mensaje del usuario y el contexto (pasajero/conductor)
 * para determinar qué system prompt utilizar en la comunicación con el LLM.
 *
 * @param message El mensaje o pregunta del usuario
 * @param context El contexto de la conversación: "pasajero" o "conductor"
 */
public record ChatRequestDto(
        String message,
        String context
) {
    /** Tope de caracteres por mensaje (controla el coste de tokens de la IA). */
    public static final int MAX_MENSAJE = 1000;

    /**
     * Constructor que asigna valores por defecto si son nulos.
     */
    public ChatRequestDto {
        if (message == null) message = "";
        if (message.length() > MAX_MENSAJE) message = message.substring(0, MAX_MENSAJE);
        if (!"conductor".equals(context)) context = "pasajero";
    }
}
