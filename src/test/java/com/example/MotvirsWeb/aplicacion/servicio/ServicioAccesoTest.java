package com.example.MotvirsWeb.aplicacion.servicio;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Optional;

import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.infraestructura.socket.WebSocketService;

/** IDOR: un usuario no puede operar ni leer servicios de otros. */
@SuppressWarnings("null")
@ExtendWith(MockitoExtension.class)
class ServicioAccesoTest {

    @Mock
    private ServicioRepository servicioRepository;
    @Mock
    private WebSocketService webSocketService;
    @Mock
    private NivelesService nivelesService;
    @Mock
    private ViajeEnVivoService viajeEnVivo;
    @InjectMocks
    private ServicioServiceImpl servicioService;

    private final ObjectId pasajeroId = new ObjectId();
    private final ObjectId conductorId = new ObjectId();
    private Servicio servicio;

    @BeforeEach
    void setUp() {
        servicio = new Servicio();
        servicio.setId("s1");
        servicio.setPasajero(new Servicio.PasajeroEmbedded(pasajeroId, "Pasajero", "p@x.com"));
        servicio.setConductor(new Servicio.ConductorEmbedded(Conductor.builder().id(conductorId)
                .nombre_y_Apellido("Cond").build()));
        servicio.setEstado(EstadoServicio.FINALIZADO);
        when(servicioRepository.findById("s1")).thenReturn(Optional.of(servicio));
    }

    private static Conductor conductor(ObjectId id) {
        return Conductor.builder().id(id).nombre_y_Apellido("X").build();
    }

    private static HttpStatus estado(ResponseStatusException e) {
        return HttpStatus.valueOf(e.getStatusCode().value());
    }

