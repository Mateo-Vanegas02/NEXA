package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.Dispositivo;
import com.example.MotvirsWeb.dominio.modelo.Usuario;
import com.example.MotvirsWeb.dominio.repositorio.DispositivoRepository;
import lombok.RequiredArgsConstructor;
import org.bson.types.ObjectId;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Teléfonos de cada usuario para los avisos push. La app registra su token al iniciar sesión (y cuando FCM lo
 * rota) y lo quita al cerrar sesión. Un usuario guarda como máximo {@link #MAX_POR_USUARIO} teléfonos: los más
 * viejos se descartan.
 */
@Service
@RequiredArgsConstructor
public class DispositivosService {

    static final int MAX_POR_USUARIO = 5;

    private final DispositivoRepository repositorio;
    private final Clock clock;

    /** Registra o actualiza el token; si estaba a nombre de otra cuenta (mismo teléfono), pasa a esta. */
    public void registrar(Usuario usuario, String token, String plataforma) {
        String limpio = token.trim();
        try {
            guardar(usuario, limpio, plataforma);
        } catch (DuplicateKeyException e) {
            guardar(usuario, limpio, plataforma); // otra petición lo creó a la vez: ahora existe y se actualiza
        }
        List<Dispositivo> suyos = repositorio.findByUsuarioIdOrderByActualizadoEnDesc(usuario.getId());
        if (suyos.size() > MAX_POR_USUARIO) {
            repositorio.deleteAll(suyos.subList(MAX_POR_USUARIO, suyos.size()));
        }
    }

    private void guardar(Usuario usuario, String token, String plataforma) {
        Dispositivo d = repositorio.findByToken(token).orElseGet(Dispositivo::new);
        d.setToken(token);
        d.setUsuarioId(usuario.getId());
        d.setRol(usuario.getRol());
        d.setPlataforma(plataforma == null ? "ANDROID" : plataforma);
        d.setActualizadoEn(LocalDateTime.now(clock));
        repositorio.save(d);
    }

    /** Quita el token de esa cuenta (cerrar sesión); no toca el de otras cuentas. */
    public void eliminar(Usuario usuario, String token) {
        repositorio.deleteByUsuarioIdAndToken(usuario.getId(), token.trim());
    }

    public List<String> tokensDe(ObjectId usuarioId) {
        if (usuarioId == null) {
            return List.of();
        }
        return repositorio.findByUsuarioIdOrderByActualizadoEnDesc(usuarioId).stream().map(Dispositivo::getToken).toList();
    }

    /** Tokens de varios usuarios a la vez (una sola consulta). */
    public Map<ObjectId, List<String>> tokensDe(Collection<ObjectId> usuarioIds) {
        if (usuarioIds == null || usuarioIds.isEmpty()) {
            return Map.of();
        }
        return repositorio.findByUsuarioIdIn(usuarioIds).stream().collect(Collectors.groupingBy(
                Dispositivo::getUsuarioId, Collectors.mapping(Dispositivo::getToken, Collectors.toList())));
    }
}
