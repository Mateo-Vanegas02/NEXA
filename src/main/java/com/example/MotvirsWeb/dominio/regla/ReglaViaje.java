package com.example.MotvirsWeb.dominio.regla;

import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Reglas puras del viaje en curso: cuándo el conductor puede finalizar, cuánto falta para llegar y qué puntos del
 * recorrido real vale la pena guardar. La posición siempre es la que conoce el servidor, no un dato del navegador.
 */
@Component
public class ReglaViaje {

    private final double radioDestinoMetros;
    private final boolean exigirDestino;
    private final double puntoMinimoMetros;
    private final int maxPuntos;
    private final double velocidadKmh;
    private final double factorRuta;
    private final double umbralCobroCompleto;
    private final double fraccionCobroAnticipado;

    public ReglaViaje(ModeloNexaProperties cfg) {
        this.radioDestinoMetros = cfg.getViaje().getRadioDestinoMetros();
        this.exigirDestino = cfg.getViaje().isExigirDestino();
        this.puntoMinimoMetros = cfg.getViaje().getPuntoMinimoMetros();
        this.maxPuntos = cfg.getViaje().getMaxPuntosRecorrido();
        this.velocidadKmh = cfg.getBeneficios().getVelocidadKmh();
        this.factorRuta = cfg.getRutas().getFactorRecta();
        this.umbralCobroCompleto = cfg.getViaje().getUmbralCobroCompleto();
        this.fraccionCobroAnticipado = cfg.getViaje().getFraccionCobroAnticipado();
    }

    public double radioDestinoMetros() {
        return radioDestinoMetros;
    }

    public boolean exigeDestino() {
        return exigirDestino;
    }

    public double distanciaMetros(PuntoGeo a, PuntoGeo b) {
        return a.distanciaKm(b) * 1000.0;
    }

    /** ¿Está el conductor lo bastante cerca del destino para finalizar? */
    public boolean enElDestino(PuntoGeo conductor, PuntoGeo destino) {
        return distanciaMetros(conductor, destino) <= radioDestinoMetros;
    }

    /**
     * Fracción del viaje que se cobra al finalizar. Llegando al destino (o sin datos para medir) se cobra completo;
     * si el conductor finaliza antes, con menos del umbral de la distancia planeada recorrida se cobra la fracción
     * anticipada (la mitad) y desde el umbral el viaje completo.
     *
     * @param enElDestino  el conductor está dentro del radio del destino
     * @param recorridoKm  kilómetros recorridos con el viaje en curso; null si no se pueden medir
     * @param planeadoKm   distancia del viaje cotizada
     */
    public double factorCobro(boolean enElDestino, Double recorridoKm, double planeadoKm) {
        if (enElDestino || recorridoKm == null || !Double.isFinite(recorridoKm) || planeadoKm <= 0) {
            return 1.0;
        }
        return recorridoKm / planeadoKm >= umbralCobroCompleto ? 1.0 : fraccionCobroAnticipado;
    }

    /** Kilómetros estimados por calle a partir de la línea recta (misma aproximación de la cotización). */
    public double kmPorCalle(PuntoGeo desde, PuntoGeo hasta) {
        return desde.distanciaKm(hasta) * factorRuta;
    }

    /** Minutos estimados para recorrer {@code km} a la velocidad urbana configurada (mínimo 1 si falta algo). */
    public int etaMinutos(double km) {
        if (km <= 0 || velocidadKmh <= 0) {
            return 0;
        }
        return (int) Math.max(1, Math.ceil(km / velocidadKmh * 60.0));
    }

    /** ¿Se guarda este punto del recorrido? Solo si avanzó lo suficiente y no se superó el tope. */
    public boolean debeGuardarPunto(PuntoGeo ultimo, PuntoGeo nuevo, int puntosGuardados) {
        if (puntosGuardados >= maxPuntos) {
            return false;
        }
        return ultimo == null || distanciaMetros(ultimo, nuevo) >= puntoMinimoMetros;
    }

    /** Kilómetros reales recorridos: suma de tramos entre puntos consecutivos. */
    public static double distanciaRecorridaKm(List<PuntoGeo> puntos) {
        double km = 0;
        for (int i = 1; i < puntos.size(); i++) {
            km += puntos.get(i - 1).distanciaKm(puntos.get(i));
        }
        return km;
    }
}