    @Test
    void otroConductorNoPuedeIniciarUnServicioAjeno() {
        servicio.setEstado(EstadoServicio.ACEPTADO);
        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> servicioService.iniciarServicio("s1", conductor(new ObjectId())));
        assertEquals(HttpStatus.FORBIDDEN, estado(e));
        verify(servicioRepository, never()).save(any());
    }

    @Test
    void elConductorAsignadoSiPuedeIniciar() {
        servicio.setEstado(EstadoServicio.ACEPTADO);
        servicio.setFechaLlegada(java.time.LocalDateTime.now());
        assertNotNull(servicioService.iniciarServicio("s1", conductor(conductorId)));
        verify(viajeEnVivo).iniciar(servicio);
    }

    @Test
    void noSePuedeIniciarSinHaberConfirmadoLaLlegada() {
        servicio.setEstado(EstadoServicio.ACEPTADO);
        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> servicioService.iniciarServicio("s1", conductor(conductorId)));
        assertEquals(HttpStatus.CONFLICT, estado(e));
        verify(servicioRepository, never()).save(any());
        verify(viajeEnVivo, never()).iniciar(any());
    }

    @Test
    void elConductorPuedeFinalizarEnCualquierTramoYSeCobraLaMitadAntesDeLaMitad() {
        servicio.setEstado(EstadoServicio.EN_CURSO);
        when(viajeEnVivo.estaEnElDestino(servicio, conductorId)).thenReturn(false);
        when(viajeEnVivo.factorCobro(any(), any(), any())).thenReturn(0.5);
        servicioService.finalizarServicio("s1", conductor(conductorId));
        assertEquals(EstadoServicio.FINALIZADO, servicio.getEstado());
        assertTrue(servicio.isFinalizadoAntesDelDestino());
        assertEquals(0.5, servicio.getFraccionCobrada());
    }

    @Test
    void llegandoAlDestinoSeCobraCompletoYNoQuedaMarcadoComoAnticipado() {
        servicio.setEstado(EstadoServicio.EN_CURSO);
        when(viajeEnVivo.estaEnElDestino(servicio, conductorId)).thenReturn(true);
        servicioService.finalizarServicio("s1", conductor(conductorId));
        assertFalse(servicio.isFinalizadoAntesDelDestino());
        assertEquals(1.0, servicio.getFraccionCobrada());
    }

    @Test
    void alFinalizarSeGuardaElRecorridoReal() {
        servicio.setEstado(EstadoServicio.EN_CURSO);
        var puntos = java.util.List.of(new Servicio.Coordenada(10.4, -75.5), new Servicio.Coordenada(10.41, -75.5));
        when(viajeEnVivo.terminar(conductorId, "s1")).thenReturn(new ViajeEnVivoService.Recorrido(1.1, puntos));
        servicioService.finalizarServicio("s1", conductor(conductorId));
        assertEquals(1.1, servicio.getDistanciaRecorridaKm());
        assertEquals(puntos, servicio.getRecorrido());
        assertEquals(EstadoServicio.FINALIZADO, servicio.getEstado());
    }

    @Test
    void otroConductorNoLeeUnServicioAjeno() {
        ResponseStatusException e = assertThrows(ResponseStatusException.class,
                () -> servicioService.obtenerServicioDeConductor("s1", conductor(new ObjectId())));
        assertEquals(HttpStatus.FORBIDDEN, estado(e));
    }

    @Test
    void cualquierConductorVeUnServicioAunSolicitado() {
        servicio.setEstado(EstadoServicio.SOLICITADO);
        servicio.setConductor(null);
        assertEquals(servicio, servicioService.obtenerServicioDeConductor("s1", conductor(new ObjectId())));
    }

    @Test
    void elConductorAsignadoLeeSuServicio() {
        assertEquals(servicio, servicioService.obtenerServicioDeConductor("s1", conductor(conductorId)));
    }

    @Test
    void unPasajeroAjenoNoPuedeCalificar() {
        ResponseStatusException e = assertThrows(ResponseStatusException.class, () -> servicioService
                .calificarServicio("s1", "pasajero", 5.0, "x", new ObjectId().toString()));
        assertEquals(HttpStatus.FORBIDDEN, estado(e));
        verify(servicioRepository, never()).save(any());
    }

    @Test
    void unConductorNoPuedeCalificarComoPasajero() {
        ResponseStatusException e = assertThrows(ResponseStatusException.class, () -> servicioService
                .calificarServicio("s1", "pasajero", 5.0, "x", conductorId.toString()));
        assertEquals(HttpStatus.FORBIDDEN, estado(e));
    }

    @Test
    void noSeCalificaUnViajeSinFinalizar() {
        servicio.setEstado(EstadoServicio.EN_CURSO);
        ResponseStatusException e = assertThrows(ResponseStatusException.class, () -> servicioService
                .calificarServicio("s1", "pasajero", 5.0, "x", pasajeroId.toString()));
        assertEquals(HttpStatus.BAD_REQUEST, estado(e));
        assertEquals(EstadoServicio.EN_CURSO, servicio.getEstado());
    }

    @Test
    void laCalificacionDebeEstarEnRango() {
        for (double invalida : new double[] { -1, 5.5, Double.NaN }) {
            ResponseStatusException e = assertThrows(ResponseStatusException.class, () -> servicioService
                    .calificarServicio("s1", "pasajero", invalida, "x", pasajeroId.toString()));
            assertEquals(HttpStatus.BAD_REQUEST, estado(e));
        }
    }

    @Test
    void guardaLosFactoresDeQuienCalificaEnOrdenDelCatalogo() {
        servicioService.calificarServicio("s1", "pasajero", 2.0, "tarde",
                java.util.List.of("LLEGADA_TARDE", "ACEPTACION_LENTA", "LLEGADA_TARDE"), pasajeroId.toString());
        assertEquals(java.util.List.of("ACEPTACION_LENTA", "LLEGADA_TARDE"), servicio.getFactoresConductor());
        assertEquals(2.0, servicio.getCalificacionConductor());
    }

    @Test
    void unFactorQueContradiceLaNotaODeOtroRolDa400() {
        for (java.util.List<String> malos : java.util.List.of(
                java.util.List.of("LLEGADA_TARDE"),        // negativo con 5 estrellas
                java.util.List.of("ESPERA_EN_EL_PUNTO"),   // es del conductor
                java.util.List.of("NO_EXISTE"))) {
            ResponseStatusException e = assertThrows(ResponseStatusException.class, () -> servicioService
                    .calificarServicio("s1", "pasajero", 5.0, "", malos, pasajeroId.toString()));
            assertEquals(HttpStatus.BAD_REQUEST, estado(e));
        }
        verify(servicioRepository, never()).save(any());
    }

    @Test
    void elPasajeroDelViajeSiPuedeCalificar() {
        assertNotNull(servicioService.calificarServicio("s1", "pasajero", 4.5, "bien", pasajeroId.toString()));
        assertEquals(4.5, servicio.getCalificacionConductor());
    }
}
