package com.example.MotvirsWeb.dominio.regla;

import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Reglas puras de XP y niveles del modelo NEXA v2.0 (secciones 9, 10, 11 y 13 del documento).
 *
 * <pre>
 * XP_pasajero  = V · A(n_día) · F(e) · [fijo + por_mil · min{T0 ; tope}/1000 + por_bloque · min{B ; tope_B}]
 * XP_conductor = V · G(c) · [la misma base]
 * B            = 10 · D_xp,   D_xp = min{D ; factor_rodeo · D_recta}
 * X_n          = 10 · round(base · (n − 1)^exp / 10)     (pasajero, sin techo)
 * X_n^c        = base_c · (n − 1)²                       (conductor, XP de 90 días)
 * </pre>
 * Los niveles empiezan en 1. El XP se guarda con un decimal.
 */
@Component
public class ModeloXp {

    /** Hechos de un viaje que deciden si da XP (ecuación 16). */
    public record Viaje(
            boolean finalizado,
            double minutos,
            double distanciaKm,
            double distanciaRectaKm,
            int viajesParejaDia) {
    }

    public record Requisito(String texto, boolean cumplido) {
    }

    private final ModeloNexaProperties cfg;

    public ModeloXp(ModeloNexaProperties cfg) {
        this.cfg = cfg;
    }

    // ------------------------------------------------------------------ viaje

    /** Ecuación 26: distancia válida para el XP, acotada contra rodeos. */
    public double distanciaXp(double distanciaKm, double distanciaRectaKm) {
        return Math.min(distanciaKm, cfg.getXp().getFactorRodeo() * distanciaRectaKm);
    }

    /** Ecuación 16: el viaje cuenta para XP (estado, duración, distancia y pareja del día). */
    public boolean valido(Viaje v) {
        ModeloNexaProperties.Xp x = cfg.getXp();
        return v.finalizado()
                && v.minutos() >= x.getMinMinutos()
                && distanciaXp(v.distanciaKm(), v.distanciaRectaKm()) >= x.getMinKm()
                && v.viajesParejaDia() <= x.getMaxViajesParejaDia();
    }

    /** Parte entre corchetes de las ecuaciones 14 y 22. */
    public double xpBase(long tarifaBase, double distanciaXpKm) {
        ModeloNexaProperties.Xp x = cfg.getXp();
        double bloques = Math.min(10 * distanciaXpKm, x.getTopeBloques());
        return x.getFijo()
                + x.getPorMil() * Math.min(tarifaBase, x.getTopeTarifa()) / 1000.0
                + x.getPorBloque() * bloques;
    }

    /** Ecuación 15: factor de espera; sin registro de llegada (null) es neutro. */
    public double factorEspera(Double minutosEsperando) {
        ModeloNexaProperties.Xp x = cfg.getXp();
        if (minutosEsperando == null) {
            return 1.0;
        }
        if (minutosEsperando <= x.getPuntualMinutos()) {
            return x.getFactorPuntual();
        }
        if (minutosEsperando <= x.getEsperaSinPenalizar()) {
            return 1.0;
        }
        double f = 1 - x.getPenalizacionMinuto() * (minutosEsperando - x.getEsperaSinPenalizar());
        return Math.max(x.getFactorEsperaMin(), f);
    }

    /** Ecuación 17: factor por número de viajes válidos del día, contando este (1, 2, 3...). */
    public double factorDia(int viajeValidoDelDia) {
        ModeloNexaProperties.Xp x = cfg.getXp();
        if (viajeValidoDelDia <= x.getViajesDiaCompletos()) {
            return 1.0;
        }
        if (viajeValidoDelDia <= x.getViajesDiaMedios()) {
            return x.getFactorDiaMedio();
        }
        return 0.0;
    }

    /** Ecuación 23: factor del conductor por la calificación del viaje (null = neutro). */
    public double factorCalificacion(Double calificacion) {
        ModeloNexaProperties.Conductor c = cfg.getConductor();
        if (calificacion == null) {
            return c.getMultBueno();
        }
        if (calificacion >= c.getCalExcelente()) {
            return c.getMultExcelente();
        }
        if (calificacion >= c.getCalBuena()) {
            return c.getMultBueno();
        }
        return c.getMultBajo();
    }

    /** Ecuación 14: XP del pasajero por un viaje, con un decimal. */
    public double xpPasajero(Viaje v, long tarifaBase, int viajeValidoDelDia, Double minutosEsperando) {
        if (!valido(v)) {
            return 0;
        }
        double base = xpBase(tarifaBase, distanciaXp(v.distanciaKm(), v.distanciaRectaKm()));
        return unDecimal(factorDia(viajeValidoDelDia) * factorEspera(minutosEsperando) * base);
    }

