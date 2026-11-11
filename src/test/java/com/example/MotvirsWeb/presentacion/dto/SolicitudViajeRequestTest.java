package com.example.MotvirsWeb.presentacion.dto;

import com.example.MotvirsWeb.aplicacion.comando.SolicitudViaje;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.*;

class SolicitudViajeRequestTest {

    private final Validator validador = Validation.buildDefaultValidatorFactory().getValidator();

    private SolicitudViajeRequest valida() {
        return new SolicitudViajeRequest("Calle 1", "Calle 2",
                new SolicitudViajeRequest.Coordenada(4.6, -74.1),
                new SolicitudViajeRequest.Coordenada(4.7, -74.0),
                "2026-10-13T22:00:00.000Z", "Efectivo", null, false);
    }

    private Set<String> mensajes(Object dto) {
        return validador.validate(dto).stream().map(ConstraintViolation::getMessage).collect(Collectors.toSet());
    }

    @Test
    void solicitudCompletaEsValida() {
        assertTrue(validador.validate(valida()).isEmpty());
    }

    @Test
    void faltanCamposObligatorios() {
        SolicitudViajeRequest vacia = new SolicitudViajeRequest(null, " ", null, null, null, null, null, false);
        Set<String> m = mensajes(vacia);
        assertTrue(m.contains("El origen es obligatorio"));
        assertTrue(m.contains("El destino es obligatorio"));
        assertTrue(m.contains("La ubicación de origen es obligatoria"));
        assertTrue(m.contains("La ubicación de destino es obligatoria"));
    }

    @Test
    void coordenadasFueraDeRangoSeRechazan() {
        SolicitudViajeRequest r = new SolicitudViajeRequest("A", "B",
                new SolicitudViajeRequest.Coordenada(91.0, -74.1), new SolicitudViajeRequest.Coordenada(4.7, 181.0),
                null, null, null, false);
        Set<String> m = mensajes(r);
        assertTrue(m.contains("Latitud fuera de rango"));
        assertTrue(m.contains("Longitud fuera de rango"));
    }

    @Test
    void aComandoCopiaLosDatos() {
        SolicitudViaje c = valida().aComando();
        assertEquals("Calle 1", c.origen());
        assertEquals(4.7, c.ubicacionDestino().latitud());
        assertEquals("Efectivo", c.metodoPago());
    }

    @Test
    void calificacionFueraDeRangoSeRechaza() {
        assertTrue(validador.validate(new CalificacionRequest(4.5, "ok")).isEmpty());
        assertTrue(validador.validate(new CalificacionRequest(null, "solo comentario")).isEmpty());
        assertEquals(Set.of("La calificación debe estar entre 0 y 5"), mensajes(new CalificacionRequest(5.5, null)));
        assertEquals(Set.of("La calificación debe estar entre 0 y 5"), mensajes(new CalificacionRequest(-1.0, null)));
    }
}
