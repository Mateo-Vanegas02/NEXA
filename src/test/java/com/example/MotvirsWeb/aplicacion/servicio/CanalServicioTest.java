package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.comando.SolicitudViaje;
import com.example.MotvirsWeb.aplicacion.puerto.CanalPeticion;
import com.example.MotvirsWeb.dominio.modelo.CanalServicio;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaPropertiesTestSupport;
import com.example.MotvirsWeb.dominio.regla.ModeloTarifa;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.regla.Ruta;
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
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** Un viaje pedido en la web se atiende en la web y uno pedido en la app, en la app. */
@ExtendWith(MockitoExtension.class)
class CanalServicioTest {

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
    private DespachoService despachoService;
    @Mock
    private ViajeEnVivoService viajeEnVivo;
    @Mock
    private com.example.MotvirsWeb.dominio.regla.PuntoRecogida puntoRecogida;
    @Mock
    private CanalPeticion canalPeticion;
    @Mock
    private AvisosService avisos;
    @InjectMocks
    private ServicioServiceImpl servicioService;

    private Pasajero pasajero;
    private Conductor conductor;

    @BeforeEach
    void preparar() {
        pasajero = Pasajero.builder().id(new ObjectId()).nombreCompleto("Laura").email("l@t.co").build();
        conductor = Conductor.builder().id(new ObjectId()).nombre_y_Apellido("Carlos").email("c@t.co").build();
    }

    private Servicio solicitud(String id, CanalServicio canal) {
        Servicio s = new Servicio();
        s.setId(id);
        s.setEstado(EstadoServicio.SOLICITADO);
        s.setCanal(canal);
        s.setPasajero(new Servicio.PasajeroEmbedded(pasajero.getId(), "Laura", "l@t.co"));
        s.setOrigen("Origen");
        s.setDestino("Destino");
        s.setUbicacionOrigen(new Servicio.Coordenada(10.42, -75.54));
        s.setUbicacionDestino(new Servicio.Coordenada(10.44, -75.51));
        s.setFechaHora(java.time.LocalDateTime.now());
        s.setTarifa(8000);
        s.setDistanciaKM(3.4);
        return s;
    }

    @Test
    void laSolicitudGuardaElCanalPorElQueSePidio() {
        when(canalPeticion.actual()).thenReturn(CanalServicio.APP);
        when(servicioRepository.save(any(Servicio.class))).thenAnswer(i -> i.getArgument(0));
        var tarifa = new ModeloTarifa(ModeloNexaPropertiesTestSupport.cargar());
        when(cotizacionService.cotizar(any(Pasajero.class), any(PuntoGeo.class), any(PuntoGeo.class)))
                .thenReturn(new CotizacionService.Cotizacion(new Ruta(5.0, 5.0 / 1.3, "recta"), tarifa.cotizar(5.0, 1)));

        servicioService.solicitarViaje(new SolicitudViaje("Calle 1", "Calle 2",
                new SolicitudViaje.Coordenada(10.4236, -75.5487), new SolicitudViaje.Coordenada(10.4424, -75.5130),
                null, null, "EFECTIVO", false), pasajero);

        ArgumentCaptor<Servicio> guardado = ArgumentCaptor.forClass(Servicio.class);
        verify(servicioRepository).save(guardado.capture());
        assertEquals(CanalServicio.APP, guardado.getValue().getCanal());
    }

    @Test
    void aceptarDesdeLaWebUnViajeDeLaAppDaConflictoSinTomarlo() {
        when(canalPeticion.actual()).thenReturn(CanalServicio.WEB);
        when(servicioRepository.findById("s1")).thenReturn(Optional.of(solicitud("s1", CanalServicio.APP)));

        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> servicioService.aceptarServicio("s1", conductor));

        assertEquals(HttpStatus.CONFLICT, e.getStatusCode());
        assertEquals(CanalServicio.APP.mensajeOtroCanal(), e.getReason());
        verify(servicioRepository, never()).tomarSiDisponible(any(), any(), any());
    }

    @Test
    void unViajeAntiguoSinCanalSeAtiendeDesdeLaWeb() {
        when(canalPeticion.actual()).thenReturn(CanalServicio.APP);
        Servicio antiguo = solicitud("s1", null);
        antiguo.setEstado(EstadoServicio.ACEPTADO);
        antiguo.setConductor(new Servicio.ConductorEmbedded(conductor));
        when(servicioRepository.findById("s1")).thenReturn(Optional.of(antiguo));

        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> servicioService.cancelarServicioConductor("s1", conductor));

        assertEquals(HttpStatus.CONFLICT, e.getStatusCode());
        verify(servicioRepository, never()).save(any());
    }

    @Test
    void elPasajeroNoCancelaDesdeLaAppUnViajeDeLaWeb() {
        when(canalPeticion.actual()).thenReturn(CanalServicio.APP);
        when(servicioRepository.findById("s1")).thenReturn(Optional.of(solicitud("s1", CanalServicio.WEB)));

        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> servicioService.cancelarViajePasajero("s1", pasajero));

        assertEquals(HttpStatus.CONFLICT, e.getStatusCode());
    }

    @Test
    void cadaConductorVeSoloLasSolicitudesDeSuCanal() {
        when(canalPeticion.actual()).thenReturn(CanalServicio.APP);
        when(despachoService.posicionDe(any(), any(), any())).thenReturn(Optional.empty());
        when(servicioRepository.findByEstado(EstadoServicio.SOLICITADO))
                .thenReturn(List.of(solicitud("web", CanalServicio.WEB), solicitud("app", CanalServicio.APP),
                        solicitud("vieja", null)));
        when(despachoService.filtrarPorOla(anyList(), eq(conductor), any(), any())).thenAnswer(i -> i.getArgument(0));
        when(nivelesService.ordenarParaConductor(anyList(), eq(conductor), any(), any())).thenAnswer(i -> i.getArgument(0));

        List<Servicio> vistas = servicioService.obtenerServiciosDisponibles(conductor, null, null);

        assertEquals(List.of("app"), vistas.stream().map(Servicio::getId).toList());
    }

    @Test
    void lasUbicacionesCuentanSoloLosConductoresDelCanal() {
        ModeloNexaProperties cfg = ModeloNexaPropertiesTestSupport.cargar();
        UbicacionConductorService ubicaciones = new UbicacionConductorService(cfg,
                Clock.fixed(Instant.parse("2026-11-11T12:00:00Z"), ZoneId.of("UTC")));
        PuntoGeo recogida = new PuntoGeo(10.4236, -75.5253);
        ObjectId app = new ObjectId();
        ubicaciones.registrar(app, new PuntoGeo(10.4300, -75.5253), true, CanalServicio.APP); // ~0,7 km
        ubicaciones.registrar(new ObjectId(), new PuntoGeo(10.4300, -75.5253), true, CanalServicio.WEB);
        ubicaciones.registrar(new ObjectId(), new PuntoGeo(10.4560, -75.5253), true, CanalServicio.APP); // ~3,6 km

        assertEquals(1, ubicaciones.contarDisponiblesEnRadio(recogida, 1.5, CanalServicio.APP));
        assertEquals(2, ubicaciones.contarDisponiblesEnRadio(recogida, 1.5));
        assertEquals(List.of(app), ubicaciones.disponiblesEntreRadios(recogida, 0, 1.5, CanalServicio.APP));
        assertEquals(1, ubicaciones.disponiblesEntreRadios(recogida, 1.5, 4, CanalServicio.APP).size());
    }
}
