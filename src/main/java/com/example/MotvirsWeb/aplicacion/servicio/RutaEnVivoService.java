package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.ProveedorRutas;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.regla.Ruta;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.presentacion.dto.RutasEnVivoDto;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Clock;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Rutas en vivo del conductor: cuando toma otra calle, la app pide rutas nuevas desde donde va (hasta tres) y él
 * elige una. Con el viaje en curso, la elegida reemplaza el trazado que ve el pasajero; yendo a recoger solo la usa el
 * conductor. El precio no cambia: se cobra según lo recorrido. Solo se puede elegir una de las rutas que el servidor
 * acaba de ofrecer (se recuerdan 10 minutos en memoria), así la app no guarda trazados arbitrarios.
 */
@Service
public class RutaEnVivoService {

    static final long VIGENCIA_OFERTA_MS = 10 * 60 * 1000L;
    private static final int MAX_OFERTAS = 2000;

    private record Oferta(String conductorId, List<String> geometrias, long vence) {
    }

    private final ServicioRepository servicios;
    private final ProveedorRutas rutas;
    private final Clock clock;
    private final Map<String, Oferta> ofertas = new ConcurrentHashMap<>();

    public RutaEnVivoService(ServicioRepository servicios, ProveedorRutas rutas, Clock clock) {
        this.servicios = servicios;
        this.rutas = rutas;
        this.clock = clock;
    }

    public RutasEnVivoDto.Alternativas alternativas(Conductor conductor, String servicioId, PuntoGeo desde) {
        Servicio s = viajeDe(conductor, servicioId);
        boolean enCurso = s.getEstado() == EstadoServicio.EN_CURSO;
        Servicio.Coordenada c = enCurso ? s.getUbicacionDestino() : s.getUbicacionOrigen();
        if (c == null) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "El viaje no tiene destino con coordenadas");
        }
        List<Ruta> encontradas = rutas.alternativas(desde, new PuntoGeo(c.getLatitud(), c.getLongitud()));
        List<RutasEnVivoDto.Opcion> opciones = opciones(encontradas);
        long ahora = clock.millis();
        if (ofertas.size() >= MAX_OFERTAS) {
            ofertas.values().removeIf(o -> o.vence() <= ahora);
        }
        ofertas.put(servicioId, new Oferta(conductor.getIdString(),
                opciones.stream().map(RutasEnVivoDto.Opcion::geometria).toList(), ahora + VIGENCIA_OFERTA_MS));
        return new RutasEnVivoDto.Alternativas(servicioId, enCurso ? "EN_CURSO" : "ACEPTADO", opciones);
    }

    public RutasEnVivoDto.Elegida elegir(Conductor conductor, String servicioId, int indice) {
        Servicio s = viajeDe(conductor, servicioId);
        Oferta o = ofertas.get(servicioId);
        if (o == null || o.vence() <= clock.millis() || !o.conductorId().equals(conductor.getIdString())
                || indice < 0 || indice >= o.geometrias().size()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Pide las rutas otra vez");
        }
        String geometria = o.geometrias().get(indice);
        if (geometria == null || geometria.isBlank()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Esa ruta no tiene trazado");
        }
        boolean compartida = s.getEstado() == EstadoServicio.EN_CURSO
                && servicios.cambiarRutaEnCurso(servicioId, conductor.getId(), geometria) > 0;
        return new RutasEnVivoDto.Elegida(servicioId, geometria, compartida);
    }

    /** Ordena la más rápida primero y marca la más rápida y la más corta. */
    static List<RutasEnVivoDto.Opcion> opciones(List<Ruta> encontradas) {
        List<Ruta> conTrazado = new ArrayList<>(encontradas.stream().filter(Ruta::tieneTrazado).toList());
        if (conTrazado.isEmpty()) {
            return List.of();
        }
        conTrazado.sort(Comparator.comparingDouble(Ruta::duracionMin));
        Ruta corta = conTrazado.stream().min(Comparator.comparingDouble(Ruta::distanciaKm)).orElseThrow();
        List<RutasEnVivoDto.Opcion> lista = new ArrayList<>();
        for (int i = 0; i < conTrazado.size(); i++) {
            Ruta r = conTrazado.get(i);
            String etiqueta = i == 0 ? "RAPIDA" : r == corta ? "CORTA" : "ALTERNATIVA";
            lista.add(new RutasEnVivoDto.Opcion(i, r.geometria(), redondear(r.distanciaKm()),
                    redondear(r.duracionMin()), etiqueta));
        }
        return lista;
    }

    private Servicio viajeDe(Conductor conductor, String servicioId) {
        Servicio s = servicios.findById(servicioId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Viaje no encontrado"));
        if (s.getConductor() == null || s.getConductor().getId() == null
                || !s.getConductor().getId().equals(conductor.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Ese viaje no es tuyo");
        }
        if (s.getEstado() != EstadoServicio.ACEPTADO && s.getEstado() != EstadoServicio.EN_CURSO) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "El viaje ya no está activo");
        }
        return s;
    }

    private static double redondear(double v) {
        return Math.round(v * 100) / 100.0;
    }
}
