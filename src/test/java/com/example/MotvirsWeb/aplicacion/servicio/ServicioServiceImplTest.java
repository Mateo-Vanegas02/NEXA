package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.comando.SolicitudViaje;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.infraestructura.socket.WebSocketService;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaPropertiesTestSupport;
import com.example.MotvirsWeb.dominio.regla.ModeloTarifa;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.regla.RegistroLlegada;
import com.example.MotvirsWeb.dominio.regla.Ruta;
import org.springframework.http.HttpStatus;

@SuppressWarnings("null")
@ExtendWith(MockitoExtension.class)
public class ServicioServiceImplTest {

    @Mock
    private ServicioRepository servicioRepository;
    @Mock
    private WebSocketService webSocketService;
    @Mock
    private NivelesService nivelesService;
    @Mock
    private CotizacionService cotizacionService;
    @Mock
    private DeudaService deudaService;
    @Mock
    private RegistroLlegada registroLlegada;
    @Mock
    private ModeloTarifa modeloTarifa;
    @Mock
    private DespachoService despachoService;
    @Mock
    private ViajeEnVivoService viajeEnVivo;
    @Mock
    private com.example.MotvirsWeb.dominio.repositorio.VehiculoRepository vehiculoRepository;
    @Mock
    private com.example.MotvirsWeb.dominio.regla.PuntoRecogida puntoRecogida;

    @org.mockito.Spy
    private com.example.MotvirsWeb.dominio.regla.ModeloExtra modeloExtra =
            new com.example.MotvirsWeb.dominio.regla.ModeloExtra(ModeloNexaPropertiesTestSupport.cargar());

    @InjectMocks
    private ServicioServiceImpl servicioService;

    private Pasajero testPasajero;
    private Conductor testConductor;
    private Servicio testServicio;
    private ObjectId testPasajeroId;
    private ObjectId testConductorId;

    @BeforeEach
    void setUp() {
        testPasajeroId = new ObjectId();
        testConductorId = new ObjectId();

        testPasajero = Pasajero.builder()
                .id(testPasajeroId)
                .nombreCompleto("Pasajero Test")
                .email("pasajero@test.com")
                .build();

        testConductor = Conductor.builder()
                .id(testConductorId)
                .nombre_y_Apellido("Conductor Test")
                .email("conductor@test.com")
                .build();

        testServicio = new Servicio();
        testServicio.setId("s1");
        testServicio.setPasajero(new Servicio.PasajeroEmbedded(testPasajeroId, "Pasajero Test", "pasajero@test.com"));
        testServicio.setEstado(EstadoServicio.SOLICITADO);
    }

    private static final SolicitudViaje SOLICITUD = new SolicitudViaje("Calle 1", "Calle 2",
            new SolicitudViaje.Coordenada(10.4236, -75.5487), new SolicitudViaje.Coordenada(10.4424, -75.5130),
            null, null, "EFECTIVO", false);

    private CotizacionService.Cotizacion cotizacionDe(double km, int nivelModelo) {
        var tarifa = new ModeloTarifa(ModeloNexaPropertiesTestSupport.cargar());
        return new CotizacionService.Cotizacion(new Ruta(km, km / 1.3, "recta"), tarifa.cotizar(km, nivelModelo));
    }

    @Test
    void solicitarViaje_Success() {
        when(servicioRepository.save(any(Servicio.class))).thenAnswer(i -> i.getArgument(0));
        when(cotizacionService.cotizar(any(Pasajero.class), any(PuntoGeo.class), any(PuntoGeo.class)))
                .thenReturn(cotizacionDe(5.0, 1));

        Map<String, Object> result = servicioService.solicitarViaje(SOLICITUD, testPasajero);

        assertNotNull(result);
        assertTrue(result.containsKey("mensaje"));
        ArgumentCaptor<Servicio> guardado = ArgumentCaptor.forClass(Servicio.class);
        verify(servicioRepository).save(guardado.capture());
        assertEquals(9000, guardado.getValue().getTarifa(), "el precio lo fija el servidor");
        assertEquals(5.0, guardado.getValue().getDistanciaKM(), "la distancia la fija el servidor");
        assertEquals(EstadoServicio.SOLICITADO, guardado.getValue().getEstado());
        verify(webSocketService).notificarNuevoServicioDisponible(any());
    }

    @Test
    void solicitarViaje_ConOtraSolicitudEsperando_Conflicto() {
        when(servicioRepository.existsByPasajeroIdAndEstado(testPasajeroId, EstadoServicio.SOLICITADO))
                .thenReturn(true);

        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> servicioService.solicitarViaje(SOLICITUD, testPasajero));

