package com.example.MotvirsWeb.aplicacion.herramientas;

import org.springframework.ai.tool.annotation.Tool;
import org.springframework.stereotype.Service;

/**
 * MCP Tools para el chatbot NEXA.
 *
 * Esta clase expone herramientas (tools) que el LLM (Gemini) puede invocar
 * dinámicamente durante una conversación para obtener información pública de
 * NEXA.
 *
 * IMPORTANTE: Solo se expone información de carácter PÚBLICO, es decir,
 * la misma información visible en las páginas públicas (index.html y
 * home_conductor.html).
 * NO se expone información privada de la base de datos (estadísticas, usuarios,
 * servicios, etc.).
 *
 * Patrón: MCP Server In-Process (Model Context Protocol)
 */
@Service
public class NexaTools {

        // ==================== TOOLS PÚBLICOS ====================

        @Tool(description = "Consulta la información de contacto de NEXA: " +
                        "email, teléfono, horarios de atención al cliente y sitio web oficial")
        public String consultarInfoContacto() {
                return """
                                Información de contacto de NEXA:
                                - Email: nexabikeservice@gmail.com
                                - Teléfono: (+57) 986-4763477
                                - Horarios: Lunes a Viernes de 8:00 AM a 6:00 PM, Sábado y Domingo de 10:00 AM a 3:00 PM
                                - Web: www.NEXA.com

                                Equipo directivo:
                                - Mateo Vanegas: Fundador y CEO
                                - Weider Navarro: Gerente de Infraestructura de Datos
                                - Frank Salcedo: Coordinador de Diseño Visual
                                - Ferney: Director en Servicio al Cliente
                                """;
        }

        @Tool(description = "Consulta los beneficios exclusivos del programa para conductores NEXA: " +
                        "bonificaciones por carreras, programa conductor fiel con premios, " +
                        "y revisiones tecnomecánicas gratuitas. Información pública visible en la página de conductores.")
        public String consultarBeneficiosConductor() {
                return """
                                Beneficios Exclusivos para Conductores NEXA:

                                1. Bono por Carreras: Por cada 10 carreras completadas, el conductor obtiene una bonificación especial.

                                2. Programa Conductor Fiel: Disfruta de premios como cambio de aceite, descuentos en papeles (SOAT, tecnomecánica), entre otros beneficios exclusivos.

                                3. Revisión Tecnomecánica Gratuita: Siendo un conductor ejemplar con buenas calificaciones, recibes revisión tecnomecánica gratuita cada 6 meses.
                                """;
        }

        @Tool(description = "Consulta los servicios y beneficios disponibles para pasajeros de NEXA: " +
                        "reservas de viajes, seguimiento en tiempo real, calificaciones, " +
                        "métodos de pago, promociones y programa de usuario fiel. " +
                        "Información pública visible en la página principal de pasajeros.")
        public String consultarServiciosPasajero() {
                return """
                                Servicios para Pasajeros NEXA:

                                === SERVICIOS ===
                                - Reserva de Viajes: Solicita y reserva viajes en moto fácilmente, eligiendo destino y tipo de moto.
                                - Seguimiento en Tiempo Real: Rastrea la ubicación de tu conductor en vivo para mayor seguridad.
                                - Calificaciones y Reseñas: Califica a los conductores y deja reseñas sobre tu experiencia.
                                - Pagos Seguros: Tarjetas de crédito, débito o billeteras digitales.
                                - Asistencia en Ruta: Servicio de asistencia en carretera durante el viaje.

                                === BENEFICIOS ===
                                - Promociones: Cada viernes y festivos, descuentos del 20%% al 45%% en todos los viajes.
                                - Usuario Fiel: Después de 2 meses usando NEXA, accede al programa de afiliados. Invita personas y recibe cupones. Después de 1 año, tu invitado tiene su primer viaje gratis y tú también (disponible durante 3 días).
                                - Contenido Exclusivo: Artículos, tutoriales y consejos sobre seguridad, técnicas de conducción y más.
                                """;
        }

        @Tool(description = "Consulta la historia, misión y visión de NEXA, " +
                        "el servicio de mototaxis en Cartagena, Colombia. " +
                        "Información pública visible en ambas páginas.")
        public String consultarSobreNexa() {
                return """
                                Sobre NEXA:

                                HISTORIA: NEXA comenzó con una idea simple: brindar transporte rápido, seguro y accesible. Empezó con un solo casco extra y una moto, ofreciendo viajes a amigos y conocidos. El boca a boca lo convirtió en un servicio confiable que muchas personas eligen día a día. Fundada en 2023 en Cartagena.

                                MISIÓN: Ofrecer un servicio de moto taxi rápido, seguro y accesible, con conductores capacitados y motos en óptimas condiciones. Ser una alternativa que ahorra tiempo, reduce el tráfico y mejora la vida de los usuarios.

                                VISIÓN: Convertirse en el servicio de moto taxi más confiable y reconocido de Cartagena, integrando tecnología para mejorar la experiencia, optimizando rutas y promoviendo movilidad ágil y sostenible.
                                """;
        }

        @Tool(description = "Consulta información sobre el registro e inicio de sesión en NEXA " +
                        "para pasajeros y conductores. Información pública visible en las páginas.")
        public String consultarRegistroLogin() {
                return """
                                Registro e Inicio de Sesión en NEXA:
                                - Los usuarios pueden registrarse y iniciar sesión desde la página.
                                - Los pasajeros pueden acceder a la sección de Conductor desde el menú.
                                - Los conductores pueden acceder a la sección de Pasajero desde el menú.
                                - Eslogan: "Evita el tráfico y ahorra tiempo con nuestro servicio de moto."
                                """;
        }
}