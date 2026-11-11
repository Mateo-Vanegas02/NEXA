package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Gamificado;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Rol;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio.DesgloseTarifa;
import com.example.MotvirsWeb.dominio.modelo.Usuario;
import com.example.MotvirsWeb.dominio.modelo.XpEvento;
import com.example.MotvirsWeb.dominio.regla.CatalogoBeneficios;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.ModeloTarifa;
import com.example.MotvirsWeb.dominio.regla.ModeloXp;
import com.example.MotvirsWeb.dominio.regla.PrioridadRecogida;
import com.example.MotvirsWeb.dominio.regla.StatsConductor;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.example.MotvirsWeb.dominio.repositorio.XpEventoRepository;
import com.example.MotvirsWeb.presentacion.dto.NivelDto;
import com.example.MotvirsWeb.presentacion.dto.NivelDto.BeneficioInfo;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.bson.types.ObjectId;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Clock;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Orquesta el sistema de niveles del modelo v2.2: XP del viaje, niveles del pasajero (sin techo) y del conductor
 * (con calidad), comisión y beneficios. Las reglas puras viven en {@link ModeloXp}, {@link ModeloTarifa},
 * {@link PrioridadRecogida} y {@link CatalogoBeneficios}.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class NivelesService {

    /** Resultado de procesar un viaje finalizado. */
    public record ResultadoViaje(double xpPasajero, double xpConductor, int nivelPasajeroAntes,
            int nivelPasajeroDespues, int nivelConductorAntes, int nivelConductorDespues,
            DesgloseTarifa desglose, Double xpFaltanteConductor) {
        public boolean subioNivelConductor() {
            return nivelConductorDespues > nivelConductorAntes;
        }
    }

    private final ModeloNexaProperties cfg;
    private final ModeloXp modeloXp;
    private final ModeloTarifa modeloTarifa;
    private final PrioridadRecogida prioridad;
    private final CatalogoBeneficios catalogo;
    private final UsuarioRepository usuarioRepository;
    private final ServicioRepository servicioRepository;
    private final XpEventoRepository xpRepository;
    private final Clock clock;
    private final MongoTemplate mongoTemplate;
    private final com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo correo;

    /** Métricas de calidad cacheadas por conductor (se consultan en cada poll del dashboard). */
    private final Map<ObjectId, StatsEnCache> cacheStats = new ConcurrentHashMap<>();

    private record StatsEnCache(StatsConductor stats, long expiraMs) {
    }

    private LocalDateTime ahora() {
        return LocalDateTime.now(clock);
    }

    public LocalDateTime momentoActual() {
        return ahora();
    }

    /** Los niveles empiezan en 1; un usuario nuevo guarda 0 hasta su primer XP. */
    static int nivelDe(Gamificado g) {
        return Math.max(1, g.getNivel());
    }

    private static double unDecimal(double v) {
        return Math.round(v * 10) / 10.0;
    }

    // ═════════════════════════ FINALIZACIÓN DEL VIAJE ═════════════════════════

    /**
     * Otorga XP y fija el desglose definitivo con la comisión real. Idempotente: un viaje nunca otorga XP dos
     * veces. Muta {@code s} (el llamador lo guarda).
     */
    public ResultadoViaje procesarFinalizacion(Servicio s) {
        String viajeId = s.getId();
        Pasajero pasajero = cargar(s.getPasajero() == null ? null : s.getPasajero().getId(), Pasajero.class);
        Conductor conductor = cargar(s.getConductor() == null ? null : s.getConductor().getId(), Conductor.class);
        LocalDateTime ahora = ahora();

        int nivelPasAntes = pasajero == null ? 0 : nivelDe(pasajero);
        int nivelCondAntes = conductor == null ? 0 : nivelDe(conductor);

        // 1) Desglose definitivo con la comisión del nivel actual del conductor. Si ya es
        //    definitivo (reintento) no se toca: un viaje cerrado no cambia de comisión.
        boolean yaDefinitivo = s.getDesglose() != null && s.getDesglose().isDefinitivo();
        DesgloseTarifa definitivo;
        if (yaDefinitivo) {
            definitivo = s.getDesglose();
        } else {
            definitivo = desgloseDefinitivo(s, nivelCondAntes);
            s.setDesglose(definitivo);
        }

        // 2) XP con antifraude. Dos fases: evento (aplicado=false) -> suma al usuario -> aplicado=true,
        //    de modo que un corte a mitad se completa en el reintento.
        ModeloXp.Viaje viaje = hechosDelViaje(s);
        boolean valido = modeloXp.valido(viaje);
        long tarifaBase = Math.round(definitivo.getTarifaBase());

        double xpPas = 0;
        double xpCond = 0;
        if (pasajero != null) {
            int viajeDelDia = viajesValidosHoy(pasajero.getId(), ahora) + 1;
            double calculado = modeloXp.xpPasajero(viaje, tarifaBase, viajeDelDia, minutosEsperando(s));
            String nota = !valido ? "ANTIFRAUDE" : (calculado == 0 ? "LIMITE_DIA" : null);
            Otorgado o = otorgar(pasajero.getId(), Rol.PASAJERO, viajeId, calculado, nota, ahora);
            if (o.aplicar() && !yaDefinitivo) {
                xpPas = o.xp();
                pasajero.setXpTotal(unDecimal(pasajero.getXpTotal() + xpPas));
                int nuevo = modeloXp.nivelPasajero(pasajero.getXpTotal());
                if (nuevo != pasajero.getNivel()) {
                    pasajero.setNivel(nuevo);
                    pasajero.setNivelActualizadoEn(ahora);
                }
                if (valido) {
                    pasajero.setUltimoViajeEn(ahora);
                }
                usuarioRepository.save(pasajero);
                marcarAplicado(o);
            }
        }
        if (conductor != null) {
            double calculado = modeloXp.xpConductor(viaje, tarifaBase, null);
            Otorgado o = otorgar(conductor.getId(), Rol.CONDUCTOR, viajeId, calculado, valido ? null : "ANTIFRAUDE", ahora);
            if (o.aplicar() && !yaDefinitivo) {
                xpCond = o.xp();
                conductor.setXpTotal(unDecimal(conductor.getXpTotal() + xpCond));
                recalcularConductor(conductor);
                usuarioRepository.save(conductor);
                marcarAplicado(o);
            }
        }
        if (!yaDefinitivo) {
            s.setXpGanadoPasajero(xpPas);
            s.setXpGanadoConductor(xpCond);
        }

        return new ResultadoViaje(xpPas, xpCond, nivelPasAntes, pasajero == null ? 0 : nivelDe(pasajero),
                nivelCondAntes, conductor == null ? 0 : nivelDe(conductor), definitivo,
                conductor == null ? null : xpFaltanteConductor(conductor));
    }

    /** XP de 90 días que le faltan al conductor para el nivel siguiente; null si ya está en el máximo. */
    Double xpFaltanteConductor(Conductor c) {
        int nivel = nivelDe(c);
        if (nivel >= modeloXp.nivelMaximoConductor()) {
            return null;
        }
        return Math.max(0, unDecimal(modeloXp.xpConductorParaNivel(nivel + 1) - c.getXp90d()));
    }

    /** Reintenta los viajes finalizados cuyo procesamiento de niveles no terminó. */
    public int reprocesarPendientes() {
        ModeloNexaProperties.Job job = cfg.getJob();
        LocalDateTime ahoraJvm = LocalDateTime.now(); // fechaFinalizacion se guarda con el reloj de la JVM
        List<Servicio> pendientes = servicioRepository.findPendientesDeNiveles(
                ahoraJvm.minusDays(job.getReprocesoDias()), ahoraJvm.minusMinutes(job.getReprocesoGraciaMinutos()));
        int reprocesados = 0;
        for (Servicio s : pendientes) {
            try {
                procesarFinalizacion(s);
                servicioRepository.save(s);
                reprocesados++;
            } catch (Exception e) {
                log.error("No se pudo reprocesar niveles del servicio {}", s.getId(), e);
            }
        }
        return reprocesados;
    }

    /** Hechos del viaje que decide la validez del XP (ecuación 16): estado, duración, distancia y pareja del día. */
    private ModeloXp.Viaje hechosDelViaje(Servicio s) {
        LocalDateTime inicio = s.getFechaInicio() != null ? s.getFechaInicio() : s.getFechaAceptacion();
        double minutos = inicio == null || s.getFechaFinalizacion() == null ? 0
                : Duration.between(inicio, s.getFechaFinalizacion()).toSeconds() / 60.0;
        // Si se finalizó antes de la mitad (se cobró solo una fracción), el XP también cuenta solo esa fracción del viaje
        double fraccion = s.getFraccionCobrada() != null && s.getFraccionCobrada() > 0 && s.getFraccionCobrada() <= 1.0
                ? s.getFraccionCobrada() : 1.0;
        return new ModeloXp.Viaje(s.getEstado() == EstadoServicio.FINALIZADO, minutos, s.getDistanciaKM() * fraccion,
                distanciaRectaKm(s) * fraccion, viajesDeLaPareja(s));
    }

    /** Línea recta entre origen y destino; sin coordenadas se usa la distancia declarada (no se acota). */
    double distanciaRectaKm(Servicio s) {
        Servicio.Coordenada o = s.getUbicacionOrigen();
        Servicio.Coordenada d = s.getUbicacionDestino();
        if (o == null || d == null) {
            return s.getDistanciaKM();
        }
        return PrioridadRecogida.distanciaKm(o.getLatitud(), o.getLongitud(), d.getLatitud(), d.getLongitud());
    }

    /** Viajes finalizados hoy entre este pasajero y este conductor, contando el actual. */
    private int viajesDeLaPareja(Servicio s) {
        if (s.getPasajero() == null || s.getConductor() == null || s.getFechaFinalizacion() == null) {
            return 1;
        }
        LocalDate dia = s.getFechaFinalizacion().toLocalDate();
        long n = servicioRepository.contarFinalizadosDeLaPareja(s.getPasajero().getId(), s.getConductor().getId(),
                dia.atStartOfDay(), dia.plusDays(1).atStartOfDay());
        return (int) Math.max(1, n);
    }

    /** Viajes con XP que el pasajero ya sumó hoy (día del negocio), para el factor A(n). */
    private int viajesValidosHoy(ObjectId pasajeroId, LocalDateTime ahora) {
        LocalDate hoy = ahora.toLocalDate();
        return (int) xpRepository.findByUsuarioIdAndRolAndCreadoEnBetween(pasajeroId, Rol.PASAJERO,
                hoy.atStartOfDay(), hoy.plusDays(1).atStartOfDay()).stream()
                .filter(e -> XpEvento.MOTIVO_VIAJE.equals(e.getMotivo()) && e.getXp() > 0).count();
    }

    /** Minutos que el conductor esperó; null si no hay llegada verificada (factor neutro). */
    private static Double minutosEsperando(Servicio s) {
        return s.getFechaLlegada() == null ? null : s.getMinutosEspera();
    }

    /** Vista del desglose según quién pregunta; null-safe y solo para las partes del viaje. */
    public Object desgloseParaUsuario(String servicioId, Usuario usuario) {
        Servicio s = servicioRepository.findById(servicioId).orElseThrow(
                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Servicio no encontrado"));
        if (s.getDesglose() == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El viaje no tiene desglose");
        }
        if (usuario instanceof Pasajero && s.getPasajero() != null && usuario.getId().equals(s.getPasajero().getId())) {
            return com.example.MotvirsWeb.presentacion.dto.DesglosePasajeroDto.de(s.getDesglose(), s.getDeudaCobrada());
        }
        if (usuario instanceof Conductor && s.getConductor() != null && usuario.getId().equals(s.getConductor().getId())) {
            return com.example.MotvirsWeb.presentacion.dto.DesgloseConductorDto.de(s.getDesglose(), s.getDeudaCobrada());
        }
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No participas en este viaje");
    }

    /**
     * Registra un XP del libro respetando la idempotencia: un viaje da XP una sola vez por rol.
     * Devuelve el XP otorgado y si falta sumarlo al usuario.
     */
    private Otorgado otorgar(ObjectId usuarioId, Rol rol, String viajeId, double xp, String nota, LocalDateTime ahora) {
        Optional<XpEvento> previo = xpRepository.findByViajeIdAndRolAndMotivo(viajeId, rol, XpEvento.MOTIVO_VIAJE);
        if (previo.isPresent()) {
            return new Otorgado(previo.get().getXp(), !previo.get().isAplicado(), previo.get());
        }
        try {
            XpEvento evento = xpRepository.save(XpEvento.builder().usuarioId(usuarioId).rol(rol).viajeId(viajeId)
                    .xp(xp).motivo(XpEvento.MOTIVO_VIAJE).nota(nota).creadoEn(ahora).build());
            return new Otorgado(xp, true, evento);
        } catch (DuplicateKeyException e) {
            return new Otorgado(0, false, null); // otro hilo ya lo registró
        }
    }

    /** Resultado de registrar el XP de un viaje: cuánto, y si falta sumarlo al usuario. */
    private record Otorgado(double xp, boolean aplicar, XpEvento evento) {
    }

    private void marcarAplicado(Otorgado o) {
        if (o.evento() != null && !o.evento().isAplicado()) {
            o.evento().setAplicado(true);
            xpRepository.save(o.evento());
        }
    }

    /**
     * Cobro final del modelo con la comisión real del conductor. Usa la distancia y el multiplicador fijados al
     * cotizar, así que el precio solo puede bajar respecto a la cotización.
     */
    private DesgloseTarifa desgloseDefinitivo(Servicio s, int nivelConductorAnterior) {
        double m = s.getDesglose() != null && s.getDesglose().getFactorDinamico() >= 1.0
                ? s.getDesglose().getFactorDinamico()
                : modeloTarifa.multiplicador();
        // Si el conductor finalizó antes de la mitad del recorrido, se factura solo esa fracción del viaje
        double fraccion = s.getFraccionCobrada() != null && s.getFraccionCobrada() > 0 && s.getFraccionCobrada() <= 1.0
                ? s.getFraccionCobrada() : 1.0;
        ModeloTarifa.Cobro cobro = modeloTarifa.cobrar(s.getDistanciaKM() * fraccion, m, Math.max(1, s.getNivelPasajero()),
                modeloTarifa.comision(nivelConductorAnterior), s.getMinutosEspera());
        s.setTarifa(cobro.precio());
        DesgloseTarifa d = DesgloseTarifa.deCobro(cobro, true);
        conExtraVoluntario(d, s.getExtraVoluntario());
        return d;
    }

    /**
     * El extra voluntario va completo al conductor: suma al total del pasajero y a la ganancia, sin
     * tocar comisión, descuento ni margen de la plataforma (modelo v2.2, sección 12A).
     */
    static void conExtraVoluntario(DesgloseTarifa d, long extra) {
        if (extra <= 0) {
            return;
        }
        d.setExtraVoluntario(extra);
        d.setTotalPasajero(d.getTotalPasajero() + extra);
        d.setGananciaConductor(d.getGananciaConductor() + extra);
    }

    /**
     * La calificación llega después de finalizar: ajusta el XP del conductor por el factor de calificación
     * (ecuación 23). Devuelve el delta aplicado (0 si no hubo cambio).
     */
    public double registrarCalificacionConductor(Servicio s) {
        if (s.getConductor() == null || s.getCalificacionConductor() == null || s.getId() == null) {
            return 0;
        }
        ObjectId conductorId = s.getConductor().getId();
        Optional<XpEvento> viaje = xpRepository.findByViajeIdAndRolAndMotivo(s.getId(), Rol.CONDUCTOR, XpEvento.MOTIVO_VIAJE);
        if (viaje.isEmpty() || xpRepository.existsByViajeIdAndRolAndMotivo(s.getId(), Rol.CONDUCTOR,
                XpEvento.MOTIVO_AJUSTE_CALIFICACION)) {
            return 0;
        }
        double factor = modeloXp.factorCalificacion(s.getCalificacionConductor()) - modeloXp.factorCalificacion(null);
        double delta = unDecimal(viaje.get().getXp() * factor);
        try {
            xpRepository.save(XpEvento.builder().usuarioId(conductorId).rol(Rol.CONDUCTOR).viajeId(s.getId())
                    .xp(delta).motivo(XpEvento.MOTIVO_AJUSTE_CALIFICACION)
                    .nota("calificacion=" + s.getCalificacionConductor()).aplicado(true).creadoEn(ahora()).build());
        } catch (DuplicateKeyException e) {
            return 0;
        }
        Conductor conductor = cargar(conductorId, Conductor.class);
        if (conductor != null) {
            conductor.setXpTotal(Math.max(0, unDecimal(conductor.getXpTotal() + delta)));
            recalcularConductor(conductor);
            usuarioRepository.save(conductor);
        }
        s.setXpGanadoConductor(unDecimal(s.getXpGanadoConductor() + delta));
        return delta;
    }

    // ═════════════════════════ CONDUCTOR: ventana y calidad ═════════════════════════

    /** Actualiza xp90d, métricas de calidad y nivel. No persiste. */
    public StatsConductor recalcularConductor(Conductor c) {
        LocalDateTime ahora = ahora();
        LocalDateTime desde = ahora.minusDays(cfg.getConductor().getVentanaDias());
        double xp90 = Math.max(0, unDecimal(xpRepository.findByUsuarioIdAndRolAndCreadoEnAfter(c.getId(), Rol.CONDUCTOR, desde)
                .stream().mapToDouble(XpEvento::getXp).sum()));
        StatsConductor stats = estadisticas(c, desde);
        guardarEnCache(c, stats);
        int nivel = modeloXp.nivelConductor(xp90, stats);
        if (nivel != c.getNivel()) {
            c.setNivel(nivel);
            c.setNivelActualizadoEn(ahora);
        }
        c.setXp90d(xp90);
        return stats;
    }

    /** Métricas de la ventana móvil, con caché corta (nexa.conductor.cache-stats-segundos; 0 = sin caché). */
    public StatsConductor estadisticasCacheadas(Conductor c) {
        long ttlMs = cfg.getConductor().getCacheStatsSegundos() * 1000L;
        if (ttlMs > 0) {
            StatsEnCache enCache = cacheStats.get(c.getId());
            if (enCache != null && enCache.expiraMs() > System.currentTimeMillis()) {
                return enCache.stats();
            }
        }
        StatsConductor stats = estadisticas(c, ahora().minusDays(cfg.getConductor().getVentanaDias()));
        guardarEnCache(c, stats);
        return stats;
    }

    private void guardarEnCache(Conductor c, StatsConductor stats) {
        long ttlMs = cfg.getConductor().getCacheStatsSegundos() * 1000L;
        if (ttlMs > 0) {
            cacheStats.put(c.getId(), new StatsEnCache(stats, System.currentTimeMillis() + ttlMs));
        }
    }

    public StatsConductor estadisticas(Conductor c, LocalDateTime desde) {
        List<Servicio> servicios = servicioRepository.findResumenDeCalidad(c.getId(), desde);
        double suma = 0;
        int calificados = 0;
        int finalizados = 0;
        int cancelados = 0;
        for (Servicio s : servicios) {
            if (s.getCalificacionConductor() != null) {
                suma += s.getCalificacionConductor();
                calificados++;
            }
            if (s.getEstado() == EstadoServicio.FINALIZADO) {
                finalizados++;
            } else if (s.getEstado() == EstadoServicio.CANCELADO && "CONDUCTOR".equals(s.getCanceladoPor())) {
                cancelados++;
            }
        }
        int aceptados = finalizados + cancelados;
        return new StatsConductor(calificados == 0 ? null : suma / calificados,
                aceptados == 0 ? 1.0 : (double) finalizados / aceptados,
                aceptados == 0 ? 0.0 : (double) cancelados / aceptados);
    }

    /**
     * Comisión φ de la plataforma para este conductor según su nivel. Sirve para mostrarle lo que ganaría
     * con cada solicitud; el cobro definitivo se sigue calculando al finalizar.
     */
    public double comisionDe(Conductor conductor) {
        return modeloTarifa.comision(nivelDe(conductor));
    }

    // ═════════════════════════ MATCHING / PRIORIDAD ═════════════════════════

    /** Filtra por la ventana de prioridad y ordena por puntaje para un conductor. */
    public List<Servicio> ordenarParaConductor(List<Servicio> disponibles, Conductor conductor, Double lat, Double lng) {
        Double calificacion = estadisticasCacheadas(conductor).calificacion();
        Map<ObjectId, List<ObjectId>> favoritosPorPasajero = favoritosDe(disponibles);
        LocalDateTime ahora = ahora();
        Map<String, Double> puntajes = new HashMap<>();
        List<Servicio> visibles = new ArrayList<>();
        for (Servicio s : disponibles) {
            int nivel = Math.max(1, s.getNivelPasajero());
            Double eta = etaA(s, lat, lng);
            boolean favorito = s.getPasajero() != null && favoritosPorPasajero
                    .getOrDefault(s.getPasajero().getId(), List.of()).contains(conductor.getId());
            long segundos = s.getSolicitadoEn() == null ? Long.MAX_VALUE
                    : Duration.between(s.getSolicitadoEn(), ahora).getSeconds();
            if (prioridad.visiblePara(nivel, calificacion, favorito && prioridad.favoritoCercano(nivel, eta), segundos)) {
                visibles.add(s);
                puntajes.put(s.getId(), prioridad.puntaje(nivel, calificacion, eta, favorito));
            }
        }
        visibles.sort((a, b) -> Double.compare(puntajes.get(b.getId()), puntajes.get(a.getId())));
        return visibles; // sort estable: a igual puntaje se conserva el orden por fecha
    }

    /** Un conductor no puede aceptar un pedido que aún no le es visible por prioridad. */
    public void verificarPuedeAceptar(Servicio s, Conductor conductor) {
        if (ordenarParaConductor(List.of(s), conductor, null, null).isEmpty()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Este viaje tiene prioridad para conductores mejor calificados. Intenta en unos segundos.");
        }
    }

    private Double etaA(Servicio s, Double lat, Double lng) {
        if (lat == null || lng == null || s.getUbicacionOrigen() == null) {
            return null;
        }
        return prioridad.etaMinutos(PrioridadRecogida.distanciaKm(lat, lng,
                s.getUbicacionOrigen().getLatitud(), s.getUbicacionOrigen().getLongitud()));
    }

    /** Favoritos de los pasajeros que ya los tienen, con una sola consulta (no una por pedido). */
    private Map<ObjectId, List<ObjectId>> favoritosDe(List<Servicio> servicios) {
        Set<String> ids = new HashSet<>();
        for (Servicio s : servicios) {
            if (prioridad.puedeTenerFavoritos(Math.max(1, s.getNivelPasajero())) && s.getPasajero() != null
                    && s.getPasajero().getId() != null) {
                ids.add(s.getPasajero().getIdString());
            }
        }
        Map<ObjectId, List<ObjectId>> favoritos = new HashMap<>();
        if (!ids.isEmpty()) {
            for (Usuario u : usuarioRepository.findAllById(ids)) {
                if (u instanceof Pasajero p && p.getConductoresFavoritos() != null) {
                    favoritos.put(p.getId(), p.getConductoresFavoritos());
                }
            }
        }
        return favoritos;
    }

    // ═════════════════════════ PASAJERO: favoritos ═════════════════════════

    public void cambiarFavorito(Pasajero p, String conductorId, boolean agregar) {
        if (!prioridad.puedeTenerFavoritos(nivelDe(p))) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Los conductores favoritos se desbloquean en el nivel " + cfg.getBeneficios().getFavoritosDesdeNivel());
        }
        if (!ObjectId.isValid(conductorId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Conductor inválido");
        }
        ObjectId id = new ObjectId(conductorId);
        if (cargar(id, Conductor.class) == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Conductor no encontrado");
        }
        List<ObjectId> favoritos = p.getConductoresFavoritos() == null ? new ArrayList<>()
                : new ArrayList<>(p.getConductoresFavoritos());
        if (agregar && !favoritos.contains(id)) {
            favoritos.add(id);
        } else if (!agregar) {
            favoritos.remove(id);
        }
        p.setConductoresFavoritos(favoritos);
        usuarioRepository.save(p);
    }

    // ═════════════════════════ ESTADO PARA LOS DASHBOARDS ═════════════════════════

    public NivelDto estado(Usuario usuario) {
        boolean esConductor = usuario instanceof Conductor;
        Gamificado g = (Gamificado) usuario;
        int nivel = nivelDe(g);
        int maxConductor = modeloXp.nivelMaximoConductor();

        double xp = esConductor ? ((Conductor) usuario).getXp90d() : g.getXpTotal();
        double xpNivelActual = esConductor ? modeloXp.xpConductorParaNivel(nivel) : modeloXp.xpParaNivel(nivel);
        boolean ultimo = esConductor && nivel >= maxConductor;
        Double xpSig = ultimo ? null : (esConductor ? modeloXp.xpConductorParaNivel(nivel + 1) : modeloXp.xpParaNivel(nivel + 1));
        double progreso = xpSig == null ? 1.0
                : Math.max(0, Math.min(1.0, (xp - xpNivelActual) / (xpSig - xpNivelActual)));
        double faltante = xpSig == null ? 0 : Math.max(0, unDecimal(xpSig - xp));

        // Escalera: del 1 al 5 como mínimo y hasta un nivel por encima del actual (el pasajero no tiene techo).
        int hasta = esConductor ? maxConductor : Math.max(5, nivel + 1);
        List<NivelDto.NivelInfo> niveles = new ArrayList<>();
        List<BeneficioInfo> activos = new ArrayList<>();
        for (int n = 1; n <= hasta; n++) {
            List<BeneficioInfo> beneficios = esConductor ? List.of()
                    : catalogo.delNivel(n).stream()
                            .map(b -> new BeneficioInfo(b.clave(), b.titulo(), b.descripcion(), b.nivel(), b.nivel() <= nivel))
                            .toList();
            if (n <= nivel) {
                activos.addAll(beneficios);
            }
            niveles.add(new NivelDto.NivelInfo(n, esConductor ? modeloXp.xpConductorParaNivel(n) : modeloXp.xpParaNivel(n),
                    esConductor ? null : modeloTarifa.descuentoNivel(n), beneficios,
                    esConductor ? modeloTarifa.comision(n) : null));
        }

        NivelDto.ConductorInfo infoConductor = null;
        if (esConductor) {
            StatsConductor stats = estadisticasCacheadas((Conductor) usuario);
            List<NivelDto.Requisito> reqs = ultimo ? List.of()
                    : modeloXp.requisitos(nivel + 1, stats).stream()
                            .map(r -> new NivelDto.Requisito(r.texto(), r.cumplido())).toList();
            boolean bloqueado = xpSig != null && xp >= xpSig;
            infoConductor = new NivelDto.ConductorInfo(modeloTarifa.comision(nivel),
                    ultimo ? null : modeloTarifa.comision(nivel + 1), stats.calificacion(),
                    stats.aceptacion(), stats.cancelacion(), reqs, bloqueado);
        }

        return new NivelDto(usuario.getIdString(), esConductor ? "conductor" : "pasajero", nivel, unDecimal(xp),
                xpNivelActual, xpSig, faltante, progreso, esConductor ? 0 : modeloTarifa.descuentoNivel(nivel),
                esConductor ? 0 : prioridad.ventanaSegundos(nivel), niveles, activos, infoConductor);
    }

    // ═════════════════════════ MANTENIMIENTO DIARIO ═════════════════════════

    /** Baja un nivel a los pasajeros inactivos y recalcula la ventana de los conductores. */
    public void mantenimientoDiario() {
        LocalDateTime ahora = ahora();
        LocalDateTime limite = ahora.minusDays(cfg.getNiveles().getInactividadDias());
        int pagina = 0;
        Page<Usuario> pasajeros;
        do {
            pasajeros = usuarioRepository.findByRol(Rol.PASAJERO, PageRequest.of(pagina++, 200, Sort.by("id")));
            for (Usuario u : pasajeros) {
                if (u instanceof Pasajero p) {
                    if (bajaPorInactividad(p, limite, ahora)) {
                        Map<String, Object> campos = new HashMap<>();
                        campos.put("nivel", p.getNivel());
                        campos.put("xpTotal", p.getXpTotal());
                        campos.put("nivelActualizadoEn", p.getNivelActualizadoEn());
                        actualizarCampos(p.getId(), campos);
                    } else if (debeAvisarInactividad(p, ahora)) {
                        avisarInactividad(p, ahora);
                    }
                }
            }
        } while (pasajeros.hasNext());

        pagina = 0;
        Page<Usuario> conductores;
        do {
            conductores = usuarioRepository.findByRol(Rol.CONDUCTOR, PageRequest.of(pagina++, 200, Sort.by("id")));
            for (Usuario u : conductores) {
                if (u instanceof Conductor c) {
                    int nivelAntes = c.getNivel();
                    double xpAntes = c.getXp90d();
                    recalcularConductor(c);
                    if (c.getNivel() != nivelAntes || c.getXp90d() != xpAntes) {
                        Map<String, Object> campos = new HashMap<>();
                        campos.put("nivel", c.getNivel());
                        campos.put("xp90d", c.getXp90d());
                        campos.put("nivelActualizadoEn", c.getNivelActualizadoEn());
                        actualizarCampos(c.getId(), campos);
                    }
                }
            }
        } while (conductores.hasNext());
    }

    /**
     * Actualiza solo los campos indicados ($set) para no sobrescribir con una lectura vieja
     * otros cambios del usuario (contraseña, favoritos...).
     */
    private void actualizarCampos(ObjectId id, Map<String, Object> campos) {
        Update update = new Update();
        campos.forEach((campo, valor) -> {
            if (valor != null) {
                update.set(campo, valor);
            }
        });
        mongoTemplate.updateFirst(Query.query(Criteria.where("_id").is(id)), update, Usuario.class);
    }

    /** true si el pasajero bajó de nivel (ecuación 21: al inicio del nivel anterior). Visible para pruebas. */
    /** Desde cuándo se cuenta la inactividad: su último viaje válido, el último cambio de nivel o su registro. */
    LocalDateTime referenciaInactividad(Pasajero p, LocalDateTime ahora) {
        LocalDateTime referencia = Collections.max(Arrays.asList(
                p.getUltimoViajeEn() == null ? LocalDateTime.MIN : p.getUltimoViajeEn(),
                p.getNivelActualizadoEn() == null ? LocalDateTime.MIN : p.getNivelActualizadoEn()));
        return referencia.equals(LocalDateTime.MIN)
                ? (p.getFechaRegistro() == null ? ahora : p.getFechaRegistro())
                : referencia;
    }

    /** Día en que el pasajero bajaría de nivel si no vuelve a viajar. */
    LocalDateTime fechaBajaPorInactividad(Pasajero p, LocalDateTime ahora) {
        return referenciaInactividad(p, ahora).plusDays(cfg.getNiveles().getInactividadDias());
    }

    /**
     * Se avisa una sola vez por periodo de inactividad, en los días previos a la baja
     * ({@code nexa.niveles.aviso-inactividad-dias}). Volver a viajar reinicia el aviso.
     */
    boolean debeAvisarInactividad(Pasajero p, LocalDateTime ahora) {
        int diasAviso = cfg.getNiveles().getAvisoInactividadDias();
        if (diasAviso <= 0 || nivelDe(p) <= 1) {
            return false;
        }
        LocalDateTime baja = fechaBajaPorInactividad(p, ahora);
        if (ahora.isBefore(baja.minusDays(diasAviso)) || !ahora.isBefore(baja)) {
            return false;
        }
        LocalDateTime avisado = p.getAvisoInactividadEn();
        return avisado == null || avisado.isBefore(referenciaInactividad(p, ahora));
    }

    private void avisarInactividad(Pasajero p, LocalDateTime ahora) {
        try {
            correo.enviarAvisoInactividad(p.getEmail(), p.getNombreCompleto(), nivelDe(p),
                    fechaBajaPorInactividad(p, ahora).toLocalDate());
        } catch (RuntimeException e) {
            log.warn("No se pudo avisar la baja de nivel al pasajero {}", p.getId(), e);
            return;
        }
        p.setAvisoInactividadEn(ahora);
        actualizarCampos(p.getId(), Map.<String, Object>of("avisoInactividadEn", ahora));
    }

    boolean bajaPorInactividad(Pasajero p, LocalDateTime limite, LocalDateTime ahora) {
        if (nivelDe(p) <= 1) {
            return false;
        }
        LocalDateTime referencia = referenciaInactividad(p, ahora);
        if (!referencia.isBefore(limite)) {
            return false;
        }
        double nuevoXp = modeloXp.xpTrasInactividad(p.getXpTotal());
        if (nuevoXp >= p.getXpTotal()) {
            return false;
        }
        p.setXpTotal(nuevoXp);
        p.setNivel(modeloXp.nivelPasajero(nuevoXp));
        p.setNivelActualizadoEn(ahora);
        return true;
    }

    // ═════════════════════════ UTILIDADES ═════════════════════════

    private <T extends Usuario> T cargar(ObjectId id, Class<T> tipo) {
        if (id == null) {
            return null;
        }
        return usuarioRepository.findById(id.toString()).filter(tipo::isInstance).map(tipo::cast).orElse(null);
    }
}
