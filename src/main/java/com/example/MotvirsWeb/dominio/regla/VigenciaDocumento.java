package com.example.MotvirsWeb.dominio.regla;

import com.example.MotvirsWeb.dominio.modelo.TipoDocumento;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

/**
 * Estado de vigencia de un documento según su fecha de vencimiento. La tarjeta de propiedad no vence; la licencia, el
 * SOAT y la tecnomecánica sí. «Por vencer» = faltan {@link #DIAS_AVISO} días o menos.
 */
public enum VigenciaDocumento {
    NO_VENCE, SIN_FECHA, VIGENTE, POR_VENCER, VENCIDO;

    public static final int DIAS_AVISO = 30;

    public static boolean vence(TipoDocumento tipo) {
        return tipo != null && tipo != TipoDocumento.TARJETA_PROPIEDAD;
    }

    public static VigenciaDocumento de(TipoDocumento tipo, LocalDate venceEl, LocalDate hoy) {
        if (!vence(tipo)) {
            return NO_VENCE;
        }
        if (venceEl == null) {
            return SIN_FECHA;
        }
        if (venceEl.isBefore(hoy)) {
            return VENCIDO;
        }
        return ChronoUnit.DAYS.between(hoy, venceEl) <= DIAS_AVISO ? POR_VENCER : VIGENTE;
    }

    /** Días que faltan (negativo si ya venció); null sin fecha. */
    public static Long diasRestantes(LocalDate venceEl, LocalDate hoy) {
        return venceEl == null ? null : ChronoUnit.DAYS.between(hoy, venceEl);
    }
}
