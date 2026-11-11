package com.example.MotvirsWeb.aplicacion.verificacion;

import com.example.MotvirsWeb.dominio.modelo.AuditoriaVerificacion;
import com.example.MotvirsWeb.dominio.modelo.AuditoriaVerificacion.Accion;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.dominio.modelo.Rol;
import com.example.MotvirsWeb.dominio.modelo.Vehiculo;
import com.example.MotvirsWeb.dominio.repositorio.AuditoriaVerificacionRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.example.MotvirsWeb.dominio.repositorio.VehiculoRepository;
import com.example.MotvirsWeb.infraestructura.socket.WebSocketService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import com.example.MotvirsWeb.infraestructura.verificacion.ManualVerificationProvider;
import com.example.MotvirsWeb.infraestructura.verificacion.MockVerificationProvider;

/** Repositorios en memoria (mocks con lista): no toca ninguna base real. */
class VerificacionConductorServiceTest {

    private UsuarioRepository usuarios;
    private VehiculoRepository vehiculos;
    private AuditoriaVerificacionRepository auditoriaRepo;
    private final List<AuditoriaVerificacion> auditoria = new ArrayList<>();
    private Conductor conductor;

    @BeforeEach
    void setUp() {
        usuarios = mock(UsuarioRepository.class);
        vehiculos = mock(VehiculoRepository.class);
        auditoriaRepo = mock(AuditoriaVerificacionRepository.class);
        conductor = Conductor.builder().email("c@test.com").rol(Rol.CONDUCTOR)
                .estadoValidacion(EstadoValidacion.PENDIENTE).licencia(1234567).build();
        conductor.setId(new org.bson.types.ObjectId("507f1f77bcf86cd799439011"));
        when(usuarios.findConductorByEmail("c@test.com")).thenReturn(Optional.of(conductor));
        when(usuarios.findConductorByEmail("otro@test.com")).thenReturn(Optional.empty());
        when(vehiculos.findByConductorAsignado(conductor))
                .thenReturn(List.of(Vehiculo.builder().placa("ABC123").activo(true).build()));
        when(auditoriaRepo.save(any())).thenAnswer(i -> {
            AuditoriaVerificacion a = i.getArgument(0);
            auditoria.add(0, a);
            return a;
        });
        when(auditoriaRepo.findTop20ByConductorEmailOrderByFechaDesc(any())).thenAnswer(i -> new ArrayList<>(auditoria));
    }

    private VerificacionConductorService servicio(DriverVerificationProvider p) {
        return new VerificacionConductorService(usuarios, vehiculos, auditoriaRepo, p, mock(WebSocketService.class), true);
    }

    @Test
    void conProveedorManualElResultadoEsUnavailableYNoSeApruebaSolo() {
        VerificacionConductorService s = servicio(new ManualVerificationProvider());
        AuditoriaVerificacion a = s.verificar("c@test.com", "admin@test.com", null);
        assertEquals("UNAVAILABLE", a.getResultado());
        assertEquals(EstadoValidacion.PENDIENTE, conductor.getEstadoValidacion());
        assertEquals("admin@test.com", a.getAdminEmail());
        assertEquals("****567", a.getDocumentoEnmascarado());
    }

    @Test
    void noSePuedeAprobarSinVerificacionVerified() {
        VerificacionConductorService s = servicio(new ManualVerificationProvider());
        s.verificar("c@test.com", "admin@test.com", null);
        VerificacionException ex = assertThrows(VerificacionException.class,
                () -> s.decidir("c@test.com", "admin@test.com", true, null));
        assertEquals(VerificacionException.Tipo.NO_VERIFICADO, ex.getTipo());
        assertEquals(EstadoValidacion.PENDIENTE, conductor.getEstadoValidacion());
        verify(usuarios, never()).save(any());
    }

    @Test
    void verificacionManualHabilitaAprobarYQuedaAuditada() {
        VerificacionConductorService s = servicio(new ManualVerificationProvider());
        s.marcarManual("c@test.com", "admin@test.com", VerificationStatus.VERIFIED, "Documentos revisados y legibles");
        AuditoriaVerificacion dec = s.decidir("c@test.com", "admin@test.com", true, null);
        assertEquals(EstadoValidacion.APROBADO, conductor.getEstadoValidacion());
        assertEquals(Accion.APROBADO, dec.getAccion());
        assertEquals("VERIFIED", dec.getResultado());
        assertEquals(2, auditoria.size());
        assertNotNull(dec.getFecha());
    }

