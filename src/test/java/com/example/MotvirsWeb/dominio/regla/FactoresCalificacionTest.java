package com.example.MotvirsWeb.dominio.regla;

import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

class FactoresCalificacionTest {

    @Test
    void cadaRolTieneSuCatalogoConFactoresBuenosYMalosSinRepetir() {
        for (String rol : List.of("pasajero", "conductor")) {
            List<FactoresCalificacion.Factor> catalogo = FactoresCalificacion.catalogo(rol);
            assertTrue(catalogo.stream().anyMatch(FactoresCalificacion.Factor::positivo), rol);
            assertTrue(catalogo.stream().anyMatch(f -> !f.positivo()), rol);
            Set<String> codigos = new HashSet<>();
            catalogo.forEach(f -> assertTrue(codigos.add(f.codigo()), "repetido: " + f.codigo()));
            catalogo.forEach(f -> assertFalse(f.etiqueta().isBlank()));
        }
        assertThrows(IllegalArgumentException.class, () -> FactoresCalificacion.catalogo("admin"));
    }

    @Test
    void losFactoresDelModeloEstanEnElCatalogo() {
        // Lo que más pesa en el modelo v1: espera hasta aceptar (pasajero) y espera en el punto (conductor).
        assertTrue(FactoresCalificacion.catalogo("pasajero").stream()
                .anyMatch(f -> f.codigo().equals("ACEPTACION_LENTA")));
        assertTrue(FactoresCalificacion.catalogo("conductor").stream()
                .anyMatch(f -> f.codigo().equals("ESPERA_EN_EL_PUNTO")));
    }

    @Test
    void normalizaSinRepetidosYEnElOrdenDelCatalogo() {
        assertEquals(List.of("ACEPTACION_LENTA", "DEJO_ANTES_DEL_DESTINO"), FactoresCalificacion.normalizar(
                "pasajero", 1.0, List.of(" DEJO_ANTES_DEL_DESTINO", "ACEPTACION_LENTA", "ACEPTACION_LENTA", "")));
        assertEquals(List.of("AMABLE"), FactoresCalificacion.normalizar("conductor", 5.0, List.of("AMABLE")));
    }

    @Test
    void sinFactoresDevuelveVacioAunSinNota() {
        assertEquals(List.of(), FactoresCalificacion.normalizar("pasajero", null, null));
        assertEquals(List.of(), FactoresCalificacion.normalizar("pasajero", 4.0, List.of()));
    }

    @Test
    void elCorteEsElDelModelo() {
        assertTrue(FactoresCalificacion.esSatisfecho(4.0));
        assertFalse(FactoresCalificacion.esSatisfecho(3.5));
        assertEquals(List.of("LLEGADA_TARDE"),
                FactoresCalificacion.normalizar("pasajero", 3.5, List.of("LLEGADA_TARDE")));
    }

    @Test
    void rechazaLoQueNoCorresponde() {
        assertThrows(IllegalArgumentException.class,
                () -> FactoresCalificacion.normalizar("pasajero", 5.0, List.of("LLEGADA_TARDE")));
        assertThrows(IllegalArgumentException.class,
                () -> FactoresCalificacion.normalizar("pasajero", 1.0, List.of("AMABLE")));
        assertThrows(IllegalArgumentException.class,
                () -> FactoresCalificacion.normalizar("pasajero", 1.0, List.of("ESPERA_EN_EL_PUNTO")));
        assertThrows(IllegalArgumentException.class,
                () -> FactoresCalificacion.normalizar("conductor", null, List.of("AMABLE")));
    }
}
