package com.example.MotvirsWeb.aplicacion.puerto;

import com.example.MotvirsWeb.dominio.modelo.TipoDocumento;

import java.util.Optional;

/** Puerto de salida: lee el número impreso en la foto de un documento (hoy con un modelo de visión). */
public interface LectorDocumentos {

    /** Número leído (solo letras y dígitos) o vacío si no es legible o el servicio no responde. */
    Optional<String> leerNumero(TipoDocumento tipo, byte[] imagen, String contentType);
}
