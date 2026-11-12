package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorPush;
import com.example.MotvirsWeb.aplicacion.puerto.NotificadorPush.Aviso;
import com.example.MotvirsWeb.aplicacion.puerto.NotificadorPush.Canal;
import com.example.MotvirsWeb.dominio.modelo.CanalServicio;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.regla.DespachoOlas;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaProperties;
import com.example.MotvirsWeb.dominio.regla.ModeloNexaPropertiesTestSupport;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** Qué push sale con cada evento, a quién y con qué texto. */
class AvisosServiceTest {

    private static final ZoneId BOGOTA = ZoneId.of("America/Bogota");
    private static final PuntoGeo RECOGIDA = new PuntoGeo(10.4236, -75.5253);

    private final Instant ahora = Instant.parse("2026-11-11T17:00:00Z");
    private final Clock reloj = Clock.fixed(ahora, BOGOTA);
    private final ModeloNexaProperties cfg = ModeloNexaPropertiesTestSupport.cargar();
    private final NotificadorPush push = mock(NotificadorPush.class);
    private final DispositivosService dispositivos = mock(DispositivosService.class);
    private final NivelesService niveles = mock(NivelesService.class);
    private final UsuarioRepository usuarios = mock(UsuarioRepository.class);
    private UbicacionConductorService ubicaciones;
    private AvisosService avisos;

    private final Conductor cerca = conductor("Carlos Pérez");
    private final Conductor lejos = conductor("Andrés Gómez");
    private final Conductor deLaWeb = conductor("Mario Ruiz");

    private static Conductor conductor(String nombre) {
        return Conductor.builder().id(new ObjectId()).nombre_y_Apellido(nombre).email(nombre + "@t.co").build();
    }

    @BeforeEach
    void preparar() {
        ubicaciones = new UbicacionConductorService(cfg, reloj);
        DespachoService despacho = new DespachoService(new DespachoOlas(cfg), ubicaciones, reloj, cfg);
        avisos = new AvisosService(push, dispositivos, ubicaciones, despacho, niveles, usuarios, cfg);
        when(push.activo()).thenReturn(true);
        ubicaciones.registrar(cerca.getId(), new PuntoGeo(10.4300, -75.5253), true, CanalServicio.APP); // ~0,7 km
        ubicaciones.registrar(lejos.getId(), new PuntoGeo(10.4440, -75.5253), true, CanalServicio.APP); // ~2,3 km
        ubicaciones.registrar(deLaWeb.getId(), new PuntoGeo(10.4300, -75.5253), true, CanalServicio.WEB);
        when(usuarios.findAllById(any())).thenReturn(List.of(cerca, lejos, deLaWeb));
        when(niveles.gananciaEstimada(any(), any())).thenReturn(6964L);
        when(dispositivos.tokensDe(anyCollection())).thenAnswer(i -> {
            Map<ObjectId, List<String>> m = new HashMap<>();
            for (Object id : (Collection<?>) i.getArgument(0)) {
                m.put((ObjectId) id, List.of("tok-" + id));
            }
            return m;
        });
    }

    private Servicio solicitud(CanalServicio canal, long segundosEsperando) {
        Servicio s = new Servicio();
        s.setId("s1");
        s.setEstado(EstadoServicio.SOLICITADO);
        s.setCanal(canal);
        s.setPasajero(new Servicio.PasajeroEmbedded(new ObjectId(), "Laura Díaz", "l@t.co"));
        s.setUbicacionOrigen(new Servicio.Coordenada(RECOGIDA.latitud(), RECOGIDA.longitud()));
        s.setDestino("C.C. Unicentro");
        s.setDistanciaKM(3.4);
        s.setSolicitadoEn(LocalDateTime.now(reloj).minusSeconds(segundosEsperando));
        return s;
    }

    @SuppressWarnings("unchecked")
    private Map<String, Aviso> enviados() {
        ArgumentCaptor<Collection<String>> tokens = ArgumentCaptor.forClass(Collection.class);
        ArgumentCaptor<Aviso> aviso = ArgumentCaptor.forClass(Aviso.class);
        verify(push, org.mockito.Mockito.atLeast(0)).enviar(tokens.capture(), aviso.capture());
        Map<String, Aviso> porToken = new HashMap<>();
        for (int i = 0; i < aviso.getAllValues().size(); i++) {
            for (String t : tokens.getAllValues().get(i)) {
                porToken.put(t, aviso.getAllValues().get(i));
            }
        }
        return porToken;
    }

    @Test
    void laSolicitudNuevaLlegaSoloALosConductoresDeLaAppEnLaPrimeraOla() {
        avisos.solicitudNueva(solicitud(CanalServicio.APP, 0));

        Map<String, Aviso> enviados = enviados();
        assertEquals(1, enviados.size(), "solo el de la app a 0,7 km (la primera ola es de 1,5 km)");
        Aviso a = enviados.get("tok-" + cerca.getId());
        assertEquals("SOLICITUD_NUEVA", a.tipo());
        assertEquals(Canal.SOLICITUDES, a.canal());
        assertEquals("Nueva solicitud · Ganas $6.964", a.titulo());
        assertTrue(a.cuerpo().startsWith("A 7"), a.cuerpo());
        assertTrue(a.cuerpo().contains("3,4 km de viaje · C.C. Unicentro"), a.cuerpo());
        assertEquals("s1", a.datos().get("servicioId"));
        assertEquals(Duration.ofSeconds(45), a.vigencia());
    }

