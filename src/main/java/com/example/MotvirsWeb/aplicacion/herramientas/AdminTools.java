package com.example.MotvirsWeb.aplicacion.herramientas;

import com.example.MotvirsWeb.dominio.modelo.NotaAdmin;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;
import com.example.MotvirsWeb.aplicacion.servicio.NotaAdminService;

/**
 * MCP Tools para el chatbot privado del Administrador.
 *
 * Expone capacidades CRUD para el sistema de Notas/Apuntes del administrador.
 */
@Service
public class AdminTools {

    private final NotaAdminService notaAdminService;

    public AdminTools(NotaAdminService notaAdminService) {
        this.notaAdminService = notaAdminService;
    }

    @Tool(description = "Crea una nueva nota o apunte en el tablero. Requiere un título descriptivo y el contenido completo de la nota.")
    public String crearNota(String titulo, String contenido) {
        try {
            NotaAdmin nota = notaAdminService.crearNota(titulo, contenido);
            return "Nota creada exitosamente con ID: " + nota.getIdString();
        } catch (Exception e) {
            return "Error al crear la nota: " + e.getMessage();
        }
    }

    @Tool(description = "Lista todas las notas y apuntes guardados actualmente en el tablero. Devuelve el ID, título, contenido y fecha de cada nota.")
    public String listarNotas() {
        List<NotaAdmin> notas = notaAdminService.listarTodasLasNotas();
        if (notas.isEmpty()) {
            return "No tienes ninguna nota guardada en tu tablero en este momento.";
        }

        String listado = notas.stream()
                .map(n -> String.format("- ID: [%s]\n  Título: %s\n  Contenido: %s\n  Fecha: %s",
                        n.getIdString(), n.getTitulo(), n.getContenido(), n.getFechaCreacion()))
                .collect(Collectors.joining("\n\n"));

        return "Tus notas actuales son:\n" + listado;
    }

    @Tool(description = "Busca notas que contengan una palabra o frase específica en su título.")
    public String buscarNotaPorTitulo(String titulo) {
        List<NotaAdmin> notas = notaAdminService.buscarNotasPorTitulo(titulo);
        if (notas.isEmpty()) {
            return "No se encontraron notas que coincidan con el título: " + titulo;
        }

        String listado = notas.stream()
                .map(n -> String.format("- ID: [%s]\n  Título: %s\n  Contenido: %s\n  Fecha: %s",
                        n.getIdString(), n.getTitulo(), n.getContenido(), n.getFechaCreacion()))
                .collect(Collectors.joining("\n\n"));

        return "Resultados de la búsqueda:\n" + listado;
    }

    @Tool(description = "Actualiza o modifica el título o contenido de una nota existente usando su ID. Puedes actualizar el título, el contenido, o ambos.")
    public String actualizarNota(String id, String nuevoTitulo, String nuevoContenido) {
        try {
            NotaAdmin nota = notaAdminService.actualizarNota(id, nuevoTitulo, nuevoContenido);
            return "Nota actualizada exitosamente. El nuevo título es: " + nota.getTitulo()
                    + "\nEl nuevo contenido es:\n" + nota.getContenido();
        } catch (Exception e) {
            return "Error al actualizar la nota (asegúrate de que el ID sea correcto): " + e.getMessage();
        }
    }

    @Tool(description = "Elimina permanentemente una nota del tablero usando su ID.")
    public String eliminarNota(String id) {
        try {
            notaAdminService.eliminarNota(id);
            return "La nota con ID " + id + " ha sido eliminada permanentemente.";
        } catch (Exception e) {
            return "Error al eliminar la nota (asegúrate de que el ID sea correcto): " + e.getMessage();
        }
    }
}
