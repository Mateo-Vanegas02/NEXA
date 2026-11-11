package com.example.MotvirsWeb.aplicacion.puerto;

/**
 * Puerto de salida: envío de correos. La aplicación depende de esta interfaz; el proveedor
 * concreto (SMTP/Gmail) vive en infraestructura.
 */
public interface NotificadorCorreo {

    /** Reenvía al buzón de soporte un mensaje enviado desde el formulario de contacto. */
    void enviarMensajeContacto(String nombre, String email, String mensaje);

    /** Envía al usuario el enlace para restablecer su contraseña. */
    void enviarCorreoRecuperacion(String emailDestino, String token);

    /** Avisa al conductor qué información adicional debe enviar y hasta cuándo. */
    void enviarSolicitudInformacion(String emailDestino, String nombre, String mensaje, java.time.LocalDate plazo);

    /** Avisa al conductor que su solicitud se rechazó por no responder dentro del plazo. */
    void enviarRechazoPorPlazo(String emailDestino, String nombre);

    /** Avisa al pasajero que, si no viaja antes de esa fecha, bajará al nivel anterior. */
    void enviarAvisoInactividad(String emailDestino, String nombre, int nivelActual, java.time.LocalDate baja);

    /** Avisa al pasajero que se le perdonó su deuda por cancelación. */
    void enviarDeudaCondonada(String emailDestino, String nombre, long monto, String motivo);

    /** Avisa al pasajero que su deuda se cobrará junto con el próximo viaje que pida. */
    void enviarDeudaSeCobraEnProximoViaje(String emailDestino, String nombre, long monto);
}
