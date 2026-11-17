package com.example.MotvirsWeb.aplicacion.servicio;

import com.mongodb.MongoException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.mongodb.UncategorizedMongoDbException;
import org.springframework.transaction.support.TransactionOperations;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.server.ResponseStatusException;

import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;

class EjecutorTransaccionesTest {

    private final EjecutorTransacciones ejecutor =
            new EjecutorTransacciones(TransactionOperations.withoutTransaction());

    @AfterEach
    void limpiar() {
        TransactionSynchronizationManager.setActualTransactionActive(false);
    }

    private static RuntimeException conflictoTransitorio() {
        MongoException causa = new MongoException(112, "WriteConflict");
        causa.addLabel(MongoException.TRANSIENT_TRANSACTION_ERROR_LABEL);
        return new UncategorizedMongoDbException("conflicto", causa);
    }

    @Test
    void unConflictoTransitorioSeReintentaYElSegundoIntentoDecide() {
        AtomicInteger intentos = new AtomicInteger();
        String r = ejecutor.ejecutar(() -> {
            if (intentos.incrementAndGet() == 1) throw conflictoTransitorio();
            return "ok";
        });
        assertEquals("ok", r);
        assertEquals(2, intentos.get());
    }

    @Test
    void siElConflictoPersisteSeRespondeConflictoNunca500() {
        AtomicInteger intentos = new AtomicInteger();
        ResponseStatusException e = assertThrows(ResponseStatusException.class, () -> ejecutor.ejecutar(() -> {
            intentos.incrementAndGet();
            throw conflictoTransitorio();
        }));
        assertEquals(409, e.getStatusCode().value());
        assertEquals(EjecutorTransacciones.MAX_INTENTOS, intentos.get());
    }

    @Test
    void unErrorDeNegocioNoSeReintenta() {
        AtomicInteger intentos = new AtomicInteger();
        assertThrows(IllegalStateException.class, () -> ejecutor.ejecutar(() -> {
            intentos.incrementAndGet();
            throw new IllegalStateException("regla de negocio");
        }));
        assertEquals(1, intentos.get());
    }

    @Test
    void dentroDeOtraTransaccionSeUneSinReintentar() {
        TransactionSynchronizationManager.setActualTransactionActive(true);
        AtomicInteger intentos = new AtomicInteger();
        assertThrows(UncategorizedMongoDbException.class, () -> ejecutor.ejecutar(() -> {
            intentos.incrementAndGet();
            throw conflictoTransitorio();
        }));
        assertEquals(1, intentos.get());
    }

    @Test
    void reconoceElConflictoPorCodigoAunqueVengaEnvuelto() {
        assertTrue(EjecutorTransacciones.esTransitorio(new RuntimeException(new MongoException(112, "WriteConflict"))));
        assertFalse(EjecutorTransacciones.esTransitorio(new MongoException(11000, "duplicate key")));
    }
}