    @Test
    void conMockVerificaYApruebaPeroMismatchBloquea() {
        VerificacionConductorService s = servicio(new MockVerificationProvider());
        assertEquals("VERIFIED", s.verificar("c@test.com", "a@test.com", null).getResultado());

        when(vehiculos.findByConductorAsignado(conductor))
                .thenReturn(List.of(Vehiculo.builder().placa("MMM123").activo(true).build()));
        auditoria.clear();
        assertEquals("MISMATCH", s.verificar("c@test.com", "a@test.com", null).getResultado());
        assertThrows(VerificacionException.class, () -> s.decidir("c@test.com", "a@test.com", true, null));
    }

    @Test
    void rechazarExigeMotivoValidoYSeAudita() {
        VerificacionConductorService s = servicio(new ManualVerificationProvider());
        assertThrows(EntradaInvalidaException.class, () -> s.decidir("c@test.com", "a@test.com", false, null));
        assertThrows(EntradaInvalidaException.class, () -> s.decidir("c@test.com", "a@test.com", false, "<b>x</b>"));
        assertEquals(EstadoValidacion.PENDIENTE, conductor.getEstadoValidacion());
        AuditoriaVerificacion a = s.decidir("c@test.com", "a@test.com", false, "Placa no coincide con tarjeta");
        assertEquals(EstadoValidacion.RECHAZADO, conductor.getEstadoValidacion());
        assertEquals(Accion.RECHAZADO, a.getAccion());
        assertEquals("Placa no coincide con tarjeta", a.getMotivo());
    }

    @Test
    void siElProveedorLanzaExcepcionDegradaAUnavailable() {
        DriverVerificationProvider roto = mock(DriverVerificationProvider.class);
        when(roto.nombre()).thenReturn("ROTO");
        when(roto.verifyPlate(any(), any())).thenThrow(new IllegalStateException("fallo interno secreto"));
        when(roto.verifyDriver(any())).thenThrow(new RuntimeException("otro"));
        AuditoriaVerificacion a = servicio(roto).verificar("c@test.com", "a@test.com", null);
        assertEquals("UNAVAILABLE", a.getResultado());
        assertFalse(String.valueOf(a.getMotivo()).contains("secreto"));
        assertEquals(EstadoValidacion.PENDIENTE, conductor.getEstadoValidacion());
    }

    @Test
    void entradasInvalidasYEstados() {
        VerificacionConductorService s = servicio(new MockVerificationProvider());
        assertThrows(EntradaInvalidaException.class, () -> s.verificar("c@test.com", "a@test.com", "12ab"));
        assertEquals(VerificacionException.Tipo.NO_ENCONTRADO, assertThrows(VerificacionException.class,
                () -> s.estado("otro@test.com")).getTipo());
        assertThrows(EntradaInvalidaException.class,
                () -> s.marcarManual("c@test.com", "a@test.com", VerificationStatus.UNAVAILABLE, "nota valida"));
        conductor.setEstadoValidacion(EstadoValidacion.APROBADO);
        assertEquals(VerificacionException.Tipo.ESTADO_INVALIDO, assertThrows(VerificacionException.class,
                () -> s.decidir("c@test.com", "a@test.com", false, "motivo valido")).getTipo());
    }

    @Test
    void placaLegadaConFormatoInvalidoQuedaUnavailable() {
        when(vehiculos.findByConductorAsignado(conductor))
                .thenReturn(List.of(Vehiculo.builder().placa("ABCDEF").activo(true).build()));
        AuditoriaVerificacion a = servicio(new MockVerificationProvider()).verificar("c@test.com", "a@test.com", null);
        assertEquals("UNAVAILABLE", a.getResultadoPlaca());
    }

    @Test
    void limiteDeVerificacionesPorAdmin() {
        VerificacionConductorService s = servicio(new MockVerificationProvider());
        for (int i = 0; i < 20; i++) {
            s.verificar("c@test.com", "spam@test.com", null);
        }
        assertEquals(VerificacionException.Tipo.LIMITE_EXCEDIDO, assertThrows(VerificacionException.class,
                () -> s.verificar("c@test.com", "spam@test.com", null)).getTipo());
    }
}
