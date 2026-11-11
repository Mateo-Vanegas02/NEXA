package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.NotaAdmin;
import com.example.MotvirsWeb.dominio.repositorio.NotaAdminRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class NotaAdminService {

    private final NotaAdminRepository notaAdminRepository;

    public NotaAdmin crearNota(String titulo, String contenido) {
        NotaAdmin nota = NotaAdmin.builder()
                .titulo(titulo)
                .contenido(contenido)
                .fechaCreacion(LocalDateTime.now())
                .build();
        return notaAdminRepository.save(nota);
    }

    public List<NotaAdmin> listarTodasLasNotas() {
        return notaAdminRepository.findAll();
    }

    public List<NotaAdmin> buscarNotasPorTitulo(String titulo) {
        return notaAdminRepository.findByTituloLikeIgnoreCase(java.util.regex.Pattern.quote(titulo));
    }

    public Optional<NotaAdmin> obtenerNotaPorId(String id) {
        return notaAdminRepository.findById(id);
    }

    public NotaAdmin actualizarNota(String id, String nuevoTitulo, String nuevoContenido) {
        NotaAdmin nota = notaAdminRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Nota no encontrada"));
        if (nuevoTitulo != null && !nuevoTitulo.trim().isEmpty()) {
            nota.setTitulo(nuevoTitulo);
        }
        if (nuevoContenido != null && !nuevoContenido.trim().isEmpty()) {
            nota.setContenido(nuevoContenido);
        }
        return notaAdminRepository.save(nota);
    }

    public void eliminarNota(String id) {
        if (!notaAdminRepository.existsById(id)) {
            throw new RuntimeException("Nota no encontrada");
        }
        notaAdminRepository.deleteById(id);
    }
}