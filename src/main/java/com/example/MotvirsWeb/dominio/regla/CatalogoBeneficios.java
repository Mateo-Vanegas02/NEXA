package com.example.MotvirsWeb.dominio.regla;

import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * Escalera de beneficios del pasajero (tabla de la sección 10). El único beneficio en dinero es el descuento;
 * los demás son de servicio. Los números salen de la configuración, no del texto.
 */
@Component
public class CatalogoBeneficios {

    /** Beneficio que se agrega al llegar a {@code nivel}. */
    public record Beneficio(int nivel, String clave, String titulo, String descripcion) {
    }

    private final ModeloNexaProperties cfg;
    private final ModeloTarifa tarifa;
    private final PrioridadRecogida prioridad;

    public CatalogoBeneficios(ModeloNexaProperties cfg, ModeloTarifa tarifa, PrioridadRecogida prioridad) {
        this.cfg = cfg;
        this.tarifa = tarifa;
        this.prioridad = prioridad;
    }

    /** Beneficios que se agregan exactamente en {@code nivel}. */
    public List<Beneficio> delNivel(int nivel) {
        List<Beneficio> l = new ArrayList<>();
        double dto = tarifa.descuentoNivel(nivel);
        double dtoPrevio = tarifa.descuentoNivel(nivel - 1);
        if (nivel == 1) {
            l.add(new Beneficio(1, "XP", "Acumula XP", "Ves cuánto te falta para el siguiente nivel."));
        } else if (dto > dtoPrevio) {
            l.add(new Beneficio(nivel, "DESCUENTO", "Descuento del " + Math.round(dto * 100) + " %",
                    "En cada viaje, hasta $" + cfg.getDescuento().getTopeViaje() + " de descuento."));
        }
        int seg = prioridad.ventanaSegundos(nivel);
        if (nivel > 1 && seg > prioridad.ventanaSegundos(nivel - 1)) {
            l.add(new Beneficio(nivel, "PRIORIDAD", "Prioridad en la asignación",
                    "Durante " + seg + " s tu solicitud la ven primero los conductores con calificación de "
                            + cfg.getBeneficios().getCalificacionConductor() + " o más."));
        }
        if (nivel == cfg.getCancelacion().getNivelGraciaExtendida()) {
            l.add(new Beneficio(nivel, "CANCELACION", "Cancelación gratis más larga",
                    "Cancelas sin cargo hasta " + Math.round(cfg.getCancelacion().getGraciaExtendidaMinutos())
                            + " min después de que un conductor acepta."));
        }
        if (nivel == cfg.getBeneficios().getFavoritosDesdeNivel()) {
            l.add(new Beneficio(nivel, "FAVORITOS", "Conductores favoritos",
                    "Un favorito a menos de " + Math.round(cfg.getBeneficios().getFavoritoEtaMinutos())
                            + " min recibe tu solicitud primero."));
        }
        if (nivel == cfg.getBeneficios().getFavoritoAmpliadoDesdeNivel()) {
            l.add(new Beneficio(nivel, "FAVORITOS_AMPLIADO", "Favoritos más lejos",
                    "Tus favoritos a menos de " + Math.round(cfg.getBeneficios().getFavoritoAmpliadoEtaMinutos())
                            + " min reciben tu solicitud primero."));
        }
        if (nivel == 8) {
            l.add(new Beneficio(8, "SOPORTE", "Insignia y soporte prioritario",
                    "Tu insignia es visible y te atendemos primero."));
        }
        if (nivel == 9) {
            l.add(new Beneficio(9, "ACCESO_ANTICIPADO", "Acceso anticipado", "Pruebas las funciones nuevas antes que nadie."));
        }
        if (nivel == 10) {
            l.add(new Beneficio(10, "RECONOCIMIENTO", "Reconocimiento",
                    "Reconocemos tu nivel; sigues sumando sin techo."));
        }
        return l;
    }
}
