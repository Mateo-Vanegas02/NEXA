package com.example.MotvirsWeb.dominio.regla;

import org.springframework.stereotype.Component;

/**
 * Reglas puras de precio del modelo NEXA v2.0 (secciones 4, 5, 7, 8 y 12 del documento).
 *
 * <pre>
 * T0 = 100 · round(max{T_min ; banderazo + por_km · D} / 100)
 * W  = valor_minuto · max{0 ; min{e ; e_max} − e_gracia}
 * Δ  = min{d_L · T0 ; tope ; max{0 ; M·T0 − T_min} ; max{0 ; (φ − m_min)·M·T0 − holgura}}
 * P  = 100 · round((M·T0 − Δ + W) / 100)
 * C  = (1 − φ) · M·T0 + W          (conductor)
 * I  = P − C = φ·M·T0 − Δ + r      (plataforma, r = residuo del redondeo)
 * </pre>
 * El dinero se maneja en pesos enteros: M·T0 se redondea al peso antes de repartir, así
 * C + I = P siempre se cumple exactamente.
 */
@Component
public class ModeloTarifa {

    /** Resultado completo del cobro de un viaje, en pesos. */
    public record Cobro(
            double distanciaKm,
            long tarifaBase,
            double multiplicador,
            long tarifaAjustada,
            int nivelPasajero,
            long descuento,
            long recargoEspera,
            long precio,
            double comisionPct,
            long montoConductor,
            long montoPlataforma,
            long residuo) {

        /** Margen de la plataforma sobre la tarifa ajustada (M·T0). */
        public double margen() {
            return tarifaAjustada == 0 ? 0 : (double) montoPlataforma / tarifaAjustada;
        }
    }

    /** Situación del viaje al momento de una cancelación del pasajero. */
    public record SituacionCancelacion(
            boolean aceptado,
            double minutosDesdeAceptacion,
            boolean conductorLlego,
            double minutosEsperando) {
    }

    private final ModeloNexaProperties cfg;

    public ModeloTarifa(ModeloNexaProperties cfg) {
        this.cfg = cfg;
    }

    /** Ecuación 1: tarifa base por distancia, redondeada a $100 y nunca menor que la mínima. */
    public long tarifaBase(double distanciaKm) {
        if (!Double.isFinite(distanciaKm) || distanciaKm < 0) {
            throw new IllegalArgumentException("Distancia inválida: " + distanciaKm);
        }
        ModeloNexaProperties.Tarifa t = cfg.getTarifa();
        double cruda = Math.max(t.getMinima(), t.getBanderazo() + t.getPorKm() * distanciaKm);
        return redondear(cruda);
    }

    /** Ecuación 2: recargo por espera; 0 si no hay registro de llegada (minutos null). */
    public long recargoEspera(Double minutosEsperando) {
        if (minutosEsperando == null || minutosEsperando <= 0) {
            return 0;
        }
        ModeloNexaProperties.Espera e = cfg.getEspera();
        double cobrables = Math.max(0, Math.min(minutosEsperando, e.getMaxMinutos()) - e.getGraciaMinutos());
        return Math.round(e.getValorMinuto() * cobrables);
    }

    /** Multiplicador vigente. En la fase de prueba es fijo (nexa.multiplicador.fijo). */
    public double multiplicador() {
        return Math.min(cfg.getMultiplicador().getMax(), Math.max(1.0, cfg.getMultiplicador().getFijo()));
    }

    /** Ecuación 20: descuento del nivel del pasajero (fracción). */
    public double descuentoNivel(int nivelPasajero) {
        ModeloNexaProperties.Descuento d = cfg.getDescuento();
        if (nivelPasajero < d.getNivelMin()) {
            return 0;
        }
        return Math.min(d.getPorNivel() * nivelPasajero, d.getMax());
    }

    /** Comisión de la plataforma según el nivel del conductor (1..5; fuera de rango se acota). */
    public double comision(int nivelConductor) {
        double[] tabla = cfg.getComision().getPorNivel();
        int i = Math.max(1, Math.min(nivelConductor, tabla.length)) - 1;
        return tabla[i];
    }

    /** Comisión más baja de la tabla: el peor caso para el margen al cotizar. */
    public double comisionMinima() {
        double min = Double.MAX_VALUE;
        for (double c : cfg.getComision().getPorNivel()) {
            min = Math.min(min, c);
        }
        return min;
    }

