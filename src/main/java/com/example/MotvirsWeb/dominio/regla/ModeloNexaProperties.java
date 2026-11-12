package com.example.MotvirsWeb.dominio.regla;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.PropertySource;
import org.springframework.stereotype.Component;

/**
 * Parámetros del modelo NEXA v2.0 (modelo-nexa.properties, prefijo {@code nexa.}).
 * Los arrays del conductor se indexan por nivel desde 1: la posición 0 es el nivel 1.
 */
@Data
@Component
@PropertySource(value = "classpath:modelo-nexa.properties", encoding = "UTF-8")
@ConfigurationProperties(prefix = "nexa")
public class ModeloNexaProperties {

    private Zona zona = new Zona();
    private Rutas rutas = new Rutas();
    private Tarifa tarifa = new Tarifa();
    private Espera espera = new Espera();
    private Multiplicador multiplicador = new Multiplicador();
    private Descuento descuento = new Descuento();
    private Margen margen = new Margen();
    private Comision comision = new Comision();
    private Xp xp = new Xp();
    private Niveles niveles = new Niveles();
    private Conductor conductor = new Conductor();
    private Cancelacion cancelacion = new Cancelacion();
    private Llegada llegada = new Llegada();
    private Extra extra = new Extra();
    private Job job = new Job();
    private Beneficios beneficios = new Beneficios();
    private Despacho despacho = new Despacho();
    private Avisos avisos = new Avisos();
    private Recogida recogida = new Recogida();
    private Seguimiento seguimiento = new Seguimiento();
    private Viaje viaje = new Viaje();
    /** Zona horaria del negocio (America/Bogota). */
    private String zonaHoraria;

    @Data
    public static class Zona {
        /** Vértices "lat lng" separados por ";". */
        private String poligono;
        private double distanciaMaxKm;
    }

    @Data
    public static class Rutas {
        private String proveedor;
        private double factorRecta;
        /** Base del servicio OSRM (solo con proveedor=osrm), p. ej. https://router.project-osrm.org */
        private String osrmUrl;
        /** Milisegundos máximos de espera a OSRM antes de caer a la línea recta. */
        private int osrmTimeoutMs = 2000;
    }

    @Data
    public static class Tarifa {
        private long banderazo;
        private long porKm;
        private long minima;
        private long redondeo;
    }

    @Data
    public static class Espera {
        private long valorMinuto;
        private double graciaMinutos;
        private double maxMinutos;
    }

    @Data
    public static class Multiplicador {
        private double fijo;
        private double max;
    }

    @Data
    public static class Descuento {
        private int nivelMin;
        private double porNivel;
        private double max;
        private long topeViaje;
    }

    @Data
    public static class Margen {
        private double minimo;
        private long holguraRedondeo;
    }

    @Data
    public static class Comision {
        private double[] porNivel;
    }

    @Data
    public static class Xp {
        private double fijo;
        private double porMil;
        private long topeTarifa;
        private double porBloque;
        private double topeBloques;
        private double factorRodeo;
        private double minMinutos;
        private double minKm;
        private int maxViajesParejaDia;
        private double puntualMinutos;
        private double factorPuntual;
        private double esperaSinPenalizar;
        private double penalizacionMinuto;
        private double factorEsperaMin;
        private int viajesDiaCompletos;
        private int viajesDiaMedios;
        private double factorDiaMedio;
    }

    @Data
    public static class Niveles {
        private double base;
        private double exponente;
        private double redondeo;
        /** Días sin viajes válidos para que el pasajero baje un nivel. */
        private int inactividadDias;
        /** Días de antelación con que se avisa al pasajero que va a bajar de nivel. */
        private int avisoInactividadDias;
    }

    @Data
    public static class Recogida {
        /** Metros máximos entre el pasajero y el punto donde pide que lo recojan. */
        private double radioMaxMetros;
    }

    @Data
    public static class Seguimiento {
        /** Segundos que vale la última posición del pasajero para el conductor; pasado ese tiempo no se muestra. */
        private int vigenciaSegundos;
    }

