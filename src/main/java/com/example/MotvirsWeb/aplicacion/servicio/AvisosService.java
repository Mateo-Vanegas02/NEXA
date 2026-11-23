package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorPush;
import com.example.MotvirsWeb.aplicacion.puerto.NotificadorPush.Aviso;
import com.example.MotvirsWeb.aplicacion.puerto.NotificadorPush.Canal;
import com.example.MotvirsWeb.dominio.modelo.CanalServicio;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.modelo.Usuario;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.bson.types.ObjectId;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Avisos push por evento de negocio, solo para viajes pedidos desde la app (los de la web siguen con STOMP).
 *
 * <p>El servidor decide a quién y qué decir: el texto se arma para cada destinatario con lo que ese rol puede ver
 * (el conductor ve su ganancia, nunca la comisión; el pasajero ve nombre, moto y placa de su conductor). El aviso
 * lleva además el id del evento y del viaje para que la app abra la pantalla correcta y pida el detalle a la API.
 * Ningún aviso puede romper el flujo del viaje: todo error se registra y se sigue.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AvisosService {

    private static final Locale ES_CO = Locale.forLanguageTag("es-CO");

    private final NotificadorPush push;
    private final DispositivosService dispositivos;
    private final UbicacionConductorService ubicaciones;
    private final DespachoService despacho;
    private final NivelesService niveles;
    private final UsuarioRepository usuarios;
    private final ModeloNexaProperties cfg;

    /** Conductores a los que se les avisó cada solicitud abierta: a ellos va el retiro silencioso. */
    private final Map<String, Set<ObjectId>> avisados = new ConcurrentHashMap<>();
    private final ThreadLocal<Boolean> confirmado = ThreadLocal.withInitial(() -> false);
    /** En un reintento parcial, solo estos tokens; null = todos. */
    private final ThreadLocal<Set<String>> soloTokens = new ThreadLocal<>();
    private final ThreadLocal<Set<String>> tokensFallidos = new ThreadLocal<>();

    public void ejecutarConfirmado(Runnable envio) {
        ejecutarConfirmado(null, envio);
    }

    /**
     * Ejecuta los avisos esperando la confirmación del proveedor (lo usa la bandeja persistente). Los errores
     * no se absorben; si algún token no se confirmó, al final lanza {@link NotificadorPush.EnvioIncompleto}
     * con todos ellos. Con {@code solo} no vacío, envía únicamente a esos tokens (reintento parcial).
     */
    public void ejecutarConfirmado(Collection<String> solo, Runnable envio) {
        confirmado.set(true);
        soloTokens.set(solo == null || solo.isEmpty() ? null : Set.copyOf(solo));
        tokensFallidos.set(new LinkedHashSet<>());
        try {
            envio.run();
            if (!tokensFallidos.get().isEmpty()) {
                throw new NotificadorPush.EnvioIncompleto(tokensFallidos.get());
            }
        } finally {
            confirmado.remove();
            soloTokens.remove();
            tokensFallidos.remove();
        }
    }

    private void enviarPush(Collection<String> tokens, Aviso aviso) {
        if (!confirmado.get()) {
            push.enviar(tokens, aviso);
            return;
        }
        if (tokens == null || tokens.isEmpty()) {
            return;
        }
        Set<String> solo = soloTokens.get();
        List<String> destino = tokens.stream().filter(t -> solo == null || solo.contains(t)).toList();
        if (destino.isEmpty()) {
            return;
        }
        try {
            push.enviarConConfirmacion(destino, aviso);
        } catch (NotificadorPush.EnvioIncompleto e) {
            tokensFallidos.get().addAll(e.tokensFallidos()); // se sigue con los demás destinatarios
        }
    }

    /** Destinatarios de una solicitud abierta; la bandeja los conserva antes de retirar la tarjeta. */
    public List<ObjectId> destinatariosRetirada(String servicioId) {
        return List.copyOf(avisados.getOrDefault(servicioId, Set.of()));
    }

    public void solicitudRetiradaA(Servicio s, String motivo, Collection<ObjectId> destinatarios) {
        seguro("solicitud retirada", () -> {
            if (!deApp(s) || destinatarios == null || destinatarios.isEmpty()) return;
            Set<ObjectId> otros = new LinkedHashSet<>(destinatarios);
            if (s.getConductor() != null) otros.remove(s.getConductor().getId());
            Aviso aviso = new Aviso("SOLICITUD_RETIRADA:" + s.getId(), "SOLICITUD_RETIRADA", Canal.SILENCIOSO,
                    null, null, Map.of("servicioId", s.getId(), "motivo", motivo), vigenciaSolicitud());
            enviarPush(tokens(otros), aviso);
            avisados.remove(s.getId());
        });
    }

    // ─────────────────────────── CONDUCTORES ───────────────────────────

    /** Solicitud recién creada: a los conductores de la app dentro de la primera ola. */
    public void solicitudNueva(Servicio s) {
        seguro("solicitud nueva", () -> {
            if (!deApp(s)) {
                return;
            }
            int ola = despacho.olaDe(s);
            avisarSolicitud(s, conductoresEntre(s, 0, ola), "SOLICITUD_NUEVA", ola);
            busquedaAlPasajero(s, "SOLICITUD_RECIBIDA", ola);
        });
    }

    /** La solicitud pasó a una ola más amplia: solo a los que entran ahora (los de antes ya la tienen). */
    public void olaAmpliada(Servicio s, int olaAnterior, int ola) {
        seguro("ola ampliada", () -> {
            if (!deApp(s) || ola <= olaAnterior) {
                return;
            }
            // Con extra la ola salta: quien ya recibió el aviso del extra no recibe además el de solicitud nueva
            Set<ObjectId> yaAvisados = avisados.getOrDefault(s.getId(), Set.of());
            List<ObjectId> nuevos = conductoresEntre(s, olaAnterior, ola).stream()
                    .filter(id -> !yaAvisados.contains(id)).toList();
            avisarSolicitud(s, nuevos, "SOLICITUD_NUEVA", ola);
            busquedaAlPasajero(s, "BUSQUEDA_AMPLIADA", ola);
        });
    }

    /** Olvida a quién se avisó de las solicitudes que ya no están abiertas (las cierra cualquier camino). */
    public void olvidarCerradas(Collection<String> abiertas) {
        avisados.keySet().retainAll(abiertas);
    }

    /** El pasajero subió el extra: a todos los que ya la ven, con la ganancia nueva. */
    public void extraSubido(Servicio s) {
        seguro("extra subido", () -> {
            if (!deApp(s)) {
                return;
            }
            int ola = despacho.olaDe(s);
            Set<ObjectId> destino = new LinkedHashSet<>(conductoresEntre(s, 0, ola));
            destino.addAll(avisados.getOrDefault(s.getId(), Set.of()));
            avisarSolicitud(s, destino, "SOLICITUD_EXTRA", s.getExtraVoluntario());
        });
    }

    /** La solicitud ya no está (la tomó otro o se canceló): la app quita la tarjeta sin mostrar nada. */
    public void solicitudRetirada(Servicio s, String motivo) {
        solicitudRetiradaA(s, motivo, destinatariosRetirada(s.getId()));
    }

    // ─────────────────────────── EL VIAJE ───────────────────────────

    public void viajeAceptado(Servicio s) {
        seguro("viaje aceptado", () -> {
            if (!deApp(s) || s.getConductor() == null) {
                return;
            }
            Servicio.ConductorEmbedded c = s.getConductor();
            String moto = unir(" · ", c.getVehiculo(), c.getPlaca());
            alPasajero(s, "VIAJE_ACEPTADO", primerNombre(c.getNombre(), "Tu conductor") + " va por ti",
                    moto.isEmpty() ? "Va en camino a tu punto de recogida" : moto);
        });
    }

    public void conductorLlego(Servicio s) {
        seguro("conductor llegó", () -> {
            if (!deApp(s) || s.getConductor() == null) {
                return;
            }
            Servicio.ConductorEmbedded c = s.getConductor();
            alPasajero(s, "CONDUCTOR_LLEGO", primerNombre(c.getNombre(), "Tu conductor") + " está en el punto",
                    c.getPlaca() == null || c.getPlaca().isBlank() ? "Sal a su encuentro" : "Busca la placa " + c.getPlaca());
        });
    }

    /** El conductor recogió al pasajero y arrancó: la notificación del viaje pasa a «en camino». */
    public void viajeIniciado(Servicio s) {
        seguro("viaje iniciado", () -> {
            if (deApp(s)) {
                alPasajero(s, "VIAJE_INICIADO",
                        s.getDestino() == null || s.getDestino().isBlank() ? "Vas en camino"
                                : "Vas camino a " + s.getDestino(),
                        "Sigue el recorrido en vivo desde la app");
            }
        });
    }

    public void viajeFinalizado(Servicio s) {
        seguro("viaje finalizado", () -> {
            if (deApp(s)) {
                alPasajero(s, "VIAJE_FINALIZADO", "Llegaste a tu destino", "Toca para ver el total y calificar el viaje");
            }
        });
    }

    /** Avisa al otro lado: si canceló el pasajero, al conductor asignado; si canceló el conductor, al pasajero. */
    public void viajeCancelado(Servicio s) {
        seguro("viaje cancelado", () -> {
            if (!deApp(s)) {
                return;
            }
            if ("CONDUCTOR".equals(s.getCanceladoPor())) {
                alPasajero(s, "VIAJE_CANCELADO", "Tu conductor canceló el viaje", "Puedes pedir otro cuando quieras");
            } else if (s.getConductor() != null && s.getConductor().getId() != null) {
                String quien = primerNombre(s.getPasajero() == null ? null : s.getPasajero().getNombre(), "El pasajero");
                Aviso aviso = new Aviso("VIAJE_CANCELADO:" + s.getId(), "VIAJE_CANCELADO", Canal.VIAJE,
                        quien + " canceló el viaje", "Ya puedes recibir otras solicitudes",
                        Map.of("servicioId", s.getId()), vigenciaViaje());
                enviarPush(dispositivos.tokensDe(s.getConductor().getId()), aviso);
            }
        });
    }

    /** Pasó la última ola y nadie aceptó: se le propone al pasajero subir el extra o seguir esperando. */
    public void sinConductores(Servicio s) {
        seguro("sin conductores", () -> {
            if (deApp(s)) {
                alPasajero(s, "SIN_CONDUCTORES", "Sin conductores cerca por ahora",
                        "Seguimos buscando. Suma un extra para que te vean primero");
            }
        });
    }

    /** La solicitud esperó demasiado sin conductor y se canceló sola, sin cargo. */
    public void solicitudVencida(Servicio s) {
        seguro("solicitud vencida", () -> {
            if (deApp(s)) {
                alPasajero(s, "SOLICITUD_VENCIDA", "No encontramos conductor",
                        "Cancelamos tu solicitud sin costo. Puedes pedir otro viaje");
            }
        });
    }

    // ─────────────────────────── DETALLE ───────────────────────────

    private void avisarSolicitud(Servicio s, Collection<ObjectId> conductores, String tipo, long variante) {
        if (conductores.isEmpty()) {
            return;
        }
        avisados.computeIfAbsent(s.getId(), k -> ConcurrentHashMap.newKeySet()).addAll(conductores);
        Map<ObjectId, List<String>> tokens = dispositivos.tokensDe(conductores);
        if (tokens.isEmpty()) {
            return;
        }
        // La ganancia depende del nivel de cada conductor: se leen todos de una vez
        List<String> ids = tokens.keySet().stream().map(ObjectId::toHexString).toList();
        PuntoGeo origen = origenDe(s);
        for (Usuario u : usuarios.findAllById(ids)) {
            if (!(u instanceof Conductor conductor) || tokens.getOrDefault(conductor.getId(), List.of()).isEmpty()) {
                continue;
            }
            String ganancia = pesos(niveles.gananciaEstimada(s, conductor));
            String titulo = "SOLICITUD_EXTRA".equals(tipo)
                    ? "Ahora ganas " + ganancia + " (+" + pesos(s.getExtraVoluntario()) + ")"
                    : "Nueva solicitud · Ganas " + ganancia;
            Optional<PuntoGeo> posicion = ubicaciones.vigente(conductor.getId());
            String distancia = posicion.isPresent() && origen != null ? "A " + metros(posicion.get().distanciaKm(origen)) : null;
            String cuerpo = unir(" · ", distancia, s.getDistanciaKM() > 0 ? km(s.getDistanciaKM()) + " de viaje" : null,
                    s.getDestino());
            Map<String, String> datos = new HashMap<>();
            datos.put("servicioId", s.getId());
            datos.put("ganancia", Long.toString(niveles.gananciaEstimada(s, conductor)));
            enviarPush(tokens.get(conductor.getId()), new Aviso(tipo + ":" + s.getId() + ":" + variante, tipo,
                    Canal.SOLICITUDES, titulo, cuerpo, datos, vigenciaSolicitud()));
        }
    }

    /** Conductores de la app con posición vigente entre el radio de la ola {@code desde} y el de la ola {@code hasta}. */
    private List<ObjectId> conductoresEntre(Servicio s, int desde, int hasta) {
        PuntoGeo origen = origenDe(s);
        List<ObjectId> ids = new ArrayList<>();
        if (origen != null) {
            double radioDesde = desde <= 0 ? -1 : despacho.radioKm(desde);
            ids.addAll(ubicaciones.disponiblesEntreRadios(origen, radioDesde, despacho.radioKm(hasta), CanalServicio.APP));
        }
        // En la última ola también entran los que tienen la pantalla bloqueada y dejaron de reportar posición
        if (despacho.esUltimaOla(hasta) && !despacho.esUltimaOla(desde)) {
            ids.addAll(ubicaciones.disponiblesSinPosicionVigente(CanalServicio.APP));
        }
        return ids;
    }

    private void alPasajero(Servicio s, String tipo, String titulo, String cuerpo) {
        if (s.getPasajero() == null || s.getPasajero().getId() == null) {
            return;
        }
        enviarPush(dispositivos.tokensDe(s.getPasajero().getId()), new Aviso(tipo + ":" + s.getId(), tipo,
                Canal.VIAJE, titulo, cuerpo, datosParaPasajero(s), vigenciaViaje()));
    }

    /**
     * Lo que la app necesita para dibujar la notificación del viaje (rediseño 2026): su conductor (nombre, moto,
     * placa y nota), el destino y, al terminar, el total. Solo lo que el pasajero ya ve en la app.
     */
    static Map<String, String> datosParaPasajero(Servicio s) {
        Map<String, String> datos = new HashMap<>();
        datos.put("servicioId", s.getId());
        if (s.getDestino() != null && !s.getDestino().isBlank()) {
            datos.put("destino", s.getDestino());
        }
        Servicio.ConductorEmbedded c = s.getConductor();
        if (c != null) {
            if (c.getNombre() != null && !c.getNombre().isBlank()) {
                datos.put("conductor", c.getNombre());
            }
            if (c.getVehiculo() != null && !c.getVehiculo().isBlank()) {
                datos.put("vehiculo", c.getVehiculo());
            }
            if (c.getPlaca() != null && !c.getPlaca().isBlank()) {
                datos.put("placa", c.getPlaca());
            }
            if (c.getCalificacion() != null) {
                datos.put("calificacion", String.format(ES_CO, "%.1f", c.getCalificacion()));
            }
        }
        if (s.getEstado() == EstadoServicio.FINALIZADO) {
            Servicio.DesgloseTarifa d = s.getDesglose();
            double total = d != null && d.getTotalPasajero() > 0 ? d.getTotalPasajero() + d.getExtraVoluntario()
                    : s.getTarifa() + s.getExtraVoluntario();
            if (total > 0) {
                datos.put("total", pesos(Math.round(total + s.getDeudaCobrada())));
            }
        }
        return datos;
    }

    /** La búsqueda de conductor en la notificación del pasajero: qué ola va y hasta dónde llega. */
    private void busquedaAlPasajero(Servicio s, String tipo, int ola) {
        if (s.getPasajero() == null || s.getPasajero().getId() == null) {
            return;
        }
        List<String> tokens = dispositivos.tokensDe(s.getPasajero().getId());
        if (tokens == null || tokens.isEmpty()) {
            return;
        }
        Map<String, String> datos = datosParaPasajero(s);
        datos.put("ola", Integer.toString(Math.max(1, ola)));
        datos.put("olas", Integer.toString(despacho.totalOlas()));
        double radio = despacho.radioKm(ola);
        if (Double.isFinite(radio)) {
            datos.put("radio", km(radio));
        }
        enviarPush(tokens, new Aviso(tipo + ":" + s.getId() + ":" + ola, tipo, Canal.VIAJE,
                "Buscando tu conductor", "Avisamos a los conductores más cerca", datos, vigenciaSolicitud()));
    }

    private List<String> tokens(Collection<ObjectId> usuarios) {
        return dispositivos.tokensDe(usuarios).values().stream().flatMap(List::stream).toList();
    }

    private static boolean deApp(Servicio s) {
        return s != null && s.getId() != null && s.getCanal() == CanalServicio.APP;
    }

    private void seguro(String evento, Runnable accion) {
        if (!push.activo()) {
            return;
        }
        try {
            accion.run();
        } catch (RuntimeException e) {
            if (confirmado.get()) throw e;
            log.warn("No se pudo preparar el aviso de {}: {}", evento, e.getMessage());
        }
    }

    private Duration vigenciaSolicitud() {
        return Duration.ofSeconds(cfg.getAvisos().getVigenciaSolicitudSegundos());
    }

    private Duration vigenciaViaje() {
        return Duration.ofMinutes(cfg.getAvisos().getVigenciaViajeMinutos());
    }

    private static PuntoGeo origenDe(Servicio s) {
        if (s.getUbicacionOrigen() == null) {
            return null;
        }
        try {
            return new PuntoGeo(s.getUbicacionOrigen().getLatitud(), s.getUbicacionOrigen().getLongitud());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    static String pesos(long valor) {
        return "$" + String.format(ES_CO, "%,d", valor);
    }

    static String metros(double km) {
        return km < 1 ? Math.round(km * 1000 / 10.0) * 10 + " m" : km(km);
    }

    static String km(double km) {
        return String.format(ES_CO, "%.1f km", km);
    }

    static String primerNombre(String nombre, String siNoHay) {
        if (nombre == null || nombre.isBlank()) {
            return siNoHay;
        }
        return nombre.trim().split("\\s+")[0];
    }

    private static String unir(String separador, String... partes) {
        List<String> llenas = new ArrayList<>();
        for (String p : partes) {
            if (p != null && !p.isBlank()) {
                llenas.add(p.trim());
            }
        }
        return String.join(separador, llenas);
    }
}
