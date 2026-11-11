package com.example.MotvirsWeb.infraestructura.correo;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Slf4j
@Service
public class EmailService implements NotificadorCorreo {

    @Autowired
    private JavaMailSender mailSender;

    @Value("${app.base-url:}") // El valor puede estar vacío
    private String configuredBaseUrl;

    // Inyectamos el correo configurado para saber a dónde enviar las notificaciones
    @Value("${spring.mail.username}")
    private String myEmail;

    @Override
    public void enviarMensajeContacto(String nombre, String correoUsuario, String mensaje) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();

            // Quien lo envía (protocolo SMTP requiere que sea tu mismo correo autenticado)
            message.setFrom(myEmail);

            // A quien le llega (A ti mismo, o al departamento de soporte)
            message.setTo(myEmail);

            message.setSubject("NEXA - Nuevo mensaje de: " + nombre);

            message.setText("Has recibido un nuevo mensaje desde la web de NEXA:\n\n" +
                    "Nombre: " + nombre + "\n" +
                    "Correo del usuario: " + correoUsuario + "\n\n" +
                    "Mensaje:\n" + mensaje);

            mailSender.send(message);
            log.info("Correo de contacto enviado");

        } catch (Exception e) {
            log.error("Error enviando correo de contacto: {}", e.getClass().getSimpleName());
            // Aquí podrías lanzar una excepción personalizada si quisieras manejarlo en el controller
        }
    }
    private String getBaseUrl() {
        // 1. Si baseUrl está configurado explícitamente, úsalo
        if (StringUtils.hasText(configuredBaseUrl)) {
            return configuredBaseUrl;
        }

        // 2. Detectar si estamos en Azure App Service
        String azureWebsiteHostname = System.getenv("WEBSITE_HOSTNAME");
        if (azureWebsiteHostname != null && !azureWebsiteHostname.isEmpty()) {
            // Ya estás en Azure, usa HTTPS
            return "https://" + azureWebsiteHostname;
        }

        // 3. Por defecto para desarrollo local
        return "http://localhost:8080/";
    }
    @Override
    public void enviarCorreoRecuperacion(String emailDestino, String token) {
        try {
            // 1. Aquí usamos tu método getBaseUrl() para asegurar que sea HTTPS en Azure
            String baseUrl = getBaseUrl();

            // 2. Construimos el link completo
            String urlReset = baseUrl + "/auth/reset-password?token=" + token;

            SimpleMailMessage message = new SimpleMailMessage();

            // From: Tu sistema
            message.setFrom(myEmail);

            // To: El usuario que perdió la contraseña (NO tú)
            message.setTo(emailDestino);

            message.setSubject("NEXA - Restablecer Contraseña");

            message.setText("Hola,\n\n" +
                    "Para restablecer tu contraseña en NEXA, haz clic en el siguiente enlace:\n\n" +
                    urlReset + "\n\n" +  // <--- ¡AQUÍ ESTÁ LA SOLUCIÓN!
                    "Este enlace expira en 30 minutos.\n" +
                    "Si no solicitaste esto, ignora este mensaje.");

            mailSender.send(message);
            log.info("Correo de recuperación enviado");

        } catch (Exception e) {
            log.error("Error enviando correo de recuperación: {}", e.getClass().getSimpleName());
            // Opcional: lanzar excepción para que el Controller se entere
        }
    }

    @Override
    public void enviarSolicitudInformacion(String emailDestino, String nombre, String mensaje, java.time.LocalDate plazo) {
        enviar(emailDestino, "NEXA - Necesitamos más información para tu solicitud",
                "Hola " + (nombre == null ? "" : nombre) + ",\n\n"
                + "Estamos revisando tu solicitud como conductor y necesitamos lo siguiente:\n\n"
                + mensaje + "\n\n"
                + "Responde a este correo (" + myEmail + ") a más tardar el " + plazo + ".\n"
                + "Si no recibimos respuesta en ese plazo, la solicitud se rechazará automáticamente.");
    }

    @Override
    public void enviarRechazoPorPlazo(String emailDestino, String nombre) {
        enviar(emailDestino, "NEXA - Tu solicitud de conductor fue rechazada",
                "Hola " + (nombre == null ? "" : nombre) + ",\n\n"
                + "No recibimos la información solicitada dentro del plazo, por lo que tu solicitud fue rechazada.\n"
                + "Puedes volver a registrarte cuando quieras.");
    }

    @Override
    public void enviarAvisoInactividad(String emailDestino, String nombre, int nivelActual,
            java.time.LocalDate baja) {
        enviar(emailDestino, "NEXA - Tu nivel " + nivelActual + " baja pronto",
                "Hola " + (nombre == null ? "" : nombre) + ",\n\n"
                + "Hace tiempo que no viajas con NEXA. Si no pides un viaje antes del "
                + baja + ", bajarás al nivel " + Math.max(1, nivelActual - 1)
                + " y perderás los beneficios de tu nivel actual.\n\n"
                + "Con un solo viaje conservas tu nivel.");
    }

    @Override
    public void enviarDeudaCondonada(String emailDestino, String nombre, long monto, String motivo) {
        enviar(emailDestino, "NEXA - Tu deuda fue perdonada",
                "Hola " + (nombre == null ? "" : nombre) + ",\n\n"
                + "Revisamos tu caso y perdonamos el cargo de " + pesos(monto) + " por cancelación.\n"
                + (motivo == null || motivo.isBlank() ? "" : "Motivo: " + motivo + "\n")
                + "\nYa puedes pedir viajes con normalidad.");
    }

    @Override
    public void enviarDeudaSeCobraEnProximoViaje(String emailDestino, String nombre, long monto) {
        enviar(emailDestino, "NEXA - Cargo por cancelación",
                "Hola " + (nombre == null ? "" : nombre) + ",\n\n"
                + "Se registró un cargo de " + pesos(monto) + " por la cancelación de tu viaje.\n"
                + "Se sumará al pago en efectivo del próximo viaje que pidas: antes de confirmarlo verás "
                + "el total exacto y podrás decidir.\n\n"
                + "Si crees que fue un error, escríbenos y lo revisamos.");
    }

    private static String pesos(long monto) {
        return "$" + java.text.NumberFormat.getIntegerInstance(
                java.util.Locale.forLanguageTag("es-CO")).format(monto);
    }

    private void enviar(String destino, String asunto, String texto) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(myEmail);
            message.setTo(destino);
            message.setSubject(asunto);
            message.setText(texto);
            mailSender.send(message);
            log.info("Correo de revisión enviado");
        } catch (Exception e) {
            log.error("Error enviando correo de revisión: {}", e.getClass().getSimpleName());
        }
    }
}
