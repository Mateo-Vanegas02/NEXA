package com.example.MotvirsWeb.aplicacion.servicio;

import com.mongodb.MongoException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionOperations;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.server.ResponseStatusException;

import java.util.function.Supplier;

/**
 * Ejecuta un caso de uso en una transacción MongoDB con reintento acotado ante conflictos transitorios.
 *
 * <p>Cuando dos peticiones escriben el mismo documento a la vez, MongoDB aborta una transacción con un error
 * transitorio ({@code TransientTransactionError}, p. ej. WriteConflict). Ese caso se reintenta completo hasta
 * {@link #MAX_INTENTOS} veces: el trabajo vuelve a leer el estado y sus actualizaciones condicionales deciden (lo
 * normal es que el perdedor reciba su 409 de negocio). Si se agotan los intentos, 409, nunca un 500.
 *
 * <p>Solo debe envolver trabajo que pueda repetirse: lecturas, escrituras condicionales y efectos registrados
 * para después del commit. Si ya hay una transacción en curso (llamada anidada), se une a ella sin reintentar:
 * reintentar dentro de una transacción abortada no sirve.
 */
@Slf4j
public class EjecutorTransacciones {

    static final int MAX_INTENTOS = 3;
    private static final int WRITE_CONFLICT = 112;

    private final TransactionOperations transacciones;

    public EjecutorTransacciones(PlatformTransactionManager gestor) {
        this(new TransactionTemplate(gestor));
    }

    EjecutorTransacciones(TransactionOperations transacciones) {
        this.transacciones = transacciones;
    }

    /** Sin transacción ni reintentos: para pruebas unitarias que no tienen MongoDB. */
    public static EjecutorTransacciones sinTransaccion() {
        return new EjecutorTransacciones(TransactionOperations.withoutTransaction());
    }

    public <T> T ejecutar(Supplier<T> trabajo) {
        if (TransactionSynchronizationManager.isActualTransactionActive()) {
            return trabajo.get();
        }
        for (int intento = 1; ; intento++) {
            try {
                return transacciones.execute(estado -> trabajo.get());
            } catch (RuntimeException e) {
                if (!esTransitorio(e)) {
                    throw e;
                }
                if (intento >= MAX_INTENTOS) {
                    log.warn("Conflicto transitorio persistente tras {} intentos", intento);
                    throw new ResponseStatusException(HttpStatus.CONFLICT,
                            "Otra operación modificó estos datos al mismo tiempo. Intenta de nuevo.", e);
                }
                log.info("Conflicto transitorio de MongoDB (intento {} de {}); se reintenta", intento, MAX_INTENTOS);
            }
        }
    }

    /** ¿Error transitorio de transacción en algún punto de la cadena de causas? */
    static boolean esTransitorio(Throwable e) {
        for (Throwable t = e; t != null; t = t.getCause() == t ? null : t.getCause()) {
            if (t instanceof MongoException m
                    && (m.hasErrorLabel(MongoException.TRANSIENT_TRANSACTION_ERROR_LABEL) || m.getCode() == WRITE_CONFLICT)) {
                return true;
            }
        }
        return false;
    }
}
