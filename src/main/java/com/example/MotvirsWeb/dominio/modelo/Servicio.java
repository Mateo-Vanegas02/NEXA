package com.example.MotvirsWeb.dominio.modelo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.bson.types.ObjectId;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.Transient;
import org.springframework.data.mongodb.core.mapping.DBRef;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

import java.time.LocalDateTime;

@Document(collection = "servicios")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Servicio {
    @Id
    private String id;

    /** Identificador estable del aviso STOMP; no se guarda en MongoDB. */
    @Transient
    private String avisoId;

    // Datos del pasajero
    private PasajeroEmbedded pasajero;


    private ConductorEmbedded conductor;

    @DBRef
    private Vehiculo vehiculo;

    private String origen;
    private String destino;
    private double distanciaKM;
    /** Trazado de la ruta cotizada (polyline precisión 5); null si el proveedor de rutas no lo entrega. */
    private String rutaGeometria;
    /** Maniobras de esa ruta con el nombre de la calle (OSRM); vacío si la ruta es en línea recta. */
    private java.util.List<com.example.MotvirsWeb.dominio.regla.PasoRuta> pasosRuta;
    /** Duración estimada de la ruta cotizada, en minutos (0 si no se conoce). */
    private double duracionEstimadaMin;
    /** Kilómetros realmente recorridos con el viaje en curso (suma de la posición del conductor). */
    private Double distanciaRecorridaKm;
    /** El conductor finalizó sin llegar al destino (el pasajero se bajó antes). */
    private boolean finalizadoAntesDelDestino;
    /** Fracción del viaje cobrada: 1 normalmente; la mitad si se finalizó antes de la mitad del recorrido. */
    private Double fraccionCobrada;
    /** Recorrido real del viaje en curso, con puntos separados al menos nexa.viaje.punto-minimo-metros. */
    private java.util.List<Coordenada> recorrido;
    private Coordenada ubicacionOrigen;
    private Coordenada ubicacionDestino;
    private LocalDateTime fechaHora;
    private LocalDateTime fechaAceptacion;
    private LocalDateTime fechaInicio;
    private LocalDateTime fechaFinalizacion;
    private LocalDateTime fechaCancelacion;
    private double tarifa;
    private String metodoPago;
    private EstadoServicio estado;
    private Double calificacionConductor;
    /** Marca durable incluso cuando la calificación enviada es null. */
    private boolean calificacionConductorRegistrada;
    private String comentariosConductor;
    private Double calificacionPasajero;
    private boolean calificacionPasajeroRegistrada;
    private String comentariosPasajero;
    /** Factores que marcó el pasajero sobre el conductor y el viaje (códigos de {@code FactoresCalificacion}). */
    private java.util.List<String> factoresConductor;
    /** Factores que marcó el conductor sobre el pasajero. */
    private java.util.List<String> factoresPasajero;

    // ── Sistema de niveles ──
    /** "PASAJERO" o "CONDUCTOR"; null en servicios anteriores al sistema. */
    private String canceladoPor;
    /** Nivel del pasajero al solicitar (insignia para el conductor). */
    private int nivelPasajero;
    /** Momento (reloj del servidor) en que se solicitó; base de la ventana de prioridad. */
    private LocalDateTime solicitadoEn;
    /** Canal por el que se pidió (WEB o APP); null en viajes anteriores, que cuentan como WEB. */
    private CanalServicio canal;
    // ── Deuda de una cancelación anterior, cobrada junto con este viaje ──
    /** Deuda que tenía el pasajero al pedir el viaje y que aceptó pagar con él; 0 si no debía nada. */
    private long deudaPorCobrar;
    /** Servicio cancelado que originó esa deuda. */
    private String deudaServicioId;
    /** Lo que realmente se cobró de esa deuda al finalizar (0 si ya se había resuelto de otra forma). */
    private long deudaCobrada;

    /** Ola del despacho en que se aceptó (desde 1); 0 en viajes anteriores a la medición. */
    private int olaAceptacion;
    /** Distancia en línea recta del conductor a la recogida al aceptar, en km; null si no tenía posición vigente. */
    private Double distanciaRecogidaKm;

    // ── Llegada, espera y cancelación (modelo v2.1) ──
    /** Hora del servidor en que el conductor confirmó "llegué" con la ubicación verificada. */
    private LocalDateTime fechaLlegada;
    /** Ubicación que reportó el conductor al confirmar la llegada. */
    private Coordenada ubicacionLlegada;
    /** Minutos que esperó el conductor entre la llegada y el inicio del viaje (o la cancelación). */
    private Double minutosEspera;
    /** Cargo al pasajero por cancelar (pesos); 0 si no hubo. Va completo al conductor. */
    private long cargoCancelacion;
    /** La plataforma ya le reconoció el cargo al conductor (llegada verificada o deuda pagada). */
    private boolean cargoAcreditadoConductor;
    private LocalDateTime cargoPagadoEn;

    // ── Extra voluntario (modelo v2.2, sección 12A) ──
    /** Total que el pasajero sumó para atraer conductor (pesos); va completo al conductor. */
    private long extraVoluntario;
    /** Cada subida de oferta, en orden. */
    private java.util.List<OfertaExtra> historialExtra = new java.util.ArrayList<>();
    /** Cómo pagó el pasajero el cargo (hoy solo EFECTIVO) y la nota opcional del administrador. */
    private String cargoMetodoPago;
    private String cargoNotaPago;
    /** El administrador perdonó el cargo (la deuda se cierra sin cobrarle al pasajero). */
    private LocalDateTime cargoCondonadoEn;
    /** Correo del administrador que lo condonó. */
    private String cargoCondonadoPor;
    private String cargoMotivoCondonacion;
    private double xpGanadoPasajero;
    private double xpGanadoConductor;
    /**
     * Desglose interno (incluye margen de la plataforma). Nunca se serializa en la entidad:
     * cada rol lo recibe como DTO propio (DesglosePasajeroDto / DesgloseConductorDto).
     */
    @com.fasterxml.jackson.annotation.JsonIgnore
    private DesgloseTarifa desglose;

    /**
     * Lo que ganaría el conductor que mira la solicitud ({@code NivelesService.gananciaEstimada}). Solo se llena en
     * la lista de solicitudes del conductor; no se guarda y el pasajero nunca lo recibe.
     */
    @Transient
    private Long gananciaEstimada;


    @Transient //  Le dice a Mongo que no guarde este campo
    public Double getCalificacionPromedio() {
        // Caso 1: Ambas calificaciones existen
        if (calificacionConductor != null && calificacionPasajero != null) {
            return (calificacionConductor + calificacionPasajero) / 2.0;
        }
        // Caso 2: Solo existe la del conductor
        if (calificacionConductor != null) {
            return calificacionConductor;
        }
        // Caso 3: Solo existe la del pasajero
        if (calificacionPasajero != null) {
            return calificacionPasajero;
        }
        // Caso 4: Ninguna existe
        return null;
    }

    /** Una subida de oferta: cuánto sumó el pasajero y cuándo. */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OfertaExtra {
        private long monto;
        private LocalDateTime en;
    }

    /** Desglose económico del viaje (COP). Ver docs/niveles/DECISIONES.md. */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DesgloseTarifa {
        private double tarifaBase;
        private double factorDinamico;
        /** tarifaBase × factorDinamico: sobre ella se calcula la ganancia del conductor. */
        private double tarifaBruta;
        /** Descuento por nivel del pasajero (modelo v2.1); lo absorbe la plataforma. */
        private double descuentoNivel;
        /** Recargo por espera del conductor (modelo v2.1); va completo al conductor. */
        private double recargoEspera;
        /** Extra voluntario del pasajero (v2.2): suma al total y a la ganancia del conductor, sin comisión. */
        private double extraVoluntario;
        /** Lo que paga el pasajero: bruta − descuento − ahorro + tasa (v2.1: tarifa ajustada − descuento + espera). */
        private double totalPasajero;
        private double comisionPct;
        private double comisionMonto;
        private double gananciaConductor;
        private double ingresoPlataforma;
        /** true cuando se recalculó con la comisión real del conductor al finalizar. */
        private boolean definitivo;

        /** Desglose del modelo v2.2. */
        public static DesgloseTarifa deCobro(com.example.MotvirsWeb.dominio.regla.ModeloTarifa.Cobro c,
                boolean definitivo) {
            DesgloseTarifa d = new DesgloseTarifa();
            d.setTarifaBase(c.tarifaBase());
            d.setFactorDinamico(c.multiplicador());
            d.setTarifaBruta(c.tarifaAjustada());
            d.setDescuentoNivel(c.descuento());
            d.setRecargoEspera(c.recargoEspera());
            d.setTotalPasajero(c.precio());
            d.setComisionPct(c.comisionPct());
            d.setComisionMonto(c.tarifaAjustada() - (c.montoConductor() - c.recargoEspera()));
            d.setGananciaConductor(c.montoConductor());
            d.setIngresoPlataforma(c.montoPlataforma());
            d.setDefinitivo(definitivo);
            return d;
        }
    }

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class Coordenada {
        private double latitud;
        private double longitud;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PasajeroEmbedded {
        @Field("_id")
        @com.fasterxml.jackson.databind.annotation.JsonSerialize(using = com.fasterxml.jackson.databind.ser.std.ToStringSerializer.class)
        private ObjectId id;  // En JSON sale como texto (la app lo lee como String)
        private String nombre;
        private String email;
        /** Foto de perfil del pasajero (null si no tiene). */
        private String fotoUrl;

        public PasajeroEmbedded(ObjectId id, String nombre, String email) {
            this.id = id;
            this.nombre = nombre;
            this.email = email;
        }

        public String getIdString() {
            return id != null ? id.toString() : null;
        }
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ConductorEmbedded {
        @Field("_id")
        @com.fasterxml.jackson.databind.annotation.JsonSerialize(using = com.fasterxml.jackson.databind.ser.std.ToStringSerializer.class)
        private ObjectId id;
        private String nombre;
        /** Foto de perfil del conductor (null si no tiene); el pasajero la ve al ser asignado. */
        private String fotoUrl;
        /** Nivel del conductor (1–5) al aceptar; lo ve el pasajero en la ficha de su conductor. */
        private Integer nivel;
        /** Calificación promedio al aceptar (null si aún no tiene). */
        private Double calificacion;
        /** Moto con la que llega, p. ej. "Yamaha FZ 150 · Negra" (null si no hay vehículo registrado). */
        private String vehiculo;
        private String placa;

        public String getIdString() {
            return id != null ? id.toString() : null;
        }

        public ConductorEmbedded(Conductor conductor) {
            if (conductor != null && conductor.getId() != null) {

                this.id = conductor.getId();
                this.nombre = conductor.getNombre_y_Apellido();
                this.fotoUrl = conductor.fotoPerfilUrl();
                this.nivel = conductor.getNivel() > 0 ? conductor.getNivel() : null;

            } else {
                System.err.println("WARN: Se intentó crear ConductorEmbedded con Conductor nulo o sin ID.");

                this.id = null;
                this.nombre = "Desconocido";
            }
        }
    }


}
