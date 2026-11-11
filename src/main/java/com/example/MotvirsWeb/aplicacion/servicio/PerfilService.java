package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.AlmacenDocumentos;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Usuario;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.example.MotvirsWeb.presentacion.dto.PerfilDto;
import lombok.RequiredArgsConstructor;
import org.bson.types.ObjectId;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.util.Optional;
import java.util.UUID;

/** Perfil del usuario: datos editables y foto de perfil (se guarda en el mismo almacén que los documentos). */
@Service
@RequiredArgsConstructor
public class PerfilService {

    public static final long MAX_BYTES_FOTO = DocumentosConductorService.MAX_BYTES;

    private final UsuarioRepository usuarioRepository;
    private final AlmacenDocumentos almacen;

    /** Foto lista para servir: tipo + flujo (quien lo recibe lo cierra). */
    public record FotoPerfil(String contentType, InputStream flujo) {
    }

    public PerfilDto perfil(Usuario usuario) {
        String nombre;
        String telefono;
        Long licencia = null;
        if (usuario instanceof Conductor c) {
            nombre = c.getNombre_y_Apellido();
            telefono = c.getNtelefono() == null ? null : String.valueOf(c.getNtelefono());
            licencia = c.getLicencia();
        } else if (usuario instanceof Pasajero p) {
            nombre = p.getNombreCompleto();
            telefono = p.getTelefono();
        } else {
            nombre = usuario.getEmail();
            telefono = null;
        }
        String url = usuario.fotoPerfilUrl();
        // El identificador del archivo cambia con cada foto nueva: sirve de versión para la caché del navegador.
        String version = usuario.tieneFotoPerfil() ? usuario.getFotoPerfilId() : null;
        return new PerfilDto(usuario.getIdString(), usuario.getRol().name(), nombre, usuario.getEmail(), telefono,
                licencia, usuario.getEstadoValidacion() == null ? null : usuario.getEstadoValidacion().name(),
                usuario.getFechaRegistro(), url != null, url == null ? null : url + "?v=" + version);
    }

    public PerfilDto actualizarDatos(Usuario usuario, String nombre, String telefono) {
        String nombreLimpio = nombre.trim().replaceAll("\\s+", " ");
        if (usuario instanceof Conductor c) {
            c.setNombre_y_Apellido(nombreLimpio);
            c.setNtelefono(Long.parseLong(telefono));
        } else if (usuario instanceof Pasajero p) {
            p.setNombreCompleto(nombreLimpio);
            p.setTelefono(telefono);
        } else {
            throw new IllegalStateException("Este tipo de cuenta no tiene perfil editable");
        }
        return perfil(usuarioRepository.save(usuario));
    }

    /** Valida (tamaño y tipo real por contenido), guarda la foto nueva y borra la anterior. */
    public PerfilDto guardarFoto(Usuario usuario, String nombreOriginal, long tamano,
                                 DocumentosConductorService.Abridor abridor) {
        if (tamano <= 0) {
            throw new DocumentoInvalidoException("Falta la foto de perfil");
        }
        if (tamano > MAX_BYTES_FOTO) {
            throw new DocumentoInvalidoException("La foto debe pesar máximo 5 MB");
        }
        String tipo;
        try (InputStream in = abridor.abrir()) {
            tipo = DocumentosConductorService.detectarTipo(in.readNBytes(12));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        if (tipo == null) {
            throw new DocumentoInvalidoException("La foto debe ser una imagen JPG, PNG o WebP");
        }

        String anterior = usuario.getFotoPerfilId();
        String nuevoId;
        try (InputStream in = abridor.abrir()) {
            nuevoId = almacen.guardar("perfil-" + usuario.getIdString() + "-" + UUID.randomUUID() + extension(tipo),
                    tipo, in);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        usuario.setFotoPerfilId(nuevoId);
        usuario.setFotoPerfilTipo(tipo);
        Usuario guardado;
        try {
            guardado = usuarioRepository.save(usuario);
        } catch (RuntimeException e) {
            almacen.eliminar(nuevoId);
            throw e;
        }
        borrarSilencioso(anterior);
        return perfil(guardado);
    }

    public PerfilDto quitarFoto(Usuario usuario) {
        String anterior = usuario.getFotoPerfilId();
        usuario.setFotoPerfilId(null);
        usuario.setFotoPerfilTipo(null);
        Usuario guardado = usuarioRepository.save(usuario);
        borrarSilencioso(anterior);
        return perfil(guardado);
    }

    /** Foto de cualquier usuario por su id (la ven quienes comparten un viaje con él). */
    public Optional<FotoPerfil> abrirFoto(String usuarioId) {
        if (usuarioId == null || !ObjectId.isValid(usuarioId)) {
            return Optional.empty();
        }
        return usuarioRepository.findById(usuarioId)
                .filter(Usuario::tieneFotoPerfil)
                .flatMap(u -> almacen.abrir(u.getFotoPerfilId())
                        .map(f -> new FotoPerfil(u.getFotoPerfilTipo() == null ? "image/jpeg" : u.getFotoPerfilTipo(), f)));
    }

    private void borrarSilencioso(String archivoId) {
        if (archivoId == null) {
            return;
        }
        try {
            almacen.eliminar(archivoId);
        } catch (RuntimeException ignorado) {
            // Un archivo huérfano no debe impedir que el usuario cambie su foto.
        }
    }

    private static String extension(String contentType) {
        return switch (contentType) {
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            default -> ".jpg";
        };
    }
}