    /** Ecuación 7: descuento efectivo en pesos (recortado por tope, tarifa mínima y margen). */
    public long descuentoEfectivo(long tarifaBase, long tarifaAjustada, int nivelPasajero, double comision) {
        ModeloNexaProperties.Descuento d = cfg.getDescuento();
        ModeloNexaProperties.Margen m = cfg.getMargen();
        double porNivel = descuentoNivel(nivelPasajero) * tarifaBase; // d_L · T0 (ecuación 7: sobre T0, no sobre M·T0)
        double sobreMinima = Math.max(0, tarifaAjustada - cfg.getTarifa().getMinima());
        double porMargen = Math.max(0, (comision - m.getMinimo()) * tarifaAjustada - m.getHolguraRedondeo());
        double delta = Math.min(Math.min(porNivel, d.getTopeViaje()), Math.min(sobreMinima, porMargen));
        // Hacia abajo: un peso de más de descuento podría romper el margen mínimo.
        return (long) Math.floor(delta + 1e-9);
    }

    /**
     * Cobro completo (ecuaciones 7 a 11).
     *
     * @param distanciaKm      distancia de la ruta cotizada (D)
     * @param multiplicador    M (1.0 en la fase de prueba)
     * @param nivelPasajero    nivel L del pasajero (desde 1)
     * @param comision         φ del conductor; al cotizar, la mínima de la tabla
     * @param minutosEsperando minutos que esperó el conductor tras llegar (null si no aplica)
     */
    public Cobro cobrar(double distanciaKm, double multiplicador, int nivelPasajero, double comision,
            Double minutosEsperando) {
        if (multiplicador < 1.0 || multiplicador > cfg.getMultiplicador().getMax()) {
            throw new IllegalArgumentException("Multiplicador fuera de rango: " + multiplicador);
        }
        long t0 = tarifaBase(distanciaKm);
        long ajustada = Math.round(multiplicador * t0);
        long descuento = descuentoEfectivo(t0, ajustada, nivelPasajero, comision);
        long espera = recargoEspera(minutosEsperando);
        long sinRedondeo = ajustada - descuento + espera;
        long precio = redondear(sinRedondeo);
        long conductor = Math.round((1 - comision) * ajustada) + espera;
        long plataforma = precio - conductor;
        return new Cobro(distanciaKm, t0, multiplicador, ajustada, nivelPasajero, descuento, espera, precio,
                comision, conductor, plataforma, precio - sinRedondeo);
    }

    /** Cobro de la fase de prueba: multiplicador vigente y sin espera. */
    public Cobro cotizar(double distanciaKm, int nivelPasajero) {
        return cobrar(distanciaKm, multiplicador(), nivelPasajero, comisionMinima(), null);
    }

    /**
     * Ecuación 25: cargo al pasajero que cancela, en pesos. Va completo al conductor.
     * <pre>
     * Q = 0                       antes de aceptar, o dentro de la gracia tras aceptar
     * Q = 20 % · T0               pasada la gracia y antes de que llegue el conductor
     * Q = max{20 % · T0 ; W(e)}   si el conductor ya llegó y lleva e minutos esperando
     * </pre>
     * No tiene tope: depende del servicio. Se paga el cargo o la espera, nunca los dos.
     *
     * @param tarifaBase T0 del servicio cancelado (sin multiplicador ni descuento)
     */
    public long cargoCancelacion(int nivelPasajero, long tarifaBase, SituacionCancelacion s) {
        if (tarifaBase < 0) {
            throw new IllegalArgumentException("Tarifa base inválida: " + tarifaBase);
        }
        ModeloNexaProperties.Cancelacion c = cfg.getCancelacion();
        if (!s.aceptado()) {
            return 0;
        }
        double gracia = nivelPasajero >= c.getNivelGraciaExtendida()
                ? c.getGraciaExtendidaMinutos()
                : c.getGraciaMinutos();
        if (s.minutosDesdeAceptacion() <= gracia) {
            return 0;
        }
        long porcentaje = Math.round(c.getPorcentaje() * tarifaBase);
        if (!s.conductorLlego()) {
            return porcentaje;
        }
        return Math.max(porcentaje, recargoEspera(s.minutosEsperando()));
    }

    private long redondear(double valor) {
        long paso = cfg.getTarifa().getRedondeo();
        return paso * Math.round(valor / paso);
    }
}
