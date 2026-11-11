package com.example.MotvirsWeb.infraestructura.almacenamiento;

import com.example.MotvirsWeb.aplicacion.puerto.AlmacenDocumentos;
import com.mongodb.client.gridfs.model.GridFSFile;
import lombok.RequiredArgsConstructor;
import org.bson.types.ObjectId;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.gridfs.GridFsTemplate;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.util.Optional;

/** Guarda los documentos en GridFS (misma MongoDB de la app); se transmite por flujo, sin cargar el archivo en memoria. */
@Component
@RequiredArgsConstructor
public class AlmacenDocumentosGridFs implements AlmacenDocumentos {

    private final GridFsTemplate gridFs;

    @Override
    public String guardar(String nombre, String contentType, InputStream contenido) {
        return gridFs.store(contenido, nombre, contentType).toHexString();
    }

    @Override
    public Optional<InputStream> abrir(String archivoId) {
        ObjectId id = idValido(archivoId);
        if (id == null) {
            return Optional.empty();
        }
        GridFSFile archivo = gridFs.findOne(Query.query(Criteria.where("_id").is(id)));
        if (archivo == null) {
            return Optional.empty();
        }
        try {
            return Optional.of(gridFs.getResource(archivo).getInputStream());
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    @Override
    public void eliminar(String archivoId) {
        ObjectId id = idValido(archivoId);
        if (id != null) {
            gridFs.delete(Query.query(Criteria.where("_id").is(id)));
        }
    }

    private static ObjectId idValido(String id) {
        return id != null && ObjectId.isValid(id) ? new ObjectId(id) : null;
    }
}
