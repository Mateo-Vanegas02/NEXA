package com.example.MotvirsWeb.aplicacion.puerto;

import java.io.InputStream;
import java.util.Optional;

/** Almacén de archivos de documentos. Hoy lo implementa GridFS; se puede cambiar por otro sin tocar los servicios. */
public interface AlmacenDocumentos {

    /** Guarda el contenido y devuelve el identificador del archivo. */
    String guardar(String nombre, String contentType, InputStream contenido);

    /** Abre el archivo para lectura; quien lo recibe debe cerrar el flujo. */
    Optional<InputStream> abrir(String archivoId);

    void eliminar(String archivoId);
}