        assertEquals(HttpStatus.CONFLICT, e.getStatusCode());
        verify(servicioRepository, never()).save(any());
        verifyNoInteractions(webSocketService);
    }

    @Test
    void solicitudPendienteDe_DevuelveLaSolicitadaOVacio() {
        when(servicioRepository.findByPasajeroIdAndEstado(testPasajeroId, EstadoServicio.SOLICITADO))
                .thenReturn(List.of(testServicio));
        assertEquals("s1", servicioService.solicitudPendienteDe(testPasajero).orElseThrow().getId());

        when(servicioRepository.findByPasajeroIdAndEstado(testPasajeroId, EstadoServicio.SOLICITADO))
                .thenReturn(List.of());
        assertTrue(servicioService.solicitudPendienteDe(testPasajero).isEmpty());
    }

    @Test
    void solicitarViaje_FueraDeLaZona_NoGuardaNiNotifica() {
        when(cotizacionService.cotizar(any(Pasajero.class), any(PuntoGeo.class), any(PuntoGeo.class)))
                .thenThrow(new ResponseStatusException(HttpStatus.BAD_REQUEST, "El origen está fuera de la zona"));

        assertThrows(ResponseStatusException.class, () -> servicioService.solicitarViaje(SOLICITUD, testPasajero));

        verify(servicioRepository, never()).save(any());
        verifyNoInteractions(webSocketService);
    }

    @Test
    void solicitarViaje_MissingFields_ThrowsException() {
        // Falta el destino
        SolicitudViaje solicitud = new SolicitudViaje("Calle 1", null,
                new SolicitudViaje.Coordenada(4.0, -74.0), new SolicitudViaje.Coordenada(4.1, -74.1),
                null, null, null, false);

        assertThrows(ResponseStatusException.class, () -> servicioService.solicitarViaje(solicitud, testPasajero));
    }

    @Test
    void aceptarServicio_Success() {
        when(servicioRepository.findById("s1")).thenReturn(Optional.of(testServicio));
        when(servicioRepository.tomarSiDisponible(eq("s1"), any(Servicio.ConductorEmbedded.class), any()))
                .thenReturn(1L);

        Map<String, Object> result = servicioService.aceptarServicio("s1", testConductor);

        assertNotNull(result);
        assertEquals(EstadoServicio.ACEPTADO, testServicio.getEstado());
        assertNotNull(testServicio.getConductor());
        assertEquals(testConductorId, testServicio.getConductor().getId());
        verify(servicioRepository, never()).save(any());
        verify(webSocketService).notificarCambioEstadoServicio(any());
        verify(webSocketService).notificarSolicitudRetirada("s1", "TOMADO");
    }

    @Test
    void aceptarServicio_AlreadyAccepted_Conflicto() {
        testServicio.setEstado(EstadoServicio.ACEPTADO);
        when(servicioRepository.findById("s1")).thenReturn(Optional.of(testServicio));

        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> servicioService.aceptarServicio("s1", testConductor));
        assertEquals(HttpStatus.CONFLICT, e.getStatusCode());
        verify(servicioRepository, never()).tomarSiDisponible(any(), any(), any());
    }

    @Test
    void aceptarServicio_OtroConductorLoTomoALaVez_ConflictoSinNotificar() {
        when(servicioRepository.findById("s1")).thenReturn(Optional.of(testServicio));
        when(servicioRepository.tomarSiDisponible(eq("s1"), any(Servicio.ConductorEmbedded.class), any()))
                .thenReturn(0L);

        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> servicioService.aceptarServicio("s1", testConductor));
        assertEquals(HttpStatus.CONFLICT, e.getStatusCode());
        assertEquals(EstadoServicio.SOLICITADO, testServicio.getEstado());
        verifyNoInteractions(webSocketService);
    }

    @Test
    void obtenerServiciosDisponibles_FiltraSolicitudesIncompletas() {
        Servicio solicitudValida = new Servicio();
        solicitudValida.setId("ok");
        solicitudValida.setEstado(EstadoServicio.SOLICITADO);
        solicitudValida.setPasajero(new Servicio.PasajeroEmbedded(testPasajeroId, "Pasajero Test", "pasajero@test.com"));
        solicitudValida.setOrigen("Origen real");
        solicitudValida.setDestino("Destino real");
        solicitudValida.setUbicacionOrigen(new Servicio.Coordenada(4.6, -74.1));
        solicitudValida.setUbicacionDestino(new Servicio.Coordenada(4.7, -74.2));
        solicitudValida.setFechaHora(java.time.LocalDateTime.now());
        solicitudValida.setTarifa(12000);
        solicitudValida.setDistanciaKM(3.5);

        Servicio solicitudFantasma = new Servicio();
        solicitudFantasma.setId("ghost");
        solicitudFantasma.setEstado(EstadoServicio.SOLICITADO);
        solicitudFantasma.setTarifa(0);
        solicitudFantasma.setDistanciaKM(0);

        when(servicioRepository.findByEstado(EstadoServicio.SOLICITADO))
                .thenReturn(List.of(solicitudFantasma, solicitudValida));

        List<Servicio> resultado = servicioService.obtenerServiciosDisponibles();

        assertEquals(1, resultado.size());
        assertEquals("ok", resultado.get(0).getId());
    }

    @Test
    void finalizarServicio_Success() {
        testServicio.setEstado(EstadoServicio.EN_CURSO);
        testServicio.setConductor(new Servicio.ConductorEmbedded(testConductor));
        when(servicioRepository.findById("s1")).thenReturn(Optional.of(testServicio));
        when(servicioRepository.save(any(Servicio.class))).thenReturn(testServicio);

        Map<String, Object> result = servicioService.finalizarServicio("s1", testConductor);

        assertNotNull(result);
        assertEquals(EstadoServicio.FINALIZADO, testServicio.getEstado());
        verify(webSocketService).notificarCambioEstadoServicio(any());
    }

    @Test
    void finalizarServicio_WrongConductor_ThrowsException() {
        testServicio.setEstado(EstadoServicio.EN_CURSO);
        Conductor otroConductor = Conductor.builder().id(new ObjectId()).build();
        testServicio.setConductor(new Servicio.ConductorEmbedded(otroConductor));

        when(servicioRepository.findById("s1")).thenReturn(Optional.of(testServicio));

        assertThrows(ResponseStatusException.class, () -> servicioService.finalizarServicio("s1", testConductor));
    }

    // ── Extra voluntario ──

    @Test
    void subirOferta_SumaYAvisaALosConductores() {
        when(servicioRepository.subirExtra(eq("s1"), eq(testPasajeroId), eq(4000L), eq(1000L), any()))
                .thenReturn(1L);
        Servicio conExtra = new Servicio();
        conExtra.setExtraVoluntario(1000);
        // la segunda lectura ya trae el total actualizado
        when(servicioRepository.findById("s1")).thenReturn(Optional.of(testServicio), Optional.of(conExtra));

        Map<String, Object> r = servicioService.subirOferta("s1", 1000, testPasajero);

        assertEquals(1000L, r.get("extraVoluntario"));
        assertEquals(4000L, r.get("margenRestante"));
        verify(webSocketService).notificarOfertaSubida("s1", 1000);
    }

    @Test
    void subirOferta_SoloMientrasEsperaConductor() {
        testServicio.setEstado(EstadoServicio.ACEPTADO);
        when(servicioRepository.findById("s1")).thenReturn(Optional.of(testServicio));

        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> servicioService.subirOferta("s1", 500, testPasajero));

        assertEquals(409, e.getStatusCode().value());
        verify(servicioRepository, never()).subirExtra(any(), any(), anyLong(), anyLong(), any());
    }

    @Test
    void subirOferta_NoPermiteTocarElViajeDeOtro() {
        when(servicioRepository.findById("s1")).thenReturn(Optional.of(testServicio));
        Pasajero otro = Pasajero.builder().id(new ObjectId()).build();

        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> servicioService.subirOferta("s1", 500, otro));

        assertEquals(403, e.getStatusCode().value());
    }

    @Test
    void subirOferta_RechazaPasosInvalidosYElTope() {
        testServicio.setExtraVoluntario(4500);
        when(servicioRepository.findById("s1")).thenReturn(Optional.of(testServicio));

        assertEquals(400, assertThrows(ResponseStatusException.class,
                () -> servicioService.subirOferta("s1", 700, testPasajero)).getStatusCode().value());
        assertEquals(400, assertThrows(ResponseStatusException.class,
                () -> servicioService.subirOferta("s1", 1000, testPasajero)).getStatusCode().value(), "pasa el tope");
        verify(servicioRepository, never()).subirExtra(any(), any(), anyLong(), anyLong(), any());
    }

    @Test
    void subirOferta_SiLaEscrituraAtomicaNoAplicaDaConflicto() {
        when(servicioRepository.findById("s1")).thenReturn(Optional.of(testServicio));
        when(servicioRepository.subirExtra(any(), any(), anyLong(), anyLong(), any())).thenReturn(0L);

        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> servicioService.subirOferta("s1", 500, testPasajero));

        assertEquals(409, e.getStatusCode().value());
        verify(webSocketService, never()).notificarOfertaSubida(any(), anyLong());
    }
}
