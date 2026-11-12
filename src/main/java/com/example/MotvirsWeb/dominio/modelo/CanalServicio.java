package com.example.MotvirsWeb.dominio.modelo;

/**
 * Por dónde se pidió un viaje y por dónde se atiende. Un viaje pedido en la web se contesta en la web y uno pedido
 * en la app, en la app: cada canal tiene sus conductores y sus avisos (STOMP en la web, push en la app).
 */
public enum CanalServicio {
    WEB,
    APP;

    /** Los viajes guardados antes de existir el canal (null) se tratan como de la web. */
    public static CanalServicio oWeb(CanalServicio canal) {
        return canal == null ? WEB : canal;
    }

    /** Texto para avisar a quien intenta atender un viaje desde el otro canal. */
    public String mensajeOtroCanal() {
        return this == APP ? "Este viaje se pidió desde la app NEXA: atiéndelo desde la app."
                : "Este viaje se pidió desde la web: atiéndelo desde la web.";
    }
}
