package com.example.MotvirsWeb.aplicacion.puerto;

import java.time.Duration;
import java.util.Collection;
import java.util.Map;

/**
 * Puerto de salida: avisos push al teléfono (FCM). La implementación vive en infraestructura/push.
 *
 * <p>Reglas: el aviso lleva solo lo que puede ver quien lo recibe (el texto se arma por destinatario) y el id del
 * evento para que la app ignore repetidos; el detalle lo pide la app a la API con su token, que pasa por
 * {@code VisibilidadServicio}. Enviar nunca lanza ni bloquea el flujo de negocio.
 */
public interface NotificadorPush {

    /** Encola el aviso para esos tokens; vuelve de inmediato. */
    void enviar(Collection<String> tokens, Aviso aviso);

    /**
     * Envía y espera la confirmación del proveedor. Intenta todos los tokens; si alguno no se confirmó lanza
     * {@link EnvioIncompleto} con esos tokens, para que la bandeja persistente reintente solo esos.
     */
    default void enviarConConfirmacion(Collection<String> tokens, Aviso aviso) {
        enviar(tokens, aviso);
    }

    /** El proveedor no confirmó el envío a estos tokens (los demás sí se entregaron). */
    final class EnvioIncompleto extends RuntimeException {
        private final java.util.Set<String> tokensFallidos;

        public EnvioIncompleto(Collection<String> tokensFallidos) {
            super("El proveedor no confirmó " + tokensFallidos.size() + " envío(s)");
            this.tokensFallidos = java.util.Set.copyOf(new java.util.LinkedHashSet<>(tokensFallidos));
        }

        public java.util.Set<String> tokensFallidos() {
            return tokensFallidos;
        }
    }

    /** false si el servidor no tiene credenciales de Firebase (los avisos se descartan). */
    boolean activo();

    /**
     * Canal de notificación de Android: decide prioridad, sonido y si el usuario puede silenciarlo.
     * {@link #SOLICITUDES} y {@link #SILENCIOSO} viajan solo como datos: la app arma la notificación (con botones y
     * cuenta regresiva) o actualiza su estado sin mostrar nada.
     */
    enum Canal {
        SOLICITUDES("nexa_solicitudes", true, true),
        VIAJE("nexa_viaje", true, false),
        CUENTA("nexa_cuenta", false, false),
        SILENCIOSO(null, false, true);

        private final String idAndroid;
        private final boolean urgente;
        private final boolean soloDatos;

        Canal(String idAndroid, boolean urgente, boolean soloDatos) {
            this.idAndroid = idAndroid;
            this.urgente = urgente;
            this.soloDatos = soloDatos;
        }

        public String idAndroid() {
            return idAndroid;
        }

        public boolean urgente() {
            return urgente;
        }

        public boolean soloDatos() {
            return soloDatos;
        }
    }

    /**
     * @param eventoId  único por evento y destinatario: la app descarta los repetidos
     * @param tipo      código del evento (p. ej. {@code VIAJE_ACEPTADO}); la app decide a qué pantalla ir
     * @param canal     canal de Android
     * @param titulo    texto corto (null en los silenciosos)
     * @param cuerpo    detalle (null en los silenciosos)
     * @param datos     ids que la app necesita para abrir la pantalla (servicioId…); nunca montos ajenos
     * @param vigencia  pasado este tiempo FCM lo descarta (una solicitud vieja no sirve)
     */
    record Aviso(String eventoId, String tipo, Canal canal, String titulo, String cuerpo, Map<String, String> datos,
            Duration vigencia) {

        public Aviso {
            datos = datos == null ? Map.of() : Map.copyOf(datos);
        }
    }
}
