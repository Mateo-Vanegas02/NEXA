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

    private static AvisosPendientesService.Pendiente pendiente(String id, String estado, int intentos) {
        return new AvisosPendientesService.Pendiente(id, "s1", "LLEGADA", estado, LocalDateTime.now(),
                null, intentos, List.of(), "lease-x", false, null, null, null);
    }

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
                .thenReturn(pendiente("s1:LLEGADA", "EN_ENVIO", 1));

        when(mongo.updateFirst(any(Query.class), any(Update.class), eq("avisos_viaje_pendientes")))
                .thenReturn(com.mongodb.client.result.UpdateResult.acknowledged(1, 1L, null));

        bandeja(encolados::add).registrar("s1", AvisosPendientesService.Tipo.LLEGADA);
        encolados.forEach(Runnable::run);

        verify(tiempoReal).notificarCambioEstadoServicio(viaje);
    }

    @Test
    void elBarridoNoEnviaEnSuPropioHiloAunqueElEnvioSeaLento() throws Exception {
        CountDownLatch envioEmpezo = new CountDownLatch(1);
        CountDownLatch liberarEnvio = new CountDownLatch(1);
        when(mongo.find(any(Query.class), eq(AvisosPendientesService.Pendiente.class), eq("avisos_viaje_pendientes")))
                .thenReturn(List.of(pendiente("s1:LLEGADA", "PENDIENTE", 0)));
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
                        pendiente("a", "PENDIENTE", 0),
                        pendiente("b", "PENDIENTE", 0)));
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

    @Test
    void laReclamacionYTodaEscrituraFinalExigenElLeasePropio() {
        Servicio viaje = new Servicio();
        viaje.setId("s1");
        viaje.setEstado(EstadoServicio.ACEPTADO);
        when(servicios.findById("s1")).thenReturn(Optional.of(viaje));
        org.mockito.ArgumentCaptor<Update> reclamo = org.mockito.ArgumentCaptor.forClass(Update.class);
        when(mongo.findAndModify(any(Query.class), reclamo.capture(), any(FindAndModifyOptions.class),
                eq(AvisosPendientesService.Pendiente.class), eq("avisos_viaje_pendientes")))
                .thenReturn(pendiente("s1:LLEGADA", "EN_ENVIO", 1));
        org.mockito.ArgumentCaptor<Query> cierre = org.mockito.ArgumentCaptor.forClass(Query.class);
        when(mongo.updateFirst(cierre.capture(), any(Update.class), eq("avisos_viaje_pendientes")))
                .thenReturn(com.mongodb.client.result.UpdateResult.acknowledged(0, 0L, null));

        bandeja(Runnable::run).despachar("s1:LLEGADA");

        Object lease = reclamo.getValue().getUpdateObject().get("$set", org.bson.Document.class).get("lease");
        assertNotNull(lease);
        org.bson.Document filtro = cierre.getValue().getQueryObject();
        assertEquals("s1:LLEGADA", filtro.get("_id"));
        assertEquals("EN_ENVIO", filtro.get("estado"));
        assertEquals(lease, filtro.get("lease"), "solo quien tiene la reclamación vigente puede cerrarla");
    }

    @Test
    void trasElTopeDeIntentosElAvisoQuedaFallidoSinReprogramar() {
        Servicio viaje = new Servicio();
        viaje.setId("s1");
        viaje.setEstado(EstadoServicio.ACEPTADO);
        when(servicios.findById("s1")).thenReturn(Optional.of(viaje));
        doThrow(new IllegalStateException("socket caído")).when(tiempoReal).notificarCambioEstadoServicio(any());
        when(mongo.findAndModify(any(Query.class), any(Update.class), any(FindAndModifyOptions.class),
                eq(AvisosPendientesService.Pendiente.class), eq("avisos_viaje_pendientes")))
                .thenReturn(pendiente("s1:LLEGADA", "EN_ENVIO", 3));
        org.mockito.ArgumentCaptor<Update> cambio = org.mockito.ArgumentCaptor.forClass(Update.class);
        when(mongo.updateFirst(any(Query.class), cambio.capture(), eq("avisos_viaje_pendientes")))
                .thenReturn(com.mongodb.client.result.UpdateResult.acknowledged(1, 1L, null));

        new AvisosPendientesService(mongo, servicios, tiempoReal, push, deudas, Runnable::run, 3, 600)
                .despachar("s1:LLEGADA");

        org.bson.Document set = cambio.getValue().getUpdateObject().get("$set", org.bson.Document.class);
        assertEquals("FALLIDO", set.get("estado"));
        assertNull(set.get("proximoIntento"));
        assertTrue(set.getString("ultimoError").startsWith("IllegalStateException"));
    }
}
