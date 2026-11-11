package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal;
import com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal.PosicionViaje;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaPropertiesTestSupport;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.regla.ReglaViaje;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

class ViajeEnVivoServiceTest {

    static class RelojManual extends Clock {
        Instant ahora = Instant.parse("2026-10-25T12:00:00Z");

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

    private static final PuntoGeo RECOGIDA = new PuntoGeo(10.4236, -75.5253);
    private static final PuntoGeo DESTINO = new PuntoGeo(10.4536, -75.5253);   // ~3,3 km al norte

    private final ObjectId conductorId = new ObjectId();
    private final ObjectId pasajeroId = new ObjectId();

    private RelojManual reloj;
    private NotificadorTiempoReal notificador;
    private UbicacionConductorService ubicaciones;
    private ViajeEnVivoService servicio;

    @BeforeEach
    void preparar() {
        armar(ModeloNexaPropertiesTestSupport.cargar());
    }

    private void armar(ModeloNexaProperties cfg) {
        reloj = new RelojManual();
        notificador = mock(NotificadorTiempoReal.class);
        ubicaciones = new UbicacionConductorService(cfg, reloj);
        servicio = new ViajeEnVivoService(notificador, new ReglaViaje(cfg), ubicaciones, reloj);
    }

    private Servicio viaje(EstadoServicio estado) {
        Servicio s = new Servicio();
        s.setId("s1");
        s.setEstado(estado);
        s.setPasajero(new Servicio.PasajeroEmbedded(pasajeroId, "P", "p@x.com"));
        Servicio.ConductorEmbedded c = new Servicio.ConductorEmbedded();
        c.setId(conductorId);
        s.setConductor(c);
        s.setUbicacionOrigen(new Servicio.Coordenada(RECOGIDA.latitud(), RECOGIDA.longitud()));
        s.setUbicacionDestino(new Servicio.Coordenada(DESTINO.latitud(), DESTINO.longitud()));
        return s;
    }

    private PosicionViaje ultimoEnvio() {
        ArgumentCaptor<PosicionViaje> captor = ArgumentCaptor.forClass(PosicionViaje.class);
        verify(notificador, org.mockito.Mockito.atLeastOnce())
                .notificarPosicionConductor(eq(pasajeroId.toHexString()), captor.capture());
        return captor.getValue();
    }

    @Test
    void elConductorRecibeLoMismoQueElPasajeroAunqueSeLimiteElEnvio() {
        servicio.seguir(viaje(EstadoServicio.ACEPTADO));
        var primero = servicio.reportar(conductorId, new PuntoGeo(10.4136, -75.5253));
        var segundo = servicio.reportar(conductorId, new PuntoGeo(10.4137, -75.5253)); // dentro del mismo segundo

        assertTrue(primero.isPresent() && segundo.isPresent());
        assertEquals("ACEPTADO", segundo.get().fase());
        assertTrue(segundo.get().etaMinutos() >= 1);
        verify(notificador, org.mockito.Mockito.times(1)).notificarPosicionConductor(any(), any());
    }

    @Test
    void sinViajeSeguidoNoHayRespuestaParaElConductor() {
        assertTrue(servicio.reportar(conductorId, RECOGIDA).isEmpty());
    }

    @Test
    void sinViajeSeguidoNoSeEnviaNada() {
        servicio.reportar(conductorId, RECOGIDA);
        verify(notificador, never()).notificarPosicionConductor(any(), any());
    }

    @Test
    void yendoARecogerElPasajeroRecibeLaPosicionYLaDistanciaALaRecogida() {
        servicio.seguir(viaje(EstadoServicio.ACEPTADO));
        servicio.reportar(conductorId, new PuntoGeo(10.4136, -75.5253)); // ~1,1 km al sur de la recogida

        PosicionViaje p = ultimoEnvio();
        assertEquals("s1", p.servicioId());
        assertEquals("ACEPTADO", p.fase());
        assertEquals(10.4136, p.latitud(), 1e-9);
        assertEquals(1.1 * 1.3, p.distanciaRestanteKm(), 0.1);
        assertTrue(p.etaMinutos() >= 1);
    }

    @Test
    void enCursoLaDistanciaEsHastaElDestino() {
        servicio.seguir(viaje(EstadoServicio.EN_CURSO));
        servicio.reportar(conductorId, RECOGIDA);

        PosicionViaje p = ultimoEnvio();
        assertEquals("EN_CURSO", p.fase());
        assertEquals(RECOGIDA.distanciaKm(DESTINO) * 1.3, p.distanciaRestanteKm(), 1e-6);
    }

