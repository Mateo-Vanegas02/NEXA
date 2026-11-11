package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.DeudaCancelacion;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.modelo.Usuario;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.mongodb.client.result.UpdateResult;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.UpdateDefinition;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class DeudaServiceTest {

    private UsuarioRepository usuarios;
    private ServicioRepository servicios;
    private MongoTemplate mongo;
    private DeudaService deudas;
    private com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo correo;
    private Pasajero pasajero;

    @BeforeEach
    void preparar() {
        usuarios = mock(UsuarioRepository.class);
        servicios = mock(ServicioRepository.class);
        mongo = mock(MongoTemplate.class);
        correo = mock(com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo.class);
        deudas = new DeudaService(usuarios, servicios, mongo, correo);
        pasajero = Pasajero.builder().id(new ObjectId()).nombreCompleto("Ana").email("ana@test.com").build();
        when(usuarios.findById(pasajero.getId().toString())).thenReturn(Optional.of(pasajero));
    }

    private void modificaDocumentos(long cuantos) {
        when(mongo.updateFirst(any(Query.class), any(UpdateDefinition.class), eq(Usuario.class)))
                .thenReturn(UpdateResult.acknowledged(cuantos, cuantos, null));
    }

    @Test
    void sinDeudaElPasajeroPuedeSolicitar() {
        assertDoesNotThrow(() -> deudas.deudaACobrarEnViaje(pasajero, false));
        assertTrue(deudas.deudaACobrarEnViaje(pasajero, false).isEmpty());
    }

    @Test
    void conDeudaSePideConfirmacionConPagoRequeridoYElMonto() {
        pasajero.setDeuda(new DeudaCancelacion("s1", 3000, LocalDateTime.now()));

        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> deudas.deudaACobrarEnViaje(pasajero, false));

        assertEquals(402, e.getStatusCode().value());
        assertTrue(e.getReason().contains("3.000"), e.getReason());
    }

    @Test
    void siElPasajeroAceptaLaDeudaSeDevuelveParaSumarlaAlViaje() {
        pasajero.setDeuda(new DeudaCancelacion("s1", 3000, LocalDateTime.now()));

        assertEquals(3000, deudas.deudaACobrarEnViaje(pasajero, true).orElseThrow().getMonto());
    }

    @Test
    void laDeudaSeLeeDeLaBaseNoDelObjetoDeLaSesion() {
        Pasajero enSesion = Pasajero.builder().id(pasajero.getId()).build();   // sin deuda cargada
        pasajero.setDeuda(new DeudaCancelacion("s1", 3000, LocalDateTime.now())); // pero en la base sí

        assertThrows(ResponseStatusException.class, () -> deudas.deudaACobrarEnViaje(enSesion, false));
    }

    @Test
    void cobrarEnViajeDescuentaLaDeudaYMarcaElCargoPagado() {
        Servicio viaje = new Servicio();
        viaje.setId("nuevo");
        viaje.setPasajero(new Servicio.PasajeroEmbedded(pasajero.getId(), "Ana", "ana@test.com"));
        viaje.setDeudaPorCobrar(3000);
        viaje.setDeudaServicioId("s1");
        Servicio cancelado = new Servicio();
        cancelado.setId("s1");
        when(servicios.findById("s1")).thenReturn(Optional.of(cancelado));
        modificaDocumentos(1);

        assertEquals(3000, deudas.cobrarEnViaje(viaje, LocalDateTime.now()));
        assertEquals(DeudaService.METODO_EN_VIAJE, cancelado.getCargoMetodoPago());
        assertNotNull(cancelado.getCargoPagadoEn());
    }

    @Test
    void cobrarEnViajeNoCobraDosVecesSiLaDeudaYaSeResolvio() {
        Servicio viaje = new Servicio();
        viaje.setId("nuevo");
        viaje.setPasajero(new Servicio.PasajeroEmbedded(pasajero.getId(), "Ana", "ana@test.com"));
        viaje.setDeudaPorCobrar(3000);
        viaje.setDeudaServicioId("s1");
        modificaDocumentos(0);

        assertEquals(0, deudas.cobrarEnViaje(viaje, LocalDateTime.now()));
        verify(servicios, never()).findById("s1");
    }

    @Test
    void sinDeudaAceptadaNoSeCobraNada() {
        assertEquals(0, deudas.cobrarEnViaje(new Servicio(), LocalDateTime.now()));
        assertEquals(0, deudas.cobrarEnViaje(null, LocalDateTime.now()));
    }

    @Test
    void registrarCreaLaDeudaSoloSiNoHabiaOtra() {
        modificaDocumentos(1);
        assertTrue(deudas.registrar(pasajero.getId(), "s1", 3000, LocalDateTime.now()));

        modificaDocumentos(0);   // la condición "deuda no existe" no se cumple
        assertFalse(deudas.registrar(pasajero.getId(), "s2", 5400, LocalDateTime.now()));
    }

    @Test
    void confirmarElPagoLiberaAlPasajeroYAcreditaAlConductor() {
        pasajero.setDeuda(new DeudaCancelacion("s1", 3000, LocalDateTime.now()));
        Servicio s = new Servicio();
        s.setId("s1");
        when(servicios.findById("s1")).thenReturn(Optional.of(s));
        modificaDocumentos(1);
        LocalDateTime ahora = LocalDateTime.now();

        DeudaCancelacion pagada = deudas.confirmarPago(pasajero.getId().toString(), ahora);

        assertEquals(3000, pagada.getMonto());
        assertEquals(ahora, s.getCargoPagadoEn());
        assertTrue(s.isCargoAcreditadoConductor());
        verify(servicios).save(s);
        verify(mongo).updateFirst(any(Query.class), any(UpdateDefinition.class), eq(Usuario.class));
    }

    @Test
    void confirmarElPagoSinDeudaOConUnPasajeroInexistenteFalla() {
        assertThrows(ResponseStatusException.class, () -> deudas.confirmarPago(pasajero.getId().toString(), LocalDateTime.now()));
        assertThrows(ResponseStatusException.class, () -> deudas.confirmarPago(new ObjectId().toString(), LocalDateTime.now()));
    }

    @Test
    void soloSeAceptaPagoEnEfectivo() {
        pasajero.setDeuda(new DeudaCancelacion("s1", 3000, LocalDateTime.now()));
        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> deudas.confirmarPago(pasajero.getId().toString(), LocalDateTime.now(), "TARJETA", null));
        assertEquals(400, e.getStatusCode().value());
    }

    @Test
    void confirmarElPagoGuardaMetodoYNota() {
        pasajero.setDeuda(new DeudaCancelacion("s1", 3000, LocalDateTime.now()));
        Servicio s = new Servicio();
        s.setId("s1");
        when(servicios.findById("s1")).thenReturn(Optional.of(s));
        modificaDocumentos(1);

        deudas.confirmarPago(pasajero.getId().toString(), LocalDateTime.now(), "EFECTIVO", "  recibido en sede  ");

        assertEquals("EFECTIVO", s.getCargoMetodoPago());
        assertEquals("recibido en sede", s.getCargoNotaPago());
    }

    @Test
    void resumirSumaLoPendienteYLoRecaudado() {
        LocalDateTime ahora = LocalDateTime.of(2026, 10, 22, 12, 0);
        var pendientes = java.util.List.of(
                new DeudaService.DeudorResumen("a", "A", "a@x", "3", "s1", 1700, ahora.minusDays(1)),
                new DeudaService.DeudorResumen("b", "B", "b@x", "3", "s2", 2400, ahora.minusDays(20)));
        var pagadas = java.util.List.of(
                new DeudaService.PagadaResumen("c", "C", "c@x", "s3", 3100, ahora.minusDays(5), ahora.minusDays(4)));

        var r = DeudaService.resumir(pendientes, pagadas, ahora);

        assertEquals(2, r.pasajerosConDeuda());
        assertEquals(4100, r.totalPorCobrar());
        assertEquals(1, r.nuevasSemana());
        assertEquals(1, r.pagadas30Dias());
        assertEquals(3100, r.recaudado30Dias());
    }

    @Test
    void elMotivoDependeDeSiElConductorYaHabiaLlegado() {
        Servicio conLlegada = new Servicio();
        conLlegada.setFechaLlegada(LocalDateTime.now());
        Servicio sinLlegada = new Servicio();
        when(servicios.findById("a")).thenReturn(Optional.of(conLlegada));
        when(servicios.findById("b")).thenReturn(Optional.of(sinLlegada));

        assertTrue(deudas.motivoDe(new DeudaCancelacion("a", 1700, LocalDateTime.now())).contains("ya había llegado"));
        assertTrue(deudas.motivoDe(new DeudaCancelacion("b", 1700, LocalDateTime.now())).contains("aceptó tu viaje"));
    }

    @Test
    void condonarLiberaAlPasajeroYDejaElMotivoYQuienLoAutorizo() {
        pasajero.setDeuda(new DeudaCancelacion("s1", 3000, LocalDateTime.now()));
        Servicio s = new Servicio();
        s.setId("s1");
        s.setCargoAcreditadoConductor(true);
        when(servicios.findById("s1")).thenReturn(Optional.of(s));
        modificaDocumentos(1);
        LocalDateTime ahora = LocalDateTime.now();

        DeudaCancelacion perdonada = deudas.condonar(pasajero.getId().toString(), "admin@nexa.com",
                "  el conductor pidió cancelar  ", ahora);

        assertEquals(3000, perdonada.getMonto());
        assertEquals(ahora, s.getCargoCondonadoEn());
        assertEquals("admin@nexa.com", s.getCargoCondonadoPor());
        assertEquals("el conductor pidió cancelar", s.getCargoMotivoCondonacion());
        assertNull(s.getCargoPagadoEn(), "condonar no es pagar");
        assertTrue(s.isCargoAcreditadoConductor(), "lo reconocido al conductor no se toca");
        verify(servicios).save(s);
    }

    @Test
    void condonarExigeUnMotivo() {
        pasajero.setDeuda(new DeudaCancelacion("s1", 3000, LocalDateTime.now()));
        for (String motivo : new String[] { null, "", "   ", "ok" }) {
            ResponseStatusException e = assertThrows(ResponseStatusException.class,
                    () -> deudas.condonar(pasajero.getId().toString(), "admin@nexa.com", motivo, LocalDateTime.now()));
            assertEquals(400, e.getStatusCode().value());
        }
        verify(servicios, never()).save(any());
    }

    @Test
    void condonarSinDeudaFalla() {
        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> deudas.condonar(pasajero.getId().toString(), "admin@nexa.com", "motivo válido", LocalDateTime.now()));
        assertEquals(400, e.getStatusCode().value());
    }

    @Test
    void siOtroAdminYaLaCerroNoSeRepite() {
        pasajero.setDeuda(new DeudaCancelacion("s1", 3000, LocalDateTime.now()));
        modificaDocumentos(0);

        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> deudas.condonar(pasajero.getId().toString(), "admin@nexa.com", "motivo válido", LocalDateTime.now()));

        assertEquals(409, e.getStatusCode().value());
        verify(servicios, never()).save(any());
    }

    @Test
    void elHistorialDistingueCargosPagadosCondonadosYPendiente() {
        LocalDateTime ahora = LocalDateTime.of(2026, 10, 24, 10, 0);
        Servicio pagado = new Servicio();
        pagado.setId("s1");
        pagado.setCargoCancelacion(1700);
        pagado.setFechaCancelacion(ahora.minusDays(10));
        pagado.setCargoPagadoEn(ahora.minusDays(9));
        pagado.setCargoMetodoPago("EFECTIVO");
        Servicio condonado = new Servicio();
        condonado.setId("s2");
        condonado.setCargoCancelacion(2400);
        condonado.setFechaCancelacion(ahora.minusDays(5));
        condonado.setCargoCondonadoEn(ahora.minusDays(4));
        condonado.setCargoMotivoCondonacion("error de la app");
        Servicio pendiente = new Servicio();
        pendiente.setId("s3");
        pendiente.setCargoCancelacion(3000);
        pendiente.setFechaCancelacion(ahora.minusDays(1));
        pasajero.setDeuda(new DeudaCancelacion("s3", 3000, ahora.minusDays(1)));
        when(servicios.findByPasajeroIdAndCargoCancelacionGreaterThan(eq(pasajero.getId()), eq(0L), any()))
                .thenReturn(java.util.List.of(pendiente, condonado, pagado));

        var h = deudas.historialDe(pasajero.getId());

        assertEquals(java.util.List.of("PENDIENTE", "CONDONADO", "PAGADO"),
                h.stream().map(DeudaService.CargoHistorial::estado).toList());
        assertEquals("error de la app", h.get(1).detalle());
        assertEquals("EFECTIVO", h.get(2).detalle());
        assertNull(h.get(0).resueltoEn());
    }
}
