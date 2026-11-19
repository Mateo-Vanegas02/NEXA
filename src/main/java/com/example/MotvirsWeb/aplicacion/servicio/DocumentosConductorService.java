package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.AlmacenDocumentos;
import com.example.MotvirsWeb.dominio.modelo.DocumentoConductor;
import com.example.MotvirsWeb.dominio.modelo.Rol;
import com.example.MotvirsWeb.dominio.modelo.TipoDocumento;
import com.example.MotvirsWeb.dominio.repositorio.DocumentoConductorRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Fotos de los documentos del conductor: valida (tamaño y tipo real por contenido), las guarda en el almacén
 * y deja el número declarado junto a cada foto para que el administrador contraste ambos.
 */
@Service
@RequiredArgsConstructor
public class DocumentosConductorService {

    public static final long MAX_BYTES = 5L * 1024 * 1024;

    private final AlmacenDocumentos almacen;
    private final DocumentoConductorRepository repositorio;
    private final UsuarioRepository usuarioRepository;

    @FunctionalInterface
    public interface Abridor {
        InputStream abrir() throws IOException;
    }

    /** Archivo recibido del formulario, ya desacoplado de la capa web. */
    public record ArchivoSubido(TipoDocumento tipo, String numeroDeclarado, String nombreOriginal, long tamano,
                                Abridor abridor) {
    }

    /** Documento listo para servir: metadatos + flujo (quien lo recibe lo cierra). */
    public record Contenido(DocumentoConductor documento, InputStream flujo) {
    }

    /** Verifica que estén los 4 documentos, una sola vez cada uno, y que cada archivo sea válido. */
    /**
     * ¿Algún otro conductor declaró esta tarjeta de propiedad al subir sus fotos (registro o vehículo agregado)?
     * {@code exceptoConductorId} null = cualquiera (registro nuevo).
     */
    public boolean tarjetaDeclaradaPorOtro(long tarjeta, String exceptoConductorId) {
        return tarjeta > 0 && repositorio.existeTarjetaDeclaradaPorOtro(String.valueOf(tarjeta), exceptoConductorId);
    }

    public void validarConjunto(List<ArchivoSubido> archivos) {
        Set<TipoDocumento> vistos = EnumSet.noneOf(TipoDocumento.class);
        for (ArchivoSubido a : archivos) {
            if (!vistos.add(a.tipo())) {
                throw new DocumentoInvalidoException("Subiste dos veces la " + a.tipo().etiqueta());
            }
            validar(a);
        }
        for (TipoDocumento t : TipoDocumento.values()) {
            if (!vistos.contains(t)) {
                throw new DocumentoInvalidoException("Falta la foto de la " + t.etiqueta());
            }
        }
    }

    /** Para un vehículo nuevo: tarjeta de propiedad, SOAT y tecnomecánica, una vez cada una y válidas. */
    public void validarVehiculo(List<ArchivoSubido> archivos) {
        Set<TipoDocumento> vistos = EnumSet.noneOf(TipoDocumento.class);
        for (ArchivoSubido a : archivos) {
            if (!a.tipo().esDeVehiculo()) {
                throw new DocumentoInvalidoException("La " + a.tipo().etiqueta() + " no corresponde a un vehículo");
            }
            if (!vistos.add(a.tipo())) {
                throw new DocumentoInvalidoException("Subiste dos veces la " + a.tipo().etiqueta());
            }
            validar(a);
        }
        for (TipoDocumento t : TipoDocumento.values()) {
            if (t.esDeVehiculo() && !vistos.contains(t)) {
                throw new DocumentoInvalidoException("Falta la foto de la " + t.etiqueta());
            }
        }
    }