    @Data
    public static class Viaje {
        /** Metros al destino dentro de los cuales el conductor puede finalizar el viaje. */
        private double radioDestinoMetros = 150;
        /** Si es false no se valida la cercanía al destino al finalizar (solo desarrollo con simulación). */
        private boolean exigirDestino = true;
        /** Metros mínimos entre dos puntos guardados del recorrido real. */
        private double puntoMinimoMetros = 20;
        /** Tope de puntos guardados del recorrido de un viaje (protege la memoria y el documento). */
        private int maxPuntosRecorrido = 2000;
        /** Fracción de la distancia del viaje desde la cual, si el conductor finaliza antes del destino, se cobra completo. */
        private double umbralCobroCompleto = 0.5;
        /** Fracción del viaje que se cobra si se finaliza antes del umbral (la regla de la mitad). */
        private double fraccionCobroAnticipado = 0.5;
    }

    @Data
    public static class Job {
        private String cron;
        private int reprocesoMinutos;
        private int reprocesoDias;
        private int reprocesoGraciaMinutos;
    }

    @Data
    public static class Despacho {
        /** Segundos desde la solicitud en que empieza cada ola; la primera es 0. */
        private int[] olaSegundos;
        /** Olas que adelanta una solicitud con extra voluntario (0 = el extra no adelanta). */
        private int olasPorExtra;
        /** Minutos que se recuerda la última posición de un conductor para contarlo como "en línea". */
        private int retencionMinutos;
        /** Radio de recogida de cada ola en km; 0 = toda la zona. Mismo largo que olaSegundos. */
        private double[] olaRadioKm;
        /** Segundos que una posición reportada por el conductor sigue valiendo. */
        private int ubicacionVigenciaSegundos;
        /** Cada cuántos segundos se revisa si alguna solicitud pasó a la siguiente ola. */
        private int revisionSegundos;
        /** Segundos tras el inicio de la última ola sin aceptación para avisar al pasajero que no hay conductores. */
        private int avisoSinConductoresSegundos;
    }

    @Data
    public static class Avisos {
        /** Vigencia en FCM del aviso de una solicitud (igual que la tarjeta en pantalla). */
        private int vigenciaSolicitudSegundos;
        private int vigenciaViajeMinutos;
        private int vigenciaCuentaHoras;
    }

    @Data
    public static class Beneficios {
        /** Segundos de prioridad por nivel del pasajero; el índice 0 es el nivel 1. */
        private int[] ventanaSegundos;
        private double calificacionConductor;
        private int favoritosDesdeNivel;
        private double favoritoEtaMinutos;
        private int favoritoAmpliadoDesdeNivel;
        private double favoritoAmpliadoEtaMinutos;
        private double pesoCalificacion;
        private double pesoCercania;
        private double bonoFavorito;
        private double etaMaxMinutos;
        private double velocidadKmh;
    }

    @Data
    public static class Conductor {
        private double base;
        private int nivelMax;
        /** Días de la ventana móvil de XP y de las métricas de calidad. */
        private int ventanaDias;
        private int cacheStatsSegundos;
        private double calExcelente;
        private double calBuena;
        private double multExcelente;
        private double multBueno;
        private double multBajo;
        private double[] calificacionMin;
        private double[] aceptacionMin;
        private double[] cancelacionMax;
    }

    @Data
    public static class Llegada {
        /** Radio (m) alrededor del punto de recogida en el que cuenta como "llegué". */
        private double radioMetros;
    }

    @Data
    public static class Extra {
        /** Máximo que el pasajero puede sumar a un viaje en total (pesos). */
        private long tope;
        /** Incrementos permitidos en cada subida (pesos). */
        private long[] pasos;
    }

    @Data
    public static class Cancelacion {
        /** Fracción de la tarifa base que se cobra al cancelar (0,20). */
        private double porcentaje;
        private double graciaMinutos;
        private int nivelGraciaExtendida;
        private double graciaExtendidaMinutos;
    }
}