    @Test
    void noSeSaturaAlPasajeroConEnviosMasSeguidosQueUnSegundo() {
        servicio.seguir(viaje(EstadoServicio.ACEPTADO));
        servicio.reportar(conductorId, RECOGIDA);
        reloj.ahora = reloj.ahora.plusMillis(300);
        servicio.reportar(conductorId, new PuntoGeo(10.4237, -75.5253));
        verify(notificador, times(1)).notificarPosicionConductor(any(), any());

        reloj.ahora = reloj.ahora.plusSeconds(2);
        servicio.reportar(conductorId, new PuntoGeo(10.4238, -75.5253));
        verify(notificador, times(2)).notificarPosicionConductor(any(), any());
    }

    @Test
    void noPierdeElRecorridoSiSeRetomaElMismoViaje() {
        Servicio s = viaje(EstadoServicio.EN_CURSO);
        servicio.seguir(s);
        servicio.reportar(conductorId, RECOGIDA);
        servicio.reportar(conductorId, new PuntoGeo(10.4336, -75.5253));

        servicio.seguir(s); // p. ej. el conductor recargó la página

        ViajeEnVivoService.Recorrido r = servicio.terminar(conductorId, "s1");
        assertEquals(2, r.puntos().size());
    }

    @Test
    void elRecorridoRealSoloGuardaPuntosSeparadosYSumaLosKilometros() {
        Servicio s = viaje(EstadoServicio.ACEPTADO);
        servicio.seguir(s);
        // Antes de iniciar el viaje no se guarda recorrido
        servicio.reportar(conductorId, RECOGIDA);

        s.setEstado(EstadoServicio.EN_CURSO);
        servicio.iniciar(s);
        servicio.reportar(conductorId, RECOGIDA);                            // primer punto
        servicio.reportar(conductorId, new PuntoGeo(10.42361, -75.5253));    // ~1 m: se descarta
        servicio.reportar(conductorId, new PuntoGeo(10.4336, -75.5253));     // ~1,1 km
        servicio.reportar(conductorId, new PuntoGeo(10.4436, -75.5253));     // ~1,1 km

        ViajeEnVivoService.Recorrido r = servicio.terminar(conductorId, "s1");
        assertEquals(3, r.puntos().size());
        assertEquals(2.2, r.km(), 0.05);
        // Terminado: ya no se sigue
        assertNull(servicio.terminar(conductorId, "s1"));
    }

    @Test
    void terminarOtroViajeNoToca() {
        servicio.seguir(viaje(EstadoServicio.EN_CURSO));
        assertNull(servicio.terminar(conductorId, "otro"));
        assertNotNull(servicio.terminar(conductorId, "s1"));
    }

    @Test
    void soloSigueViajesAceptadosOEnCurso() {
        servicio.seguir(viaje(EstadoServicio.SOLICITADO));
        servicio.seguir(viaje(EstadoServicio.FINALIZADO));
        servicio.reportar(conductorId, RECOGIDA);
        verify(notificador, never()).notificarPosicionConductor(any(), any());
    }

    // ── Finalizar en cualquier tramo: se cobra según lo recorrido ──

    private Servicio enCurso(double distanciaPlaneadaKm) {
        Servicio s = viaje(EstadoServicio.EN_CURSO);
        s.setDistanciaKM(distanciaPlaneadaKm);
        return s;
    }

    private static ViajeEnVivoService.Recorrido recorrido(double km) {
        return new ViajeEnVivoService.Recorrido(km, java.util.List.of(new Servicio.Coordenada(10.43, -75.5253),
                new Servicio.Coordenada(10.44, -75.5253)));
    }

    @Test
    void sinPosicionRecienteNoEstaEnElDestino() {
        assertFalse(servicio.estaEnElDestino(viaje(EstadoServicio.EN_CURSO), conductorId));
    }

    @Test
    void lejosDelDestinoNoEstaEnElDestino() {
        ubicaciones.registrar(conductorId, RECOGIDA, false);
        assertFalse(servicio.estaEnElDestino(viaje(EstadoServicio.EN_CURSO), conductorId));
    }

    @Test
    void cercaDelDestinoEstaEnElDestino() {
        ubicaciones.registrar(conductorId, new PuntoGeo(10.4540, -75.5253), false); // ~44 m
        assertTrue(servicio.estaEnElDestino(viaje(EstadoServicio.EN_CURSO), conductorId));
    }