    /** Ecuación 22: XP del conductor por un viaje, con un decimal (sin factor del día). */
    public double xpConductor(Viaje v, long tarifaBase, Double calificacion) {
        if (!valido(v)) {
            return 0;
        }
        double base = xpBase(tarifaBase, distanciaXp(v.distanciaKm(), v.distanciaRectaKm()));
        return unDecimal(factorCalificacion(calificacion) * base);
    }

    // ------------------------------------------------------- niveles pasajero

    /** Ecuación 18: XP acumulado para alcanzar el nivel n (n ≥ 1). */
    public double xpParaNivel(int nivel) {
        if (nivel <= 1) {
            return 0;
        }
        ModeloNexaProperties.Niveles n = cfg.getNiveles();
        double crudo = n.getBase() * Math.pow(nivel - 1, n.getExponente());
        return n.getRedondeo() * Math.round(crudo / n.getRedondeo());
    }

    /** Ecuación 19: nivel del pasajero, sin techo. */
    public int nivelPasajero(double xp) {
        if (!Double.isFinite(xp)) {
            throw new IllegalArgumentException("XP inválido: " + xp);
        }
        int nivel = 1;
        while (xp >= xpParaNivel(nivel + 1)) {
            nivel++;
        }
        return nivel;
    }

    /** Ecuación 21: XP tras un periodo de inactividad (baja al inicio del nivel anterior). */
    public double xpTrasInactividad(double xp) {
        int nivel = nivelPasajero(xp);
        if (nivel < 2) {
            return xp;
        }
        return Math.min(xp, xpParaNivel(nivel - 1));
    }

    // ------------------------------------------------------ niveles conductor

    /** Ecuación 24: XP de 90 días para el nivel n del conductor. */
    public double xpConductorParaNivel(int nivel) {
        if (nivel <= 1) {
            return 0;
        }
        return cfg.getConductor().getBase() * Math.pow(nivel - 1, 2);
    }

    public int nivelMaximoConductor() {
        return cfg.getConductor().getNivelMax();
    }

    /** Nivel del conductor solo por XP de 90 días (1..máximo). */
    public int nivelConductorPorXp(double xp90d) {
        int nivel = 1;
        while (nivel < nivelMaximoConductor() && xp90d >= xpConductorParaNivel(nivel + 1)) {
            nivel++;
        }
        return nivel;
    }

    /** Mayor nivel con XP de 90 días suficiente y requisitos de calidad cumplidos. */
    public int nivelConductor(double xp90d, StatsConductor stats) {
        for (int n = nivelConductorPorXp(xp90d); n > 1; n--) {
            if (requisitosFaltantes(n, stats).isEmpty()) {
                return n;
            }
        }
        return 1;
    }

    /** Checklist de calidad para llegar al nivel {@code nivel} del conductor. */
    public List<Requisito> requisitos(int nivel, StatsConductor stats) {
        ModeloNexaProperties.Conductor c = cfg.getConductor();
        int i = Math.max(1, Math.min(nivel, c.getNivelMax())) - 1;
        double calMin = c.getCalificacionMin()[i];
        double acepMin = c.getAceptacionMin()[i];
        double cancMax = c.getCancelacionMax()[i];
        List<Requisito> lista = new ArrayList<>();
        if (calMin > 0) {
            boolean ok = stats.calificacion() != null && stats.calificacion() >= calMin;
            lista.add(new Requisito(String.format(Locale.US, "Calificación ≥ %.2f", calMin), ok));
        }
        if (acepMin > 0) {
            lista.add(new Requisito("Aceptación ≥ " + Math.round(acepMin * 100) + "%",
                    stats.aceptacion() >= acepMin));
        }
        if (cancMax < 1) {
            lista.add(new Requisito("Cancelación ≤ " + Math.round(cancMax * 100) + "%",
                    stats.cancelacion() <= cancMax));
        }
        return lista;
    }

    public List<String> requisitosFaltantes(int nivel, StatsConductor stats) {
        List<String> faltan = new ArrayList<>();
        for (Requisito r : requisitos(nivel, stats)) {
            if (!r.cumplido()) {
                faltan.add(r.texto());
            }
        }
        return faltan;
    }

    private static double unDecimal(double valor) {
        return Math.round(valor * 10) / 10.0;
    }
}
