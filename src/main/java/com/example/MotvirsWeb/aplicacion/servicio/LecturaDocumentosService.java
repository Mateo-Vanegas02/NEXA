package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.LectorDocumentos;
import com.example.MotvirsWeb.aplicacion.verificacion.LimitadorTasa;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificacionException;
import com.example.MotvirsWeb.aplicacion.verificacion.VerificacionException.Tipo;
import com.example.MotvirsWeb.dominio.regla.ComparadorDocumento;
import com.example.MotvirsWeb.dominio.regla.ComparadorDocumento.Resultado;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;

/** A pedido del admin: lee el número de la foto de un documento y lo contrasta con el declarado. */
@Service
public class LecturaDocumentosService {

    public record Lectura(String documentoId, String declarado, String leido, Resultado resultado) {
    }

    private final DocumentosConductorService documentos;
    private final LectorDocumentos lector;
    private final LimitadorTasa limitador = new LimitadorTasa(10, 60_000);

    public LecturaDocumentosService(DocumentosConductorService documentos, LectorDocumentos lector) {
        this.documentos = documentos;
        this.lector = lector;
    }

    public Lectura leer(String documentoId, String adminEmail) {
        if (!limitador.permitir(adminEmail)) {
            throw new VerificacionException(Tipo.LIMITE_EXCEDIDO, "Demasiadas lecturas, intente en un minuto");
        }
        var contenido = documentos.abrir(documentoId)
                .orElseThrow(() -> new VerificacionException(Tipo.NO_ENCONTRADO, "Documento no encontrado"));
        byte[] bytes;
        try (InputStream in = contenido.flujo()) {
            bytes = in.readAllBytes();
        } catch (IOException e) {
            throw new VerificacionException(Tipo.NO_ENCONTRADO, "No se pudo abrir el documento");
        }
        var d = contenido.documento();
        String leido = lector.leerNumero(d.getTipo(), bytes, d.getContentType()).orElse(null);
        return new Lectura(d.getId(), d.getNumeroDeclarado(), leido, ComparadorDocumento.comparar(d.getNumeroDeclarado(), leido));
    }
}