    @Test
    void unaPosicionVencidaNoCuentaComoEnElDestino() {
        ubicaciones.registrar(conductorId, DESTINO, false);
        reloj.ahora = reloj.ahora.plusSeconds(120);
        assertFalse(servicio.estaEnElDestino(viaje(EstadoServicio.EN_CURSO), conductorId));
    }

    @Test
    void conLaValidacionApagadaEnDesarrolloSiempreEstaEnElDestino() {
        ModeloNexaProperties cfg = ModeloNexaPropertiesTestSupport.cargar();
        cfg.getViaje().setExigirDestino(false);
        armar(cfg);
        assertTrue(servicio.estaEnElDestino(viaje(EstadoServicio.EN_CURSO), conductorId));
    }

    @Test
    void llegandoAlDestinoSeCobraCompleto() {
        ubicaciones.registrar(conductorId, DESTINO, false);
        assertEquals(1.0, servicio.factorCobro(enCurso(4.0), conductorId, recorrido(0.5)));
    }

    @Test
    void finalizandoAntesDeLaMitadSeCobraLaMitad() {
        ubicaciones.registrar(conductorId, new PuntoGeo(10.43, -75.5253), false);
        assertEquals(0.5, servicio.factorCobro(enCurso(4.0), conductorId, recorrido(1.9)));
    }

    @Test
    void finalizandoDesdeLaMitadSeCobraCompleto() {
        ubicaciones.registrar(conductorId, new PuntoGeo(10.44, -75.5253), false);
        assertEquals(1.0, servicio.factorCobro(enCurso(4.0), conductorId, recorrido(2.0)));
        assertEquals(1.0, servicio.factorCobro(enCurso(4.0), conductorId, recorrido(3.5)));
    }

    @Test
    void sinRecorridoSeEstimaConLaPosicionYSinPosicionSeCobraCompleto() {
        // recogida -> ~1,1 km en línea recta (≈1,4 km por calle) de 4 km planeados: menos de la mitad
        ubicaciones.registrar(conductorId, new PuntoGeo(10.4336, -75.5253), false);
        assertEquals(0.5, servicio.factorCobro(enCurso(4.0), conductorId, null));
        ubicaciones.registrar(conductorId, new PuntoGeo(10.4436, -75.5253), false); // ~2,2 km en línea recta
        assertEquals(1.0, servicio.factorCobro(enCurso(4.0), conductorId, null));
        assertEquals(1.0, servicio.factorCobro(enCurso(4.0), new ObjectId(), null));
    }

    @Test
    void elPasajeroConsultaLaUltimaPosicionDeSuConductor() {
        Servicio viaje = viaje(EstadoServicio.ACEPTADO);
        servicio.seguir(viaje);
        assertTrue(servicio.posicionDe("s1", pasajeroId.toHexString()).isEmpty(), "aún no reportó posición");

        servicio.reportar(conductorId, new PuntoGeo(10.4136, -75.5253));
        reloj.ahora = reloj.ahora.plusSeconds(2);
        servicio.reportar(conductorId, new PuntoGeo(10.4186, -75.5253));

        PosicionViaje p = servicio.posicionDe("s1", pasajeroId.toHexString()).orElseThrow();
        assertEquals(10.4186, p.latitud(), 1e-9);
        assertEquals("ACEPTADO", p.fase());
        assertTrue(p.distanciaRestanteKm() > 0);
    }

    @Test
    void otroPasajeroNoVeLaPosicionDeEseViaje() {
        servicio.seguir(viaje(EstadoServicio.ACEPTADO));
        servicio.reportar(conductorId, new PuntoGeo(10.4136, -75.5253));

        assertTrue(servicio.posicionDe("s1", new ObjectId().toHexString()).isEmpty());
        assertTrue(servicio.posicionDe("otro-viaje", pasajeroId.toHexString()).isEmpty());
        assertTrue(servicio.posicionDe(null, null).isEmpty());
    }

    @Test
    void unaPosicionVencidaYaNoSeEntrega() {
        servicio.seguir(viaje(EstadoServicio.ACEPTADO));
        servicio.reportar(conductorId, new PuntoGeo(10.4136, -75.5253));
        assertTrue(servicio.posicionDe("s1", pasajeroId.toHexString()).isPresent());

        reloj.ahora = reloj.ahora.plusSeconds(60);

        assertTrue(servicio.posicionDe("s1", pasajeroId.toHexString()).isEmpty());
    }
}
