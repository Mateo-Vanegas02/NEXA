package com.example.MotvirsWeb.aplicacion.verificacion;

import com.example.MotvirsWeb.aplicacion.puerto.NotificadorCorreo;
import com.example.MotvirsWeb.dominio.modelo.AuditoriaVerificacion;
import com.example.MotvirsWeb.dominio.modelo.AuditoriaVerificacion.Accion;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.dominio.modelo.Rol;
import com.example.MotvirsWeb.dominio.modelo.Usuario;
import com.example.MotvirsWeb.dominio.repositorio.AuditoriaVerificacionRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class RevisionConductorServiceTest {

    private UsuarioRepository usuarios;
    private AuditoriaVerificacionRepository auditoria;
    private NotificadorCorreo correo;
    private RevisionConductorService servicio;
    private Conductor c;

    @BeforeEach
    void preparar() {
        usuarios = mock(UsuarioRepository.class);
        auditoria = mock(AuditoriaVerificacionRepository.class);
        correo = mock(NotificadorCorreo.class);
        servicio = new RevisionConductorService(usuarios, auditoria, correo, 15, "America/Bogota");
        c = Conductor.builder().email("c@test.com").rol(Rol.CONDUCTOR).licencia(1234567).build();
        c.setEstadoValidacion(EstadoValidacion.PENDIENTE);
        when(usuarios.findConductorByEmail("c@test.com")).thenReturn(Optional.of(c));
        when(auditoria.save(any())).thenAnswer(i -> i.getArgument(0));
    }

    @Test
    void solicitarInformacionPasaAEnRevisionConPlazoYCorreo() {
        AuditoriaVerificacion a = servicio.solicitarInformacion("c@test.com", "admin@x.com", "Foto del SOAT ilegible");

        assertEquals(EstadoValidacion.EN_REVISION, c.getEstadoValidacion());
        assertEquals("Foto del SOAT ilegible", c.getRevisionMensaje());
        LocalDate hoy = LocalDate.now(ZoneId.of("America/Bogota"));
        assertTrue(c.getRevisionPlazo().isAfter(hoy.plusDays(14)));
        assertEquals(Accion.SOLICITUD_INFO, a.getAccion());
        verify(correo).enviarSolicitudInformacion(eq("c@test.com"), any(), eq("Foto del SOAT ilegible"), eq(c.getRevisionPlazo()));
    }

    @Test
    void noSePuedePedirInformacionAUnConductorYaDecidido() {
        c.setEstadoValidacion(EstadoValidacion.APROBADO);
        assertThrows(VerificacionException.class, () -> servicio.solicitarInformacion("c@test.com", "a", "Falta algo importante"));
        verifyNoInteractions(correo);
    }

    @Test
    void registrarRespuestaVuelveAPendiente() {
        c.setEstadoValidacion(EstadoValidacion.EN_REVISION);
        c.setRevisionPlazo(LocalDate.now().plusDays(3));

        servicio.registrarRespuesta("c@test.com", "admin@x.com", null);

        assertEquals(EstadoValidacion.PENDIENTE, c.getEstadoValidacion());
        assertNull(c.getRevisionPlazo());
    }

    @Test
    void registrarRespuestaExigeEstarEnRevision() {
        assertThrows(VerificacionException.class, () -> servicio.registrarRespuesta("c@test.com", "a", null));
    }

    @Test
    void vencerPlazosRechazaSoloLosVencidos() {
        Conductor vencido = Conductor.builder().email("v@test.com").rol(Rol.CONDUCTOR).build();
        vencido.setEstadoValidacion(EstadoValidacion.EN_REVISION);
        vencido.setRevisionPlazo(LocalDate.now().minusDays(2));
        Conductor vigente = Conductor.builder().email("g@test.com").rol(Rol.CONDUCTOR).build();
        vigente.setEstadoValidacion(EstadoValidacion.EN_REVISION);
        vigente.setRevisionPlazo(LocalDate.now().plusDays(2));
        when(usuarios.findByRolAndEstadoValidacion(Rol.CONDUCTOR, EstadoValidacion.EN_REVISION))
                .thenReturn(List.<Usuario>of(vencido, vigente));

        int n = servicio.vencerPlazos();

        assertEquals(1, n);
        assertEquals(EstadoValidacion.RECHAZADO, vencido.getEstadoValidacion());
        assertEquals(EstadoValidacion.EN_REVISION, vigente.getEstadoValidacion());
        ArgumentCaptor<AuditoriaVerificacion> cap = ArgumentCaptor.forClass(AuditoriaVerificacion.class);
        verify(auditoria).save(cap.capture());
        assertEquals("sistema", cap.getValue().getAdminEmail());
        verify(correo).enviarRechazoPorPlazo(eq("v@test.com"), any());
    }
}