    /** Valida un archivo y devuelve su tipo real (image/jpeg, image/png o image/webp). */
    public String validar(ArchivoSubido a) {
        String que = a.tipo().etiqueta();
        if (a.tamano() <= 0) {
            throw new DocumentoInvalidoException("Falta la foto de la " + que);
        }
        if (a.tamano() > MAX_BYTES) {
            throw new DocumentoInvalidoException("La foto de la " + que + " pesa más de 5 MB");
        }
        byte[] cabecera;
        try (InputStream in = a.abridor().abrir()) {
            cabecera = in.readNBytes(12);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        String tipo = detectarTipo(cabecera);
        if (tipo == null) {
            throw new DocumentoInvalidoException("La foto de la " + que + " debe ser una imagen JPG, PNG o WebP");
        }
        return tipo;
    }

    /** Guarda todos los archivos; si uno falla, borra lo ya guardado y relanza el error. */
    public List<DocumentoConductor> guardarTodos(String conductorId, String vehiculoId, List<ArchivoSubido> archivos) {
        List<DocumentoConductor> guardados = new ArrayList<>();
        try {
            for (ArchivoSubido a : archivos) {
                String tipo = validar(a);
                String archivoId;
                try (InputStream in = a.abridor().abrir()) {
                    archivoId = almacen.guardar(a.tipo().name().toLowerCase() + "-" + UUID.randomUUID() + extension(tipo),
                            tipo, in);
                } catch (IOException e) {
                    throw new UncheckedIOException(e);
                }
                DocumentoConductor doc = DocumentoConductor.builder()
                        .conductorId(conductorId)
                        .vehiculoId(a.tipo().esDeVehiculo() ? vehiculoId : null)
                        .tipo(a.tipo())
                        .numeroDeclarado(a.numeroDeclarado())
                        .archivoId(archivoId)
                        .nombreOriginal(recortar(a.nombreOriginal()))
                        .contentType(tipo)
                        .tamano(a.tamano())
                        .subidoEn(LocalDateTime.now())
                        .build();
                try {
                    guardados.add(repositorio.save(doc));
                } catch (RuntimeException e) {
                    almacen.eliminar(archivoId);
                    throw e;
                }
            }
            return guardados;
        } catch (RuntimeException e) {
            try {
                eliminar(guardados);
            } catch (RuntimeException ignorado) {
                // Se conserva el error original; lo que quede huérfano lo limpia deshacer() del registro.
            }
            throw e;
        }
    }

    public List<DocumentoConductor> listarPorEmail(String email) {
        return usuarioRepository.findByEmailAndRol(email, Rol.CONDUCTOR)
                .map(u -> repositorio.findByConductorId(u.getIdString()))
                .orElse(List.of());
    }

    public Optional<Contenido> abrir(String documentoId) {
        return repositorio.findById(documentoId)
                .flatMap(d -> almacen.abrir(d.getArchivoId()).map(f -> new Contenido(d, f)));
    }

    /** Borra todos los documentos de un conductor (archivos y metadatos). */
    public void eliminarDeConductor(String conductorId) {
        eliminar(repositorio.findByConductorId(conductorId));
    }

    private void eliminar(List<DocumentoConductor> docs) {
        for (DocumentoConductor d : docs) {
            try {
                almacen.eliminar(d.getArchivoId());
            } finally {
                repositorio.deleteById(d.getId());
            }
        }
    }

    static String detectarTipo(byte[] h) {
        if (h.length >= 3 && (h[0] & 0xFF) == 0xFF && (h[1] & 0xFF) == 0xD8 && (h[2] & 0xFF) == 0xFF) {
            return "image/jpeg";
        }
        if (h.length >= 8 && (h[0] & 0xFF) == 0x89 && h[1] == 'P' && h[2] == 'N' && h[3] == 'G'
                && h[4] == 0x0D && h[5] == 0x0A && h[6] == 0x1A && h[7] == 0x0A) {
            return "image/png";
        }
        if (h.length >= 12 && h[0] == 'R' && h[1] == 'I' && h[2] == 'F' && h[3] == 'F'
                && h[8] == 'W' && h[9] == 'E' && h[10] == 'B' && h[11] == 'P') {
            return "image/webp";
        }
        return null;
    }

    private static String extension(String contentType) {
        return switch (contentType) {
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            default -> ".jpg";
        };
    }

    private static String recortar(String nombre) {
        if (nombre == null) {
            return null;
        }
        return nombre.length() > 100 ? nombre.substring(0, 100) : nombre;
    }
}
