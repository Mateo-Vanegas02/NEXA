package com.example.MotvirsWeb.infraestructura.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.ThreadPoolExecutor;

/**
 * Hilos propios para enviar los avisos de la bandeja persistente (STOMP, FCM, SMTP). Los envíos pueden tardar
 * (FCM síncrono, SMTP), así que no corren en el hilo de la petición ni en el de {@code @Scheduled}, que
 * comparten el despacho por olas y los procesos de niveles. Cola acotada: si se llena, el aviso sigue
 * PENDIENTE en Mongo y lo recoge el barrido.
 */
@Configuration
public class AvisosEjecucionConfig {

    @Bean(name = "avisosExecutor", destroyMethod = "shutdown")
    public ThreadPoolTaskExecutor avisosExecutor(
            @Value("${nexa.avisos-pendientes.hilos:2}") int hilos,
            @Value("${nexa.avisos-pendientes.cola:200}") int cola) {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(hilos);
        executor.setMaxPoolSize(hilos);
        executor.setQueueCapacity(cola);
        executor.setThreadNamePrefix("nexa-avisos-");
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.AbortPolicy());
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(10);
        executor.initialize();
        return executor;
    }
}
