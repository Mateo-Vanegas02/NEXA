package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.mongodb.core.FindAndModifyOptions;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class AvisosPendientesServiceTest {

    private final MongoTemplate mongo = mock(MongoTemplate.class);
    private final ServicioRepository servicios = mock(ServicioRepository.class);
    private final NotificadorTiempoReal tiempoReal = mock(NotificadorTiempoReal.class);
    private final AvisosService push = mock(AvisosService.class);
    private final DeudaService deudas = mock(DeudaService.class);
    private final List<Runnable> encolados = new ArrayList<>();

    private AvisosPendientesService bandeja(java.util.concurrent.Executor executor) {
        return new AvisosPendientesService(mongo, servicios, tiempoReal, push, deudas, executor);
    }

    @AfterEach
    void limpiarSincronizacion() {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.clearSynchronization();
        }
    }

    @Test
    void dentroDeUnaTransaccionElAvisoSeEncolaSoloDespuesDelCommit() {
        TransactionSynchronizationManager.initSynchronization();
        bandeja(encolados::add).registrar("s1", AvisosPendientesService.Tipo.LLEGADA);

        verify(mongo).insert(any(AvisosPendientesService.Pendiente.class), eq("avisos_viaje_pendientes"));
        assertTrue(encolados.isEmpty(), "antes del commit no se envía nada");

        TransactionSynchronizationManager.getSynchronizations().forEach(TransactionSynchronization::afterCommit);
        assertEquals(1, encolados.size(), "tras el commit se encola sin esperar al barrido");
    }

    @Test
    void siLaTransaccionSeRevierteNoSeEncolaNada() {
        TransactionSynchronizationManager.initSynchronization();
        bandeja(encolados::add).registrar("s1", AvisosPendientesService.Tipo.LLEGADA);

        TransactionSynchronizationManager.getSynchronizations()
                .forEach(s -> s.afterCompletion(TransactionSynchronization.STATUS_ROLLED_BACK));
        assertTrue(encolados.isEmpty());
    }

    @Test
    void elAvisoEncoladoSeEnviaAlEjecutarse() {
        Servicio viaje = new Servicio();
        viaje.setId("s1");
        viaje.setEstado(EstadoServicio.ACEPTADO);
        when(servicios.findById("s1")).thenReturn(Optional.of(viaje));
        when(mongo.findAndModify(any(Query.class), any(Update.class), any(FindAndModifyOptions.class),
                eq(AvisosPendientesService.Pendiente.class), eq("avisos_viaje_pendientes")))
                .thenReturn(new AvisosPendientesService.Pendiente("s1:LLEGADA", "s1", "LLEGADA", "EN_ENVIO",
                        LocalDateTime.now(), LocalDateTime.now().plusMinutes(10), 1, List.of()));

        bandeja(encolados::add).registrar("s1", AvisosPendientesService.Tipo.LLEGADA);
        encolados.forEach(Runnable::run);

        verify(tiempoReal).notificarCambioEstadoServicio(viaje);
    }

    @Test
    void elBarridoNoEnviaEnSuPropioHiloAunqueElEnvioSeaLento() throws Exception {
        CountDownLatch envioEmpezo = new CountDownLatch(1);
        CountDownLatch liberarEnvio = new CountDownLatch(1);
        when(mongo.find(any(Query.class), eq(AvisosPendientesService.Pendiente.class), eq("avisos_viaje_pendientes")))
                .thenReturn(List.of(new AvisosPendientesService.Pendiente("s1:LLEGADA", "s1", "LLEGADA",
                        "PENDIENTE", LocalDateTime.now(), null, 0, List.of())));
        when(mongo.findAndModify(any(Query.class), any(Update.class), any(FindAndModifyOptions.class),
                eq(AvisosPendientesService.Pendiente.class), eq("avisos_viaje_pendientes")))
                .thenAnswer(inv -> {
                    envioEmpezo.countDown();
                    liberarEnvio.await(10, TimeUnit.SECONDS); // simula un FCM o SMTP colgado
                    return null;
                });
        ExecutorService hilo = Executors.newSingleThreadExecutor();
        try {
            long antes = System.nanoTime();
            bandeja(hilo).procesar();
            long ms = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - antes);

            assertTrue(envioEmpezo.await(5, TimeUnit.SECONDS), "el envío corre en el executor de avisos");
            assertTrue(ms < 1000, "el hilo de @Scheduled vuelve sin esperar el envío (tardó " + ms + " ms)");
        } finally {
            liberarEnvio.countDown();
            hilo.shutdown();
        }
    }

    @Test
    void conLaColaLlenaElAvisoQuedaParaElProximoBarrido() {
        when(mongo.find(any(Query.class), eq(AvisosPendientesService.Pendiente.class), eq("avisos_viaje_pendientes")))
                .thenReturn(List.of(
                        new AvisosPendientesService.Pendiente("a", "s1", "LLEGADA", "PENDIENTE", LocalDateTime.now(), null, 0, List.of()),
                        new AvisosPendientesService.Pendiente("b", "s2", "LLEGADA", "PENDIENTE", LocalDateTime.now(), null, 0, List.of())));
        List<Runnable> aceptados = new ArrayList<>();
        java.util.concurrent.Executor llena = r -> {
            throw new RejectedExecutionException("llena");
        };

        assertDoesNotThrow(() -> bandeja(llena).procesar());
        assertDoesNotThrow(() -> bandeja(llena).registrar("s3", AvisosPendientesService.Tipo.INICIADO));
        assertTrue(aceptados.isEmpty());
        verify(mongo, never()).findAndModify(any(Query.class), any(Update.class), any(FindAndModifyOptions.class),
                eq(AvisosPendientesService.Pendiente.class), anyString());
    }
}
