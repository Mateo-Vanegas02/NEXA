package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/** Lo que cada rol puede ver de un viaje: calificaciones propias, un solo monto a cobrar y nada de comisión. */
class VisibilidadServicioTest {

    private Servicio viaje;

    @BeforeEach
    void preparar() {
        viaje = new Servicio();
        viaje.setId("s1");
        viaje.setEstado(EstadoServicio.FINALIZADO);
        viaje.setTarifa(6000);
        viaje.setDeudaPorCobrar(3000);
        viaje.setDeudaServicioId("s0");
        viaje.setDeudaCobrada(3000);
        viaje.setCalificacionConductor(4.0);          // la puso el pasajero al conductor
        viaje.setComentariosConductor("buen viaje");
        viaje.setCalificacionPasajero(2.0);           // la puso el conductor al pasajero
        viaje.setComentariosPasajero("no estaba en el punto");
        viaje.setXpGanadoConductor(40);
        viaje.setXpGanadoPasajero(25);
        viaje.setCargoNotaPago("nota del admin");
        viaje.setCargoMotivoCondonacion("motivo interno");
        viaje.setOlaAceptacion(2);
        viaje.setDistanciaRecogidaKm(1.2);
        Servicio.DesgloseTarifa d = new Servicio.DesgloseTarifa();
        d.setComisionMonto(900);
        d.setComisionPct(15);
        viaje.setDesglose(d);
    }

    @Test
    void elConductorSoloVeLaCalificacionQueElPuso() {
        Servicio v = VisibilidadServicio.paraConductor(viaje);
        assertEquals(2.0, v.getCalificacionPasajero());
        assertEquals("no estaba en el punto", v.getComentariosPasajero());
        assertNull(v.getCalificacionConductor(), "no ve lo que le puso el pasajero");
        assertNull(v.getComentariosConductor());
        assertEquals(2.0, v.getCalificacionPromedio(), "el promedio no puede delatar la del otro");
    }

    @Test
    void elPasajeroSoloVeLaCalificacionQueElPuso() {
        Servicio v = VisibilidadServicio.paraPasajero(viaje);
        assertEquals(4.0, v.getCalificacionConductor());
        assertEquals("buen viaje", v.getComentariosConductor());
        assertNull(v.getCalificacionPasajero(), "no ve lo que le puso el conductor");
        assertNull(v.getComentariosPasajero());
        assertEquals(4.0, v.getCalificacionPromedio());
    }

    @Test
    void elConductorVeUnSoloMontoYNingunRastroDeLaDeuda() {
        Servicio v = VisibilidadServicio.paraConductor(viaje);
        assertEquals(9000, v.getTarifa(), "ya cobrado: tarifa + deuda, sin separarlas");
        assertEquals(0, v.getDeudaPorCobrar());
        assertEquals(0, v.getDeudaCobrada());
        assertNull(v.getDeudaServicioId());

        viaje.setEstado(EstadoServicio.EN_CURSO);
        assertEquals(9000, VisibilidadServicio.paraConductor(viaje).getTarifa(), "durante el viaje ya ve lo que va a cobrar");

        viaje.setEstado(EstadoServicio.SOLICITADO);
        assertEquals(6000, VisibilidadServicio.paraConductor(viaje).getTarifa(),
                "en la lista de solicitudes la ganancia sale solo de la tarifa");

        viaje.setEstado(EstadoServicio.CANCELADO);
        assertEquals(6000, VisibilidadServicio.paraConductor(viaje).getTarifa());
    }

    @Test
    void elPasajeroSiVeSuPropiaDeuda() {
        Servicio v = VisibilidadServicio.paraPasajero(viaje);
        assertEquals(6000, v.getTarifa());
        assertEquals(3000, v.getDeudaCobrada());
    }

    @Test
    void ningunRolRecibeLoInternoNiXpDelOtro() {
        Servicio c = VisibilidadServicio.paraConductor(viaje);
        Servicio p = VisibilidadServicio.paraPasajero(viaje);
        for (Servicio v : new Servicio[] {c, p}) {
            assertNull(v.getDesglose());
            assertNull(v.getCargoNotaPago());
            assertNull(v.getCargoMotivoCondonacion());
            assertEquals(0, v.getOlaAceptacion());
            assertNull(v.getDistanciaRecogidaKm());
        }
        assertEquals(0, c.getXpGanadoPasajero());
        assertEquals(40, c.getXpGanadoConductor());
        assertEquals(0, p.getXpGanadoConductor());
    }

    @Test
    void laEntidadGuardadaNoSeToca() {
        VisibilidadServicio.paraConductor(viaje);
        VisibilidadServicio.paraPasajero(viaje);
        assertEquals(6000, viaje.getTarifa());
        assertEquals(4.0, viaje.getCalificacionConductor());
        assertEquals(2.0, viaje.getCalificacionPasajero());
        assertEquals(3000, viaje.getDeudaCobrada());
        assertNotNull(viaje.getDesglose());
    }

    @Test
    void elJsonQueSaleNoTraeNadaDeLoOculto() throws Exception {
        ObjectMapper json = new ObjectMapper().findAndRegisterModules();
        String deConductor = json.writeValueAsString(VisibilidadServicio.paraConductor(viaje));
        assertFalse(deConductor.contains("buen viaje"));
        assertFalse(deConductor.contains("\"deudaPorCobrar\":3000"));
        assertFalse(deConductor.contains("comision"));
        String dePasajero = json.writeValueAsString(VisibilidadServicio.paraPasajero(viaje));
        assertFalse(dePasajero.contains("no estaba en el punto"));
        assertFalse(dePasajero.contains("comision"));
    }

    @Test
    void nulosYListasVacias() {
        assertNull(VisibilidadServicio.paraConductor((Servicio) null));
        assertNull(VisibilidadServicio.paraPasajero((Servicio) null));
        assertTrue(VisibilidadServicio.paraConductor((java.util.List<Servicio>) null).isEmpty());
    }
}