    @Test
    void alAmpliarLaOlaSoloSeAvisaALosQueEntranAhora() {
        avisos.olaAmpliada(solicitud(CanalServicio.APP, 30), 1, 2);

        Map<String, Aviso> enviados = enviados();
        assertEquals(List.of("tok-" + lejos.getId()), List.copyOf(enviados.keySet()));
    }

    @Test
    void siElExtraAdelantaLaOlaNoLlegaDosVecesAlMismoConductor() {
        Servicio s = solicitud(CanalServicio.APP, 0);
        s.setExtraVoluntario(1000);
        avisos.extraSubido(s);        // ya avisa a los de la ola a la que saltó
        avisos.olaAmpliada(s, 1, 2);  // el planificador ve el salto después

        ArgumentCaptor<Aviso> aviso = ArgumentCaptor.forClass(Aviso.class);
        verify(push, times(2)).enviar(any(), aviso.capture()); // cerca y lejos, una vez cada uno
        assertTrue(aviso.getAllValues().stream().allMatch(a -> "SOLICITUD_EXTRA".equals(a.tipo())));
    }

    @Test
    void olvidaLasSolicitudesCerradasYYaNoLesAvisaElRetiro() {
        Servicio s = solicitud(CanalServicio.APP, 0);
        avisos.solicitudNueva(s);
        avisos.olvidarCerradas(List.of());

        avisos.solicitudRetirada(s, "CANCELADO");

        verify(push, times(1)).enviar(any(), any()); // solo el aviso de la solicitud nueva
    }

    @Test
    void unaSolicitudDeLaWebNoGeneraPush() {
        avisos.solicitudNueva(solicitud(CanalServicio.WEB, 0));
        avisos.viajeAceptado(solicitud(CanalServicio.WEB, 0));
        verify(push, never()).enviar(any(), any());
    }

    @Test
    void sinCredencialesDeFirebaseNoSePreparaNada() {
        when(push.activo()).thenReturn(false);
        avisos.solicitudNueva(solicitud(CanalServicio.APP, 0));
        verify(push, never()).enviar(any(), any());
        verify(usuarios, never()).findAllById(any());
    }

    @Test
    void alTomarseLaSolicitudLosDemasAvisadosLaQuitanEnSilencio() {
        Servicio s = solicitud(CanalServicio.APP, 0);
        avisos.olaAmpliada(s, 0, 2); // cerca y lejos
        s.setConductor(new Servicio.ConductorEmbedded(cerca));

        avisos.solicitudRetirada(s, "TOMADO");

        ArgumentCaptor<Aviso> aviso = ArgumentCaptor.forClass(Aviso.class);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<Collection<String>> tokens = ArgumentCaptor.forClass(Collection.class);
        verify(push, times(3)).enviar(tokens.capture(), aviso.capture());
        Aviso retiro = aviso.getAllValues().get(2);
        assertEquals(Canal.SILENCIOSO, retiro.canal());
        assertEquals("TOMADO", retiro.datos().get("motivo"));
        assertEquals(List.of("tok-" + lejos.getId()), List.copyOf(tokens.getAllValues().get(2)),
                "el que la tomó no recibe el retiro");
    }

    @Test
    void elPasajeroSabeQuienVaPorElYLaPlaca() {
        Servicio s = solicitud(CanalServicio.APP, 0);
        Servicio.ConductorEmbedded c = new Servicio.ConductorEmbedded(cerca);
        c.setVehiculo("Yamaha NMAX · gris");
        c.setPlaca("KZT 38F");
        s.setConductor(c);
        when(dispositivos.tokensDe(s.getPasajero().getId())).thenReturn(List.of("tok-pasajero"));

        avisos.viajeAceptado(s);
        avisos.conductorLlego(s);

        ArgumentCaptor<Aviso> aviso = ArgumentCaptor.forClass(Aviso.class);
        verify(push, times(2)).enviar(any(), aviso.capture());
        assertEquals("Carlos va por ti", aviso.getAllValues().get(0).titulo());
        assertEquals("Yamaha NMAX · gris · KZT 38F", aviso.getAllValues().get(0).cuerpo());
        assertEquals(Canal.VIAJE, aviso.getAllValues().get(0).canal());
        assertEquals("Carlos está en el punto", aviso.getAllValues().get(1).titulo());
        assertEquals("Busca la placa KZT 38F", aviso.getAllValues().get(1).cuerpo());
        assertEquals("VIAJE_ACEPTADO:s1", aviso.getAllValues().get(0).eventoId());
    }

    @Test
    void laCancelacionLeLlegaAlOtroLado() {
        Servicio s = solicitud(CanalServicio.APP, 0);
        s.setConductor(new Servicio.ConductorEmbedded(cerca));
        s.setCanceladoPor("PASAJERO");
        when(dispositivos.tokensDe(cerca.getId())).thenReturn(List.of("tok-conductor"));

        avisos.viajeCancelado(s);

        ArgumentCaptor<Aviso> aviso = ArgumentCaptor.forClass(Aviso.class);
        verify(push).enviar(org.mockito.ArgumentMatchers.eq(List.of("tok-conductor")), aviso.capture());
        assertEquals("Laura canceló el viaje", aviso.getValue().titulo());
        assertFalse(aviso.getValue().cuerpo().contains("$"), "el conductor no ve cargos del pasajero");
    }

    @Test
    void formatos() {
        assertEquals("$6.964", AvisosService.pesos(6964));
        assertEquals("$1.000", AvisosService.pesos(1000));
        assertEquals("650 m", AvisosService.metros(0.648));
        assertEquals("2,3 km", AvisosService.metros(2.31));
        assertEquals("Carlos", AvisosService.primerNombre("  Carlos Pérez ", "x"));
        assertEquals("x", AvisosService.primerNombre(null, "x"));
    }
}
