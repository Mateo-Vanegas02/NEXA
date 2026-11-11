package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.regla.ModeloNexaPropertiesTestSupport;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;

import static org.junit.jupiter.api.Assertions.*;

class UbicacionConductorServiceTest {

    /** Reloj que se mueve a mano. */
    static class RelojManual extends Clock {
        Instant ahora = Instant.parse("2026-10-24T12:00:00Z");

        @Override
        public ZoneId getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return ahora;
        }
    }

    private static final PuntoGeo CENTRO = new PuntoGeo(10.4236, -75.5253);
    private static final PuntoGeo CERCA = new PuntoGeo(10.4300, -75.5253);   // ~0,7 km
    private static final PuntoGeo LEJOS = new PuntoGeo(10.5000, -75.5253);   // ~8,5 km

    private RelojManual reloj;
    private UbicacionConductorService servicio;

    @BeforeEach
    void preparar() {
        reloj = new RelojManual();
        servicio = new UbicacionConductorService(ModeloNexaPropertiesTestSupport.cargar(), reloj);
    }

    @Test
    void laPosicionVigenteSeRecuperaYVenceConElTiempo() {
        ObjectId id = new ObjectId();
        servicio.registrar(id, CERCA, true);
        assertEquals(CERCA, servicio.vigente(id).orElseThrow());

        reloj.ahora = reloj.ahora.plusSeconds(44);
        assertTrue(servicio.vigente(id).isPresent());
        reloj.ahora = reloj.ahora.plusSeconds(2);
        assertTrue(servicio.vigente(id).isEmpty(), "pasados 45 s cuenta como sin ubicación");
    }

    @Test
    void cuentaSoloDisponiblesVigentesDentroDelRadio() {
        servicio.registrar(new ObjectId(), CERCA, true);
        servicio.registrar(new ObjectId(), LEJOS, true);
        servicio.registrar(new ObjectId(), CERCA, false); // en un viaje

        assertEquals(1, servicio.contarDisponiblesEnRadio(CENTRO, 1.5));
        assertEquals(2, servicio.contarDisponiblesEnRadio(CENTRO, Double.POSITIVE_INFINITY));

        reloj.ahora = reloj.ahora.plusSeconds(60);
        assertEquals(0, servicio.contarDisponiblesEnRadio(CENTRO, Double.POSITIVE_INFINITY));
    }

    @Test
    void cuentaAparteALosQueSiguenEnLineaPeroYaNoReportan() {
        servicio.registrar(new ObjectId(), CERCA, true);
        servicio.registrar(new ObjectId(), CERCA, false);   // en un viaje: no cuenta
        assertEquals(0, servicio.contarDisponiblesSinPosicionVigente());

        reloj.ahora = reloj.ahora.plusSeconds(60);          // la posición venció, pero sigue en línea
        assertEquals(1, servicio.contarDisponiblesSinPosicionVigente());

        reloj.ahora = reloj.ahora.plusSeconds(11 * 60);     // pasada la retención ya no cuenta
        assertEquals(0, servicio.contarDisponiblesSinPosicionVigente());
    }

    @Test
    void purgarDescartaSoloLoQueYaNiSirveParaContarEnLinea() {
        servicio.registrar(new ObjectId(), CERCA, true);
        reloj.ahora = reloj.ahora.plusSeconds(60);
        assertEquals(0, servicio.purgar(), "a los 60 s sigue contando como conductor en línea");

        servicio.registrar(new ObjectId(), LEJOS, true);
        reloj.ahora = reloj.ahora.plusSeconds(10 * 60); // la primera lleva 11 min, la segunda 10
        assertEquals(1, servicio.purgar());
    }
}
